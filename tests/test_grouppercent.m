classdef test_grouppercent < matlab.unittest.TestCase
   %TEST_GROUPPERCENT Test groupstats.grouppercent.
   %
   % grouppercent adds a within-group percent to a count table. These cases
   % separate that quantity from Percent, which groupcounts already returns,
   % and cover the two ways a table can arrive: raw, or already summarized.
   %
   % See also: groupstats.grouppercent

   properties
      Tbl
      GroupVars
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         data = groupstats.test.generateTestData('groupsummary');
         testCase.Tbl = data.tbl;
         testCase.GroupVars = data.groupvars;
      end
   end

   methods (Test)

      function testWithinGroupPercentSumsToOneHundred(testCase)
         % Every member's rows sum to 100 in its own Percent_<var> column.

         G = groupstats.grouppercent(testCase.Tbl, ["Grp", "Sub"]);

         members = unique(G.Grp);
         for n = 1:numel(members)
            rows = G.Grp == members(n);
            returned = sum(G.Percent_Grp(rows));
            testCase.verifyEqual(returned, 100, 'AbsTol', 1e-10);
         end
      end

      function testPercentSumsToOneHundredOverTheTable(testCase)
         % Percent is a different quantity: each row's share of every
         % observation, so the whole column sums to 100.

         G = groupstats.grouppercent(testCase.Tbl, ["Grp", "Sub"]);

         returned = sum(G.Percent);
         testCase.verifyEqual(returned, 100, 'AbsTol', 1e-10);
      end

      function testOneRowPerGroupIsOneHundredPercent(testCase)
         % A member holding one row is 100 percent of itself. Normalizing over
         % the whole table instead would report that row's share of every
         % observation, which is what Percent already reports.

         G = groupstats.grouppercent(testCase.Tbl, "Grp");

         returned = G.Percent_Grp;
         expected = repmat(100, height(G), 1);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);
      end

      function testGroupsetsOutsideGroupvarsCountsPerSet(testCase)
         % A groupsets variable that is not among groupvars splits the table
         % into one count per set, then stacks them.

         G = groupstats.grouppercent(testCase.Tbl, "Sub", "none", "Grp");

         returned = sort(unique(string(G.Grp)));
         expected = ["a"; "b"; "c"];
         testCase.verifyEqual(returned, expected);
      end

      function testGroupsetsPercentSumsWithinEachSet(testCase)
         % With a set variable, each set's rows sum to 100.

         G = groupstats.grouppercent(testCase.Tbl, "Sub", "none", "Grp");

         sets = unique(G.Grp);
         for n = 1:numel(sets)
            rows = G.Grp == sets(n);
            returned = sum(G.Percent_Grp(rows));
            testCase.verifyEqual(returned, 100, 'AbsTol', 1e-10);
         end
      end

      function testSeveralGroupsetsError(testCase)
         % Counting by two set variables at once would need a grid over their
         % members. Report that rather than index with a non-scalar name.

         testCase.verifyError( ...
            @() groupstats.grouppercent(testCase.Tbl, "Sub", "none", ...
            ["Grp", "Set"]), ...
            'groupstats:grouppercent:multipleGroupSets');
      end

      function testNoneSentinelIsAccepted(testCase)
         % groupstats.groupsummary passes "none" down. It means the same as an
         % empty groupsets: use groupvars.

         withnone = groupstats.grouppercent(testCase.Tbl, "Grp", "none", "none");
         withempty = groupstats.grouppercent(testCase.Tbl, "Grp");

         testCase.verifyEqual(withnone, withempty);
      end

      function testSummarizedTableIsNotRecounted(testCase)
         % A table that already carries GroupCount is used as it is. Only the
         % percent columns are added.

         counted = groupcounts(testCase.Tbl, "Grp");

         G = groupstats.grouppercent(counted, "Grp");

         returned = G.GroupCount;
         expected = counted.GroupCount;
         testCase.verifyEqual(returned, expected);

         returned = height(G);
         expected = height(counted);
         testCase.verifyEqual(returned, expected);
      end

      function testBinnedVariableDropsTheDiscPrefix(testCase)
         % groupcounts names a binned variable disc_<name>. Strip it so a
         % caller reads the same name whether or not groupbins was used.

         G = groupstats.grouppercent(testCase.Tbl, "Value", {[0 6 12]});

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "Value"));
         testCase.verifyFalse(any(startsWith(returned, "disc_")));
      end

      function testCallerVariableNamedDiscSurvives(testCase)
         % Only a name groupcounts built from a group variable loses its disc_
         % prefix. A variable the caller named disc_something keeps it.

         tbl = testCase.Tbl;
         tbl.Properties.VariableNames{1} = 'disc_Grp';

         G = groupstats.grouppercent(tbl, "disc_Grp");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "disc_Grp"));
      end
   end
end
