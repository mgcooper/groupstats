classdef test_barchartcats < matlab.unittest.TestCase
   %TEST_BARCHARTCATS Test groupstats.barchartcats.
   %
   % These cases pin the defects the audit named:
   %
   %  1. Method="median" errored, because it read a std_ column the
   %     groupsummary call never created.
   %  2. The matrix path hard-errored and could not be reached.
   %  3. SortBy accepted "order", which nothing implemented.
   %  4. ShadeGroups, PlotError, and CGroupOrder were declared and never
   %     read. Each is implemented, and covered below.
   %  5. ShadeGroups defaulted on even without cgroupvar, where the
   %     shading has nothing to tell apart. It now defaults on only when
   %     cgroupvar is given. Separately, shadebarchartgroups read
   %     H.XEndPoints in data order rather than left-to-right display
   %     order, so SortBy or XGroupOrder shaded the wrong ticks with the
   %     wrong width; it now sorts by position first.
   %
   % Every case plots into an invisible figure, so the suite runs headless.
   %
   % See also: groupstats.barchartcats

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

      function testShadeGroupsOnDrawsThePatches(testCase)
         % Turning the option on draws the alternating band patches. The
         % test passes ShadeGroups explicitly so it exercises the option,
         % not the current default.

         groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            ShadeGroups = true);

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyNotEmpty(returned);
      end

      function testShadeGroupsOffDrawsNoPatch(testCase)
         % Turning the option off removes the bands.

         groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            ShadeGroups = false);

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyEmpty(returned);
      end

      function testShadeGroupsDefaultsOffWithoutCGroupVar(testCase)
         % The shading tells one x-tick group of colored bars from the
         % next, so it is pointless with one bar per tick. Without
         % cgroupvar, ShadeGroups must default off.

         groupstats.barchartcats(testCase.Tbl, "Value", "Grp");

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyEmpty(returned);
      end

      function testShadeGroupsDefaultsOnWithCGroupVar(testCase)
         % With cgroupvar each x-tick holds several colored bars, so
         % ShadeGroups must default on.

         groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyNotEmpty(returned);
      end

      function testShadeGroupsExplicitTrueShadesSingleSeries(testCase)
         % An explicit ShadeGroups=true is not the auto-default sentinel,
         % so it must still shade a chart with no color group.

         groupstats.barchartcats(testCase.Tbl, "Value", "Grp", ...
            ShadeGroups = true);

         returned = findobj(gca, 'Type', 'patch');
         testCase.verifyNotEmpty(returned);
      end

      function testShadeGroupsSortDescendAlignsWithDisplayOrder(testCase)
         % H.XEndPoints lists each x-group in the row order XData held
         % before reordercats, not in left-to-right display order.
         % SortBy="descend" changes the display order, so the shaded
         % regions must be computed from the sorted (display) positions:
         % one region per alternating tick, each as wide as the tick
         % spacing.

         [H, ~, ax] = groupstats.barchartcats(testCase.Tbl, "Value", ...
            "Grp", SortBy = "descend", ShadeGroups = true);

         xends = sort(H.XEndPoints);
         spacing = mean(diff(xends));

         P = findobj(ax, 'Type', 'patch');
         testCase.verifyNotEmpty(P);

         returned = P.XData(2, :) - P.XData(1, :);
         expected = repmat(spacing, 1, numel(returned));
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-9);

         % Every other tick is shaded, starting at the first in display
         % order, so the patch centers land on the odd-indexed sorted
         % positions.
         returned = mean(P.XData(1:2, :), 1);
         expected = xends(1:2:end);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-9);
      end

      function testShadeGroupsSortDescendWithCGroupAlignsWithDisplayOrder( ...
            testCase)
         % The same display-order fix must hold with a color group, where
         % each x-tick's bounds are the leftmost and rightmost bar center
         % across every series.

         [H, ~, ax] = groupstats.barchartcats(testCase.Tbl, "Value", ...
            "Grp", "Sub", SortBy = "descend");

         xends = vertcat(H.XEndPoints);
         xleft = min(xends, [], 1);
         xright = max(xends, [], 1);
         [xleft, order] = sort(xleft);
         xright = xright(order);
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

      function testPlotErrorDrawsWhiskersForOneSeries(testCase)
         % summarizeTableGroups already computes the spread that pairs with
         % the method. Before this option it was discarded.

         groupstats.barchartcats(testCase.Tbl, "Value", "Grp", ...
            PlotError = true);

         returned = findobj(gca, 'Type', 'errorbar');
         testCase.verifyNotEmpty(returned);
      end

      function testPlotErrorUsesTheSpreadOfTheGroup(testCase)
         % The whisker for method mean is the standard deviation.

         groupstats.barchartcats(testCase.Tbl, "Value", "Grp", ...
            PlotError = true);

         whiskers = findobj(gca, 'Type', 'errorbar');
         expected = groupsummary(testCase.Tbl, "Grp", "std", "Value");

         returned = whiskers(1).YNegativeDelta(:);
         testCase.verifyEqual(returned, expected.std_Value, 'AbsTol', 1e-12);
      end

      function testPlotErrorRejectsSeveralSeries(testCase)
         % A categorical x-axis places every whisker on the tick center.
         % With more than one bar per tick the whiskers would not line up
         % with their bars. Say so rather than draw them in the wrong place.

         testCase.verifyError(@() groupstats.barchartcats(testCase.Tbl, ...
            "Value", "Grp", "Sub", PlotError = true), ...
            'groupstats:barchartcats:plotErrorNeedsOneSeries');
      end

      function testPlotErrorLeavesTheHoldStateAsItFoundIt(testCase)
         % plotBarErrors took hold before the several-series guard, so the
         % error left hold on and the next plot drew onto these axes.

         xg = categorical(["p"; "p"; "q"; "q"]);
         cg = categorical(["a"; "b"; "a"; "b"]);
         val = [1; 2; 3; 4];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         ax = axes(figure);
         testCase.addTeardown(@close, ancestor(ax, 'figure'));

         testCase.verifyError(@() groupstats.barchartcats(tbl, "val", ...
            "xg", "cg", PlotError = true), ...
            'groupstats:barchartcats:plotErrorNeedsOneSeries');

         returned = ishold(ax);
         expected = false;
         testCase.verifyEqual(returned, expected);
      end

      function testCGroupOrderPairsEachLabelWithItsOwnData(testCase)
         % groupsummary orders columns by category, which for a categorical
         % is alphabetical. Mapping names by first appearance instead pairs
         % each legend label with another group's bars, with no error.
         % This fixture makes the two orders disagree.

         cg = categorical(["Zeta"; "Alpha"; "Zeta"; "Alpha"]);
         xg = categorical(["x1"; "x1"; "x2"; "x2"]);
         tbl = table(xg, cg, [10; 1; 12; 3], ...
            'VariableNames', {'xg', 'cg', 'y'});

         H = groupstats.barchartcats(tbl, "y", "xg", "cg", ...
            CGroupOrder = "Zeta");

         testCase.verifyEqual(string(H(1).DisplayName), "Zeta");

         % Zeta's values are 10 and 12. Alpha's are 1 and 3.
         testCase.verifyEqual(H(1).YData(:), [10; 12]);
      end

      function testCGroupOrderOrdersTheSeries(testCase)
         % The columns of YData are the color groups, and bar draws one
         % series per column, so ordering the columns orders the legend.

         members = string(unique(testCase.Tbl.Sub, "stable"));
         order = flip(members);

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            CGroupOrder = order);

         returned = string(H(1).DisplayName);
         testCase.verifyEqual(returned, order(1));
      end

      function testCGroupOrderRejectsANonMember(testCase)
         % A name that is not a color group would otherwise index nothing
         % and drop that series without a word.
         testCase.verifyError(@() groupstats.barchartcats(testCase.Tbl, ...
            "Value", "Grp", "Sub", CGroupOrder = "nosuchgroup"), ...
            'groupstats:barchartcats:badCGroupOrder');
      end

      function testThreeOutputsOnTheNoColorGroupPath(testCase)
         % The no-color-group path turns the legend off. All three outputs
         % must still return: the legend catch must assign an empty
         % placeholder so L exists on every path.

         [H, L, ax] = groupstats.barchartcats(testCase.Tbl, "Value", "Grp");

         testCase.verifyNotEmpty(H);
         testCase.verifyTrue(isempty(L) || isgraphics(L));
         testCase.verifyTrue(isgraphics(ax, 'axes'));
      end

      function testFourOutputsAreRejected(testCase)
         % H, L, and the axes are the only outputs.

         testCase.verifyError( ...
            @() fourBarOutputs(testCase.Tbl), ...
            'MATLAB:nargoutchk:tooManyOutputs');
      end

      function testReturnsOneBarPerColorGroup(testCase)
         % One Bar object per member of the color group variable.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         testCase.verifyClass(H, 'matlab.graphics.chart.primitive.Bar');
         returned = numel(H);
         expected = numel(unique(testCase.Tbl.Sub));
         testCase.verifyEqual(returned, expected);
      end

      function testBarHeightsAreTheGroupMeans(testCase)
         % The default method is mean, so each bar is its group's mean.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         G = groupsummary(testCase.Tbl, {'Sub', 'Grp'}, "mean", "Value");
         heights = [H.YData];
         returned = sort(heights(:));
         expected = sort(G.mean_Value);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);
      end

      function testMedianMethodRuns(testCase)
         % Method="median" errored while it read a std_ column that the
         % median call never created. The spread it pairs with is the
         % interquartile range.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            Method = "median");

         testCase.verifyClass(H, 'matlab.graphics.chart.primitive.Bar');
      end

      function testMedianHeightsAreTheGroupMedians(testCase)
         % The bars carry the group medians, not the means.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            Method = "median");

         G = groupsummary(testCase.Tbl, {'Sub', 'Grp'}, "median", "Value");
         heights = [H.YData];
         returned = sort(heights(:));
         expected = sort(G.median_Value);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);
      end

      function testSortByAscendOrdersTheXGroups(testCase)
         % Ascending order puts the smallest group mean first.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            SortBy = "ascend");

         G = groupsummary(testCase.Tbl, 'Grp', "mean", "Value");
         [~, idx] = sort(G.mean_Value, 'ascend');
         returned = string(categories(H(1).XData));
         expected = string(G.Grp(idx));
         testCase.verifyEqual(returned, expected);
      end

      function testSortByOrderIsRejected(testCase)
         % "order" was accepted, and nothing implemented it, so the groups
         % stayed unsorted with no error.

         testCase.verifyError( ...
            @() groupstats.barchartcats(testCase.Tbl, "Value", "Grp", ...
            "Sub", SortBy = "order"), ...
            'MATLAB:validators:mustBeMember');
      end

      function testXGroupOrderPairsEachLabelWithItsOwnBar(testCase)
         % reordercats changes the display order and leaves the rows where
         % they are, so permuting YData alongside it moved each height onto
         % another group's tick. Reading categories() against YData hides
         % this, because the two orders coincide. Pair each bar's own x
         % value with its height instead.

         xg = categorical(["Hi"; "Hi"; "Lo"; "Lo"; "Mid"; "Mid"]);
         val = [100; 100; 10; 10; 50; 50];
         tbl = table(xg, val, 'VariableNames', {'xg', 'val'});

         H = groupstats.barchartcats(tbl, "val", "xg", XGroupOrder = "Lo");

         labels = string(H(1).XData);
         heights = H(1).YData;

         returned = heights(labels == "Hi");
         expected = 100;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);

         returned = heights(labels == "Lo");
         expected = 10;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testSortGroupMembersSurvivesCGroupOrder(testCase)
         % The sort mask marks which columns of YData the sort reads. It
         % must follow the column permutation CGroupOrder applies, so it
         % is built from the category order, not first-appearance order.
         % A first-appearance mask reads another color group's column.

         xg = categorical(["p"; "p"; "q"; "q"]);
         cg = categorical(["Alpha"; "Zeta"; "Alpha"; "Zeta"]);
         val = [100; 0; 0; 100];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         % Sorting on Alpha ascending puts q (Alpha = 0) before p
         % (Alpha = 100), whichever color group is drawn first.
         H = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            CGroupOrder = "Zeta", SortBy = "ascend", ...
            SortGroupMembers = "Alpha");

         returned = string(categories(removecats(H(1).XData)));
         expected = ["q"; "p"];
         testCase.verifyEqual(returned, expected);
      end

      function testMergeGroupMembersCombinesTheNamedMembers(testCase)
         % MergeGroupMembers names the color-group members to pool. Merging
         % two of the three color groups draws one series fewer. Each
         % (x, c) cell here holds one row, so the pooled statistic equals
         % the mean of the merged bars.

         xg = categorical(["p"; "p"; "p"; "q"; "q"; "q"]);
         cg = categorical(["a"; "b"; "c"; "a"; "b"; "c"]);
         val = [1; 3; 10; 5; 7; 20];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b"]});

         returned = numel(H);
         expected = 2;
         testCase.verifyEqual(returned, expected);

         % p merges a = 1 and b = 3; q merges a = 5 and b = 7.
         returned = H(1).YData(:);
         expected = [2; 6];
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);

         % The merged bar joins the member names and sits at the first
         % member's category position, before the unmerged group.
         returned = string({H.DisplayName})';
         expected = ["a and b"; "c"];
         testCase.verifyEqual(returned, expected);
      end

      function testMergingThreeMembers(testCase)
         % A three-member merge pools all three into one bar, the case
         % Bead groupstats-20i names in its acceptance criteria.

         xg = categorical(repmat(["p"; "q"], 4, 1));
         cg = categorical([ ...
            "a"; "a"; "b"; "b"; "c"; "c"; "d"; "d"]);
         val = [1; 2; 3; 4; 5; 6; 10; 20];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b", "c"]});

         returned = string({H.DisplayName})';
         expected = ["a and b and c"; "d"];
         testCase.verifyEqual(returned, expected);

         % p merges a = 1, b = 3, c = 5; q merges a = 2, b = 4, c = 6.
         returned = H(1).YData(:);
         expected = [3; 4];
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testMergingThreeMembersSurvivesANamedSort(testCase)
         % SortGroupMembers reads post-merge names, so a named unmerged
         % member still drives the x-group sort after a merge.

         xg = categorical(repmat(["p"; "q"], 4, 1));
         cg = categorical([ ...
            "a"; "a"; "b"; "b"; "c"; "c"; "d"; "d"]);
         val = [1; 2; 3; 4; 5; 6; 20; 10];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         % d is 20 for p and 10 for q, so ascending on d puts q first.
         H = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b", "c"]}, ...
            SortGroupMembers = "d", SortBy = "ascend");

         returned = string(categories(removecats(H(1).XData)));
         expected = ["q"; "p"];
         testCase.verifyEqual(returned, expected);
      end

      function testPooledDiffersFromMembermeanOnUnequalGroups(testCase)
         % The pooled statistic weights every row equally; membermean
         % weights every member group equally. With unequal member sizes
         % the two differ: pooled mean of a = [0 6] and b = 12 is 6, and
         % membermean is (3 + 12) / 2 = 7.5.

         xg = categorical(["p"; "p"; "p"]);
         cg = categorical(["a"; "a"; "b"]);
         val = [0; 6; 12];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         Hp = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b"]});
         returned = Hp.YData;
         expected = 6;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);

         Hm = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b"]}, MergeMethod = "membermean");
         returned = Hm.YData;
         expected = 7.5;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testUnknownMergeMemberErrors(testCase)
         % A merge member must be a member of the color-group variable.

         xg = categorical(["p"; "q"]);
         cg = categorical(["a"; "b"]);
         val = [1; 2];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         testCase.verifyError(@() groupstats.barchartcats(tbl, "val", ...
            "xg", "cg", MergeGroupMembers = {["a", "zzz"]}), ...
            'groupstats:mergegroupmembers:unknownMergeMember');
      end

      function testOverlappingMergeGroupsErrors(testCase)
         % A member named in two merge groups has no single destination.

         xg = categorical(repmat(["p"; "q"], 3, 1));
         cg = categorical(["a"; "a"; "b"; "b"; "c"; "c"]);
         val = [1; 2; 3; 4; 5; 6];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         testCase.verifyError(@() groupstats.barchartcats(tbl, "val", ...
            "xg", "cg", MergeGroupMembers = {["a", "b"], ["b", "c"]}), ...
            'groupstats:mergegroupmembers:overlappingMergeGroups');
      end

      function testMergeWithoutCGroupVarErrors(testCase)
         % Merging pools members of the color-group variable, so without
         % one there is nothing to pool.

         xg = categorical(["p"; "q"]);
         val = [1; 2];
         tbl = table(xg, val, 'VariableNames', {'xg', 'val'});

         testCase.verifyError(@() groupstats.barchartcats(tbl, "val", ...
            "xg", MergeGroupMembers = {["p", "q"]}), ...
            'groupstats:barchartcats:mergeWithoutGroupVar');
      end

      function testPlotErrorWorksWithPooledMergeToOneSeries(testCase)
         % Pooled merging keeps the rows, so the merged series has a real
         % spread and PlotError draws whiskers. PlotError needs one bar per
         % x-tick, so merge every member into one series.

         xg = categorical(repmat(["p"; "q"], 3, 1));
         cg = categorical(["a"; "a"; "b"; "b"; "c"; "c"]);
         val = [1; 2; 3; 4; 5; 6];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            MergeGroupMembers = {["a", "b", "c"]}, PlotError = true);

         returned = numel(H);
         expected = 1;
         testCase.verifyEqual(returned, expected);
      end

      function testPlotErrorRejectsMembermeanMerge(testCase)
         % The membermean merge drops the spread, so PlotError has nothing
         % to draw with it.

         xg = categorical(repmat(["p"; "q"], 3, 1));
         cg = categorical(["a"; "a"; "b"; "b"; "c"; "c"]);
         val = [1; 2; 3; 4; 5; 6];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         testCase.verifyError(@() groupstats.barchartcats(tbl, "val", ...
            "xg", "cg", MergeGroupMembers = {["a", "b", "c"]}, ...
            MergeMethod = "membermean", PlotError = true), ...
            'groupstats:barchartcats:plotErrorNeedsUnmergedGroups');
      end

      function testCallerPropertiesSurviveTheDefaults(testCase)
         % bar took the caller's properties, then the color loop set
         % FaceAlpha, LineWidth, CData, and EdgeColor whatever the caller
         % passed. FaceAlpha came back 0.75 for every call.

         xg = categorical(["p"; "p"; "q"; "q"]);
         cg = categorical(["a"; "b"; "a"; "b"]);
         val = [1; 2; 3; 4];
         tbl = table(xg, cg, val, 'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            FaceAlpha = 0.2, LineWidth = 3);

         returned = unique([H.FaceAlpha]);
         expected = 0.2;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);

         returned = unique([H.LineWidth]);
         expected = 3;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);

         % The default still applies when the caller names nothing.
         H = groupstats.barchartcats(tbl, "val", "xg", "cg");

         returned = unique([H.FaceAlpha]);
         expected = 0.75;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testXGroupOrderNamesTheOrder(testCase)
         % XGroupOrder sets the category order directly.

         order = ["c"; "b"; "a"];
         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            XGroupOrder = order);

         returned = string(categories(H(1).XData));
         testCase.verifyEqual(returned, order);
      end

      function testMatrixInputCannotReachAMatrixPath(testCase)
         % The first argument is declared tabular, so a matrix is rejected on
         % the way in. No matrix branch is reachable. Declaring it table
         % instead converted the matrix and failed later, on a variable name.

         try
            groupstats.barchartcats(magic(4), "Value", "Grp");
            testCase.verifyFail('Expected an error for a matrix input.')
         catch ME
            testCase.verifyEqual(ME.identifier, ...
               'MATLAB:validation:UnableToConvert', ...
               sprintf('Unexpected identifier: %s', ME.identifier));
         end
      end

      function testAMemberNamedAllCanBeTheSortMember(testCase)
         % Empty is the no-selection sentinel, so a member that happens to
         % be named "all" is a name like any other.

         xg = categorical(["p"; "p"; "q"; "q"]);
         cg = categorical(["all"; "y"; "all"; "y"]);
         tbl = table(xg, cg, [1; 10; 5; 2], ...
            'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.barchartcats(tbl, "val", "xg", "cg", ...
            SortBy = "ascend", SortGroupMembers = "all");

         % Over member "all" alone p is 1 and q is 5, so p leads; over
         % every bar q would lead.
         returned = string(categories(H(1).XData));
         expected = ["p"; "q"];
         testCase.verifyEqual(returned, expected);
      end

      function testSortGroupMembersWithoutCGroupVarErrors(testCase)
         % The option names color-group members, so it needs cgroupvar.

         testCase.verifyError(@() groupstats.barchartcats(testCase.Tbl, ...
            "Value", "Grp", SortBy = "ascend", SortGroupMembers = "x"), ...
            'groupstats:barchartcats:sortGroupMembersWithoutGroupVar');
      end

      function testUnknownSortGroupMemberErrors(testCase)
         % A name that matches no member would select no column and sort
         % nothing, so it is reported.

         testCase.verifyError(@() groupstats.barchartcats(testCase.Tbl, ...
            "Value", "Grp", "Sub", SortBy = "ascend", ...
            SortGroupMembers = "nosuchmember"), ...
            'groupstats:validatemember:notAMember');
      end

      function testTwoColorGroupVariablesAreRejected(testCase)
         % cgroupvar names one grouping or none.

         testCase.verifyError(@() groupstats.barchartcats(testCase.Tbl, ...
            "Value", "Grp", ["Sub", "Set"]), ...
            'MATLAB:validators:mustBeScalarOrEmpty');
      end

      function testGraphicsPropertiesPassThrough(testCase)
         % A Bar property named in the call reaches the Bar object.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            BarWidth = 0.5);

         returned = H(1).BarWidth;
         expected = 0.5;
         testCase.verifyEqual(returned, expected);
      end

      function testMissingCombinationLeavesAnEmptyBar(testCase)
         % groupsummary returns no row for an (x-group, color-group) pair
         % with no rows. A reshape of that shorter list failed, or moved
         % every later value onto another pair's bar. Each value must land
         % on its own bar and the absent pair must draw no bar.

         xg = categorical(["x1"; "x1"; "x2"]);
         cg = categorical(["a"; "b"; "a"]);
         tbl = table(xg, cg, [1; 2; 3], 'VariableNames', {'xg', 'cg', 'y'});

         H = groupstats.barchartcats(tbl, "y", "xg", "cg");

         % Series 1 is "a": x1 = 1, x2 = 3. Series 2 is "b": x1 = 2, x2
         % has no rows.
         returned = vertcat(H.YData);
         expected = [1, 3; 2, NaN];
         testCase.verifyEqual(returned, expected);
      end

      function testMissingCombinationLeavesAnEmptyWhisker(testCase)
         % The spread lands in the same slots as the height, so the
         % whisker of an absent pair is missing too.

         xg = categorical(["x1"; "x1"; "x2"; "x2"; "x2"]);
         cg = categorical(["a"; "a"; "a"; "a"; "b"]);
         tbl = table(xg, cg, [1; 3; 2; 4; 5], ...
            'VariableNames', {'xg', 'cg', 'y'});

         [H, ~, ax] = groupstats.barchartcats(tbl, "y", "xg", "cg", ...
            XGroupMembers = "x2", CGroupMembers = "b", PlotError = true);

         whisker = findobj(ax, 'Type', 'ErrorBar');
         returned = [H.YData; whisker.YNegativeDelta];
         expected = [5; 0];
         testCase.verifyEqual(returned, expected);
      end

      function testASummaryTableIsSummarizedAgain(testCase)
         % A table that groupsummary already summarized has one row per
         % pair. Naming its summary column as ydatavar summarizes those
         % rows again, so each bar is the mean of the summary rows in its
         % group, one row here.

         G = groupsummary(testCase.Tbl, ["Grp", "Sub"], "mean", "Value");

         H = groupstats.barchartcats(G, "mean_Value", "Grp", "Sub");

         expected = groupsummary(G, ["Sub", "Grp"], "mean", "mean_Value");
         returned = reshape(vertcat(H.YData)', [], 1);
         testCase.verifyEqual(returned, expected.mean_mean_Value, ...
            'AbsTol', 1e-12);
      end

      function testLegendStringFollowsCGroupOrder(testCase)
         % LegendString(i) names the i-th member in category order, and
         % CGroupOrder permutes the entries with the series, so an entry
         % stays on its member.

         cg = categorical(["Zeta"; "Alpha"; "Zeta"; "Alpha"]);
         xg = categorical(["x1"; "x1"; "x2"; "x2"]);
         tbl = table(xg, cg, [10; 1; 12; 3], ...
            'VariableNames', {'xg', 'cg', 'y'});

         [~, L] = groupstats.barchartcats(tbl, "y", "xg", "cg", ...
            CGroupOrder = "Zeta", LegendString = ["alpha"; "zeta"]);

         returned = string(L.String(:));
         expected = ["zeta"; "alpha"];
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringIsUnmovedBySortBy(testCase)
         % SortBy orders the x-groups, not the series, so the legend keeps
         % the category-order binding.

         [~, L] = groupstats.barchartcats(testCase.Tbl, "Value", "Sub", ...
            "Grp", SortBy = "descend", LegendString = ["s1"; "s2"; "s3"]);

         returned = string(L.String(:));
         expected = ["s1"; "s2"; "s3"];
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringNamesThePostMergeMembers(testCase)
         % After a merge there is one entry per post-merge member, in the
         % post-merge category order.

         [~, L] = groupstats.barchartcats(testCase.Tbl, "Value", "Sub", ...
            "Grp", MergeGroupMembers = ["a", "b"], CGroupOrder = "c", ...
            LegendString = ["merged"; "third"]);

         returned = string(L.String(:));
         expected = ["third"; "merged"];
         testCase.verifyEqual(returned, expected);
      end

      function testBarColorsFollowDefaultcolors(testCase)
         % The k-th color group takes the k-th defaultcolors row, the
         % palette boxchartcats and scatter read, with no colormap path.

         defaultcolors = groupstats.internal.privatefunction( ...
            'defaultcolors');
         palette = defaultcolors();

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         returned = vertcat(H.FaceColor);
         expected = palette(1:numel(H), :);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);

         returned = vertcat(H.EdgeColor);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testBarColorsWrapPastThePalette(testCase)
         % More series than palette rows start over from the first row.

         defaultcolors = groupstats.internal.privatefunction( ...
            'defaultcolors');
         palette = defaultcolors();
         ngroups = size(palette, 1) + 1;

         cg = categorical(string(1:ngroups)', string(1:ngroups));
         xg = categorical(repmat("x", ngroups, 1));
         tbl = table(xg, cg, (1:ngroups)', ...
            'VariableNames', {'xg', 'cg', 'y'});

         H = groupstats.barchartcats(tbl, "y", "xg", "cg");

         returned = H(end).FaceColor;
         expected = palette(1, :);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testParentDrawsEverythingIntoTheNamedAxes(testCase)
         % The bars, the whiskers, the shading, the legend, and the axis
         % formatting go into Parent, and the current axes stays empty and
         % unheld. This chart has no cgroupvar, so ShadeGroups now
         % defaults off; pass it explicitly to keep exercising the
         % shading's Parent routing.

         target = axes(figure('Visible', 'off'));
         testCase.addTeardown(@close, ancestor(target, 'figure'));
         other = axes(figure('Visible', 'off'));
         testCase.addTeardown(@close, ancestor(other, 'figure'));

         [H, L, ax] = groupstats.barchartcats(testCase.Tbl, "Value", ...
            "Grp", Parent = target, PlotError = true, ShadeGroups = true);

         returned = {ax; H.Parent; L.Axes; ...
            findobj(target, 'Type', 'ErrorBar').Parent; ...
            findobj(target, 'Type', 'Patch').Parent};
         expected = repmat({target}, 5, 1);
         testCase.verifyEqual(returned, expected);

         returned = [string(target.YGrid); string(target.Box)];
         expected = ["on"; "on"];
         testCase.verifyEqual(returned, expected);

         returned = [numel(other.Children); ishold(other); ...
            isequal(gca, other)];
         expected = [0; false; true];
         testCase.verifyEqual(returned, expected);
      end


      function testMissingCombinationDoesNotBreakTheSort(testCase)
         % The sort statistic reads the bars that exist, so an absent pair
         % does not turn its x-group's mean into NaN. Here x2 has one bar
         % of 3 and x1 has bars of 1 and 2, so x1 leads ascending.

         xg = categorical(["x1"; "x1"; "x2"]);
         cg = categorical(["a"; "b"; "a"]);
         tbl = table(xg, cg, [1; 2; 3], 'VariableNames', {'xg', 'cg', 'y'});

         H = groupstats.barchartcats(tbl, "y", "xg", "cg", ...
            SortBy = "descend");

         returned = string(categories(H(1).XData));
         expected = ["x2"; "x1"];
         testCase.verifyEqual(returned, expected);
      end

      function testXGroupWithNoSelectedBarSortsLast(testCase)
         % An x-group with none of the SortGroupMembers bars has no
         % statistic and sorts last in either direction.

         xg = categorical(["x1"; "x1"; "x2"]);
         cg = categorical(["a"; "b"; "a"]);
         tbl = table(xg, cg, [1; 2; 3], 'VariableNames', {'xg', 'cg', 'y'});

         H = groupstats.barchartcats(tbl, "y", "xg", "cg", ...
            SortBy = "descend", SortGroupMembers = "b");

         returned = string(categories(H(1).XData));
         expected = ["x1"; "x2"];
         testCase.verifyEqual(returned, expected);
      end


      function testMembermeanMergeSkipsAnAbsentMember(testCase)
         % A merged member with no rows in an x-group holds NaN there. The
         % merged bar is the mean of the members that exist, and NaN only
         % where none do.

         xg = categorical(["x1"; "x1"; "x2"; "x1"; "x2"]);
         cg = categorical(["a"; "b"; "a"; "c"; "c"]);
         tbl = table(xg, cg, [1; 3; 5; 7; 9], ...
            'VariableNames', {'xg', 'cg', 'y'});

         H = groupstats.barchartcats(tbl, "y", "xg", "cg", ...
            MergeGroupMembers = ["a", "b"], MergeMethod = "membermean");

         % x1: a = 1 and b = 3 average 2. x2: a = 5 alone. c is 7 and 9.
         returned = vertcat(H.YData);
         expected = [2, 5; 7, 9];
         testCase.verifyEqual(returned, expected);
      end


      function testCallerCDataColorsTheBars(testCase)
         % CData shows only under flat coloring, so a caller's CData turns
         % the palette default into "flat" and keeps its own colors.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", ...
            CData = [1 0 0; 0 1 0; 0 0 1]);

         returned = {string(H.FaceColor); string(H.EdgeColor); H.CData};
         expected = {"flat"; "flat"; [1 0 0; 0 1 0; 0 0 1]};
         testCase.verifyEqual(returned, expected);
      end

   end
end

function fourBarOutputs(tbl)
   %FOURBAROUTPUTS Ask barchartcats for a fourth output.
   %
   % Written as a function so the call is a statement, which is the only
   % place a four-output request is syntactically valid.

   [~, ~, ~, ~] = groupstats.barchartcats(tbl, "Value", "Grp", "Sub");
end
