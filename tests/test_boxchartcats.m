classdef test_boxchartcats < matlab.unittest.TestCase
   %TEST_BOXCHARTCATS Test groupstats.boxchartcats and boxchartxdata.
   %
   % These cases pin the defects the audit named:
   %
   %  1. LegendOrientation was declared and never read; the legend was always
   %     horizontal.
   %  2. CGroupOrder was declared and never read. It is implemented, and
   %     covered below.
   %  3. The XGroupOrder="none" branch was a commented-out no-op, so no
   %     sorting was possible.
   %
   % boxchartxdata is covered here because it reads a live boxchart handle.
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
            "Sub", LegendOrientation = "vertical");

         returned = string(L.Orientation);
         expected = "vertical";
         testCase.verifyEqual(returned, expected);
      end

      function testLegendOrientationDefaultsToHorizontal(testCase)
         % The documented default.

         [~, L] = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            "Sub");

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

      function testBoxchartxdataReturnsOneRowPerColorGroup(testCase)
         % boxchartxdata reads the x location of every box from the handle.
         % The rows are the color groups and the columns are the x ticks.

         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         xlocs = groupstats.boxchartxdata(H);

         returned = size(xlocs, 1);
         expected = numel(H);
         testCase.verifyEqual(returned, expected);
      end

      function testBoxchartxdataBoundsBracketTheCenters(testCase)
         % The left and right bounds of each x-tick group sit either side of
         % the box centers in that group.

         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", "Sub");

         [xlocs, xleft, xright] = groupstats.boxchartxdata(H);

         testCase.verifyLessThanOrEqual(xleft(:)', min(xlocs, [], 1));
         testCase.verifyGreaterThanOrEqual(xright(:)', max(xlocs, [], 1));
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
