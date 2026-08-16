classdef test_groupbayes_population < matlab.unittest.TestCase
   %TEST_GROUPBAYES_POPULATION Test how groupbayes counts its population.
   %
   % These cases use the icom-msd-shaped Info fixture, which publishes two
   % label sets: one that accounts for every row of the group column, and one
   % that does not. The two counting rules agree on the first and diverge on
   % the second, which is what makes the rule observable.
   %
   % The cases cover:
   %
   %  1. Every numeric column of the default output for the icom-msd pattern,
   %     compared against counts derived here with plain loops.
   %  2. The Population option's three values.
   %  3. The conditionals' invariance to Population, and the NaN a zero
   %     denominator count produces.
   %  4. The three-argument column syntax, which double-counted an event that
   %     occurred for more than one member.
   %  5. The pairwise case where groupA equals groupB, which counted every row
   %     twice.
   %
   % See also: groupstats.groupbayes, groupstats.test.generateTestData

   properties
      % The Info fixture and the two label sets it publishes.
      Info
      ExhaustiveLabels
      NonExhaustiveLabels
      % The disjoint, together-exhaustive pair: one outlet against every
      % subbasin. This is the icom-msd production pattern.
      PartitionGroupA
      PartitionGroupB
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         [data, expected] = groupstats.test.generateTestData('info');
         testCase.Info = data.Info;
         testCase.ExhaustiveLabels = expected.exhaustiveLabels(:);
         testCase.NonExhaustiveLabels = expected.nonExhaustiveLabels(:);
         testCase.PartitionGroupA = expected.partitionGroupA(:);
         testCase.PartitionGroupB = expected.partitionGroupB(:);
      end
   end

   methods (Test)

      function testZeroPopulationGivesNaNRatherThanAnError(testCase)
         % No row carries a requested label, so every probability has a zero
         % denominator. The documented value for one of those is NaN.

         data = groupstats.test.generateTestData('groupbayes');
         tbl = data.tbl;
         tbl.Group = repmat("C1", height(tbl), 1);

         P = groupstats.groupbayes(tbl, data.groupA, data.groupB, ...
            data.groupvar);

         testCase.verifyTrue(all(isnan(P.P_A_AND_B)));
      end

      function testEachRowsLabelsMatchItsCounts(testCase)
         % The label columns are built separately from the counts. A pairing
         % that repeats one of them the wrong way mislabels every row while
         % the numbers stay valid, so compare each row's labels against
         % counts recomputed from the table.

         data = groupstats.test.generateTestData('groupbayes');
         tbl = data.tbl;

         P = groupstats.groupbayes(tbl, ["A1"; "A2"], ["B1"; "B2"], ...
            data.groupvar);

         for k = 1:height(P)
            groupA = string(P.GroupA(k));
            groupB = string(P.GroupB(k));

            expectedA = sum(string(tbl.(data.groupvar)) == groupA);
            expectedB = sum(string(tbl.(data.groupvar)) == groupB);

            testCase.verifyEqual(P.N_A(k), expectedA, ...
               sprintf('row %d, GroupA %s', k, groupA));
            testCase.verifyEqual(P.N_B(k), expectedB, ...
               sprintf('row %d, GroupB %s', k, groupB));
         end
      end

      function testScalarSelfPairReturnsNoRows(testCase)
         % Naming the same label twice leaves no distinct pair to report,
         % because the duplicate is removed from the other set.

         data = groupstats.test.generateTestData('groupbayes');

         P = groupstats.groupbayes(data.tbl, "A1", "A1", data.groupvar);

         testCase.verifyEqual(height(P), 0);
      end

      function testPartitionGivesMarginalsThatSumToOne(testCase)
         % The icom-msd pattern: one outlet against every subbasin. The two
         % sets are disjoint and together account for every row, so the
         % marginals partition the population and no warning fires.

         P = testCase.verifyWarningFree(@() groupstats.groupbayes( ...
            testCase.Info, testCase.PartitionGroupA, ...
            testCase.PartitionGroupB, "basin"));

         returned = sum(unique(P(:, {'GroupA', 'P_A'})).P_A) ...
            + sum(unique(P(:, {'GroupB', 'P_B'})).P_B);
         testCase.verifyEqual(returned, 1, 'AbsTol', 1e-12);
      end

      function testPartitionPopulationIsTheTableHeight(testCase)
         % Every row belongs to one of the two sets, so the union count and
         % the table height agree. This is the case where the row-based and
         % column-based rules coincide, which is why the fixture also
         % publishes a set where they do not.

         P = groupstats.groupbayes(testCase.Info, ...
            testCase.PartitionGroupA, testCase.PartitionGroupB, "basin");

         returned = round(unique(P.N_A ./ P.P_A));
         testCase.verifyEqual(returned, height(testCase.Info));
      end

      function testPairwiseCallWarns(testCase)
         % A pairwise call passes the same label set as both groups, so every
         % event belongs to both. The marginals then sum to two. That is a
         % legitimate use, so the check reports rather than stops.

         labels = testCase.ExhaustiveLabels;

         testCase.verifyWarning(@() groupstats.groupbayes( ...
            testCase.Info, labels, labels, "basin"), ...
            'groupstats:groupbayes:marginalsDoNotPartition');
      end

      function testNonExhaustiveLabelsWarn(testCase)
         % Some rows belong to neither set, so the marginals do not sum to
         % one. That is a report, not a stop: a pairwise call breaks the same
         % rule on purpose.

         labels = testCase.NonExhaustiveLabels;

         testCase.verifyWarning(@() groupstats.groupbayes( ...
            testCase.Info, labels, labels, "basin"), ...
            'groupstats:groupbayes:marginalsDoNotPartition');
      end

      function testUnionPopulationExcludesOutsideRows(testCase)
         % The union count covers the rows named by the label set, not the
         % whole table.

         labels = testCase.NonExhaustiveLabels;
         P = withwarningsoff(testCase, @() groupstats.groupbayes( ...
            testCase.Info, labels, labels, "basin"));

         returned = round(unique(P.N_A) ./ unique(P.P_A));
         expected = sum(ismember(string(testCase.Info.basin), labels));
         testCase.verifyEqual(unique(returned), expected);
      end

      function testTablePopulationUsesEveryRow(testCase)
         % Population="table" counts every row, including the ones the label
         % set leaves out.

         labels = testCase.NonExhaustiveLabels;
         P = withwarningsoff(testCase, @() groupstats.groupbayes( ...
            testCase.Info, labels, labels, "basin", Population = "table"));

         returned = round(unique(P.N_A) ./ unique(P.P_A));
         testCase.verifyEqual(unique(returned), height(testCase.Info));
      end

      function testConditionalPopulationRenormalizesEachMarginal(testCase)
         % Population="withingroup" makes each marginal sum to one within its
         % own group. This is the variant the published probability table
         % needs, where the outlet must stay out of the subbasin marginal.

         labels = testCase.NonExhaustiveLabels;
         P = withwarningsoff(testCase, @() groupstats.groupbayes( ...
            testCase.Info, labels, labels, "basin", ...
            Population = "withingroup"));

         returned = sum(unique(P(:, {'GroupA', 'P_A'})).P_A);
         testCase.verifyEqual(returned, 1, 'AbsTol', 1e-12);
      end

      function testConditionalsDoNotChangeWithPopulation(testCase)
         % P_B_GIVEN_A and P_A_GIVEN_B are ratios of counts, so N cancels.
         % The docstring states this, and a caller choosing Population must be
         % able to rely on it.

         labels = testCase.NonExhaustiveLabels;
         args = {testCase.Info, labels, labels, "basin"};

         union = withwarningsoff(testCase, ...
            @() groupstats.groupbayes(args{:}));
         wholetable = withwarningsoff(testCase, ...
            @() groupstats.groupbayes(args{:}, Population = "table"));
         conditional = withwarningsoff(testCase, ...
            @() groupstats.groupbayes(args{:}, Population = "withingroup"));

         testCase.verifyEqual(wholetable.P_B_GIVEN_A, union.P_B_GIVEN_A);
         testCase.verifyEqual(wholetable.P_A_GIVEN_B, union.P_A_GIVEN_B);
         testCase.verifyEqual(conditional.P_B_GIVEN_A, union.P_B_GIVEN_A);
         testCase.verifyEqual(conditional.P_A_GIVEN_B, union.P_A_GIVEN_B);
      end

      function testUnknownPopulationErrors(testCase)
         % Population accepts three names and nothing else.

         labels = testCase.ExhaustiveLabels;

         testCase.verifyError(@() groupstats.groupbayes( ...
            testCase.Info, labels, labels, "basin", Population = "nope"), ...
            'MATLAB:validators:mustBeMember');
      end

      function testColumnSyntaxCountsEachEventOnce(testCase)
         % The three-argument syntax reads the label columns. An event that
         % occurred for several members must count once, not once per member.
         % Summing the per-member counts inflated N far past the table height.

         labels = testCase.ExhaustiveLabels;
         P = withwarningsoff(testCase, @() groupstats.groupbayes( ...
            testCase.Info, labels, labels));

         returned = round(unique(P.N_A) ./ unique(P.P_A));
         expected = sum(any(testCase.Info{:, labels}, 2));
         testCase.verifyEqual(unique(returned), expected);
         testCase.verifyLessThanOrEqual(expected, height(testCase.Info));
      end

      function testPairwiseCallDoesNotDoubleThePopulation(testCase)
         % A pairwise call passes the same label set twice. Summing the two
         % per-set counts made N twice the population.

         labels = testCase.ExhaustiveLabels;
         P = withwarningsoff(testCase, @() groupstats.groupbayes( ...
            testCase.Info, labels, labels, "basin"));

         returned = round(unique(unique(P.N_A) ./ unique(P.P_A)));
         testCase.verifyEqual(returned, height(testCase.Info));
      end

      function testDefaultOutputMatchesCountsDerivedByHand(testCase)
         % Pin every numeric column of the default output for the icom-msd
         % pattern, against counts derived here with plain loops rather than
         % from the function under test.

         groupA = testCase.PartitionGroupA;
         groupB = testCase.PartitionGroupB;
         eventtbl = testCase.Info;
         basin = string(eventtbl.basin);

         nA = arrayfun(@(A) sum(basin == A), groupA);
         nB = arrayfun(@(B) sum(basin == B), groupB);
         nAB = zeros(numel(groupA) * numel(groupB), 1);
         k = 0;
         for a = 1:numel(groupA)
            for b = 1:numel(groupB)
               k = k + 1;
               nAB(k) = sum(basin == groupA(a) & eventtbl.(groupB(b)));
            end
         end
         n = sum(ismember(basin, [groupA; groupB]));

         P = groupstats.groupbayes(eventtbl, groupA, groupB, "basin");

         testCase.verifyEqual(P.N_A, repelem(nA, numel(groupB), 1));
         testCase.verifyEqual(P.N_B, repmat(nB, numel(groupA), 1));
         testCase.verifyEqual(P.N_A_AND_B, nAB);
         testCase.verifyEqual(P.P_A, repelem(nA ./ n, numel(groupB), 1));
         testCase.verifyEqual(P.P_B, repmat(nB ./ n, numel(groupA), 1));
         testCase.verifyEqual(P.P_A_AND_B, nAB ./ n);
         testCase.verifyEqual(P.P_B_GIVEN_A, ...
            nAB ./ repelem(nA, numel(groupB), 1));
         testCase.verifyEqual(P.P_A_GIVEN_B, ...
            nAB ./ repmat(nB, numel(groupA), 1));
      end

      function testUndefinedConditionalIsNaN(testCase)
         % P(B|A) has no value when no event belongs to A. Adding a small
         % number to the denominator returned a figure of order 1e11 instead,
         % which reads as a probability and is not one.

         tbl = table(categorical(["b"; "b"], ["a", "b"]), ...
            [true; true], [true; false], ...
            'VariableNames', {'grp', 'a', 'b'});

         P = withwarningsoff(testCase, @() groupstats.groupbayes( ...
            tbl, "a", "b", "grp"));

         testCase.verifyEqual(P.N_A, 0);
         testCase.verifyTrue(isnan(P.P_B_GIVEN_A));
      end
   end
end

function out = withwarningsoff(testCase, fcn)
   %WITHWARNINGSOFF Run FCN with the partition warning disabled.
   %
   % Several cases use a label set that deliberately does not partition the
   % population. The warning is the point of another test, so silence it here
   % rather than let it fail these on an unexpected-warning check.

   state = warning('off', 'groupstats:groupbayes:marginalsDoNotPartition');
   restore = onCleanup(@() warning(state));
   out = fcn();
   testCase.assertNotEmpty(out);
end
