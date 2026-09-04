classdef test_buildfile < matlab.unittest.TestCase
   %TEST_BUILDFILE Test what the release task packages.
   %
   % releaseTask reads the Package Toolbox task held in the MATLAB Project.
   % That task carries the identifier, the author fields, the file list, and
   % the exclusions in toolbox/toolbox.ignore, so these cases read the same
   % ToolboxOptions the task builds and check what it would ship.
   %
   % Reading the options does not write anything. None of these cases
   % packages a toolbox.
   %
   % Every case is filtered before R2025a, where the Package Toolbox task
   % does not exist.
   %
   % See also: buildfile

   properties
      % The options releaseTask packages, read once per case.
      Opts

      % Repository root, derived from this file rather than from pwd, so the
      % suite runs from any folder.
      Root
   end

   methods (TestClassSetup)

      function readPackagingOptions(testCase)
         testCase.Root = fileparts(fileparts(mfilename('fullpath')));

         % The Package Toolbox task arrived in R2025a. An older release reads
         % GroupStats.prj and raises NotValidToolboxPRJ, so these cases are
         % filtered there rather than failed. The toolbox itself still runs
         % on the older release; only the maintainer's release step needs
         % R2025a.
         testCase.assumeFalse(isMATLABReleaseOlderThan("R2025a"), ...
            'Packaging through the MATLAB Project task needs R2025a.');

         prjfile = fullfile(testCase.Root, 'GroupStats.prj');
         testCase.assumeTrue(isfile(prjfile), ...
            'GroupStats.prj is missing, so there is no packaging task to read.');

         % ToolboxOptions opens the MATLAB Project, and a Project manages the
         % search path. Reading the options here therefore rewrites the path
         % for whatever runs next, which stopped later classes from resolving
         % groupstats.test.generateTestData. Put the path back, and close the
         % Project, before leaving this class.
         saved = path();
         testCase.addTeardown(@() path(saved));
         testCase.addTeardown(@() closeProjectQuietly(prjfile));

         % Read what the release task reads. Calling ToolboxOptions here
         % instead would test a copy of releaseTask rather than releaseTask.
         addpath(fullfile(testCase.Root, 'toolbox'));
         testCase.Opts = groupstats.internal.releaseoptions(testCase.Root);
      end
   end

   methods (Test)

      function testIdentifierIsTheToolboxsOwn(testCase)
         % MATLAB recognizes an installed toolbox by its identifier. A new
         % one makes an install add a second copy rather than upgrade in
         % place, and creating the R2025a task mints a fresh identifier, so
         % this pins the value the toolbox has always shipped.

         returned = string(testCase.Opts.Identifier);
         expected = "2e9607fe-5940-442b-ac19-ff08682094e5";
         testCase.verifyEqual(returned, expected);
      end

      function testEveryPackagedFileExists(testCase)
         % A packaged entry that is not on disk fails the release late, at
         % the packaging step, rather than here.

         files = string(testCase.Opts.ToolboxFiles);
         returned = files(~isfile(files) & ~isfolder(files));
         expected = strings(0, 1);
         testCase.verifyEqual(returned(:), expected);
      end

      function testEveryPackagedFileIsInsideTheToolboxFolder(testCase)
         % Packaging a file from outside toolbox/ would ship repository
         % scaffolding to an installing user.

         toolboxfolder = fullfile(testCase.Root, 'toolbox');
         files = string(testCase.Opts.ToolboxFiles);

         returned = files(~startsWith(files, toolboxfolder));
         expected = strings(0, 1);
         testCase.verifyEqual(returned(:), expected);
      end

      function testEveryToolboxFileIsPackagedOrIgnored(testCase)
         % The reverse direction. A file added under toolbox/ and never
         % packaged is missing from the release with nothing to announce it.
         % toolbox/info.xml was found this way.

         toolboxfolder = fullfile(testCase.Root, 'toolbox');
         ondisk = dir(fullfile(toolboxfolder, '**', '*'));
         ondisk = ondisk(~[ondisk.isdir]);
         ondisk = string(fullfile({ondisk.folder}, {ondisk.name}))';

         packaged = string(testCase.Opts.ToolboxFiles);

         % toolbox.ignore lists what the release leaves out. Its own header
         % states that the file is always excluded from the toolbox.
         ignored = testCase.ignoredFiles(toolboxfolder);
         ignored = [ignored; string(fullfile(toolboxfolder, 'toolbox.ignore'))];

         returned = setdiff(ondisk, [packaged; ignored]);
         expected = strings(0, 1);
         testCase.verifyEqual(returned(:), expected);
      end

      function testFolderMetadataIsNotPackaged(testCase)
         % macOS writes .DS_Store into any folder it displays. The rule that
         % drops them only takes effect when toolbox.ignore sits inside the
         % toolbox folder, so a copy at the repository root ships them.
         %
         % Write one first. A clean checkout holds none, so reading the
         % options as they are counts zero whether the rule works or not.

         seeded = fullfile(testCase.Root, 'toolbox', '.DS_Store');
         existed = isfile(seeded);
         if ~existed
            writelines("seeded by test_buildfile", seeded);
            testCase.addTeardown(@delete, seeded);
         end

         opts = groupstats.internal.releaseoptions(testCase.Root);
         files = string(opts.ToolboxFiles);

         testCase.assertTrue(isfile(seeded), ...
            'The fixture must exist for this check to mean anything.');

         returned = nnz(contains(files, ".DS_Store"));
         expected = 0;
         testCase.verifyEqual(returned, expected);
      end

      function testRepositoryScaffoldingIsNotPackaged(testCase)
         % Source control data, packaging projects, and built releases have
         % no use to an installing user.

         files = string(testCase.Opts.ToolboxFiles);

         returned = nnz(endsWith(files, ".mltbx") | endsWith(files, ".prj") ...
            | contains(files, filesep + ".git"));
         expected = 0;
         testCase.verifyEqual(returned, expected);
      end

      function testGettingStartedGuideIsPackaged(testCase)
         % The guide is what MATLAB opens after an install. Naming a file
         % the release does not carry leaves that entry broken.

         guide = string(testCase.Opts.ToolboxGettingStartedGuide);
         testCase.assertNotEmpty(guide);

         returned = ismember(guide, string(testCase.Opts.ToolboxFiles));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testVersionComesFromVersionTxt(testCase)
         % releaseoptions overwrites ToolboxVersion from version.txt, so a
         % release cannot ship a version that disagrees with the source.
         % Read the version off the options the release packages, not off
         % version.txt twice, which would hold whether or not the override
         % ran. version.txt carries a leading "v" that a version must not.

         returned = string(testCase.Opts.ToolboxVersion);
         expected = erase(strip(string(fileread(fullfile(testCase.Root, ...
            'toolbox', 'version.txt')))), "v");
         testCase.verifyEqual(returned, expected);
      end
   end

   methods (Access = private)

      function files = ignoredFiles(testCase, toolboxfolder)
         %IGNOREDFILES Expand toolbox.ignore into the paths it excludes.
         %
         % The file holds one rule per line, relative to the toolbox folder,
         % and uses % to start a comment. A rule naming a folder excludes
         % everything under it.

         files = strings(0, 1);

         ignorefile = fullfile(toolboxfolder, 'toolbox.ignore');
         if ~isfile(ignorefile)
            return
         end

         rules = strip(readlines(ignorefile));
         rules = rules(strlength(rules) > 0 & ~startsWith(rules, "%") ...
            & ~startsWith(rules, "#"));

         % Collect one cell per rule, then concatenate once, so the result
         % does not grow inside the loop.
         perrule = cell(numel(rules), 1);

         for n = 1:numel(rules)
            rule = fullfile(toolboxfolder, rules(n));

            % A trailing separator, or a real folder, means everything under
            % it goes.
            if endsWith(rules(n), "/") || isfolder(rule)
               rule = fullfile(rule, "**", "*");
            end

            matches = dir(rule);
            matches = matches(~[matches.isdir]);

            perrule{n} = string(fullfile({matches.folder}, {matches.name}))';
         end

         files = vertcat(files, perrule{:});

         testCase.assertClass(files, 'string');
      end
   end
end

function closeProjectQuietly(prjfile)
   %CLOSEPROJECTQUIETLY Close the Project this class opened, if it is open.
   %
   % The teardown runs even when the setup failed part way, so a missing or
   % already-closed Project must not raise.

   try
      proj = matlab.project.rootProject();
      if ~isempty(proj) && strcmp(proj.RootFolder, fileparts(prjfile))
         close(proj);
      end
   catch
      % No Project is open, which is the state this wanted anyway.
   end
end
