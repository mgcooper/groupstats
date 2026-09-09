classdef test_scatter < matlab.unittest.TestCase
   %TEST_SCATTER Test groupstats.scatter.
   %
   % These cases pin the defects the audit named:
   %
   %  1. The function opened a figure unconditionally, so it could not plot
   %     into an existing axes even though Parent was advertised.
   %  2. Legend, LegendString, and LegendOrientation were declared and never
   %     read.
   %  3. groupLegend declared five arguments and every call site passed four.
   %  4. The unlicensed-grpstats fallback indexed a numeric array with a
   %     categorical.
   %  5. Asking for three or more outputs failed on an unassigned output.
   %  6. props was declared and never applied, so a named graphics property
   %     was accepted and ignored.
   %
   % See also: groupstats.scatter

   properties
      Tbl
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure);
         data = groupstats.test.generateTestData('groupsummary');
         tbl = data.tbl;
         tbl.X = (1:height(tbl))';
         testCase.Tbl = tbl;
      end
   end

   methods (Test)

      function testMergeGroupMembersPoolsColorGroups(testCase)
         % MergeGroupMembers pools the named color groups, matching the
         % other charts: one Line fewer, and the merged legend entry joins
         % the member names with " and ".

         g = categorical(repmat(["a"; "b"; "c"], 4, 1));
         x = (1:12)';
         y = (12:-1:1)';
         tbl = table(x, y, g, 'VariableNames', {'x', 'y', 'g'});

         [H, L] = groupstats.scatter(tbl, "x", "y", "g", ...
            MergeGroupMembers = {["a", "b"]});

         returned = numel(H);
         expected = 2;
         testCase.verifyEqual(returned, expected);

         returned = string(L.String);
         testCase.verifyTrue(any(returned == "a and b"));
      end

      function testReturnsOneHandlePerColorGroup(testCase)
         % One Line object per member of the color group variable.

         H = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp");

         returned = numel(H);
         expected = numel(unique(testCase.Tbl.Grp));
         testCase.verifyEqual(returned, expected);
      end

      function testSizeGroupAddsAColumn(testCase)
         % H is a matrix: one row per color group, one column per size group.

         H = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", "Sub");

         returned = size(H);
         expected = [numel(unique(testCase.Tbl.Grp)), ...
            numel(unique(testCase.Tbl.Sub))];
         testCase.verifyEqual(returned, expected);
      end

      function testParentIsHonored(testCase)
         % The points go to the named axes. The function opened its own
         % figure, so an existing axes could never receive them.

         ax = axes(figure('Visible', 'off'));
         cleanup = onCleanup(@() close(ax.Parent));

         H = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            Parent = ax);

         returned = ancestor(H(1), 'axes');
         testCase.verifyEqual(returned, ax);
      end

      function testCurrentFigureIsRestored(testCase)
         % gscatter plots into gca, so the named axes is made current. Put the
         % caller's current figure back, or a later unguarded plot lands in
         % the wrong window.

         other = figure('Visible', 'off');
         ax = axes(other);
         mine = figure('Visible', 'off');
         cleanup = onCleanup(@() close([other, mine]));
         set(groot, 'CurrentFigure', mine);

         groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", Parent = ax);

         returned = gcf;
         testCase.verifyEqual(returned, mine);
      end

      function testHandlesDoNotAliasEachOther(testCase)
         % gscatter returns one handle per color group it found. Assigning a
         % single handle to a whole column of H would broadcast it, leaving
         % every row pointing at the same object.

         sub = [repmat("s1", 6, 1); repmat("s2", 6, 1)];
         col = [repmat("A", 6, 1); repmat("B", 6, 1)];
         tbl = table(categorical(col), categorical(sub), (1:12)', ...
            (12:-1:1)', 'VariableNames', {'C', 'S', 'X', 'Y'});

         H = groupstats.scatter(tbl, "X", "Y", "C", "S");

         valid = H(isgraphics(H));
         returned = numel(unique(valid));
         expected = numel(valid);
         testCase.verifyEqual(returned, expected);
      end

      function testLegendOffReturnsNoLegend(testCase)
         % Legend was declared and never read.

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            Legend = "off");

         testCase.verifyEmpty(L);
      end

      function testLegendOrientationIsHonored(testCase)
         % LegendOrientation was declared and never read.

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            LegendOrientation = "horizontal");

         returned = string(L.Orientation);
         expected = "horizontal";
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringReplacesTheEntries(testCase)
         % LegendString was declared and never read.

         entries = ["one"; "two"; "three"];
         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            LegendString = entries);

         returned = string(L.String(:));
         testCase.verifyEqual(returned, entries);
      end

      function testShortLegendStringFallsBackToTheNames(testCase)
         % A list that does not cover every entry would mislabel the rest, so
         % the member names stand instead.

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            LegendString = "only one");

         returned = string(L.String(:));
         expected = string(unique(testCase.Tbl.Grp));
         testCase.verifyEqual(sort(returned), sort(expected));
      end

      function testThirdOutputIsTheAxes(testCase)
         % The family signature is (H, L, ax), and the third output is the
         % axes the chart was drawn into.

         [~, ~, ax] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp");

         testCase.verifyTrue(isgraphics(ax, 'axes'));
      end

      function testFourOutputsAreRejected(testCase)
         % H, L, and the axes are the only outputs.

         testCase.verifyError( ...
            @() fourOutputs(testCase.Tbl), ...
            'MATLAB:nargoutchk:tooManyOutputs');
      end

      function testLinePropertiesPassThrough(testCase)
         % props was declared and never applied, so a named property was
         % accepted and ignored. gscatter draws Line objects, so a Line
         % property is what applies.

         H = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            MarkerSize = 12);

         returned = H(1).MarkerSize;
         expected = 12;
         testCase.verifyEqual(returned, expected);
      end

      function testSortByDefaultsToNoSorting(testCase)
         % SortBy defaults to "none", so the legend keeps the group order,
         % and SortVar alone changes nothing.

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            SortVar = "ydatavar");

         returned = string(L.String(:));
         expected = string(unique(testCase.Tbl.Grp));
         testCase.verifyEqual(returned, expected);
      end

      function testSortByOrdersTheLegend(testCase)
         % SortBy "descend" orders the legend by the group mean of SortVar
         % within the SortGroup groups, high to low.

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            SortVar = "ydatavar", SortBy = "descend");

         G = groupsummary(testCase.Tbl, "Grp", "mean", "Value");
         [~, order] = sort(G.mean_Value, "descend");

         returned = string(L.String(:));
         expected = string(G.Grp(order));
         testCase.verifyEqual(returned, expected);
      end

      function testCGroupOrderOrdersTheLegend(testCase)
         % CGroupOrder is a partial order: the named member comes first,
         % and the rest keep their order.

         members = string(unique(testCase.Tbl.Grp));

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            CGroupOrder = members(end));

         returned = string(L.String(1));
         expected = members(end);
         testCase.verifyEqual(returned, expected);
      end

      function testSparseSymbolGroupAlignsHandles(testCase)
         % A symbol subset can hold only a color category whose code is
         % not the last. gscatter then returns placeholder handles for the
         % unused lower codes, and handle k is category k, so the
         % assignment must align by code. A present-value mask miscounted
         % here and errored.

         g = categorical(["A"; "B"; "C"; "C"]);
         s = categorical(["s1"; "s1"; "s1"; "s2"]);
         x = (1:4)';
         y = (4:-1:1)';
         tbl = table(x, y, g, s, 'VariableNames', {'x', 'y', 'g', 's'});

         % The order A, C, B gives C code 2, and the s2 subset holds only
         % C rows, so its gscatter call returns two handles.
         H = groupstats.scatter(tbl, "x", "y", "g", "s", ...
            CGroupOrder = ["A", "C"]);

         testCase.verifySize(H, [3, 2]);
         returned = numel(H(2, 2).XData);
         expected = 1;
         testCase.verifyEqual(returned, expected);
      end

      function testCGroupOrderBeatsSortBy(testCase)
         % An explicit member order on the sorted grouping wins over
         % SortBy, the same rule the cats charts apply.

         members = string(unique(testCase.Tbl.Grp));

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            CGroupOrder = members(end), ...
            SortVar = "ydatavar", SortBy = "descend");

         returned = string(L.String(1));
         expected = members(end);
         testCase.verifyEqual(returned, expected);
      end

      function testSortByStillSortsTheOtherGrouping(testCase)
         % An explicit color order does not disable SortBy on the symbol
         % grouping, because the sort reads SortGroup.

         cmembers = string(unique(testCase.Tbl.Grp));

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            "Sub", CGroupOrder = cmembers(end), ...
            SortGroup = "sgroupvar", SortVar = "ydatavar", ...
            SortBy = "descend");

         G = groupsummary(testCase.Tbl, "Sub", "mean", "Value");
         [~, order] = sort(G.mean_Value, "descend");

         % The symbol entries follow the color entries in the legend.
         ncolor = numel(cmembers);
         returned = string(L.String(ncolor + 1));
         expected = string(G.Sub(order(1)));
         testCase.verifyEqual(returned, expected);
      end

      function testTwoSizeGroupVariablesAreRejected(testCase)
         % sgroupvar names one grouping or none.

         testCase.verifyError(@() groupstats.scatter(testCase.Tbl, ...
            "X", "Value", "Grp", ["Sub", "Set"]), ...
            'MATLAB:validators:mustBeScalarOrEmpty');
      end

      function testColorsFollowDefaultcolorsAndWrap(testCase)
         % Every chart in the family reads defaultcolors, so the k-th color
         % group takes its k-th row, and a chart with more groups than
         % rows starts over from the first row.

         defaultcolors = groupstats.internal.privatefunction( ...
            'defaultcolors');
         palette = defaultcolors();
         ngroups = size(palette, 1) + 2;

         g = categorical(repelem(string(1:ngroups)', 2, 1), ...
            string(1:ngroups));
         x = (1:2 * ngroups)';
         tbl = table(x, x, g, 'VariableNames', {'x', 'y', 'g'});

         H = groupstats.scatter(tbl, "x", "y", "g");

         returned = vertcat(H(1:size(palette, 1)).Color);
         expected = palette;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);

         returned = vertcat(H(end - 1:end).Color);
         expected = palette(1:2, :);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testSGroupOrderOrdersTheSymbolGroups(testCase)
         % SGroupOrder does the same for the symbol grouping.

         members = string(unique(testCase.Tbl.Sub));

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            "Sub", SGroupOrder = members(end));

         % The symbol entries follow the color entries in the legend.
         ncolor = numel(unique(testCase.Tbl.Grp));
         returned = string(L.String(ncolor + 1));
         expected = members(end);
         testCase.verifyEqual(returned, expected);
      end

      function testOrdinalSortVarSortsByRanking(testCase)
         % A categorical data variable whose categories are names is drawn
         % by ranking, so an ordinal SortVar sorts the legend by that
         % ranking instead of keeping the default order.

         level = categorical(["low"; "mid"; "high"; "low"; "high"; "mid"], ...
            ["low", "mid", "high"], 'Ordinal', true);
         grp = categorical(["p"; "p"; "q"; "q"; "r"; "r"]);
         tbl = table((1:6)', level, grp, ...
            'VariableNames', {'X', 'Level', 'Grp'});

         % Mean rankings: p = 1.5, q = 2, r = 2.5.
         [~, L] = groupstats.scatter(tbl, "X", "Level", "Grp", ...
            SortVar = "ydatavar", SortBy = "descend");
         returned = string(L.String(:));
         expected = ["r"; "q"; "p"];
         testCase.verifyEqual(returned, expected);

         [~, L] = groupstats.scatter(tbl, "X", "Level", "Grp", ...
            SortVar = "ydatavar", SortBy = "ascend");
         returned = string(L.String(:));
         expected = ["p"; "q"; "r"];
         testCase.verifyEqual(returned, expected);
      end

      function testRankedDataLabelsTheTicksWithTheCategories(testCase)
         % The ranked axis shows the categories at the ranks.

         level = categorical(["low"; "mid"; "high"], ...
            ["low", "mid", "high"], 'Ordinal', true);
         tbl = table((1:3)', level, categorical(["p"; "p"; "q"]), ...
            'VariableNames', {'X', 'Level', 'Grp'});

         [H, ~, ax] = groupstats.scatter(tbl, "X", "Level", "Grp");

         returned = {ax.YTick(:); string(ax.YTickLabel(:)); H(1).YData(:)};
         expected = {[1; 2; 3]; ["low"; "mid"; "high"]; [1; 2]};
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringFollowsSortBy(testCase)
         % LegendString(i) names the i-th color member in category order,
         % and SortBy moves the entries with the groups, so an entry stays
         % on its member.

         G = groupsummary(testCase.Tbl, "Grp", "mean", "Value");
         [~, order] = sort(G.mean_Value, "descend");
         names = "label " + string(G.Grp);

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            SortVar = "ydatavar", SortBy = "descend", LegendString = names);

         returned = string(L.String(:));
         expected = names(order);
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringFollowsCGroupOrder(testCase)
         % CGroupOrder moves the entries with the groups the same way.

         members = string(categories(testCase.Tbl.Grp));
         names = "label " + members;

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            CGroupOrder = members(end), LegendString = names);

         returned = string(L.String(:));
         expected = [names(end); names(1:end - 1)];
         testCase.verifyEqual(returned, expected);
      end

      function testLegendStringCoversTheSymbolGroupsToo(testCase)
         % With a size grouping the entries are the color members then the
         % symbol members, and SGroupOrder moves the symbol block.

         cmembers = string(categories(testCase.Tbl.Grp));
         smembers = string(categories(testCase.Tbl.Sub));
         names = ["c " + cmembers; "s " + smembers];

         [~, L] = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            "Sub", SGroupOrder = smembers(end), LegendString = names);

         returned = string(L.String(:));
         expected = ["c " + cmembers; "s " + smembers(end); ...
            "s " + smembers(1:end - 1)];
         testCase.verifyEqual(returned, expected);
      end


      function testOrdinalXDataIsRankedToo(testCase)
         % The x data variable takes the same path: a categorical whose
         % categories are names is ranked, its ticks are labeled, and
         % SortVar "xdatavar" sorts the legend by the ranking.

         level = categorical(["low"; "mid"; "high"; "low"; "high"; "mid"], ...
            ["low", "mid", "high"], 'Ordinal', true);
         grp = categorical(["p"; "p"; "q"; "q"; "r"; "r"]);
         tbl = table(level, (1:6)', grp, ...
            'VariableNames', {'Level', 'Y', 'Grp'});

         % Mean rankings: p = 1.5, q = 2, r = 2.5.
         [H, L, ax] = groupstats.scatter(tbl, "Level", "Y", "Grp", ...
            SortVar = "xdatavar", SortBy = "descend");

         returned = {string(L.String(:)); ax.XTick(:); ...
            string(ax.XTickLabel(:)); H(1).XData(:)};
         expected = {["r"; "q"; "p"]; [1; 2; 3]; ["low"; "mid"; "high"]; ...
            [1; 2]};
         testCase.verifyEqual(returned, expected);
      end

      function testUndefinedCategoryIsMissingNotRankZero(testCase)
         % An undefined value has category code 0. It must draw no point
         % and stay out of the legend sort, so it becomes NaN.

         level = categorical(["low"; "high"; "high"; "low"; "low"; ""], ...
            ["low", "high"], 'Ordinal', true);
         grp = categorical(["p"; "p"; "q"; "q"; "q"; "q"]);
         tbl = table((1:6)', level, grp, ...
            'VariableNames', {'X', 'Level', 'Grp'});

         % With the undefined row as rank 0, q would average 1 and p 1.5.
         % Without it q averages 4/3 and p 1.5, so p still leads descending
         % and the undefined row draws nothing.
         [H, L] = groupstats.scatter(tbl, "X", "Level", "Grp", ...
            SortVar = "ydatavar", SortBy = "ascend");

         returned = {string(L.String(:)); nnz(isnan(H(2).YData))};
         expected = {["q"; "p"]; 1};
         testCase.verifyEqual(returned, expected);
      end


      function testGroupWithNoSortDataSortsLastInBothDirections(testCase)
         % A group whose sort data is all undefined has no mean, so it
         % sorts last whichever direction is asked for.

         level = categorical(["low"; "high"; ""; ""], ["low", "high"], ...
            'Ordinal', true);
         grp = categorical(["p"; "q"; "r"; "r"]);
         tbl = table((1:4)', level, grp, ...
            'VariableNames', {'X', 'Level', 'Grp'});

         [~, L] = groupstats.scatter(tbl, "X", "Level", "Grp", ...
            SortVar = "ydatavar", SortBy = "descend");
         returned = string(L.String(:));
         expected = ["q"; "p"; "r"];
         testCase.verifyEqual(returned, expected);

         [~, L] = groupstats.scatter(tbl, "X", "Level", "Grp", ...
            SortVar = "ydatavar", SortBy = "ascend");
         returned = string(L.String(:));
         expected = ["p"; "q"; "r"];
         testCase.verifyEqual(returned, expected);
      end

   end
end

function fourOutputs(tbl)
   %FOUROUTPUTS Ask scatter for a fourth output.
   %
   % Written as a function so the call is a statement, which is the only
   % place a four-output request is syntactically valid.

   [~, ~, ~, ~] = groupstats.scatter(tbl, "X", "Value", "Grp");
end
