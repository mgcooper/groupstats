classdef test_groupdifference < matlab.unittest.TestCase
   %TEST_GROUPDIFFERENCE Test groupstats.groupdifference.
   %
   % These cases pin the four defects the audit named:
   %
   %  1. The reference group was whichever member sorted first.
   %  2. Pooled mode returned labels and results of different lengths.
   %  3. Per-set results would not concatenate when two sets chose different
   %     rank tests.
   %  4. Two of the three outputs were undocumented.
   %
   % The bootstrap outputs from bootdiff are random, so no case asserts on
   % them. The rank-test outputs and every label are deterministic.
   %
   % See also: groupstats.groupdifference, bootdiff

   properties
      % The fixture table and the names it is built around.
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
            groupstats.test.generateTestData('groupdifference');
         testCase.Tbl = data.tbl;
         testCase.GroupVar = data.groupvar;
         testCase.DataVar = data.datavar;
         testCase.ConditionVar = data.conditionvar;
         testCase.Reference = data.reference;
         testCase.Expected = expected;
      end
   end

   methods (Test)

      function testEmptyReferenceGroupInASetIsReported(testCase)
         % A reference group absent from one condition set would take the
         % all-zero branch, because all([]) is true, and then fail inside the
         % bootstrap with no mention of the reference.

         tbl = table( ...
            categorical(["ctrl"; "ctrl"; "trt"; "trt"; "trt"; "trt"]), ...
            categorical(["s1"; "s1"; "s1"; "s1"; "s2"; "s2"]), ...
            [1; 2; 5; 6; 7; 8], ...
            'VariableNames', {'Group', 'Set', 'Value'});

         testCase.verifyError(@() groupstats.groupdifference(tbl, ...
            "Group", "Value", conditionvar = "Set", ...
            ReferenceGroup = "ctrl"), ...
            'groupstats:groupdifference:emptyReferenceGroup');
      end

      function testDefaultReferenceIsTheFirstMember(testCase)
         % With no reference named, the comparison is against the member that
         % sorts first. Pinning this documents the risk the option removes.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar);

         returned = stats.ingroup;
         expected = testCase.Expected.alphabeticalReference;
         testCase.verifyEqual(returned, expected);
      end

      function testNamedReferenceIsHonored(testCase)
         % ReferenceGroup selects the member every other member is compared
         % against, whatever the sort order.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference);

         returned = stats.ingroup;
         expected = testCase.Reference;
         testCase.verifyEqual(returned, expected);
      end

      function testNamedReferenceComparesEveryOtherMember(testCase)
         % The other two members are the outgroup, in their original order.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference);

         returned = sort(stats.outgroup{1});
         expected = ["aaa"; "zzz"];
         testCase.verifyEqual(returned, expected);
      end

      function testCellstrGroupVariableWorks(testCase)
         % A cell array of char groups like a categorical or a string. The
         % == operator rejects a cell array, so the comparison converts to
         % text first.

         tbl = testCase.Tbl;
         tbl.Group = cellstr(string(tbl.Group));

         stats = groupstats.groupdifference(tbl, testCase.GroupVar, ...
            testCase.DataVar, ReferenceGroup = testCase.Reference);

         returned = stats.ingroup;
         expected = testCase.Reference;
         testCase.verifyEqual(returned, expected);
      end

      function testMultipleReferenceGroupsError(testCase)
         % ReferenceGroup names one member. A list of members raises the
         % arguments-block validation error, not a subscript error from
         % inside the reordering.

         testCase.verifyError( ...
            @() groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = ["ctrl", "aaa"]), ...
            'MATLAB:validators:mustBeScalarOrEmpty');
      end

      function testUnknownReferenceErrors(testCase)
         % A reference that is not a member of the group variable is an error,
         % not a fall back to the first member.

         testCase.verifyError( ...
            @() groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ReferenceGroup = "nope"), ...
            'groupstats:groupdifference:badReferenceGroup');
      end

      function testPooledLabelsMatchThePooledResult(testCase)
         % Pooled mode runs one comparison, so it returns one p-value, one
         % hypothesis result, and one outgroup label. Sizing the label from
         % the member count left it longer than the result.

         [stats, ~, result] = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference, pooled = true);

         testCase.verifyEqual(numel(stats.p), 1);
         testCase.verifyEqual(numel(stats.h), 1);
         testCase.verifyEqual(numel(stats.outgroup), 1);
         testCase.verifyEqual(numel(result), 1);
      end

      function testPooledOutgroupNamesEveryPooledMember(testCase)
         % The pooled label lists the members that went into the pool.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference, pooled = true);

         returned = stats.outgroup;
         expected = "aaa, zzz";
         testCase.verifyEqual(returned, expected);
      end

      function testMixedRankTestsConcatenate(testCase)
         % One set has an all-zero reference and takes the signrank path; the
         % other takes the ranksum path. Concatenating them failed while the
         % test name was part of the variable name.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference, ...
            conditionvar = testCase.ConditionVar);

         returned = height(stats);
         expected = numel(testCase.Expected.sets);
         testCase.verifyEqual(returned, expected);
      end

      function testTestnameRecordsWhichTestRan(testCase)
         % The test name is a value, so a caller can still tell the two apart.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference, ...
            conditionvar = testCase.ConditionVar);

         returned = sort(unique(vertcat(stats.testname{:})));
         expected = sort(testCase.Expected.testnames);
         testCase.verifyEqual(returned, expected);
      end

      function testEverySetIsLabeled(testCase)
         % Every row names the set it came from. The labels were assigned in a
         % second loop over sets, which reached only one row per set.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference, ...
            conditionvar = testCase.ConditionVar);

         returned = sort(stats.set);
         expected = testCase.Expected.sets;
         testCase.verifyEqual(returned, expected);
      end

      function testThreeOutputsAreReturned(testCase)
         % The docstring documents all three outputs, so all three must come
         % back with one entry per set.

         [stats, samples, result] = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference, ...
            conditionvar = testCase.ConditionVar);

         expected = numel(testCase.Expected.sets);
         testCase.verifyEqual(height(stats), expected);
         testCase.verifyEqual(numel(samples), expected);
         testCase.verifyEqual(numel(result), expected);
      end

      function testStatsDropsTheRawSampleVariables(testCase)
         % boot_medians and result leave STATS and become the second and third
         % outputs, so STATS stays readable.

         stats = groupstats.groupdifference(testCase.Tbl, ...
            testCase.GroupVar, testCase.DataVar, ...
            ReferenceGroup = testCase.Reference);

         returned = string(stats.Properties.VariableNames);
         testCase.verifyFalse(any(returned == "boot_medians"));
         testCase.verifyFalse(any(returned == "result"));
      end
   end
end
