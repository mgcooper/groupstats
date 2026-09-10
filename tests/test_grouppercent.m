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

         G = groupstats.grouppercent(testCase.Tbl, "Sub", GroupSets = "Grp");

         returned = sort(unique(string(G.Grp)));
         expected = ["a"; "b"; "c"];
         testCase.verifyEqual(returned, expected);
      end

      function testGroupsetsPercentSumsWithinEachSet(testCase)
         % With a set variable, each set's rows sum to 100.

         G = groupstats.grouppercent(testCase.Tbl, "Sub", GroupSets = "Grp");

         sets = unique(G.Grp);
         for n = 1:numel(sets)
            rows = G.Grp == sets(n);
            returned = sum(G.Percent_Grp(rows));
            testCase.verifyEqual(returned, 100, 'AbsTol', 1e-10);
         end
      end

      function testMixedGroupsetsCountsTheExtraSet(testCase)
         % A GroupSets vector may mix a variable that is among groupvars
         % with one that is not. The extra one is counted per set, and
         % every named variable gets its percent column.

         G = groupstats.grouppercent(testCase.Tbl, "Grp", ...
            GroupSets = ["Grp", "Set"]);

         % The fixture: Grp a is rows 1 to 4, b 5 to 8, c 9 to 12; Set p is
         % rows 1 to 6 and q 7 to 12. Counting per set gives (a,p)=4,
         % (b,p)=2, (b,q)=2, (c,q)=4. Within Grp, b splits 50/50 and a and
         % c are whole. Within Set, each set is 4 of 6 and 2 of 6.
         G = sortrows(G, ["Set", "Grp"]);

         returned = string(G.Grp);
         expected = ["a"; "b"; "b"; "c"];
         testCase.verifyEqual(returned, expected);

         returned = G.GroupCount;
         expected = [4; 2; 2; 4];
         testCase.verifyEqual(returned, expected);

         returned = G.Percent_Grp;
         expected = [100; 50; 50; 100];
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);

         returned = G.Percent_Set;
         expected = 100 * [4; 2; 2; 4] / 6;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);
      end

      function testSeveralGroupsetsError(testCase)
         % Counting by two set variables at once would need a grid over their
         % members. Report that rather than index with a non-scalar name.

         testCase.verifyError( ...
            @() groupstats.grouppercent(testCase.Tbl, "Sub", ...
            GroupSets = ["Grp", "Set"]), ...
            'groupstats:grouppercent:multipleGroupSets');
      end

      function testNoneGroupSetsSentinelErrors(testCase)
         % string.empty() is the one no-groupsets sentinel, so a scalar
         % "none" GroupSets is rejected with a rewrite hint. The third
         % argument here is groupbins, where "none" stays legal as a
         % binning scheme.

         % Catch the exception directly so the message guidance is checked
         % too, not only the identifier.
         exception = MException.empty();
         try
            groupstats.grouppercent(testCase.Tbl, "Grp", "none", ...
               GroupSets = "none");
         catch exception
         end
         testCase.assertNotEmpty(exception);
         returned = exception.identifier;
         expected = 'groupstats:validategroupsets:noneIsNotASentinel';
         testCase.verifyEqual(returned, expected);
         testCase.verifySubstring(exception.message, "string.empty()");
      end

      function testEmptyGroupSetsMeansUseGroupVars(testCase)
         % An explicit string.empty() GroupSets must mean the same as
         % omitting the option: use groupvars.

         returned = groupstats.grouppercent(testCase.Tbl, "Grp", "none", ...
            GroupSets = string.empty());
         expected = groupstats.grouppercent(testCase.Tbl, "Grp");

         testCase.verifyEqual(returned, expected);
      end

      function testRowSelectKeepsOnlyTheNamedMembers(testCase)
         % RowSelectVar and RowSelectMembers drop rows before counting, the
         % same option pair groupsummary has.

         G = groupstats.grouppercent(testCase.Tbl, "Grp", ...
            RowSelectVar = "Sub", RowSelectMembers = "x");

         returned = sum(G.GroupCount);
         expected = sum(testCase.Tbl.Sub == "x");
         testCase.verifyEqual(returned, expected);
      end

      function testRowSelectMembersWithoutVarErrors(testCase)
         % Members alone have no column to search, under this function's
         % own identifier.

         testCase.verifyError( ...
            @() groupstats.grouppercent(testCase.Tbl, "Grp", ...
            RowSelectMembers = "x"), ...
            'groupstats:grouppercent:membersWithoutGroupVar');
      end

      function testRowSelectOnASummarizedTableErrors(testCase)
         % A summarized table has one row per group, so selecting its rows
         % would drop groups from a count already made.

         counted = groupcounts(testCase.Tbl, "Grp");

         testCase.verifyError( ...
            @() groupstats.grouppercent(counted, "Grp", ...
            RowSelectVar = "Grp", RowSelectMembers = "a"), ...
            'groupstats:grouppercent:rowSelectOnSummarizedTable');
      end

      function testRowSelectVarWithoutMembersErrors(testCase)
         % The other half alone selects no rows and leaves an empty count.

         testCase.verifyError( ...
            @() groupstats.grouppercent(testCase.Tbl, "Grp", ...
            RowSelectVar = "Sub"), ...
            'groupstats:grouppercent:rowSelectVarWithoutMembers');
      end

      function testEmptySummarizedCellstrTableReturnsEmpty(testCase)
         % A zero-row summarized table with a cellstr group column has no
         % first element to inspect, so the conversion must not read one.

         counted = table(cell(0, 1), zeros(0, 1), zeros(0, 1), ...
            'VariableNames', {'Grp', 'GroupCount', 'Percent'});

         G = groupstats.grouppercent(counted, "Grp");

         returned = height(G);
         expected = 0;
         testCase.verifyEqual(returned, expected);

         returned = ismember("Percent_Grp", ...
            string(G.Properties.VariableNames));
         expected = true;
         testCase.verifyEqual(returned, expected);
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

      function testIncludedEdgePicksTheBinOfAValueOnAnEdge(testCase)
         % Value runs 1 to 12. With edges [0 6 12], "left" puts 6 in the
         % second bin and "right" puts it in the first, and the percents
         % follow the counts.

         G = groupstats.grouppercent(testCase.Tbl, "Value", {[0 6 12]});
         returned = G.GroupCount(:);
         expected = [5; 7];
         testCase.verifyEqual(returned, expected);

         G = groupstats.grouppercent(testCase.Tbl, "Value", {[0 6 12]}, ...
            IncludedEdge = "right");
         returned = [G.GroupCount(:); G.Percent(:)];
         expected = [6; 6; 50; 50];
         testCase.verifyEqual(returned, expected);
      end

   end
end
