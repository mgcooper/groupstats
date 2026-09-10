classdef test_boxchartcats < matlab.unittest.TestCase
   %TEST_BOXCHARTCATS Test groupstats.boxchartcats.
   %
   % These cases pin the defects the audit named:
   %
   %  1. LegendOrientation was declared and never read; the legend was always
   %     horizontal.
   %  2. CGroupOrder was declared and never read. It is implemented, and
   %     covered below.
   %  3. The XGroupOrder="none" branch was a commented-out no-op, so no
   %     sorting was possible.
   %  4. ShadeGroups defaulted on even without cgroupvar, where the
   %     shading has nothing to tell apart. It now defaults on only when
   %     cgroupvar is given. barchartcats had a sibling defect where
   %     SortBy shaded the wrong ticks; boxchartxdata already places its
   %     columns by display position, so boxchartcats does not carry it,
   %     which the sort-order shading tests below confirm.
   %
   % boxchartxdata has its own class, test_boxchartxdata, which draws a
   % chart with boxchartcats for each case.
   %
   % Every case plots into an invisible figure, so the suite runs headless.
   %
   % See also: groupstats.boxchartcats, groupstats.boxchartxdata

   properties
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

      function testThirdOutputIsTheAxes(testCase)
         % The family signature is (H, L, ax), and the third output is the
         % axes the chart was drawn into.

         [~, ~, ax] = groupstats.boxchartcats(testCase.Tbl, "Value", ...
            "Grp", "Sub");

         testCase.verifyTrue(isgraphics(ax, 'axes'));
      end

      function testFourOutputsAreRejected(testCase)
         % H, L, and the axes are the only outputs.

         testCase.verifyError( ...
            @() fourBoxOutputs(testCase.Tbl), ...
            'MATLAB:nargoutchk:tooManyOutputs');
      end

      function testThirdOutputIsThePassedParentAxes(testCase)
         % A caller can pass the BoxChart Parent property and draw into an
         % axes that is not current, so the returned axes must be derived
         % from the chart rather than from gca. The mean symbols, shading,
         % and legend still target the current axes; Bead groupstats-50y
         % covers routing them, so this test turns them off.

         target = axes(figure('Visible', 'off'));
         testCase.addTeardown(@close, ancestor(target, 'figure'));
         other = axes(figure('Visible', 'off'));
         testCase.addTeardown(@close, ancestor(other, 'figure'));

         [~, ~, ax] = groupstats.boxchartcats(testCase.Tbl, "Value", ...
            "Grp", "Sub", Parent = target, PlotMeans = false, ...
            ShadeGroups = false, Legend = "off");

         testCase.verifyEqual(ax, target);
      end

      function testMergeGroupMembersPoolsColorGroups(testCase)
         % MergeGroupMembers pools the named color groups, matching the
         % other charts: one box series fewer, and the merged label joins
         % the member names with " and ".

         xg = categorical(repmat(["p"; "q"], 6, 1));
         cg = categorical(repmat(["a"; "a"; "b"; "b"; "c"; "c"], 2, 1));
         val = (1:12)';
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         [H, L] = groupstats.boxchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b"]});

         returned = numel(H);
         expected = 2;
         testCase.verifyEqual(returned, expected);

         returned = string(L.String);
         testCase.verifyTrue(any(returned == "a and b"));
      end

      function testMergeWithoutCGroupVarErrors(testCase)
         % Merging pools members of the color-group variable, so without
         % one there is nothing to pool.

         xg = categorical(["p"; "q"]);
         val = [1; 2];
         tbl = table(xg, val, 'VariableNames', {'xg', 'val'});

         testCase.verifyError(@() groupstats.boxchartcats(tbl, "val", ...
            "xg", MergeGroupMembers = {["p", "q"]}), ...
            'groupstats:boxchartcats:mergeWithoutGroupVar');
      end

      function testAllSingletonBoxesWarn(testCase)
         % Every box holding exactly one observation collapses the chart
         % to points, so the chart reports it.

         xg = categorical(["p"; "q"; "p"; "q"]);
         cg = categorical(["a"; "a"; "b"; "b"]);
         val = (1:4)';
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         testCase.verifyWarning(@() groupstats.boxchartcats(tbl, "val", ...
            "xg", "cg"), ...
            'groupstats:boxchartcats:allBoxesSingleObservation');
      end

      function testSingletonWithMissingPartnerStillWarns(testCase)
         % boxchart omits missing YData, so a box holding one finite value
         % and one NaN renders as a singleton and must still count as one.

         xg = categorical(["p"; "p"; "q"]);
         cg = categorical(["a"; "a"; "a"]);
         val = [1; NaN; 2];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         testCase.verifyWarning(@() groupstats.boxchartcats(tbl, "val", ...
            "xg", "cg"), ...
            'groupstats:boxchartcats:allBoxesSingleObservation');
      end

      function testABoxWithTwoRowsDoesNotWarn(testCase)
         % Any box with two or more rows means the shape was chosen, so
         % there is no report, even when other boxes hold one row.

         xg = categorical(["p"; "p"; "q"]);
         cg = categorical(["a"; "a"; "a"]);
         val = (1:3)';
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         testCase.verifyWarningFree(@() groupstats.boxchartcats(tbl, ...
            "val", "xg", "cg"));
      end

      function testOrdinalXGroupWithPlainColorGroupPlotsMeans(testCase)
         % boxchartstats summarized on [XData CData]. Concatenating an
         % ordinal categorical with a plain one throws, and the fallback
         % summarized by XData alone, giving one value per x-tick where one
         % per box was needed. The ordinary two-group call raised
         % "left and right sides have a different number of elements",
         % because PlotMeans is on by default.

         xg = categorical(repmat(["Jan"; "Feb"; "Mar"], 4, 1), ...
            ["Jan", "Feb", "Mar"], 'Ordinal', true);
         cg = categorical(repmat(["lo"; "lo"; "lo"; "hi"; "hi"; "hi"], 2, 1));
         val = [1; 10; 100; 2; 20; 200; 1; 10; 100; 2; 20; 200];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.boxchartcats(tbl, "val", "xg", "cg");

         returned = numel(H);
         expected = 2;
         testCase.verifyEqual(returned, expected);

         % Each mean symbol must carry its own group's mean. The values are
         % decades apart, so a mispaired symbol cannot match by chance.
         marks = findobj(ancestor(H(1), 'axes'), 'Type', 'scatter');
         returned = sort([marks.YData]);
         expected = [1, 2, 10, 20, 100, 200];
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testConnectMeansFollowsOneColorAcrossTheTicks(testCase)
         % plot reads each column as one line. xlocs holds one row per color
         % group, so the untransposed call drew one short line per x-tick
         % joining the color groups inside it, rather than one line per
         % color group across the ticks.

         testCase.verifyConnectingLines("ConnectMeans");
      end

      function testConnectMediansFollowsOneColorAcrossTheTicks(testCase)
         % The median branch needs the same transpose as the mean branch.
         % Exercising only ConnectMeans leaves this one free to regress.

         testCase.verifyConnectingLines("ConnectMedians");
      end

      function testCGroupOrderOrdersTheSeries(testCase)
         % boxchart reads its series order from the categories of the
         % GroupByColor data, so ordering them orders the legend.

         members = string(categories(removecats( ...
            categorical(testCase.Tbl.Sub))));
         order = flip(members);

         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            CGroupOrder = order);

         returned = string(H(1).DisplayName);
         testCase.verifyEqual(returned, order(1));
      end

      function testCGroupOrderRejectsANonMember(testCase)
         testCase.verifyError(@() groupstats.boxchartcats(testCase.Tbl, ...
            "Value", "Grp", "Sub", CGroupOrder = "nosuchgroup"), ...
            'groupstats:boxchartcats:badCGroupOrder');
      end

      function testReturnsOneBoxChartPerColorGroup(testCase)
         % One BoxChart object per member of the color group variable.

         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         testCase.verifyClass(H, 'matlab.graphics.chart.primitive.BoxChart');
         returned = numel(H);
         expected = numel(unique(testCase.Tbl.Sub));
         testCase.verifyEqual(returned, expected);
      end

      function testLegendOrientationIsHonored(testCase)
         % The option was declared and never read, so the legend was always
         % horizontal. barchartcats already honored it.

         [~, L] = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            "Sub", LegendOrientation = "horizontal");

         returned = string(L.Orientation);
         expected = "horizontal";
         testCase.verifyEqual(returned, expected);
      end

      function testSortByAscendOrdersTheXGroups(testCase)
         % SortBy orders the x-groups by their group mean. The branch that
         % would have done this was commented out.

         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            SortBy = "ascend");

         G = groupsummary(testCase.Tbl, 'Grp', "mean", "Value");
         [~, idx] = sort(G.mean_Value, 'ascend');
         returned = string(categories(H(1).XData));
         expected = string(G.Grp(idx));
         testCase.verifyEqual(returned, expected);
      end

      function testSortByDescendReversesTheOrder(testCase)
         % Descending is the reverse of ascending.

         ascending = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            "Sub", SortBy = "ascend");
         ascorder = string(categories(ascending(1).XData));
         clf

         descending = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            "Sub", SortBy = "descend");

         returned = string(categories(descending(1).XData));
         expected = flip(ascorder);
         testCase.verifyEqual(returned, expected);
      end

      function testXGroupOrderNamesTheOrder(testCase)
         % XGroupOrder sets the category order directly and takes precedence.

         order = ["c"; "b"; "a"];
         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            XGroupOrder = order);

         returned = string(categories(H(1).XData));
         testCase.verifyEqual(returned, order);
      end

      function testSortGroupMembersRestrictsTheSortStatistic(testCase)
         % SortGroupMembers names the color-group members whose rows compute
         % each x-group's mean. Here the two members order the x-groups
         % differently, so the option is observable.

         xg = categorical(["p"; "p"; "q"; "q"]);
         cg = categorical(["x"; "y"; "x"; "y"]);
         tbl = table(xg, cg, [1; 10; 5; 2], ...
            'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.boxchartcats(tbl, "val", "xg", "cg", ...
            SortBy = "ascend", SortGroupMembers = "x");

         % Over every row p averages 5.5 and q 3.5, so q would lead. Over
         % member x alone p is 1 and q is 5, so p leads.
         returned = string(categories(H(1).XData));
         expected = ["p"; "q"];
         testCase.verifyEqual(returned, expected);
      end

      function testAMemberNamedAllCanBeTheSortMember(testCase)
         % Empty is the no-selection sentinel, so a member that happens to
         % be named "all" is a name like any other.

         xg = categorical(["p"; "p"; "q"; "q"]);
         cg = categorical(["all"; "y"; "all"; "y"]);
         tbl = table(xg, cg, [1; 10; 5; 2], ...
            'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.boxchartcats(tbl, "val", "xg", "cg", ...
            SortBy = "ascend", SortGroupMembers = "all");

         % Over member "all" alone p is 1 and q is 5, so p leads; over
         % every row q would lead.
         returned = string(categories(H(1).XData));
         expected = ["p"; "q"];
         testCase.verifyEqual(returned, expected);
      end

      function testSortGroupMembersPutsAnEmptyXGroupLast(testCase)
         % An x-group with no rows in the named members has no statistic,
         % so it sorts after the groups that have one.

         xg = categorical(["p"; "p"; "q"; "q"; "r"]);
         cg = categorical(["x"; "y"; "x"; "y"; "y"]);
         tbl = table(xg, cg, [5; 10; 1; 2; 0], ...
            'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.boxchartcats(tbl, "val", "xg", "cg", ...
            SortBy = "ascend", SortGroupMembers = "x");

         returned = string(categories(H(1).XData));
         expected = ["q"; "p"; "r"];
         testCase.verifyEqual(returned, expected);

         % Descending puts the largest first and still the empty group
         % last, where sort's default would put a missing value first.
         clf
         H = groupstats.boxchartcats(tbl, "val", "xg", "cg", ...
            SortBy = "descend", SortGroupMembers = "x");

         returned = string(categories(H(1).XData));
         expected = ["p"; "q"; "r"];
         testCase.verifyEqual(returned, expected);
      end

      function testSortGroupMembersWithoutCGroupVarErrors(testCase)
         % The option names color-group members, so it needs cgroupvar.

         testCase.verifyError(@() groupstats.boxchartcats(testCase.Tbl, ...
            "Value", "Grp", SortBy = "ascend", SortGroupMembers = "x"), ...
            'groupstats:boxchartcats:sortGroupMembersWithoutGroupVar');
      end

      function testUnknownSortGroupMemberErrors(testCase)
         % A name that matches no member would select no rows and sort
         % nothing, so it is reported.

         testCase.verifyError(@() groupstats.boxchartcats(testCase.Tbl, ...
            "Value", "Grp", "Sub", SortBy = "ascend", ...
            SortGroupMembers = "nosuchmember"), ...
            'groupstats:validatemember:notAMember');
      end

      function testSortGroupMembersReadsPostMergeNames(testCase)
         % After a merge the color groups carry the merged label, so
         % SortGroupMembers names that label, and an original member of
         % the merge is not a member any more.

         xg = categorical(["p"; "p"; "p"; "q"; "q"; "q"]);
         cg = categorical(["a"; "b"; "c"; "a"; "b"; "c"]);
         tbl = table(xg, cg, [1; 1; 10; 5; 5; 0], ...
            'VariableNames', {'xg', 'cg', 'val'});

         % Over every row p averages 4 and q averages 10/3, so q would
         % lead. Over the merged "a and b" rows p averages 1 and q
         % averages 5, so p leads.
         H = groupstats.boxchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b"]}, SortBy = "ascend", ...
            SortGroupMembers = "a and b");

         returned = string(categories(H(1).XData));
         expected = ["p"; "q"];
         testCase.verifyEqual(returned, expected);

         testCase.verifyError(@() groupstats.boxchartcats(tbl, "val", ...
            "xg", "cg", MergeGroupMembers = {["a", "b"]}, ...
            SortGroupMembers = "a"), ...
            'groupstats:validatemember:notAMember');
      end

      function testUnknownSortGroupMemberErrorsWithoutASort(testCase)
         % The names are checked whatever SortBy is, as barchartcats does,
         % so a typo is reported even when no sort runs.

         testCase.verifyError(@() groupstats.boxchartcats(testCase.Tbl, ...
            "Value", "Grp", "Sub", SortGroupMembers = "nosuchmember"), ...
            'groupstats:validatemember:notAMember');
      end

      function testTwoColorGroupVariablesAreRejected(testCase)
         % cgroupvar names one grouping or none.

         testCase.verifyError(@() groupstats.boxchartcats(testCase.Tbl, ...
            "Value", "Grp", ["Sub", "Set"]), ...
            'MATLAB:validators:mustBeScalarOrEmpty');
      end

      function testGraphicsPropertiesPassThrough(testCase)
         % A BoxChart property named in the call reaches the BoxChart object.

         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            Notch = "off");

         returned = string(H(1).Notch);
         expected = "off";
         testCase.verifyEqual(returned, expected);
      end

      function testHiddenOutliersFitTheYLimitsToTheWhiskers(testCase)
         % With MarkerStyle "none" boxchart draws no outlier points, so the
         % y limits follow the whiskers rather than the data range.

         tbl = outlierTable();

         groupstats.boxchartcats(tbl, "Value", "Grp", "Sub", ...
            MarkerStyle = "none");

         returned = max(ylim);
         testCase.verifyLessThan(returned, 1000);
      end

      function testHiddenOutliersLeaveTheWhiskersVisible(testCase)
         % The limits still cover every whisker tip.

         tbl = outlierTable();

         groupstats.boxchartcats(tbl, "Value", "Grp", "Sub", ...
            MarkerStyle = "none");

         y = groupstats.boxchartydata( ...
            tbl.Value(tbl.Grp == "a" & tbl.Sub == "x"));
         bounds = ylim;
         testCase.verifyLessThanOrEqual(bounds(1), min(y.whiskers));
         testCase.verifyGreaterThanOrEqual(bounds(2), max(y.whiskers));
      end

      function testConstantDataDoesNotBreakTheYLimits(testCase)
         % Every whisker at the same value gives a zero-width range, which
         % ylim rejects. Pad it instead.

         tbl = testCase.Tbl;
         tbl.Value(:) = 5;

         testCase.verifyWarningFree(@() groupstats.boxchartcats(tbl, ...
            "Value", "Grp", "Sub", MarkerStyle = "none"));
      end

      function testSparseGroupGridDoesNotBreakShading(testCase)
         % A group grid with a missing x-group and color-group combination
         % leaves naninterp1 too few points to interpolate between.

         tbl = testCase.Tbl(testCase.Tbl.Grp ~= "b" | testCase.Tbl.Sub ~= "y", :);
         tbl = tbl(tbl.Grp ~= "c", :);

         testCase.verifyWarningFree(@() groupstats.boxchartcats(tbl, ...
            "Value", "Grp", "Sub"));
      end

      function testShadeGroupsDefaultsOffWithoutCGroupVar(testCase)
         % The shading tells one x-tick group of colored boxes from the
         % next, so it is pointless with one box per tick. Without
         % cgroupvar, ShadeGroups must default off.

         groupstats.boxchartcats(testCase.Tbl, "Value", "Grp");

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyEmpty(returned);
      end

      function testShadeGroupsDefaultsOnWithCGroupVar(testCase)
         % With cgroupvar each x-tick holds several colored boxes, so
         % ShadeGroups must default on.

         groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyNotEmpty(returned);
      end

      function testShadeGroupsExplicitTrueShadesSingleSeries(testCase)
         % An explicit ShadeGroups=true is not the auto-default sentinel,
         % so it must still shade a chart with no color group.

         groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            ShadeGroups = true);

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyNotEmpty(returned);
      end

      function testShadeGroupsSortDescendAlignsWithDisplayOrder(testCase)
         % boxchartxdata places each column at its rounded tick position,
         % so its xleft/xright already come out in left-to-right display
         % order, unlike barchartcats' H.XEndPoints. This pins that
         % boxchartcats does not carry the sibling defect: SortBy still
         % shades alternating ticks in display order, each patch as wide
         % as the tick spacing.

         [H, ~, ax] = groupstats.boxchartcats(testCase.Tbl, "Value", ...
            "Grp", SortBy = "descend", ShadeGroups = true);

         [~, xleft, xright] = groupstats.boxchartxdata(H);
         centers = (xleft + xright) / 2;
         spacing = mean(diff(centers));

         P = findobj(ax, 'Type', 'patch');
         testCase.verifyNotEmpty(P);

         returned = P.XData(2, :) - P.XData(1, :);
         expected = repmat(spacing, 1, numel(returned));
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-9);

         returned = mean(P.XData(1:2, :), 1);
         expected = centers(1:2:end);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-9);
      end

      function testShadeGroupsSortDescendWithCGroupAlignsWithDisplayOrder( ...
            testCase)
         % The same display-order check, with a color group present.

         [H, ~, ax] = groupstats.boxchartcats(testCase.Tbl, "Value", ...
            "Grp", "Sub", SortBy = "descend");

         [~, xleft, xright] = groupstats.boxchartxdata(H);
         centers = (xleft + xright) / 2;
         spacing = mean(diff(centers));

         P = findobj(ax, 'Type', 'patch');
         testCase.verifyNotEmpty(P);

         % boxchartxdata reads box vertex positions off the rendered
         % graphics primitive, which stores them at single precision.
         % Drawing the shading patch after that read can shift the boxes
         % by one single-precision ULP (about 1.19e-7), so this
         % comparison needs a looser tolerance than the exact math above.
         returned = P.XData(2, :) - P.XData(1, :);
         expected = repmat(spacing, 1, numel(returned));
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-6);

         returned = mean(P.XData(1:2, :), 1);
         expected = centers(1:2:end);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-6);
      end

      function testLegendStringFollowsCGroupOrder(testCase)
         % LegendString(i) names the i-th member in category order, and
         % CGroupOrder permutes the entries with the series, so an entry
         % stays on its member.

         [~, L] = groupstats.boxchartcats(testCase.Tbl, "Value", "Sub", ...
            "Grp", CGroupOrder = "c", LegendString = ["s1"; "s2"; "s3"]);

         returned = string(L.String(:));
         expected = ["s3"; "s1"; "s2"];
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringIsUnmovedBySortBy(testCase)
         % SortBy orders the x-groups, not the series, so the legend keeps
         % the category-order binding.

         [~, L] = groupstats.boxchartcats(testCase.Tbl, "Value", "Sub", ...
            "Grp", SortBy = "descend", LegendString = ["s1"; "s2"; "s3"]);

         returned = string(L.String(:));
         expected = ["s1"; "s2"; "s3"];
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringNamesThePostMergeMembers(testCase)
         % After a merge there is one entry per post-merge member, in the
         % post-merge category order.

         [~, L] = groupstats.boxchartcats(testCase.Tbl, "Value", "Sub", ...
            "Grp", MergeGroupMembers = ["a", "b"], CGroupOrder = "c", ...
            LegendString = ["merged"; "third"]);

         returned = string(L.String(:));
         expected = ["third"; "merged"];
         testCase.verifyEqual(returned, expected);
      end

      function testAllMissingDataIsReported(testCase)
         % boxchart draws nothing from all-missing data and the helpers
         % that read the drawn boxes then index with NaN. The chart reports
         % the empty selection first, and the single-observation warning
         % stays quiet because no box is drawn.

         tbl = table(categorical(["p"; "q"]), categorical(["a"; "a"]), ...
            [NaN; NaN], 'VariableNames', {'xg', 'cg', 'val'});

         lastwarn('');
         testCase.verifyError( ...
            @() groupstats.boxchartcats(tbl, "val", "xg", "cg"), ...
            'groupstats:boxchartcats:allDataMissing');

         [~, returned] = lastwarn();
         expected = '';
         testCase.verifyEqual(returned, expected);
      end

      function testParentDrawsEverythingIntoTheNamedAxes(testCase)
         % The boxes, the mean symbols, the shading, the legend, and the
         % axis formatting go into Parent, and the current axes stays
         % empty and unheld.

         target = axes(figure('Visible', 'off'));
         testCase.addTeardown(@close, ancestor(target, 'figure'));
         other = axes(figure('Visible', 'off'));
         testCase.addTeardown(@close, ancestor(other, 'figure'));

         [H, L, ax] = groupstats.boxchartcats(testCase.Tbl, "Value", ...
            "Grp", "Sub", Parent = target);

         % One mean-symbol scatter per color group, and one shading patch.
         symbols = findobj(target, 'Type', 'Scatter');
         returned = {ax; H(1).Parent; L.Axes; numel(symbols); ...
            unique([symbols.Parent]); ...
            findobj(target, 'Type', 'Patch').Parent};
         expected = {target; target; target; numel(H); target; target};
         testCase.verifyEqual(returned, expected);

         returned = [string(target.YGrid); string(target.Box)];
         expected = ["off"; "on"];
         testCase.verifyEqual(returned, expected);

         returned = [numel(other.Children); ishold(other); ...
            isequal(gca, other)];
         expected = [0; false; true];
         testCase.verifyEqual(returned, expected);
      end

   end

   methods (Access = private)

      function verifyConnectingLines(testCase, option)
         %VERIFYCONNECTINGLINES Check one connecting-line option.
         %
         % Each of the two color groups holds values a decade apart, so a
         % line built across the wrong axis cannot match by chance. Both the
         % mean and the median of each group equal those values here, so one
         % expectation serves both options.

         xg = categorical(repmat(["a"; "b"; "c"], 4, 1));
         cg = categorical(repmat(["lo"; "lo"; "lo"; "hi"; "hi"; "hi"], 2, 1));
         val = [1; 10; 100; 2; 20; 200; 1; 10; 100; 2; 20; 200];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         args = {option, true};
         H = groupstats.boxchartcats(tbl, "val", "xg", "cg", args{:});

         lines = findall(ancestor(H(1), 'axes'), 'Type', 'line');

         % One line per color group, each spanning all three x-ticks.
         returned = numel(lines);
         expected = 2;
         testCase.verifyEqual(returned, expected);

         returned = sort(arrayfun(@(L) numel(L.XData), lines))';
         expected = [3, 3];
         testCase.verifyEqual(returned, expected);

         % Each line carries one color group's values, not a mix.
         returned = sort(cell2mat(arrayfun(@(L) L.YData(:), lines, ...
            'UniformOutput', false)))';
         expected = [1, 2, 10, 20, 100, 200];
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

   end
end

function tbl = outlierTable()
   %OUTLIERTABLE Build a table whose first group holds a real outlier.
   %
   % Ten observations per group and color pairing, so a single large value
   % sits beyond the inner fence. Two observations cannot produce an outlier:
   % they are the two quartiles, so the fences reach past both.

   n = 10;
   grp = repelem(["a"; "b"; "c"], 2 * n, 1);
   sub = repmat(repelem(["x"; "y"], n, 1), 3, 1);
   value = repmat((1:n)', 6, 1);
   value(1) = 1000;

   tbl = table(categorical(grp), categorical(sub), value, ...
      'VariableNames', {'Grp', 'Sub', 'Value'});
end

function fourBoxOutputs(tbl)
   %FOURBOXOUTPUTS Ask boxchartcats for a fourth output.
   %
   % Written as a function so the call is a statement, which is the only
   % place a four-output request is syntactically valid.

   [~, ~, ~, ~] = groupstats.boxchartcats(tbl, "Value", "Grp", "Sub");
end
