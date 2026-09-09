classdef test_groupcompare < matlab.unittest.TestCase
   %TEST_GROUPCOMPARE Test groupstats.groupcompare.
   %
   % groupcompare is the reference comparison. These cases pin the one row
   % per comparison shape with plain columns and the explicit Test option.
   % They also pin the reference-relative Tail, the Bootstrap opt-in, and
   % the set and pooled forms. The bootstrap draws are seeded.
   %
   % See also: groupstats.groupcompare, groupstats.test.generateTestData

   properties
      Tbl
      GroupVar
      DataVar
      ConditionVar
      Reference
      Expected
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         [data, expected] = ...
            groupstats.test.generateTestData('groupcompare');
         testCase.Tbl = data.tbl;
         testCase.GroupVar = data.groupvar;
         testCase.DataVar = data.datavar;
         testCase.ConditionVar = data.conditionvar;
         testCase.Reference = data.reference;
         testCase.Expected = expected;
         state = rng(11);
         testCase.addTeardown(@() rng(state));
      end
   end

   methods (Test)

      function testOneRowPerComparisonWithPlainColumns(testCase)
         % Two members against the reference give two rows, and every
         % column is a plain array.

         stats = groupstats.groupcompare(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = testCase.Reference);

         returned = {height(stats); stats.Properties.VariableNames; ...
            stats.Reference; stats.Group; stats.DataVar; stats.Test; ...
            class(stats.P); class(stats.H)};
         expected = {2; {'Reference', 'Group', 'DataVar', 'Test', 'P', 'H'}; ...
            ["ctrl"; "ctrl"]; ["aaa"; "zzz"]; ["Value"; "Value"]; ...
            ["ranksum"; "ranksum"]; 'double'; 'logical'};
         testCase.verifyEqual(returned, expected);
      end

      function testDefaultReferenceIsTheFirstMember(testCase)
         % Without ReferenceGroup the first member in category order is the
         % reference.

         stats = groupstats.groupcompare(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar);

         returned = unique(stats.Reference);
         expected = testCase.Expected.alphabeticalReference;
         testCase.verifyEqual(returned, expected);
      end

      function testRanksumMatchesTheBuiltin(testCase)
         % P is the two-sample rank-sum p-value of the reference against
         % the group.

         tbl = testCase.Tbl;
         stats = groupstats.groupcompare(tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = "ctrl");

         returned = stats.P;
         expected = [ranksum(tbl.Value(tbl.Group == "ctrl"), ...
            tbl.Value(tbl.Group == "aaa")); ...
            ranksum(tbl.Value(tbl.Group == "ctrl"), ...
            tbl.Value(tbl.Group == "zzz"))];
         testCase.verifyEqual(returned, expected);
      end

      function testSignrankTestsAgainstTheReferenceMedian(testCase)
         % Test="signrank" is the one-sample sign-rank test of each group
         % against the reference median. In set s2 the reference is all
         % zeros, so it is a test against zero.

         tbl = testCase.Tbl;
         stats = groupstats.groupcompare(tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = "ctrl", Test = "signrank", ...
            ConditionVar = testCase.ConditionVar);

         % The fixture records the reference median of each set. The
         % expected p-values come from those medians, not from a repeat of
         % the function's own arithmetic.
         medians = testCase.Expected.setMedians;
         returned = stats.P(stats.Set == "s1" & stats.Group == "aaa");
         expected = signrank(tbl.Value(tbl.Group == "aaa" & tbl.Set == "s1"), ...
            medians(1));
         testCase.verifyEqual(returned, expected);

         returned = stats.P(stats.Set == "s2" & stats.Group == "aaa");
         expected = signrank(tbl.Value(tbl.Group == "aaa" & tbl.Set == "s2"), ...
            medians(2));
         testCase.verifyEqual(returned, expected);

         returned = unique(stats.Test);
         expected = "signrank";
         testCase.verifyEqual(returned, expected);
      end

      function testTailIsReadAgainstTheReference(testCase)
         % "right" means the reference median is greater. With a reference
         % well above the group, "right" is significant and "left" is not,
         % under every test.

         tbl = table(categorical([repmat("ref", 12, 1); repmat("g", 12, 1)]), ...
            [(20:31)'; (1:12)'], 'VariableNames', {'Group', 'Value'});

         tests = ["ranksum", "signrank", "permutation"];
         returned = false(numel(tests), 2);
         for n = 1:numel(tests)
            right = groupstats.groupcompare(tbl, "Group", "Value", ...
               ReferenceGroup = "ref", Test = tests(n), Tail = "right", ...
               NumPermutations = 200);
            left = groupstats.groupcompare(tbl, "Group", "Value", ...
               ReferenceGroup = "ref", Test = tests(n), Tail = "left", ...
               NumPermutations = 200);
            returned(n, :) = [right.H, left.H];
         end
         expected = repmat([true, false], numel(tests), 1);
         testCase.verifyEqual(returned, expected);
      end

      function testPermutationTestReportsTheOneCluster(testCase)
         % The two samples are independent trials of one data point, so
         % permutest finds one cluster. Two shifted samples reject and two
         % draws of the same distribution do not.

         % Twenty-five values a side keep nchoosek(50, 25) exact, so
         % permutest counts its permutations without a warning.
         tbl = table(categorical([repmat("ref", 25, 1); repmat("far", 25, 1); ...
            repmat("same", 25, 1)]), [randn(25, 1); randn(25, 1) + 3; ...
            randn(25, 1)], 'VariableNames', {'Group', 'Value'});

         stats = groupstats.groupcompare(tbl, "Group", "Value", ...
            ReferenceGroup = "ref", Test = "permutation", ...
            NumPermutations = 500);

         returned = {stats.Group; stats.H; unique(stats.Test)};
         expected = {["far"; "same"]; [true; false]; "permutation"};
         testCase.verifyEqual(returned, expected);
      end

      function testAlphaSetsTheRejectionLevel(testCase)
         % H is P at or below Alpha, so a permissive Alpha rejects where the
         % default does not.

         stats = groupstats.groupcompare(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = "ctrl");
         loose = groupstats.groupcompare(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = "ctrl", Alpha = 0.99);

         returned = {stats.H; loose.H; loose.P};
         expected = {stats.P <= 0.05; [true; true]; stats.P};
         testCase.verifyEqual(returned, expected);
      end

      function testConditionVarAddsASetColumnFirst(testCase)
         % One block of comparisons per set, Set leading the columns.

         stats = groupstats.groupcompare(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ConditionVar = testCase.ConditionVar, ...
            ReferenceGroup = "ctrl");

         returned = {stats.Properties.VariableNames(1); stats.Set; stats.Group};
         expected = {{'Set'}; repelem(testCase.Expected.sets, 2, 1); ...
            repmat(["aaa"; "zzz"], 2, 1)};
         testCase.verifyEqual(returned, expected);
      end

      function testPooledGivesOneRowPerSet(testCase)
         % Pooled compares the reference against the other members
         % combined, so each set has one row naming the pooled members.

         stats = groupstats.groupcompare(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ConditionVar = testCase.ConditionVar, ...
            ReferenceGroup = "ctrl", Pooled = true);

         returned = {height(stats); stats.Group; stats.Set};
         expected = {2; ["aaa, zzz"; "aaa, zzz"]; testCase.Expected.sets};
         testCase.verifyEqual(returned, expected);
      end

      function testBootstrapAddsTheFourColumnsAndSamples(testCase)
         % Bootstrap=true adds MedianDiff, CILower, CIUpper, HBootstrap,
         % and returns one column of differences per row.

         [stats, samples] = groupstats.groupcompare(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ReferenceGroup = "ctrl", ...
            Bootstrap = true, NumBootstrap = 200);

         returned = {stats.Properties.VariableNames(7:10); size(samples); ...
            class(stats.HBootstrap)};
         expected = {{'MedianDiff', 'CILower', 'CIUpper', 'HBootstrap'}; ...
            [200, 2]; 'logical'};
         testCase.verifyEqual(returned, expected);
      end

      function testWithoutBootstrapSamplesIsEmpty(testCase)
         % Without Bootstrap there are no bootstrap columns and no samples.

         [stats, samples] = groupstats.groupcompare(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar);

         returned = {any(stats.Properties.VariableNames == "MedianDiff"); ...
            isempty(samples)};
         expected = {false; true};
         testCase.verifyEqual(returned, expected);
      end

      function testBootstrapDifferenceIsSigned(testCase)
         % A group above the reference has a positive median difference and
         % an interval above zero; one below is negative. The old engine
         % took an absolute value and lost the sign.

         tbl = table(categorical([repmat("ref", 20, 1); repmat("up", 20, 1); ...
            repmat("down", 20, 1)]), [(1:20)'; (1:20)' + 10; (1:20)' - 10], ...
            'VariableNames', {'Group', 'Value'});

         stats = groupstats.groupcompare(tbl, "Group", "Value", ...
            ReferenceGroup = "ref", Bootstrap = true, NumBootstrap = 300);

         returned = {stats.Group; sign(stats.MedianDiff); stats.HBootstrap; ...
            stats.CILower(2) > 0; stats.CIUpper(1) < 0};
         expected = {["down"; "up"]; [-1; 1]; [true; true]; true; true};
         testCase.verifyEqual(returned, expected);
      end

      function testBootstrapSamplesFollowTheSets(testCase)
         % With sets, the sample columns follow the rows of stats.

         [stats, samples] = groupstats.groupcompare(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ConditionVar = testCase.ConditionVar, Pooled = true, ...
            Bootstrap = true, NumBootstrap = 100);

         returned = {size(samples); median(samples)'};
         expected = {[100, height(stats)]; stats.MedianDiff};
         testCase.verifyEqual(returned, expected);
      end

      function testMissingDataValuesDoNotReachTheEngines(testCase)
         % A NaN in a sample leaves it before the test and the bootstrap
         % run. The reference median, the sign-rank p, and the bootstrap
         % difference are then the ones the present values give.

         tbl = testCase.Tbl;
         tbl.Value(find(tbl.Group == "ctrl", 1)) = NaN;
         clean = testCase.Tbl;
         clean(find(clean.Group == "ctrl", 1), :) = [];

         state = rng;
         withnan = groupstats.groupcompare(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", Test = "signrank", Bootstrap = true, ...
            NumBootstrap = 100);
         rng(state);
         without = groupstats.groupcompare(clean, "Group", "Value", ...
            ReferenceGroup = "ctrl", Test = "signrank", Bootstrap = true, ...
            NumBootstrap = 100);

         returned = {withnan.P; withnan.MedianDiff; any(isnan(withnan.P))};
         expected = {without.P; without.MedianDiff; false};
         testCase.verifyEqual(returned, expected);
      end

      function testUnknownTestIsRejected(testCase)
         % Test takes the comparetest namelist values and nothing else.

         testCase.verifyError(@() groupstats.groupcompare(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, Test = "ttest"), ...
            'MATLAB:validators:mustBeMember');
      end

      function testDataErrorsCarryThisFunctionsIdentifier(testCase)
         % groupsamples reports a bad reference and an empty reference set
         % under its own identifiers. groupcompare renames them to its own,
         % so a caller pins one function. The shared preprocessing's
         % unknown-variable identifier passes through unchanged.

         tbl = testCase.Tbl;
         sparse = tbl(~(tbl.Group == "ctrl" & tbl.Set == "s2"), :);
         calls = {@() groupstats.groupcompare(tbl, "Group", "Value", ...
            ReferenceGroup = "nope"); ...
            @() groupstats.groupcompare(sparse, "Group", "Value", ...
            ReferenceGroup = "ctrl", ConditionVar = "Set"); ...
            @() groupstats.groupcompare(tbl, "Group", "nope")};
         returned = strings(3, 1);
         for n = 1:3
            try
               calls{n}();
            catch e
               returned(n) = e.identifier;
            end
         end
         expected = ["groupstats:groupcompare:badReferenceGroup"; ...
            "groupstats:groupcompare:emptyReferenceGroup"; ...
            "groupstats:prepareTableGroups:unknownVariable"];
         testCase.verifyEqual(returned, expected);
      end

      function testNoUsableRowGivesTheSchemaWithNoRows(testCase)
         % Every condition value missing leaves no set, so stats keeps its
         % columns and has no rows, with and without the bootstrap columns.

         tbl = testCase.Tbl;
         tbl.Set(:) = missing;

         stats = groupstats.groupcompare(tbl, "Group", "Value", ...
            ConditionVar = "Set");
         [boot, samples] = groupstats.groupcompare(tbl, "Group", "Value", ...
            ConditionVar = "Set", Bootstrap = true);

         returned = {height(stats); stats.Properties.VariableNames; ...
            height(boot); boot.Properties.VariableNames(end); ...
            size(samples)};
         expected = {0; {'Set', 'Reference', 'Group', 'DataVar', 'Test', ...
            'P', 'H'}; 0; {'HBootstrap'}; [10000, 0]};
         testCase.verifyEqual(returned, expected);
      end

      function testOtherErrorsPassThroughUnchanged(testCase)
         % Only groupsamples' own identifiers are renamed. A group variable
         % that cannot be read as text fails inside string(), and that
         % error keeps its identifier.

         tbl = testCase.Tbl;
         tbl.Group = [num2cell(1:height(tbl) - 1)'; {struct()}];

         raised = "";
         try
            groupstats.groupcompare(tbl, "Group", "Value");
         catch e
            raised = string(e.identifier);
         end

         returned = [strlength(raised) > 0, ...
            startsWith(raised, "groupstats:groupcompare:")];
         expected = [true, false];
         testCase.verifyEqual(returned, expected);
      end

      function testASetWithOnlyTheReferenceHasNoComparison(testCase)
         % A set where only the reference has rows yields no row of stats,
         % pooled or not, and the bootstrap runs on the other sets.

         tbl = testCase.Tbl;
         tbl = tbl(~(tbl.Group ~= "ctrl" & tbl.Set == "s2"), :);

         stats = groupstats.groupcompare(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", ConditionVar = "Set", Pooled = true, ...
            Bootstrap = true, NumBootstrap = 50);

         returned = {stats.Set; stats.Group};
         expected = {"s1"; "aaa, zzz"};
         testCase.verifyEqual(returned, expected);
      end

      function testMemberAbsentFromASetHasNoComparisonThere(testCase)
         % A member with no rows in a set gets no row in that set, and the
         % bootstrap runs on the rows that exist.

         tbl = testCase.Tbl;
         tbl = tbl(~(tbl.Group == "zzz" & tbl.Set == "s2"), :);

         stats = groupstats.groupcompare(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", ConditionVar = "Set", ...
            Bootstrap = true, NumBootstrap = 50);

         returned = {stats.Set; stats.Group};
         expected = {["s1"; "s1"; "s2"]; ["aaa"; "zzz"; "aaa"]};
         testCase.verifyEqual(returned, expected);
      end

      function testPermutationWithNoClusterGivesNaN(testCase)
         % Two identical samples have a t-statistic of zero, below any
         % cluster threshold, so permutest finds no cluster: P is NaN and H
         % is false.

         tbl = table(categorical([repmat("ref", 10, 1); repmat("same", 10, 1)]), ...
            [(1:10)'; (1:10)'], 'VariableNames', {'Group', 'Value'});

         stats = groupstats.groupcompare(tbl, "Group", "Value", ...
            ReferenceGroup = "ref", Test = "permutation", ...
            NumPermutations = 100);

         returned = {isnan(stats.P); stats.H};
         expected = {true; false};
         testCase.verifyEqual(returned, expected);
      end


      function testPooledWithoutSetsGivesOneComparison(testCase)
         % Pooled without ConditionVar is the way to pool across sets: one
         % comparison of the reference against every other row.

         stats = groupstats.groupcompare(testCase.Tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", Pooled = true);

         tbl = testCase.Tbl;
         returned = {height(stats); stats.Group; stats.P};
         expected = {1; "aaa, zzz"; ranksum(tbl.Value(tbl.Group == "ctrl"), ...
            tbl.Value(tbl.Group ~= "ctrl"))};
         testCase.verifyEqual(returned, expected);
      end

      function testEmptyReferenceWithoutSetsAndMatrixDataVarAreRenamed(testCase)
         % The two remaining groupsamples identifiers take this function's
         % name too: an all-missing reference without ConditionVar, and a
         % matrix data variable.

         tbl = testCase.Tbl;
         allmissing = tbl;
         allmissing.Value(allmissing.Group == "ctrl") = NaN;
         matrixvar = tbl;
         matrixvar.Pair = [tbl.Value, tbl.Value];

         calls = {@() groupstats.groupcompare(allmissing, "Group", ...
            "Value", ReferenceGroup = "ctrl"); ...
            @() groupstats.groupcompare(matrixvar, "Group", "Pair")};
         returned = strings(2, 1);
         for n = 1:2
            try
               calls{n}();
            catch e
               returned(n) = e.identifier;
            end
         end
         expected = ["groupstats:groupcompare:emptyReferenceGroup"; ...
            "groupstats:groupcompare:multiColumnDataVar"];
         testCase.verifyEqual(returned, expected);
      end

   end
end
