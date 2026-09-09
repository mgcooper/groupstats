classdef test_groupsamples < matlab.unittest.TestCase
   %TEST_GROUPSAMPLES Test groupstats.groupsamples.
   %
   % groupsamples collects each group member's data, reference first, once
   % per condition set. These cases pin the row order, the labels, the
   % pooled shape, and the two errors. The last case hands two samples to
   % the vendored permutest, which the move into private/ made reachable.
   %
   % See also: groupstats.groupsamples, groupstats.test.generateTestData

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
      end
   end

   methods (Test)

      function testOneRowPerMemberInCategoryOrder(testCase)
         % Without a named reference the first member in category order
         % leads, and every member has one row.

         S = groupstats.groupsamples(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar);

         returned = S.Group;
         expected = testCase.Expected.members;
         testCase.verifyEqual(returned, expected);
      end

      function testDataHoldsEachMembersColumn(testCase)
         % Each Data cell holds that member's values as one column.

         S = groupstats.groupsamples(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar);

         tbl = testCase.Tbl;
         returned = S.Data{2};
         expected = tbl.Value(tbl.Group == "ctrl");
         testCase.verifyEqual(returned, expected);
      end

      function testNamedReferenceComesFirst(testCase)
         % ReferenceGroup moves its member to the first row; the rest keep
         % their order.

         S = groupstats.groupsamples(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = testCase.Reference);

         returned = S.Group;
         expected = ["ctrl"; "aaa"; "zzz"];
         testCase.verifyEqual(returned, expected);
      end

      function testConditionVarGivesOneBlockPerSet(testCase)
         % With ConditionVar the members repeat once per set, reference
         % first within each, and Set leads the columns.

         S = groupstats.groupsamples(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ConditionVar = testCase.ConditionVar, ...
            ReferenceGroup = testCase.Reference);

         returned = {S.Properties.VariableNames; S.Set; S.Group};
         expected = {{'Set', 'Group', 'Data'}; ...
            repelem(testCase.Expected.sets, 3, 1); ...
            repmat(["ctrl"; "aaa"; "zzz"], 2, 1)};
         testCase.verifyEqual(returned, expected);
      end

      function testPooledJoinsTheOtherMembers(testCase)
         % Pooled keeps the reference row and pools the rest into one row
         % whose label joins their names. Pooling is within a set.

         S = groupstats.groupsamples(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ConditionVar = testCase.ConditionVar, ...
            ReferenceGroup = testCase.Reference, Pooled = true);

         tbl = testCase.Tbl;
         returned = {S.Group; numel(S.Data{2})};
         expected = {repmat(["ctrl"; "aaa, zzz"], 2, 1); ...
            nnz(tbl.Group ~= "ctrl" & tbl.Set == "s1")};
         testCase.verifyEqual(returned, expected);
      end

      function testMemberAbsentFromASetGetsNoRowThere(testCase)
         % A member with no rows in a set has nothing to hold, so the set
         % lists only the members present. Pooling reads the present ones.

         tbl = testCase.Tbl;
         tbl = tbl(~(tbl.Group == "zzz" & tbl.Set == "s2"), :);

         S = groupstats.groupsamples(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", ConditionVar = "Set");
         pooled = groupstats.groupsamples(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", ConditionVar = "Set", Pooled = true);

         returned = {S.Group; pooled.Group};
         expected = {["ctrl"; "aaa"; "zzz"; "ctrl"; "aaa"]; ...
            ["ctrl"; "aaa, zzz"; "ctrl"; "aaa"]};
         testCase.verifyEqual(returned, expected);
      end

      function testMissingGroupAndSetValuesAreLeftOut(testCase)
         % A row whose group or condition value is undefined belongs to no
         % member. It forms no member and no set, and the rows that remain
         % group as before.

         tbl = testCase.Tbl;
         tbl.Group(1) = missing;
         tbl.Set(2) = missing;

         S = groupstats.groupsamples(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", ConditionVar = "Set");

         returned = {unique(S.Set); unique(S.Group); ...
            sum(cellfun(@numel, S.Data))};
         expected = {["s1"; "s2"]; ["aaa"; "ctrl"; "zzz"]; height(tbl) - 2};
         testCase.verifyEqual(returned, expected);
      end

      function testASetWithOnlyTheReferenceKeepsItsOneRow(testCase)
         % Pooling a set that holds only the reference has nothing to
         % pool, so the set keeps its reference row alone.

         tbl = testCase.Tbl;
         tbl = tbl(~(tbl.Group ~= "ctrl" & tbl.Set == "s2"), :);

         S = groupstats.groupsamples(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", ConditionVar = "Set", Pooled = true);

         returned = {S.Set; S.Group};
         expected = {["s1"; "s1"; "s2"]; ["ctrl"; "aaa, zzz"; "ctrl"]};
         testCase.verifyEqual(returned, expected);
      end

      function testMissingDataValuesLeaveTheSample(testCase)
         % A NaN is not an observation, so it leaves the sample; a member
         % whose values are all missing has no sample and no row.

         tbl = testCase.Tbl;
         tbl.Value(find(tbl.Group == "aaa", 1)) = NaN;
         tbl.Value(tbl.Group == "zzz") = NaN;

         S = groupstats.groupsamples(tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl");

         returned = {S.Group; numel(S.Data{2}); any(isnan(S.Data{2}))};
         expected = {["ctrl"; "aaa"]; nnz(tbl.Group == "aaa") - 1; false};
         testCase.verifyEqual(returned, expected);
      end

      function testCellstrGroupVariableWorks(testCase)
         % A cellstr group variable is compared as text.

         tbl = testCase.Tbl;
         tbl.Group = cellstr(tbl.Group);

         S = groupstats.groupsamples(tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = "ctrl");

         returned = S.Group(1);
         expected = "ctrl";
         testCase.verifyEqual(returned, expected);
      end

      function testUnknownReferenceErrors(testCase)
         % A ReferenceGroup that is no member is a caller error.

         testCase.verifyError(@() groupstats.groupsamples(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ReferenceGroup = "nope"), ...
            'groupstats:groupsamples:badReferenceGroup');
      end

      function testEmptyReferenceInASetErrors(testCase)
         % A set with no reference rows cannot be compared. The message
         % names the set.

         tbl = testCase.Tbl;
         tbl(tbl.Group == "ctrl" & tbl.Set == "s2", :) = [];

         try
            groupstats.groupsamples(tbl, testCase.GroupVar, ...
               testCase.DataVar, ConditionVar = testCase.ConditionVar, ...
               ReferenceGroup = "ctrl");
            testCase.verifyFail("no error was raised");
         catch e
            returned = {e.identifier; contains(e.message, "s2")};
            expected = {'groupstats:groupsamples:emptyReferenceGroup'; true};
            testCase.verifyEqual(returned, expected);
         end
      end

      function testUnknownVariablesAreReported(testCase)
         % A missing group, data, or condition variable is named by the
         % shared preprocessing before any indexing runs.

         tbl = testCase.Tbl;
         returned = strings(3, 1);
         calls = {@() groupstats.groupsamples(tbl, "nope", "Value"); ...
            @() groupstats.groupsamples(tbl, "Group", "nope"); ...
            @() groupstats.groupsamples(tbl, "Group", "Value", ...
            ConditionVar = "nope")};
         for n = 1:3
            try
               calls{n}();
            catch e
               returned(n) = e.identifier;
            end
         end
         expected = repmat("groupstats:prepareTableGroups:unknownVariable", ...
            3, 1);
         testCase.verifyEqual(returned, expected);
      end

      function testMatrixVariablesAreRejected(testCase)
         % A matrix group or condition variable fails the shared guard; a
         % matrix data variable fails this function's own, since a sample
         % is one column.

         tbl = testCase.Tbl;
         tbl.Pair = [tbl.Value, tbl.Value];

         testCase.verifyError(@() groupstats.groupsamples(tbl, "Pair", ...
            "Value"), 'groupstats:prepareTableGroups:multiColumnGroupVar');
         testCase.verifyError(@() groupstats.groupsamples(tbl, "Group", ...
            "Value", ConditionVar = "Pair"), ...
            'groupstats:prepareTableGroups:multiColumnGroupVar');
         testCase.verifyError(@() groupstats.groupsamples(tbl, "Group", ...
            "Pair"), 'groupstats:groupsamples:multiColumnDataVar');
      end

      function testNoUsableRowGivesTheSchemaWithNoRows(testCase)
         % Every condition value missing leaves no set, and every group
         % value missing leaves no member. S then keeps its columns and has
         % no rows, whatever ReferenceGroup names and with or without
         % ConditionVar.

         tbl = testCase.Tbl;
         tbl.Set(:) = missing;
         S = groupstats.groupsamples(tbl, "Group", "Value", ...
            ConditionVar = "Set");

         nogroups = testCase.Tbl;
         nogroups.Group(:) = missing;
         R = groupstats.groupsamples(nogroups, "Group", "Value", ...
            ReferenceGroup = "ctrl");

         returned = {height(S); S.Properties.VariableNames; height(R); ...
            R.Properties.VariableNames};
         expected = {0; {'Set', 'Group', 'Data'}; 0; {'Group', 'Data'}};
         testCase.verifyEqual(returned, expected);
      end

      function testTwoConditionVariablesAreRejected(testCase)
         % ConditionVar names one variable or none.

         testCase.verifyError(@() groupstats.groupsamples(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ConditionVar = ["Set", "Group"]), ...
            'MATLAB:validators:mustBeScalarOrEmpty');
      end

      function testTwoSamplesFeedPermutest(testCase)
         % permutest resolves from inside the namespace, and the two Data
         % columns are the samples it takes, one trial per value.

         returned = which('permutest', 'in', 'groupstats.groupcompare');
         testCase.verifyTrue(endsWith(returned, ...
            fullfile('+groupstats', 'private', 'permutest.m')));

         S = groupstats.groupsamples(testCase.Tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = "ctrl");
         permutest = groupstats.internal.privatefunction('permutest');
         [~, p] = permutest(S.Data{1}', S.Data{2}', false, 0.05, 50, true);

         testCase.verifyGreaterThanOrEqual(p, 0);
         testCase.verifyLessThanOrEqual(p, 1);
      end

      function testAllMissingReferenceValuesWithoutSetsErrors(testCase)
         % A reference member whose every value is missing has rows but no
         % data. The error fires without ConditionVar too, and its message
         % names no set.

         tbl = testCase.Tbl;
         tbl.Value(tbl.Group == "ctrl") = NaN;

         raised = "";
         message = "";
         try
            groupstats.groupsamples(tbl, "Group", "Value", ...
               ReferenceGroup = "ctrl");
         catch e
            raised = string(e.identifier);
            message = string(e.message);
         end

         returned = {raised; contains(message, "set")};
         expected = {"groupstats:groupsamples:emptyReferenceGroup"; false};
         testCase.verifyEqual(returned, expected);
      end

      function testPooledWithoutSetsPoolsEveryOtherMember(testCase)
         % Pooled without ConditionVar pools across the whole table: the
         % reference row and one row holding every other member's values.

         S = groupstats.groupsamples(testCase.Tbl, "Group", "Value", ...
            ReferenceGroup = "ctrl", Pooled = true);

         tbl = testCase.Tbl;
         returned = {S.Group; numel(S.Data{2})};
         expected = {["ctrl"; "aaa, zzz"]; nnz(tbl.Group ~= "ctrl")};
         testCase.verifyEqual(returned, expected);
      end

   end
end
