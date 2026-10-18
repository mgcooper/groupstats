classdef test_groupci < matlab.unittest.TestCase
   %TEST_GROUPCI Test groupstats.groupci.
   %
   % Every expected interval is a hand value from the formulas of the
   % DesignSpec, not a value read from the production code:
   %
   %  - the mean interval, mean +/- t(1 - Alpha/2, N - 1) * s / sqrt(N);
   %  - the median interval, median +/- 1.57 * IQR / sqrt(N), with the
   %    quartiles of the default quantile rule.
   %
   % The t values come from an independent table: t(0.975, 7) =
   % 2.3646242516, t(0.95, 7) = 1.8945786051, and t(0.975, 1) =
   % 12.7062047362.
   %
   % The chart cases compare the rows with the boxes boxchartcats draws, so
   % the same arguments give the same pairings in the same order.
   %
   % See also: groupstats.groupci, groupstats.boxchartcats

   properties
      % The groupsummary fixture: Grp a, b, c by Sub x, y, two values per
      % pairing, and Value 1:12.
      Tbl
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure);
         data = groupstats.test.generateTestData('groupsummary');
         testCase.Tbl = data.tbl;
      end
   end

   methods (Test)

      % ---- Interval values

      function testMeanIntervalOfOneToEight(testCase)
         % The mean of 1:8 is 4.5, s = sqrt(6), and
         % 2.3646242516 * sqrt(6) / sqrt(8) = 2.04782467.

         returned = groupstats.groupci(oneGroup(1:8), "Value", "Grp");

         testCase.verifyEqual(returned.N, 8);
         testCase.verifyEqual(returned.Estimate, 4.5, 'AbsTol', 1e-12);
         testCase.verifyEqual([returned.CILower returned.CIUpper], ...
            [2.45217533 6.54782467], 'AbsTol', 1e-6);
      end

      function testAlphaSetsTheMeanLevel(testCase)
         % At Alpha 0.10 the t value is 1.8945786051, so the half-width is
         % 1.8945786051 * sqrt(6) / sqrt(8) = 1.64075324.

         returned = groupstats.groupci(oneGroup(1:8), "Value", "Grp", ...
            Alpha = 0.10);

         testCase.verifyEqual([returned.CILower returned.CIUpper], ...
            [2.85924676 6.14075324], 'AbsTol', 1e-6);
      end

      function testMedianIntervalOfOneToEight(testCase)
         % Q1 = 2 + 0.5 * (3 - 2) = 2.5 and Q3 = 6 + 0.5 * (7 - 6) = 6.5, so
         % the half-width is 1.57 * 4 / sqrt(8) = 2.22031529.

         returned = groupstats.groupci(oneGroup(1:8), "Value", "Grp", ...
            Method = "median");

         testCase.verifyEqual(returned.Estimate, 4.5, 'AbsTol', 1e-12);
         testCase.verifyEqual([returned.CILower returned.CIUpper], ...
            [2.27968471 6.72031529], 'AbsTol', 1e-6);
      end

      function testFixtureMeanTable(testCase)
         % Each pairing holds two values two apart, so s = sqrt(2) and the
         % half-width is 12.7062047362 * sqrt(2) / sqrt(2). Pairing a-x
         % holds 1 and 3, so its interval is [-10.70620474, 14.70620474].

         returned = groupstats.groupci(testCase.Tbl, "Value", "Grp", "Sub");

         testCase.verifyEqual(string(returned.Properties.VariableNames), ...
            ["Grp" "Sub" "N" "Estimate" "CILower" "CIUpper"]);
         testCase.verifyClass(returned.Grp, 'categorical');
         testCase.verifyClass(returned.Sub, 'categorical');
         testCase.verifyEqual(string(returned.Grp), ...
            ["a"; "a"; "b"; "b"; "c"; "c"]);
         testCase.verifyEqual(string(returned.Sub), ...
            ["x"; "y"; "x"; "y"; "x"; "y"]);
         testCase.verifyEqual(returned.N, repmat(2, 6, 1));

         estimate = [2; 3; 6; 7; 10; 11];
         testCase.verifyEqual(returned.Estimate, estimate, 'AbsTol', 1e-12);
         testCase.verifyEqual(returned.CILower, estimate - 12.70620474, ...
            'AbsTol', 1e-6);
         testCase.verifyEqual(returned.CIUpper, estimate + 12.70620474, ...
            'AbsTol', 1e-6);
      end

      function testFixtureMedianTable(testCase)
         % Two values are the two quartiles, so IQR = 2 and the half-width
         % is 1.57 * 2 / sqrt(2) = 2.22031529. Pairing a-x gives
         % [-0.22031529, 4.22031529].

         returned = groupstats.groupci(testCase.Tbl, "Value", "Grp", ...
            "Sub", Method = "median");

         estimate = [2; 3; 6; 7; 10; 11];
         testCase.verifyEqual(returned.Estimate, estimate, 'AbsTol', 1e-12);
         testCase.verifyEqual(returned.CILower, estimate - 2.22031529, ...
            'AbsTol', 1e-6);
         testCase.verifyEqual(returned.CIUpper, estimate + 2.22031529, ...
            'AbsTol', 1e-6);
      end

      function testMedianBoundsAreTheNotch(testCase)
         % For every pairing with N >= 2, the median bounds equal the notch
         % that boxchartydata returns. They also equal the formula notch,
         % with quartiles from the default quantile rule.

         tbl = skewedTable();

         returned = groupstats.groupci(tbl, "Value", "Grp", "Sub", ...
            Method = "median");

         checked = 0;
         for k = find(returned.N >= 2)'
            y = tbl.Value(tbl.Grp == returned.Grp(k) ...
               & tbl.Sub == returned.Sub(k));
            y = y(~isnan(y));
            bounds = [returned.CILower(k) returned.CIUpper(k)];

            notch = groupstats.boxchartydata(y).notches;
            testCase.verifyEqual(bounds, notch, 'AbsTol', 1e-12);

            halfwidth = 1.57 * (quantile(y, 0.75) - quantile(y, 0.25)) ...
               / sqrt(numel(y));
            expected = median(y) + [-halfwidth halfwidth];
            testCase.verifyEqual(bounds, expected, 'AbsTol', 1e-12);
            checked = checked + 1;
         end
         testCase.verifyEqual(checked, 4);
      end

      % ---- Missing values and small groups

      function testEmptyOneValueAndNaNPairings(testCase)
         % a-x holds 1, NaN, and 3, so NaN leaves N = 2 and the interval of
         % {1, 3}. a-y has no rows. b-x holds one value. b-y holds only NaN,
         % so it is empty too.

         tbl = table( ...
            categorical(["a"; "a"; "a"; "b"; "b"; "b"]), ...
            categorical(["x"; "x"; "x"; "x"; "y"; "y"]), ...
            [1; NaN; 3; 5; NaN; NaN], ...
            'VariableNames', {'Grp', 'Sub', 'Value'});

         returned = groupstats.groupci(tbl, "Value", "Grp", "Sub");

         testCase.verifyEqual(string(returned.Grp), ["a"; "a"; "b"; "b"]);
         testCase.verifyEqual(string(returned.Sub), ["x"; "y"; "x"; "y"]);
         testCase.verifyEqual(returned.N, [2; 0; 1; 0]);
         testCase.verifyEqual(returned.Estimate, [2; NaN; 5; NaN], ...
            'AbsTol', 1e-12);
         testCase.verifyEqual(returned.CILower, ...
            [-10.70620474; NaN; NaN; NaN], 'AbsTol', 1e-6);
         testCase.verifyEqual(returned.CIUpper, ...
            [14.70620474; NaN; NaN; NaN], 'AbsTol', 1e-6);
      end

      function testOneValueHasNaNMedianBounds(testCase)
         % boxchart draws a zero-width notch for one value. groupci
         % returns NaN bounds there, as the help states.

         returned = groupstats.groupci(oneGroup(7), "Value", "Grp", ...
            Method = "median");

         testCase.verifyEqual(returned.Estimate, 7);
         testCase.verifyEqual([returned.CILower returned.CIUpper], ...
            [NaN NaN]);
      end

      function testEqualValuesGiveZeroWidthBounds(testCase)
         % No spread gives no width. The median bounds equal the value; the
         % mean bounds may differ from it by rounding error.

         medianci = groupstats.groupci(oneGroup([5 5 5]), "Value", ...
            "Grp", Method = "median");
         meanci = groupstats.groupci(oneGroup([5 5 5]), "Value", "Grp");

         testCase.verifyEqual([medianci.CILower medianci.CIUpper], [5 5]);
         testCase.verifyEqual([meanci.CILower meanci.CIUpper], [5 5], ...
            'AbsTol', 1e-12);
      end

      function testIntegerAndLogicalDataConvertToDouble(testCase)
         % int8 1 and 3 give the {1, 3} interval. Logical true and false
         % are 1 and 0: mean 0.5, s = sqrt(0.5), and the half-width is
         % 12.7062047362 * sqrt(0.5) / sqrt(2) = 6.35310237.

         asint = groupstats.groupci(oneGroup(int8([1 3])), "Value", "Grp");
         aslogical = groupstats.groupci(oneGroup([true false]), ...
            "Value", "Grp");

         testCase.verifyClass(asint.Estimate, 'double');
         testCase.verifyEqual([asint.CILower asint.CIUpper], ...
            [-10.70620474 14.70620474], 'AbsTol', 1e-6);
         testCase.verifyEqual([aslogical.CILower aslogical.CIUpper], ...
            0.5 + [-6.35310237 6.35310237], 'AbsTol', 1e-6);
      end

      function testWithoutCGroupVarOneRowPerXMember(testCase)
         % Without cgroupvar the table holds the x grouping alone. Grp a
         % holds 1:4, so its mean interval uses N = 4.

         returned = groupstats.groupci(testCase.Tbl, "Value", "Grp");

         testCase.verifyEqual(string(returned.Properties.VariableNames), ...
            ["Grp" "N" "Estimate" "CILower" "CIUpper"]);
         testCase.verifyEqual(string(returned.Grp), ["a"; "b"; "c"]);
         testCase.verifyEqual(returned.N, [4; 4; 4]);
         testCase.verifyEqual(returned.Estimate, [2.5; 6.5; 10.5], ...
            'AbsTol', 1e-12);
      end

      % ---- The rows match the drawn boxes

      function testRowsMatchTheDrawnBoxes(testCase)
         % The default call gives the boxes in drawn order.

         verifyRowsMatchBoxes(testCase, testCase.Tbl, {});
      end

      function testMemberSelectionMatchesTheChart(testCase)
         verifyRowsMatchBoxes(testCase, testCase.Tbl, ...
            {'XGroupMembers', ["c", "a"], 'CGroupMembers', "y"});
      end

      function testRowSelectionMatchesTheChart(testCase)
         verifyRowsMatchBoxes(testCase, testCase.Tbl, ...
            {'RowSelectVar', "Set", 'RowSelectMembers', "p"});
      end

      function testPooledMergeMatchesTheChart(testCase)
         % The merged group pools the rows of x and y, so each Grp member
         % holds four values under the label "x and y".

         returned = verifyRowsMatchBoxes(testCase, testCase.Tbl, ...
            {'MergeGroupMembers', ["x", "y"]});

         testCase.verifyEqual(string(returned.Sub), repmat("x and y", 3, 1));
         testCase.verifyEqual(returned.N, [4; 4; 4]);
         testCase.verifyEqual(returned.Estimate, [2.5; 6.5; 10.5], ...
            'AbsTol', 1e-12);
      end

      function testOrdinalOrderMatchesTheChart(testCase)
         % An ordinal grouping keeps its category order, c before a and b.

         tbl = testCase.Tbl;
         tbl.Grp = categorical(string(tbl.Grp), ["c", "a", "b"], ...
            'Ordinal', true);

         returned = verifyRowsMatchBoxes(testCase, tbl, {});

         testCase.verifyEqual(string(returned.Grp), ...
            ["c"; "c"; "a"; "a"; "b"; "b"]);
         testCase.verifyTrue(isordinal(returned.Grp));
      end

      function testMissingGroupValuesAreDropped(testCase)
         % Rows 1 and 2 lose their Grp value. a-x keeps 3 alone and a-y
         % keeps 4 alone.

         tbl = testCase.Tbl;
         tbl.Grp(1:2) = missing;

         returned = verifyRowsMatchBoxes(testCase, tbl, {});

         testCase.verifyEqual(returned.N(1:2), [1; 1]);
         testCase.verifyEqual(returned.Estimate(1:2), [3; 4]);
      end

      function testEmptyPairingIsARowTheChartDoesNotDraw(testCase)
         % Without the b-y rows the chart draws five boxes. groupci returns
         % six rows, and the b-y row has N = 0.

         tbl = testCase.Tbl(~(testCase.Tbl.Grp == "b" ...
            & testCase.Tbl.Sub == "y"), :);

         returned = verifyRowsMatchBoxes(testCase, tbl, {});

         testCase.verifyEqual(height(returned), 6);
         empty = returned(returned.N == 0, :);
         testCase.verifyEqual(string([empty.Grp empty.Sub]), ["b" "y"]);
         testCase.verifyEqual(empty.Estimate, NaN);
      end

      function testTimetableTimeGroupMatchesTheChart(testCase)
         % Each distinct time is one member. Two times by two subgroups,
         % with values 1:8, give four pairings of two values each.

         time = datetime(2020, 1, [1; 1; 1; 1; 2; 2; 2; 2]);
         sub = categorical(["x"; "y"; "x"; "y"; "x"; "y"; "x"; "y"]);
         tt = timetable(time, sub, (1:8)', 'VariableNames', {'Sub', 'Value'});

         returned = verifyRowsMatchBoxes(testCase, tt, {}, "time");

         testCase.verifyClass(returned, 'table');
         testCase.verifyEqual(returned.N, [2; 2; 2; 2]);
         testCase.verifyEqual(returned.Estimate, [2; 3; 6; 7], ...
            'AbsTol', 1e-12);
      end

      % ---- Products

      function testNeedsOnlyMatlab(testCase)
         % The t quantile uses betaincinv and erfcinv, so groupci and its
         % helpers need no toolbox.

         [~, products] = matlab.codetools.requiredFilesAndProducts( ...
            which('groupstats.groupci'));

         returned = string({products.Name});
         expected = "MATLAB";
         testCase.verifyEqual(returned, expected);
      end

      % ---- Errors

      function testNonNumericDataErrors(testCase)
         tbl = testCase.Tbl;
         tbl.Value = string(tbl.Value);

         testCase.verifyError(@() groupstats.groupci(tbl, "Value", "Grp"), ...
            'groupstats:groupci:nonNumericData');
      end

      function testCategoricalDataErrors(testCase)
         % D3 accepts numeric or logical data only. A categorical with
         % numeric labels must not become an interval of its label values.

         tbl = testCase.Tbl;
         tbl.Value = categorical(tbl.Value);

         testCase.verifyError(@() groupstats.groupci(tbl, "Value", "Grp"), ...
            'groupstats:groupci:nonNumericData');
      end

      function testExtremeAlphaBoundsOfZeroCenteredSamples(testCase)
         % [-1 1] and [-1 0 1] have mean 0, so the bounds are minus and
         % plus the half-width, and a width of 1e-16 stays visible. The
         % "groupci" test data derives each half-width from an exact t
         % identity. Near Alpha 1 a t value can cancel to 0, and for tiny
         % Alpha it can overflow to Inf. At Alpha 1e-310 the true [-1 1]
         % half-width exceeds the double range, so its bounds are -Inf and
         % Inf.

         [data, expected] = groupstats.test.generateTestData("groupci");

         for n = 1:numel(data.alpha)
            ci = groupstats.groupci(data.tbl, "Value", "Grp", ...
               Alpha = data.alpha(n));

            halfwidth = expected.halfwidth(:, n);
            testCase.verifyEqual(ci.Estimate, [0; 0]);
            testCase.verifyEqual([ci.CILower ci.CIUpper], ...
               [-halfwidth halfwidth], 'RelTol', 1e-12, ...
               sprintf('Alpha %g', data.alpha(n)));
         end
      end

      function testAlphaWithMedianErrors(testCase)
         testCase.verifyError(@() groupstats.groupci(testCase.Tbl, ...
            "Value", "Grp", Method = "median", Alpha = 0.1), ...
            'groupstats:groupci:alphaWithMedian');
      end

      function testMergeWithoutCGroupVarErrors(testCase)
         testCase.verifyError(@() groupstats.groupci(testCase.Tbl, ...
            "Value", "Grp", MergeGroupMembers = ["x", "y"]), ...
            'groupstats:groupci:mergeWithoutGroupVar');
      end

      function testReservedGroupNameErrors(testCase)
         tbl = renamevars(testCase.Tbl, "Sub", "Estimate");

         testCase.verifyError(@() groupstats.groupci(tbl, "Value", ...
            "Grp", "Estimate"), 'groupstats:groupci:reservedName');
      end

      function testAlphaOutsideTheOpenUnitIntervalErrors(testCase)
         % A level of 0 or 1 gives no interval.

         testCase.verifyError(@() groupstats.groupci(testCase.Tbl, ...
            "Value", "Grp", Alpha = 0), ...
            'MATLAB:validators:mustBeGreaterThan');
         testCase.verifyError(@() groupstats.groupci(testCase.Tbl, ...
            "Value", "Grp", Alpha = 1), ...
            'MATLAB:validators:mustBeLessThan');
      end
   end
end

function tbl = oneGroup(values)
   %ONEGROUP A table with one Grp member that holds VALUES.

   values = values(:);
   tbl = table(categorical(repmat("a", numel(values), 1)), values, ...
      'VariableNames', {'Grp', 'Value'});
end

function tbl = skewedTable()
   %SKEWEDTABLE Pairings of different sizes and shapes, one with NaN.
   %
   % a-x holds 2.^(0:7), a-y holds [1 2 3 4 100], b-x holds [1 2 NaN 3],
   % and b-y holds [0 0 0 1 5]. Each has N >= 2 after NaN removal.

   values = {2 .^ (0:7), [1 2 3 4 100], [1 2 NaN 3], [0 0 0 1 5]};
   grp = ["a" "a" "b" "b"];
   sub = ["x" "y" "x" "y"];

   counts = cellfun(@numel, values);
   tbl = table(categorical(repelem(grp, counts)'), ...
      categorical(repelem(sub, counts)'), [values{:}]', ...
      'VariableNames', {'Grp', 'Sub', 'Value'});
end

function returned = verifyRowsMatchBoxes(testCase, tbl, args, xgroupvar)
   %VERIFYROWSMATCHBOXES Compare the groupci rows with the drawn boxes.
   %
   % Draws boxchartcats and calls groupci with the same arguments. Each
   % drawn box is one (x member, color member) pairing with at least one
   % value. The boxes are read in drawn order: the x-axis categories left
   % to right, and the color series in turn at each one. The groupci rows
   % with N >= 1 must name the same pairings in the same order. Each N must
   % equal the count of non-missing values in its box.

   arguments
      testCase
      tbl
      args cell
      xgroupvar (1, 1) string = "Grp"
   end

   H = groupstats.boxchartcats(tbl, "Value", xgroupvar, "Sub", args{:});
   returned = groupstats.groupci(tbl, "Value", xgroupvar, "Sub", args{:});

   ax = ancestor(H(1), 'axes');
   xorder = reshape(string(ax.XAxis.Categories), [], 1);

   % List every (x, series) slot in drawn order, x-major, then keep the
   % slots that hold a value. Each kept slot is one drawn box.
   [cidx, xidx] = ndgrid(1:numel(H), 1:numel(xorder));
   cidx = cidx(:);
   xidx = xidx(:);
   counts = arrayfun(@(c, x) nnz(~isnan( ...
      H(c).YData(string(H(c).XData) == xorder(x)))), cidx, xidx);
   drawn = [xorder(xidx) reshape(string({H(cidx).DisplayName}), [], 1)];
   drawn = drawn(counts > 0, :);
   counts = counts(counts > 0);

   rows = returned(returned.N >= 1, :);
   testCase.verifyEqual([string(rows.(xgroupvar)) string(rows.Sub)], drawn);
   testCase.verifyEqual(rows.N, counts);
end
