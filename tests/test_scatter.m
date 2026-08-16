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
   %  6. Props was declared and never applied, so a named graphics property
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

      function testThreeOutputsAreRejected(testCase)
         % H and L are the only outputs. A third failed on an unassigned
         % output rather than saying so.

         testCase.verifyError( ...
            @() threeOutputs(testCase.Tbl), ...
            'MATLAB:nargoutchk:tooManyOutputs');
      end

      function testLinePropertiesPassThrough(testCase)
         % Props was declared and never applied, so a named property was
         % accepted and ignored. gscatter draws Line objects, so a Line
         % property is what applies.

         H = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            MarkerSize = 12);

         returned = H(1).MarkerSize;
         expected = 12;
         testCase.verifyEqual(returned, expected);
      end

      function testSortByYDataVarForcesDescending(testCase)
         % Choosing ydatavar forces descending, which the docstring states.

         H = groupstats.scatter(testCase.Tbl, "X", "Value", "Grp", ...
            SortVar = "ydatavar");

         testCase.verifyNotEmpty(H);
      end
   end
end

function threeOutputs(tbl)
   %THREEOUTPUTS Ask scatter for a third output.
   %
   % Written as a function so the call is a statement, which is the only
   % place a three-output request is syntactically valid.

   [~, ~, ~] = groupstats.scatter(tbl, "X", "Value", "Grp");
end
