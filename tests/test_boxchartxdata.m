classdef test_boxchartxdata < matlab.unittest.TestCase
   %TEST_BOXCHARTXDATA Test groupstats.boxchartxdata.
   %
   % boxchartxdata reads the x coordinates boxchart drew from the chart
   % handle. These cases pin the layout of its outputs: one row per color
   % group and one column per x-tick, NaN where a group has no box, bounds
   % that bracket the centers, and the same centers whether the boxes are
   % notched or plain.
   %
   % Every case plots into an invisible figure, so the suite runs headless.
   %
   % See also: groupstats.boxchartxdata, groupstats.boxchartydata

   properties
      Tbl
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         %LOADTESTDATA Open an invisible figure and load the shared table.

         % boxchartxdata reads a drawn chart, so every case draws one with
         % boxchartcats first. The same fixture table the chart tests use
         % gives the cases a known grid of x-groups and color groups.
         testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure);
         data = groupstats.test.generateTestData('groupsummary');
         testCase.Tbl = data.tbl;
      end
   end

   methods (Test)

      function testBoxchartxdataKeepsNaNForATickAGroupDoesNotReach(testCase)
         % One column per tick up to the highest tick any group reaches. A
         % group whose boxes stop before that tick keeps NaN in the later
         % columns; sizing by a group's box count would grow the matrix
         % with zeros instead.

         xg = categorical(["p"; "p"; "q"; "q"; "r"; "r"]);
         cg = categorical(["a"; "a"; "a"; "a"; "b"; "b"]);
         tbl = table(xg, cg, [1; 2; 3; 4; 5; 6], ...
            'VariableNames', {'xg', 'cg', 'val'});

         H = groupstats.boxchartcats(tbl, "val", "xg", "cg", ...
            PlotMeans = false, ShadeGroups = false);
         [xlocs, xleft, xright] = groupstats.boxchartxdata(H);

         returned = size(xlocs);
         expected = [2 3];
         testCase.verifyEqual(returned, expected);

         returned = isnan(xlocs);
         expected = [false false true; true true false];
         testCase.verifyEqual(returned, expected);

         % The bounds share the tick columns: the left bound comes from
         % the first group, which reaches ticks 1 and 2, and the right
         % bound from the last group, which reaches tick 3 only.
         returned = [isnan(xleft); isnan(xright)];
         expected = [false false true; true true false];
         testCase.verifyEqual(returned, expected);
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

         returned = all(xleft(:)' <= min(xlocs, [], 1)) ...
            && all(xright(:)' >= max(xlocs, [], 1));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testNotchedAndPlainBoxesGiveTheSameCenters(testCase)
         % A notched box has 8 vertices and a plain one 4. The vertex count
         % chooses the stride, and either stride must give the same centers.

         notched = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            "Sub", Notch = "on", PlotMeans = false, ShadeGroups = false);
         xnotched = groupstats.boxchartxdata(notched);
         clf

         plain = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            "Sub", Notch = "off", PlotMeans = false, ShadeGroups = false);
         xplain = groupstats.boxchartxdata(plain);

         returned = xplain;
         expected = xnotched;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);
      end

      function testOneColorGroupSetsBothBounds(testCase)
         % With one color group the first group is also the last, so the
         % right bound comes from the same boxes as the left bound.

         H = groupstats.boxchartcats(testCase.Tbl, "Value", "Grp", ...
            PlotMeans = false, ShadeGroups = false);

         [xlocs, xleft, xright] = groupstats.boxchartxdata(H);

         returned = [any(isnan(xleft)); any(isnan(xright))];
         expected = [false; false];
         testCase.verifyEqual(returned, expected);

         returned = xleft < xlocs & xlocs < xright;
         expected = true(size(xlocs));
         testCase.verifyEqual(returned, expected);
      end
   end
end
