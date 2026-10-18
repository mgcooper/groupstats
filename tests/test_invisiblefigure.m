classdef test_invisiblefigure < matlab.unittest.TestCase
   %TEST_INVISIBLEFIGURE Test the InvisibleFigure fixture.
   %
   % Chart tests compare drawn colors with defaultcolors, whose first seven
   % rows come from the root defaultAxesColorOrder value. From R2025a that
   % value follows the graphics theme. An R2025b batch session can change
   % the theme about one second after graphics start. The fixture holds the
   % value for the test, so a palette read and a chart's own read agree, and
   % it puts back the state it found.
   %
   % See also: groupstats.test.fixtures.InvisibleFigure

   methods (Test)

      function testPaletteHoldsAcrossAThemeChange(testCase)
         % Force the theme change between the palette read and the chart
         % call. The chart must still draw the palette the test read.

         testCase.assumeFalse(isMATLABReleaseOlderThan("R2025a"), ...
            "Graphics themes arrive in R2025a.");

         % Start from the light theme, and put back the temporary value
         % this test found when it ends.
         graphicstheme = settings().matlab.appearance.figure.GraphicsTheme;
         testCase.addTeardown(@restoreTemporaryValue, graphicstheme, ...
            graphicstheme.hasTemporaryValue, temporaryValue(graphicstheme));
         graphicstheme.TemporaryValue = "light";
         lightorder = get(groot, 'factoryAxesColorOrder');

         testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure);
         defaultcolors = groupstats.internal.privatefunction( ...
            'defaultcolors');
         palette = defaultcolors();

         % The change must reach the root color order, or this test checks
         % nothing.
         graphicstheme.TemporaryValue = "dark";
         testCase.assertNotEqual(get(groot, 'factoryAxesColorOrder'), ...
            lightorder, 'The forced theme change kept the color order.');

         % The table holds three color groups, one bar each.
         cg = categorical(["a"; "b"; "c"]);
         tbl = table(categorical(repmat("x", 3, 1)), cg, [1; 2; 3], ...
            'VariableNames', {'xg', 'cg', 'y'});
         H = groupstats.barchartcats(tbl, "y", "xg", "cg");

         returned = vertcat(H.FaceColor);
         expected = palette(1:3, :);
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testTeardownLeavesAnUnsetColorOrderUnset(testCase)
         % A root default that no code set stays unset after the test.

         testCase.assumeFalse(isfield(get(groot, 'default'), ...
            'defaultAxesColorOrder'), 'A root default is already set.');

         applyAndTearDown()

         returned = isfield(get(groot, 'default'), 'defaultAxesColorOrder');
         testCase.verifyFalse(returned);
      end

      function testTeardownRestoresASetColorOrder(testCase)
         % A root default that code set comes back with its own value.

         original = get(groot, 'default');
         testCase.addTeardown(@restoreColorOrder, original);
         expected = [1 0 0; 0 1 0; 0 0 1];
         set(groot, 'defaultAxesColorOrder', expected)

         applyAndTearDown()

         returned = get(groot, 'defaultAxesColorOrder');
         testCase.verifyEqual(returned, expected);
      end
   end
end

function applyAndTearDown()
   %APPLYANDTEARDOWN Set up the fixture outside the framework, then end it.
   %
   % A running test cannot apply a fixture to a second test case. Deleting
   % the fixture object runs every teardown its setup registered.

   fixture = groupstats.test.fixtures.InvisibleFigure;
   fixture.setup();
   delete(fixture)
end

function value = temporaryValue(setting)
   %TEMPORARYVALUE Return a setting's temporary value, or "" when it has none.

   value = "";
   if setting.hasTemporaryValue
      value = setting.TemporaryValue;
   end
end

function restoreTemporaryValue(setting, hadvalue, value)
   %RESTORETEMPORARYVALUE Put a setting's temporary value back as it was.

   if hadvalue
      setting.TemporaryValue = value;
   elseif setting.hasTemporaryValue
      setting.clearTemporaryValue();
   end
end

function restoreColorOrder(original)
   %RESTORECOLORORDER Put the root defaultAxesColorOrder value back.
   %
   % ORIGINAL is the struct get(groot, 'default') returned. A default it
   % does not hold was unset, so remove it.

   if isfield(original, 'defaultAxesColorOrder')
      set(groot, 'defaultAxesColorOrder', original.defaultAxesColorOrder)
   else
      set(groot, 'defaultAxesColorOrder', 'remove')
   end
end
