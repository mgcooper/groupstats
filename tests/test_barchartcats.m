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

      function testGraphicsPropertiesPassThrough(testCase)
         % A Bar property named in the call reaches the Bar object.

         H = groupstats.barchartcats(testCase.Tbl, "Value", "Grp", "Sub", ...
            BarWidth = 0.5);

         returned = H(1).BarWidth;
         expected = 0.5;
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
