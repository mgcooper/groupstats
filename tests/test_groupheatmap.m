classdef test_groupheatmap < matlab.unittest.TestCase
   %TEST_GROUPHEATMAP Test groupstats.groupheatmap.
   %
   % The expected cell values are hand values. The "groupheatmap" case of
   % generateTestData stores them for each Method, and the comments below
   % derive the others. No expected value comes from the built-in heatmap or
   % from groupheatmap. The tests read ColorDisplayData, the display data,
   % and the chart parents, and no test pins a color that depends on the
   % release or the theme.
   %
   % See also: groupstats.groupheatmap, groupstats.test.generateTestData

   properties (TestParameter)
      % Every heatmap Method.
      method = {'mean', 'median', 'count', 'sum', 'min', 'max'}

      % Every data property that groupheatmap sets from its own inputs.
      dataprop = {'SourceTable', 'XVariable', 'YVariable', ...
         'ColorVariable', 'ColorMethod', 'XData', 'YData', 'ColorData', ...
         'XDisplayData', 'YDisplayData'}
   end

   properties
      % The groupheatmap case: Grp p, q, r by Sub u, v, w.
      Data
      % Its hand values.
      Expected
      % The groupsummary case table: Grp a, b, c by Sub x, y.
      Tbl
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure);
         [testCase.Data, testCase.Expected] = ...
            groupstats.test.generateTestData('groupheatmap');
         data = groupstats.test.generateTestData('groupsummary');
         testCase.Tbl = data.tbl;
      end
   end

   methods (Test)

      % ---- Cell values

      function testEachMethodShowsEachPairingsValue(testCase, method)
         % Every cell holds the hand value of its own pairing. Row v holds
         % the mixed, NaN-only, and empty pairings.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", Method = method);

         testCase.verifyEqual(displayed(h.XDisplayData), ...
            testCase.Expected.xmembers);
         testCase.verifyEqual(displayed(h.YDisplayData), ...
            testCase.Expected.cmembers);
         testCase.verifyEqual(h.ColorDisplayData, ...
            testCase.Expected.(method), 'AbsTol', 1e-12);
      end

      function testEmptyPairingsShowNaNOrZero(testCase, method)
         % q-v holds only NaN and r-v has no rows. Both show NaN for mean,
         % median, min, and max, and 0 for count and sum.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", Method = method);

         returned = h.ColorDisplayData(2, 2:3);
         if ismember(method, ["count", "sum"])
            expected = [0 0];
         else
            expected = [NaN NaN];
         end
         testCase.verifyEqual(returned, expected);
      end

      function testTheDocumentedExample(testCase)
         % Each Grp-Sub pairing of the groupsummary case holds two values
         % two apart: a-x {1, 3}, a-y {2, 4}, and so on.

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub");
         testCase.verifyEqual(h.ColorDisplayData, [2 6 10; 3 7 11]);

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            Method = "count");
         testCase.verifyEqual(h.ColorDisplayData, repmat(2, 2, 3));
      end

      % ---- Selection and merge

      function testMemberSelection(testCase)
         % Grp a and c keep their columns; Sub y keeps its row.

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            XGroupMembers = ["a", "c"]);
         testCase.verifyEqual(displayed(h.XDisplayData), ["a"; "c"]);
         testCase.verifyEqual(h.ColorDisplayData, [2 10; 3 11]);

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            CGroupMembers = "y");
         testCase.verifyEqual(displayed(h.YDisplayData), "y");
         testCase.verifyEqual(h.ColorDisplayData, [3 7 11]);
      end

      function testRowSelection(testCase)
         % Set p holds rows 1:6: a-x {1, 3}, a-y {2, 4}, b-x {5}, b-y {6}.

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            RowSelectVar = "Set", RowSelectMembers = "p");

         testCase.verifyEqual(displayed(h.XDisplayData), ["a"; "b"]);
         testCase.verifyEqual(h.ColorDisplayData, [2 5; 3 6]);
      end

      function testMergePoolsTheMemberRows(testCase)
         % "u and w" pools u and w. Column p holds {1 2 9 50}, with mean
         % 62/4. Column q holds eight values that sum to 431, and column r
         % holds eleven that sum to 79. The merged row takes the position
         % of u, its first member.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", MergeGroupMembers = ["u", "w"]);

         testCase.verifyEqual(displayed(h.YDisplayData), ["u and w"; "v"]);
         testCase.verifyEqual(h.ColorDisplayData, ...
            [62/4 431/8 79/11; 18 NaN NaN], 'AbsTol', 1e-12);
      end

      function testMergeReadsOriginalNamesAndOrdersByMergedNames(testCase)
         % CGroupMembers names the original members; CGroupOrder names the
         % merged label.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", CGroupMembers = ["u", "w"], ...
            MergeGroupMembers = ["u", "w"]);
         testCase.verifyEqual(displayed(h.YDisplayData), "u and w");

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", MergeGroupMembers = ["u", "w"], CGroupOrder = "v");
         testCase.verifyEqual(displayed(h.YDisplayData), ["v"; "u and w"]);
      end

      % ---- Ordering

      function testExplicitOrdersMoveTheCellsWithTheirLabels(testCase)
         % A partial order puts the named members first and keeps the rest
         % in category order.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", XGroupOrder = "r", CGroupOrder = ["w", "u"]);

         testCase.verifyEqual(displayed(h.XDisplayData), ["r"; "p"; "q"]);
         testCase.verifyEqual(displayed(h.YDisplayData), ["w"; "u"; "v"]);
         testCase.verifyEqual(h.ColorDisplayData, ...
            testCase.Expected.mean([3 1 2], [3 1 2]), 'AbsTol', 1e-12);
      end

      function testSortByOrdersTheColumnMeans(testCase)
         % The column means over every row, ignoring NaN, are p 24, q
         % 39.4167, and r 11.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", SortBy = "ascend");
         testCase.verifyEqual(displayed(h.XDisplayData), ["r"; "p"; "q"]);

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", SortBy = "descend");
         testCase.verifyEqual(displayed(h.XDisplayData), ["q"; "p"; "r"]);
      end

      function testSortGroupMembersSelectsTheRows(testCase)
         % Row u alone gives p 4, q 10.5, and r 25. Row v alone gives p 18
         % and NaN for q and r, which go last even in a descending sort.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", SortBy = "descend", SortGroupMembers = "u");
         testCase.verifyEqual(displayed(h.XDisplayData), ["r"; "q"; "p"]);

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", SortBy = "descend", SortGroupMembers = "v");
         testCase.verifyEqual(displayed(h.XDisplayData), ["p"; "q"; "r"]);
      end

      function testColorScalingDoesNotChangeTheSort(testCase)
         % Scaled colors are display colors; the sort reads the cell values.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", SortBy = "ascend", ColorScaling = "scaledcolumns");
         testCase.verifyEqual(displayed(h.XDisplayData), ["r"; "p"; "q"]);
      end

      function testXGroupOrderWinsOverSortBy(testCase)
         % An ascending sort would give r, p, q.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", XGroupOrder = "q", SortBy = "ascend");
         testCase.verifyEqual(displayed(h.XDisplayData), ["q"; "p"; "r"]);
      end

      function testOrdinalOrderDropsUnusedCategories(testCase)
         % The ordinal order r, q, p holds; z has no rows and no column.

         tbl = testCase.Data.tbl;
         tbl.Grp = categorical(string(tbl.Grp), ["r", "q", "p", "z"], ...
            'Ordinal', true);

         h = groupstats.groupheatmap(tbl, "Value", "Grp", "Sub");

         testCase.verifyEqual(displayed(h.XDisplayData), ["r"; "q"; "p"]);
         testCase.verifyEqual(h.ColorDisplayData, ...
            testCase.Expected.mean(:, [3 2 1]), 'AbsTol', 1e-12);
      end

      function testTimetableTimeGrouping(testCase)
         % Two times by two subgroups, values 1:8: each cell holds two
         % values two apart.

         time = datetime(2020, 1, [1; 1; 1; 1; 2; 2; 2; 2]);
         sub = categorical(["x"; "y"; "x"; "y"; "x"; "y"; "x"; "y"]);
         tt = timetable(time, sub, (1:8)', ...
            'VariableNames', {'Sub', 'Value'});

         h = groupstats.groupheatmap(tt, "Value", "time", "Sub");

         testCase.verifyNumElements(h.XDisplayData, 2);
         testCase.verifyEqual(h.ColorDisplayData, [2 6; 3 7]);
      end

      % ---- Parent

      function testParentFigureLeavesOtherFiguresAlone(testCase)
         % The chart replaces the axes of the named figure; another figure
         % keeps its children.

         target = figure('Visible', 'off');
         testCase.addTeardown(@close, target);
         axes(target);
         other = figure('Visible', 'off');
         testCase.addTeardown(@close, other);
         plot(axes(other), 1:3);
         before = other.Children;

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            Parent = target);

         testCase.verifySameHandle(h.Parent, target);
         testCase.verifyNumElements(target.Children, 1);
         testCase.verifyEqual(other.Children, before);
         testCase.verifyTrue(all(isvalid(before)));
      end

      function testParentPanel(testCase)
         target = figure('Visible', 'off');
         testCase.addTeardown(@close, target);
         panel = uipanel(target);

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            Parent = panel);

         testCase.verifySameHandle(h.Parent, panel);
      end

      function testParentTiledLayoutWithNexttile(testCase)
         % Each nexttile call picks the tile the next chart replaces.

         target = figure('Visible', 'off');
         testCase.addTeardown(@close, target);
         layout = tiledlayout(target, 1, 2);

         nexttile(layout);
         first = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", ...
            "Sub", Parent = layout);
         nexttile(layout);
         second = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", ...
            "Sub", Parent = layout, Method = "count");

         testCase.verifySameHandle(first.Parent, layout);
         testCase.verifySameHandle(second.Parent, layout);
         testCase.verifyEqual([first.Layout.Tile second.Layout.Tile], [1 2]);
         testCase.verifyEqual(second.ColorDisplayData, repmat(2, 2, 3));
      end

      function testNoParentUsesTheCurrentFigure(testCase)
         % Without Parent the chart replaces the current axes, as heatmap
         % does.

         target = gcf;
         ax = axes(target);

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub");

         testCase.verifySameHandle(h.Parent, target);
         testCase.verifyFalse(isvalid(ax));
      end

      % ---- Properties

      function testPassThroughPropertiesTakeEffect(testCase)
         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            Title = "Value by pairing", CellLabelFormat = "%.1f", ...
            ColorbarVisible = "off", MissingDataColor = [1 0 0]);

         testCase.verifyEqual(string(h.Title), "Value by pairing");
         testCase.verifyEqual(string(h.CellLabelFormat), "%.1f");
         testCase.verifyEqual(string(h.ColorbarVisible), "off");
         testCase.verifyEqual(h.MissingDataColor, [1 0 0]);
      end

      function testInterpreterDefaultsToNoneAndACallerValueWins(testCase)
         % The axis labels are the variable names, as the built-in sets them.

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub");
         testCase.verifyEqual(string(h.Interpreter), "none");
         testCase.verifyEqual(string(h.XLabel), "Grp");
         testCase.verifyEqual(string(h.YLabel), "Sub");

         h = groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
            Interpreter = "tex");
         testCase.verifyEqual(string(h.Interpreter), "tex");
      end

      % ---- Errors and products

      function testDataPropertyErrorsNameTheInput(testCase, dataprop)
         % The test reads a value of the right type from a reference
         % heatmap. The arguments block accepts it, so groupheatmap itself
         % must reject it.

         reference = heatmap(figure('Visible', 'off'), testCase.Tbl, ...
            "Grp", "Sub", 'ColorVariable', "Value");
         testCase.addTeardown(@close, ancestor(reference, 'figure'));
         value = reference.(dataprop);

         owner = struct(SourceTable = "tbl", XVariable = "xgroupvar", ...
            YVariable = "cgroupvar", ColorVariable = "ydatavar", ...
            ColorMethod = "Method", XData = "XGroupMembers", ...
            YData = "CGroupMembers", ColorData = "Method", ...
            XDisplayData = "XGroupOrder", YDisplayData = "CGroupOrder");

         try
            groupstats.groupheatmap(testCase.Tbl, "Value", "Grp", "Sub", ...
               dataprop, value);
            testCase.verifyFail("No error for " + dataprop + ".");
         catch e
            testCase.verifyEqual(e.identifier, ...
               'groupstats:groupheatmap:dataProperty');
            testCase.verifySubstring(e.message, owner.(dataprop));
         end
      end

      function testNonNumericDataErrorsAndLeavesNoChart(testCase)
         tbl = testCase.Tbl;
         tbl.Value = string(tbl.Value);
         target = gcf;
         ax = axes(target);

         testCase.verifyError(@() groupstats.groupheatmap(tbl, "Value", ...
            "Grp", "Sub"), 'groupstats:groupheatmap:nonNumericData');

         testCase.verifyTrue(isvalid(ax));
         testCase.verifyEmpty(findall(groot, 'Type', 'heatmap'));
      end

      function testUnknownMethodFailsValidation(testCase)
         testCase.verifyError(@() groupstats.groupheatmap(testCase.Tbl, ...
            "Value", "Grp", "Sub", Method = "mode"), ...
            'MATLAB:validators:mustBeMember');
      end

      function testUnknownOrderMemberErrors(testCase)
         testCase.verifyError(@() groupstats.groupheatmap(testCase.Tbl, ...
            "Value", "Grp", "Sub", XGroupOrder = "zz"), ...
            'groupstats:groupheatmap:badXGroupOrder');
         testCase.verifyError(@() groupstats.groupheatmap(testCase.Tbl, ...
            "Value", "Grp", "Sub", SortBy = "ascend", ...
            SortGroupMembers = "zz"), ...
            'groupstats:validatemember:notAMember');
      end

      function testNeedsOnlyMatlab(testCase)
         [~, products] = matlab.codetools.requiredFilesAndProducts( ...
            which('groupstats.groupheatmap'));

         returned = string({products.Name});
         expected = "MATLAB";
         testCase.verifyEqual(returned, expected);
      end

      % ---- Readability (groupstats-ctg.6)

      function testFontSizeFollowsTheAxesFont(testCase)
         % HeatmapChart keeps its own font size of 12 otherwise. The chart
         % takes the parent figure's axes font, and a caller value wins.

         f = figure('Visible', 'off', 'DefaultAxesFontSize', 21);
         testCase.addTeardown(@() close(f));
         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", Parent = f);
         testCase.verifyEqual(h.FontSize, 21);

         g = figure('Visible', 'off', 'DefaultAxesFontSize', 21);
         testCase.addTeardown(@() close(g));
         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", Parent = g, FontSize = 9);
         testCase.verifyEqual(h.FontSize, 9);
      end

      function testDefaultTitleNamesTheMappedQuantity(testCase)
         % The title says which statistic of which variable the colors
         % map, from the table's description and units when set.

         tbl = testCase.Data.tbl;
         tbl.Properties.VariableDescriptions{'Value'} = 'value of things';
         tbl.Properties.VariableUnits{'Value'} = 'kg';

         h = groupstats.groupheatmap(tbl, "Value", "Grp", "Sub", ...
            Method = "median");

         testCase.verifyEqual(string(h.Title), ...
            "Median of value of things (kg)");
      end

      function testCountUsesADiscreteColormap(testCase)
         % The fixture counts run from 0 to 7: eight levels, one color
         % each, with each level centered on its color.

         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", Method = "count");

         testCase.verifyEqual(size(h.Colormap, 1), 8);
         testCase.verifyEqual(h.ColorLimits, [-0.5 7.5]);
      end

      function testCallerColormapWinsForCount(testCase)
         % A caller colormap is kept as given.

         cmap = gray(4);
         h = groupstats.groupheatmap(testCase.Data.tbl, "Value", "Grp", ...
            "Sub", Method = "count", Colormap = cmap);

         testCase.verifyEqual(h.Colormap, cmap);
      end

   end
end

function names = displayed(labels)
   %DISPLAYED Display data as a string column, for comparison.

   names = reshape(string(labels), [], 1);
end
