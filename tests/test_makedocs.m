classdef test_makedocs < matlab.unittest.TestCase
   %TEST_MAKEDOCS Test groupstats.internal.makedocs.
   %
   % makedocs builds the Help browser pages. These cases build each part into
   % a scratch folder and check the files the part names, so the shipped
   % toolbox/docs/html is never written. The "functions" part needs m2html;
   % its case is filtered when the GROUPSTATS_M2HTML environment variable
   % does not name the m2html folder.
   %
   % See also: groupstats.internal.makedocs

   properties
      % The scratch output folder, one per test.
      OutputFolder
   end

   methods (TestMethodSetup)

      function makeScratch(testCase)
         testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure);
         folder = testCase.applyFixture( ...
            matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
         testCase.OutputFolder = fullfile(folder, "html");
      end
   end

   methods (Test)

      function testDocpagesPublishesEveryDocsSource(testCase)
         % One page per groupstats_*.m source in toolbox/docs/, and a page
         % whose source no longer exists is removed.

         plantStalePage(testCase.OutputFolder, "groupstats_gone.html")
         groupstats.internal.makedocs(Parts = "docpages", ...
            OutputFolder = testCase.OutputFolder);

         sources = dir(fullfile(groupstats.internal.buildpath(), ...
            'docs', 'groupstats_*.m'));
         expected = sort(string(erase({sources.name}, ".m")) + ".html");
         pages = dir(fullfile(testCase.OutputFolder, 'groupstats_*.html'));
         returned = sort(string({pages.name}));
         testCase.verifyEqual(returned, expected);
         testCase.verifyGreaterThan(numel(returned), 0);
      end

      function testDemosPublishesTheNamedDemoAndTheLiveScripts(testCase)
         % One page per named demo, and one per live script. One demo
         % stands for the loop: publishing every demo with its figures
         % takes minutes, and the docs task does that for real. The
         % plain-text live scripts export from R2025a, as the docs task
         % needs.

         testCase.assumeFalse(isMATLABReleaseOlderThan("R2025a"), ...
            "export reads plain-text live scripts from R2025a.");

         % A page for a demo file that is gone, and a numbered figure the
         % demo no longer draws, are stale outputs the build must remove.
         plantStalePage(testCase.OutputFolder, "demo_gone.html")
         plantStalePage(testCase.OutputFolder, "demo_gone_01.png")
         plantStalePage(testCase.OutputFolder, "demo_groupmap_99.png")
         groupstats.internal.makedocs(Parts = "demos", ...
            Demos = "demo_groupmap", OutputFolder = testCase.OutputFolder);

         expected = sort(["demo_groupmap.html", "gettingStarted.html", ...
            "usingGroupStats.html"]);
         pages = dir(fullfile(testCase.OutputFolder, '*.html'));
         returned = sort(string({pages.name}));
         testCase.verifyEqual(returned, expected);
         stale = dir(fullfile(testCase.OutputFolder, '*gone*'));
         testCase.verifyEmpty(stale);
         testCase.verifyFalse(isfile(fullfile(testCase.OutputFolder, ...
            "demo_groupmap_99.png")));
      end

      function testDemosNeedR2025aAndSaySo(testCase)
         % Before R2025a the demos part stops with its reason before it
         % writes a page. Filtered on R2025a and later, where it runs.

         testCase.assumeTrue(isMATLABReleaseOlderThan("R2025a"), ...
            "the guard fires before R2025a only.");

         testCase.verifyError(@() groupstats.internal.makedocs( ...
            Parts = "demos", Demos = "demo_groupmap", ...
            OutputFolder = testCase.OutputFolder), ...
            'groupstats:makedocs:needsR2025a');
         testCase.verifyEmpty(dir(fullfile(testCase.OutputFolder, '*.html')));
      end

      function testDemosWritesWhitePngsNotBlack(testCase)
         testCase.assumeFalse(isMATLABReleaseOlderThan("R2025a"), ...
            "export reads plain-text live scripts from R2025a.");
         % publish captures a figure as a PNG through the hardcopy
         % renderer, which resolves the GraphicsTheme setting on its own,
         % separate from the figure's own white Color; in a headless
         % session with GraphicsTheme at its default "auto" that renderer
         % wrote a black PNG until makedocs forced the setting to "light"
         % for the run. demo_groupmap draws no figure, so this uses
         % demo_groupcompare, whose bootstrap section draws one.

         groupstats.internal.makedocs(Parts = "demos", ...
            Demos = "demo_groupcompare", OutputFolder = testCase.OutputFolder);

         pages = dir(fullfile(testCase.OutputFolder, ...
            'demo_groupcompare_*.png'));
         testCase.verifyGreaterThan(numel(pages), 0);
         img = imread(fullfile(pages(1).folder, pages(1).name));
         returned = reshape(img(1, 1, :), 1, []);
         expected = uint8([255 255 255]);
         testCase.verifyEqual(returned, expected);
      end

      function testDemosPngsAreScaledForSharpness(testCase)
         testCase.assumeFalse(isMATLABReleaseOlderThan("R2025a"), ...
            "export reads plain-text live scripts from R2025a.");
         % A headless session's ScreenPixelsPerInch is fixed and
         % read-only, so a captured figure's glyph and line detail
         % cannot be raised by dpi alone; makedocs instead scales the
         % figure Position and the point-based font and line size
         % defaults together by FIGURESCALE = 2 for the run (see the
         % comment above pubopts in makedocs.m). Measured before that
         % change: demo_groupcompare's PNG was 704 px wide. 1200 sits
         % comfortably above that and below the scaled ~1400 px, so this
         % catches the scaling being dropped without pinning an exact
         % pixel count that print's rounding could shift by one.

         groupstats.internal.makedocs(Parts = "demos", ...
            Demos = "demo_groupcompare", OutputFolder = testCase.OutputFolder);

         pages = dir(fullfile(testCase.OutputFolder, ...
            'demo_groupcompare_*.png'));
         testCase.verifyGreaterThan(numel(pages), 0);
         info = imfinfo(fullfile(pages(1).folder, pages(1).name));
         returned = info.Width;
         expected = 1200;
         testCase.verifyGreaterThanOrEqual(returned, expected);
      end

      function testDemolistDefaultsToEveryDemoFile(testCase)
         % The default list is every demo file other than demo_all; a
         % name list selects those files; an unknown name selects nothing.

         examples = fullfile(groupstats.internal.buildpath(), 'examples');
         demos = dir(fullfile(examples, 'demo_*.m'));
         demos = demos(~strcmp({demos.name}, 'demo_all.m'));
         expected = string(fullfile({demos.folder}, {demos.name}))';

         returned = groupstats.internal.demolist();
         testCase.verifyEqual(returned, expected);

         returned = groupstats.internal.demolist(["demo_groupmap", "nope"]);
         expected = string(fullfile(examples, "demo_groupmap.m"));
         testCase.verifyEqual(returned, expected);

         returned = groupstats.internal.demolist("nope");
         testCase.verifyEqual(returned, strings(0, 1));
      end

      function testFunctionsBuildsOnePagePerPublicFunction(testCase)
         % m2html writes function_index.html and one page per file in the
         % namespace folder, and the shipped template is the one used.

         m2htmlfolder = string(getenv("GROUPSTATS_M2HTML"));
         testCase.assumeTrue(strlength(m2htmlfolder) > 0 && ...
            isfile(fullfile(m2htmlfolder, "m2html.m")), ...
            "GROUPSTATS_M2HTML does not name the m2html folder.");

         % m2html mirrors the source folder, so the pages sit under
         % m2html/+groupstats/, where docpath searches. A page for a
         % function that is gone is stale and must be removed.
         m2htmlpath = fullfile(testCase.OutputFolder, 'm2html');
         plantStalePage(fullfile(m2htmlpath, '+groupstats'), "gone.html")
         groupstats.internal.makedocs(Parts = "functions", ...
            OutputFolder = testCase.OutputFolder);

         publicfiles = dir(fullfile(groupstats.internal.buildpath(), ...
            '+groupstats', '*.m'));
         expected = sort(string(erase({publicfiles.name}, ".m")) + ".html");
         pages = dir(fullfile(m2htmlpath, '+groupstats', '*.html'));
         returned = sort(string({pages.name}));
         % m2html writes a per-folder index beside the pages too.
         returned = returned(returned ~= "function_index.html");
         testCase.verifyEqual(returned, expected);
         testCase.verifyTrue(isfile(fullfile(m2htmlpath, ...
            'function_index.html')));
         testCase.verifyTrue(isfile(fullfile(m2htmlfolder, 'templates', ...
            'blue2_groupstats', 'master.tpl')));
      end

      function testThePathIsRestoredAfterTheBuild(testCase)
         % The sources and m2html join the path for the run only, so a
         % later dependency scan in the same session sees nothing new.

         before = path;
         groupstats.internal.makedocs(Parts = "docpages", ...
            OutputFolder = testCase.OutputFolder);

         returned = path;
         expected = before;
         testCase.verifyEqual(returned, expected);
      end

      function testDocsearchIndexesTheHelpFolder(testCase)
         % builddocsearchdb indexes only the help_location of a registered
         % product, which is the shipped toolbox/docs/html and no scratch
         % folder, so this case builds there and puts the previous database
         % back afterwards, leaving the working tree as it was.

         htmlpath = fullfile(groupstats.internal.buildpath(), 'docs', 'html');
         previous = dir(fullfile(htmlpath, 'helpsearch*'));
         keep = fullfile(testCase.OutputFolder, 'previous');
         mkdir(keep)
         for n = 1:numel(previous)
            copyfile(fullfile(htmlpath, previous(n).name), ...
               fullfile(keep, previous(n).name));
         end
         testCase.addTeardown(@() restoreDatabase(htmlpath, keep, previous));

         groupstats.internal.makedocs(Parts = "docsearch");

         index = dir(fullfile(htmlpath, 'helpsearch*'));
         testCase.verifyEqual(numel(index), 1);
         testCase.verifyTrue(index.isdir);
      end

      function testMissingM2htmlIsReported(testCase)
         % An environment variable that names a folder without m2html.m is
         % as good as none: the functions part names the three ways to fix
         % it. The variable is read before the path, so the path state does
         % not matter here.

         testCase.applyFixture( ...
            matlab.unittest.fixtures.EnvironmentVariableFixture( ...
            "GROUPSTATS_M2HTML", testCase.OutputFolder));

         testCase.verifyError(@() groupstats.internal.makedocs( ...
            Parts = "functions", OutputFolder = testCase.OutputFolder), ...
            'groupstats:makedocs:m2htmlNotFound');
      end

      function testAGivenM2htmlPathWins(testCase)
         % M2htmlPath given as an argument is read before the environment,
         % which here names a folder without m2html.m.

         m2htmlfolder = string(getenv("GROUPSTATS_M2HTML"));
         testCase.assumeTrue(strlength(m2htmlfolder) > 0 && ...
            isfile(fullfile(m2htmlfolder, "m2html.m")), ...
            "GROUPSTATS_M2HTML does not name the m2html folder.");
         testCase.applyFixture( ...
            matlab.unittest.fixtures.EnvironmentVariableFixture( ...
            "GROUPSTATS_M2HTML", testCase.OutputFolder));

         groupstats.internal.makedocs(Parts = "functions", ...
            OutputFolder = testCase.OutputFolder, M2htmlPath = m2htmlfolder);

         testCase.verifyTrue(isfile(fullfile(testCase.OutputFolder, ...
            'm2html', 'function_index.html')));
      end

      function testM2htmlOnThePathIsFoundWithoutTheVariable(testCase)
         % With no argument and an empty environment variable, m2html on
         % the path is the last resort.

         m2htmlfolder = string(getenv("GROUPSTATS_M2HTML"));
         testCase.assumeTrue(strlength(m2htmlfolder) > 0 && ...
            isfile(fullfile(m2htmlfolder, "m2html.m")), ...
            "GROUPSTATS_M2HTML does not name the m2html folder.");
         testCase.addTeardown(@() setenv("GROUPSTATS_M2HTML", m2htmlfolder));
         setenv("GROUPSTATS_M2HTML", "")
         testCase.applyFixture( ...
            matlab.unittest.fixtures.PathFixture(m2htmlfolder));

         groupstats.internal.makedocs(Parts = "functions", ...
            OutputFolder = testCase.OutputFolder);

         testCase.verifyTrue(isfile(fullfile(testCase.OutputFolder, ...
            'm2html', 'function_index.html')));
      end

      function testAGivenM2htmlPathWithoutTheFileIsReported(testCase)
         % A folder that holds no m2html.m is as good as none.

         testCase.verifyError(@() groupstats.internal.makedocs( ...
            Parts = "functions", OutputFolder = testCase.OutputFolder, ...
            M2htmlPath = testCase.OutputFolder), ...
            'groupstats:makedocs:m2htmlNotFound');
      end

      function testAMissingTemplateIsReported(testCase)
         % A Template name with no folder under docs/templates/m2html fails
         % before m2html runs.

         m2htmlfolder = string(getenv("GROUPSTATS_M2HTML"));
         testCase.assumeTrue(strlength(m2htmlfolder) > 0 && ...
            isfile(fullfile(m2htmlfolder, "m2html.m")), ...
            "GROUPSTATS_M2HTML does not name the m2html folder.");

         testCase.verifyError(@() groupstats.internal.makedocs( ...
            Parts = "functions", OutputFolder = testCase.OutputFolder, ...
            Template = "nosuchtemplate"), ...
            'groupstats:makedocs:templateNotFound');
      end

      function testARelativeOutputFolderIsMadeAbsolute(testCase)
         % publish and m2html change folder while they run, so a relative
         % output folder is resolved first and the pages land in it.

         parent = fileparts(testCase.OutputFolder);
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(parent)

         groupstats.internal.makedocs(Parts = "docpages", ...
            OutputFolder = "html");

         pages = dir(fullfile(testCase.OutputFolder, 'groupstats_*.html'));
         testCase.verifyGreaterThan(numel(pages), 0);
      end
   end
end

function restoreDatabase(htmlpath, keep, previous)
   %RESTOREDATABASE Put the search database that was there before back.

   current = dir(fullfile(htmlpath, 'helpsearch*'));
   for n = 1:numel(current)
      rmdir(fullfile(htmlpath, current(n).name), 's')
   end
   for n = 1:numel(previous)
      copyfile(fullfile(keep, previous(n).name), ...
         fullfile(htmlpath, previous(n).name));
   end
end

function plantStalePage(folder, name)
   %PLANTSTALEPAGE Write an empty output file that no source produces.
   %
   % The build must remove it, so a test writes it before the build and
   % checks for it after. The folder is created when it does not exist.

   if ~isfolder(folder)
      mkdir(folder)
   end
   fid = fopen(fullfile(folder, name), 'w');
   fclose(fid);
end
