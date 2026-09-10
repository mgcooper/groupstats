classdef test_demos < matlab.unittest.TestCase
   %TEST_DEMOS Run every demo headless through demo_all.
   %
   % The demos are the toolbox's worked examples. demo_all runs its roster
   % in order, so a demo that errors, or that raises a warning, fails here,
   % and a demo file the roster does not name is reported too.
   %
   % See also: demo_all

   methods (TestMethodSetup)

      function makeFiguresInvisible(testCase)
         % demo_all("-close") closes every figure it opens, so a figure
         % fixture would lose its handle. The visibility default keeps the
         % run headless instead, and is put back at teardown.
         saved = get(groot, "DefaultFigureVisible");
         testCase.addTeardown(@() set(groot, "DefaultFigureVisible", saved));
         set(groot, "DefaultFigureVisible", "off")

         % The demos are scripts in examples/, which buildtool test does not
         % add to the path, so the fixture makes demo_all and the scripts
         % callable for the test and removes them afterwards.
         examples = fullfile(groupstats.internal.buildpath(), "examples");
         testCase.applyFixture( ...
            matlab.unittest.fixtures.PathFixture(examples));
      end
   end

   methods (Test)

      function testDemoAllRunsEveryDemoWithoutAWarning(testCase)
         % The demos print tables and open figures; none may warn.

         testCase.verifyWarningFree(@() evalc('demo_all("-close")'));
      end

      function testRosterNamesEveryDemoFile(testCase)
         % Every demo_*.m file in examples/, other than demo_all itself,
         % must be in the roster. demo_all skips an unlisted file and
         % reports nothing.

         examples = fullfile(groupstats.internal.buildpath(), "examples");
         files = dir(fullfile(examples, "demo_*.m"));
         names = string(erase({files.name}, ".m"));
         names = names(names ~= "demo_all");

         % The roster is the demos array in demo_all.m. Reading it from
         % the file takes no time; the other case runs the demos.
         source = fileread(fullfile(examples, "demo_all.m"));
         block = regexp(source, 'demos = \[(.*?)\];', 'tokens', 'once');
         tokens = regexp(block{1}, '"(demo_\w+)"', 'tokens');
         listed = cellfun(@(t) string(t{1}), tokens);

         returned = sort(listed(:));
         expected = sort(names(:));
         testCase.verifyEqual(returned, expected);
      end
   end
end
