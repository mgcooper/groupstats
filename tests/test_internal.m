classdef test_internal < matlab.unittest.TestCase
   %TEST_INTERNAL Test the toolbox internal functions.
   %
   % Covers the scaffolding no other test file reaches: the function
   % signature file, the path builder, the version reader, and backupfile.
   %
   % See also: groupstats.internal.buildpath,
   % groupstats.internal.privatefunction, groupstats.internal.version

   properties
      % A handle to the private backupfile helper, and a scratch folder to
      % run it in.
      backupfile
      ScratchDir
   end

   methods (TestClassSetup)

      function resolvePrivateHandles(testCase)
         testCase.backupfile = ...
            groupstats.internal.privatefunction('backupfile');
      end
   end

   methods (TestMethodSetup)

      function makeScratchDir(testCase)
         testCase.ScratchDir = tempname();
         mkdir(testCase.ScratchDir);
         testCase.addTeardown(@() rmdir(testCase.ScratchDir, 's'));
      end
   end

   methods (Test)

      function testFunctionSignaturesValidate(testCase)
         % An invalid signature file breaks tab completion with no error at
         % run time, so validate it here.

         jsonfile = fullfile(groupstats.internal.buildpath(), ...
            'functionSignatures.json');

         returned = validateFunctionSignaturesJSON(jsonfile);

         testCase.verifyEmpty(returned);
      end

      function testBuildpathReturnsTheToolboxFolder(testCase)
         % buildpath() with no argument is the toolbox folder.

         returned = groupstats.internal.buildpath();

         testCase.verifyTrue(isfolder(returned));
         testCase.verifyTrue(isfolder(fullfile(returned, '+groupstats')));
      end

      function testBuildpathAppendsAFolder(testCase)
         % A folder name is appended to the toolbox folder.

         returned = groupstats.internal.buildpath('+groupstats');

         testCase.verifyTrue(isfolder(returned));
      end

      function testVersionMatchesTheVersionFile(testCase)
         % version.txt is the one place the version is written down.

         returned = groupstats.internal.version();

         versionfile = fullfile(groupstats.internal.buildpath(), ...
            'version.txt');
         expected = strtrim(fileread(versionfile));
         testCase.verifyEqual(returned, expected);
      end

      function testVersionStartsWithV(testCase)
         % The packaging task strips the leading v, so it has to be there.

         returned = groupstats.internal.version();

         testCase.verifyTrue(startsWith(returned, 'v'));
      end

      function testVersionErrorsWithoutTheVersionFile(testCase)
         % The release task reads this value, so a missing file must name
         % itself rather than fail somewhere downstream.

         versionfile = fullfile(groupstats.internal.buildpath(), ...
            'version.txt');
         hidden = [versionfile '.hidden'];

         movefile(versionfile, hidden);
         testCase.addTeardown(@() movefile(hidden, versionfile));

         testCase.verifyError(@() groupstats.internal.version(), ...
            'groupstats:version:versionFileNotFound');
      end

      function testCheckdependenciesFindsNothingWhenAllResolve(testCase)
         % Names every MATLAB install defines, so the result cannot depend
         % on which toolboxes this machine has.

         returned = groupstats.internal.checkdependencies(["sin"; "fullfile"]);

         testCase.verifyEmpty(returned);
      end

      function testCheckdependenciesWarnsAboutMissingNames(testCase)
         % Opening the project must report a missing dependency, so the
         % failure names the cause instead of appearing later in a chart.

         missing = "groupstats_test_no_such_function";

         testCase.verifyWarning( ...
            @() groupstats.internal.checkdependencies(missing), ...
            'groupstats:checkdependencies:missingDependencies');
      end

      function testCheckdependenciesReturnsOnlyTheMissingNames(testCase)
         % The warning is expected here, so the assertion can read the
         % returned list instead.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'groupstats:checkdependencies:missingDependencies'));

         required = ["sin"; "groupstats_test_no_such_function"; "fullfile"];

         returned = groupstats.internal.checkdependencies(required);

         testCase.verifyEqual(returned, "groupstats_test_no_such_function");
      end

      function testDocpathFindsTheLandingPage(testCase)
         % groupstats.help() opens this page, so it has to be there.

         returned = groupstats.internal.docpath("groupstats_welcome");

         testCase.verifyTrue(isfile(returned));
      end

      function testDocpathReturnsEmptyForAMissingPage(testCase)
         % An empty result lets the caller name the page it was given.

         returned = groupstats.internal.docpath("nosuchpage");

         testCase.verifyEqual(returned, "");
      end

      function testHelpErrorsForAMissingPage(testCase)
         % The error must come before the browser opens.

         testCase.verifyError(@() groupstats.help("nosuchpage"), ...
            'groupstats:help:docNotFound');
      end

      function testMakecontentsWritesAContentsFileForANewPackage(testCase)
         % A package added since the last run holds no Contents.m, and the
         % update step only reads folders that hold one. Adding a package
         % must still produce its listing.

         % makecontents rewrites every Contents.m under the toolbox, and
         % writes one for any package that holds none. Both changes must be
         % undone, so running the suite leaves the working tree unchanged.
         listings = findContentsFiles();
         originals = arrayfun(@(file) string(fileread(file)), listings);
         testCase.addTeardown(@() restoreListings(listings, originals));

         package = fullfile(groupstats.internal.buildpath(), ...
            '+groupstats', '+tmpcontents');
         mkdir(package);
         testCase.addTeardown(@() rmdir(package, 's'));

         writelines([
            "function value = tmpfunction()"
            "   %TMPFUNCTION Stand in for a newly added package member."
            "   value = 1;"
            "end"
            ], fullfile(package, 'tmpfunction.m'));

         groupstats.internal.makecontents("-nobackup");

         contentsfile = fullfile(package, 'Contents.m');
         testCase.assertTrue(isfile(contentsfile));

         % The listing must name the function, not just the header.
         testCase.verifyTrue( ...
            any(contains(readlines(contentsfile), "tmpfunction")));
      end

      function testMakecontentsLeavesNoArtifactInAPackage(testCase)
         % The backup default wrote Contents_<date>.m beside the original.
         % That file is a callable member of the package, so test_namelists
         % read it as a namelist and failed, and the packaging fileset covers
         % the folder, so it shipped inside the mltbx.

         listings = findContentsFiles();
         originals = arrayfun(@(file) string(fileread(file)), listings);
         testCase.addTeardown(@() restoreListings(listings, originals));

         groupstats.internal.makecontents();

         returned = numel(dir(fullfile(groupstats.internal.buildpath(), ...
            '**', 'Contents_*.m')));
         expected = 0;
         testCase.verifyEqual(returned, expected);

         % An explicit backup still writes nothing into the toolbox.
         groupstats.internal.makecontents('-backup');

         returned = numel(dir(fullfile(groupstats.internal.buildpath(), ...
            '**', 'Contents_*.m')));
         expected = 0;
         testCase.verifyEqual(returned, expected);
      end

      % ---- backupfile

      function testBackupfileNamesABackup(testCase)
         % The backup name carries the original name and a date stamp.

         source = fullfile(testCase.ScratchDir, 'data.txt');
         writelines("content", source);

         returned = testCase.backupfile(source);

         testCase.verifyTrue(startsWith(returned, ...
            fullfile(testCase.ScratchDir, 'data_')));
         testCase.verifyTrue(endsWith(returned, '.txt'));
      end

      function testBackupfileMakesNoCopyByDefault(testCase)
         % Naming a backup does not create one.

         source = fullfile(testCase.ScratchDir, 'data.txt');
         writelines("content", source);

         backup = testCase.backupfile(source);

         testCase.verifyFalse(isfile(backup));
      end

      function testBackupfileCopiesWhenAsked(testCase)
         % The second argument makes the copy.

         source = fullfile(testCase.ScratchDir, 'data.txt');
         writelines("content", source);

         backup = testCase.backupfile(source, true);

         testCase.verifyTrue(isfile(backup));
         testCase.verifyEqual(readlines(backup), readlines(source));
      end

      function testBackupfileWarnsWhenTheSourceIsMissing(testCase)
         % A missing source is a warning, so a caller does not need to test
         % isfile before every call.

         source = fullfile(testCase.ScratchDir, 'nosuchfile.txt');

         testCase.verifyWarning(@() testCase.backupfile(source, true), '');
      end

      function testBackupfileWarnsWhenTheBackupExists(testCase)
         % A second backup in the same second would overwrite the first, so
         % backupfile warns and keeps the file it already made.

         source = fullfile(testCase.ScratchDir, 'data.txt');
         writelines("content", source);

         % The backup name carries the time to the second, and there is no
         % way to hand backupfile a clock. Create the file the next call
         % names, then call it, and check inside the loop whether the
         % collision warning fired. A call that crosses a second boundary
         % gets a different name and no warning, so try again.
         predicted = "";
         warned = false;
         for attempt = 1:20
            predicted = testCase.backupfile(source);
            writelines("earlier backup", predicted);

            lastwarn('');
            warnstate = warning('off', 'all');
            testCase.backupfile(source, true);
            warning(warnstate);

            if contains(lastwarn(), 'Backup already exists')
               warned = true;
               break
            end
         end

         testCase.assertTrue(warned, ...
            'The clock moved on during every attempt.');

         % The warning path must not touch the file that is already there.
         % writelines ends the file with a newline, so read the first line.
         contents = readlines(predicted);
         testCase.verifyEqual(contents(1), "earlier backup");
      end

      function testBackupfileZipsTheCopy(testCase)
         % The third argument replaces the copy with a zip file.

         source = fullfile(testCase.ScratchDir, 'data.txt');
         writelines("content", source);

         backup = testCase.backupfile(source, true, true);

         testCase.verifyTrue(endsWith(backup, '.zip'));
         testCase.verifyTrue(isfile(backup));

         % The copy the zip was made from must be gone.
         testCase.verifyFalse(isfile(erase(backup, '.zip')));
      end

      function testBackupfileReturnsNothingWithNoOutput(testCase)
         % A zero-output call assigns nothing, so it prints no ans.

         source = fullfile(testCase.ScratchDir, 'data.txt');
         writelines("content", source);

         testCase.verifyWarningFree(@() callWithNoOutput( ...
            testCase.backupfile, source));
      end

      function testBackupfileReturnsBothNames(testCase)
         % The second output is the backup file name without its folder.

         source = fullfile(testCase.ScratchDir, 'data.txt');
         writelines("content", source);

         [fullpath, filename] = testCase.backupfile(source);

         [~, name, ext] = fileparts(fullpath);
         expected = [name ext];
         testCase.verifyEqual(filename, expected);
      end
   end
end

function listings = findContentsFiles()
   %FINDCONTENTSFILES Return every Contents.m under the toolbox folder.

   found = dir(fullfile(groupstats.internal.buildpath(), '**', 'Contents.m'));
   listings = string(fullfile({found.folder}, {found.name}))';
end

function restoreListings(paths, contents)
   %RESTORELISTINGS Undo every change makecontents made to a Contents.m.
   %
   % Writes back the text each listed file held, and deletes any Contents.m
   % that the run added.

   % Delete first, so a file that was added cannot be read as an original.
   % delete reports nothing when it removes nothing, so check each file.
   added = setdiff(findContentsFiles(), paths);
   removed = true(size(added));
   for n = 1:numel(added)
      delete(added(n))
      removed(n) = ~isfile(added(n));
   end

   % fwrite rather than writelines, so the bytes match what was read. Report
   % a file that cannot be opened, and keep restoring the rest, because a
   % file left unrestored is a change to the working tree.
   restored = true(size(paths));
   for n = 1:numel(paths)
      fid = fopen(paths(n), 'w');
      if fid < 0
         restored(n) = false;
         continue
      end
      fwrite(fid, char(contents(n)));
      fclose(fid);
   end

   % A file left behind, or left unrestored, is a change to the working
   % tree, so report both here rather than let the test pass.
   assert(all(removed), 'Could not delete: %s', ...
      strjoin(added(~removed), ', '))
   assert(all(restored), 'Could not restore: %s', ...
      strjoin(paths(~restored), ', '))
end

function callWithNoOutput(fcn, varargin)
   %CALLWITHNOOUTPUT Invoke FCN as a statement, requesting no output.

   fcn(varargin{:});
end
