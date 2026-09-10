classdef test_internal < matlab.unittest.TestCase
   %TEST_INTERNAL Test the toolbox internal functions.
   %
   % Covers the scaffolding no other test file reaches: the function
   % signature file, the path builder, the version reader, backupfile and
   % the Contents generators, the dependency check and the vendoring
   % (installRequiredFiles, vendordependencies, vendoredfiles,
   % undersource), the vendored tablecompletions copy, docpath, and help.
   %
   % The live-script cases read tests/fixtures/gs_livescript.mlx, which
   % calls gs_live_inside and gs_live_outside, two helpers each case
   % places where it needs them.
   %
   % See also: groupstats.internal.buildpath,
   % groupstats.internal.privatefunction, groupstats.internal.version,
   % groupstats.internal.vendordependencies

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

      function testCheckdependenciesNoArgumentFindsNothingToVendor(testCase)
         % The no-argument form scans the toolbox against itself. Empty
         % means every file the package calls ships inside it, which is
         % what the check task asserts and the clean-path install relies
         % on. The scan takes tens of seconds.

         returned = groupstats.internal.checkdependencies();
         expected = strings(0, 1);
         testCase.verifyEqual(returned, expected);
      end

      function testCheckdependenciesReportsADeletedVendoredCopy(testCase)
         % A copy vendored.txt names that is not on disk is a missing file
         % the static scan cannot see when the source checkout is off the
         % path, so it is reported by its listed path.

         tb = fullfile(testCase.ScratchDir, "tb");
         mkdir(fullfile(tb, "+gsv", "private"))
         writelines("function gs_check_fcn(), end", ...
            fullfile(tb, "+gsv", "gs_check_fcn.m"))
         writelines([
            "# test list"
            "+gsv/private/gs_check_gone.m <- /nowhere/gs_check_gone.m"
            ], fullfile(tb, "vendored.txt"))

         returned = testCase.verifyWarning(@() ...
            groupstats.internal.checkdependencies(ToolboxFolder = tb), ...
            'groupstats:checkdependencies:missingDependencies');
         expected = string(fullfile(tb, "+gsv", "private", ...
            "gs_check_gone.m"));
         testCase.verifyEqual(returned, expected);
      end

      function testUndersourceMatchesOnFolderBoundaries(testCase)
         % A sibling whose name starts with the root's name is not under
         % it, and a trailing separator on the root is ignored.

         undersource = groupstats.internal.privatefunction('undersource');

         root = fullfile(tempdir, "src");
         returned = undersource([root; fullfile(root, "lib"); ...
            root + "-copy"; fullfile(tempdir, "other")], root + filesep);
         expected = [true; true; false; false];
         testCase.verifyEqual(returned, expected);

         % A ".." segment resolves before the comparison, so a path that
         % climbs out of the root is not under it, and one that climbs
         % within it is.
         returned = undersource([fullfile(root, "..", "outside"); ...
            fullfile(root, "lib", "..", "x"); fullfile(root, ".", "lib")], ...
            root);
         expected = [false; true; true];
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesTellsASourcePrefixSiblingApart(testCase)
         % A demo that calls a helper from a folder named like the source
         % with a suffix is not calling into the source, so the call is
         % not an unreachable one. It is an external call the source
         % cannot satisfy, which is the other error.

         [tb, src] = testCase.makeVendorFixture();
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'installRequiredFiles:notUnderLocalSource'));
         sibling = testCase.ScratchDir + "/src-copy";
         mkdir(sibling)
         writelines("function gs_vendor_other(), end", ...
            fullfile(sibling, "gs_vendor_other.m"))
         mkdir(fullfile(tb, "examples"))
         writelines("gs_vendor_other()", ...
            fullfile(tb, "examples", "gs_vendor_demo.m"))
         addpath(sibling, fullfile(tb, "examples"))
         testCase.addTeardown(@() rmpath(sibling, fullfile(tb, "examples")))

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty()), ...
            'groupstats:vendordependencies:unresolved');
      end

      function testCheckdependenciesScansLiveScripts(testCase)
         % A shipped live script calls functions too, and the .m scan does
         % not read it. The fixture live script in a scratch toolbox calls
         % one helper inside the toolbox and one outside, so the scan must
         % report the outside one only.

         tb = fullfile(testCase.ScratchDir, "tb");
         [~, outside] = testCase.placeLiveScriptHelpers(tb);
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'groupstats:checkdependencies:missingDependencies'));

         missing = groupstats.internal.checkdependencies(ToolboxFolder = tb);

         % The fixture's calls are a closed set, so the result is exactly
         % the outside helper.
         returned = missing;
         expected = outside;
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesLocalResolvesARelativeSource(testCase)
         % A relative localSourcePath is made absolute before the working
         % folder changes to projectPath, so every copy still lands.

         [proj, src] = testCase.makeLocalInstallFixture();
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(testCase.ScratchDir)

         [names, from] = groupstats.internal.installRequiredFiles( ...
            projectPath = proj, localSourcePath = "src", ...
            installPath = fullfile(proj, "private"), ...
            ignoreFolder = "nosuchfolder", Source = "local");

         returned = names;
         expected = "gs_test_helper.m";
         testCase.verifyEqual(returned, expected);

         returned = from;
         expected = string(fullfile(src, "lib", "gs_test_helper.m"));
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesLeavesAFailedOverwriteOut(testCase)
         % A destination that existed before and survived a failed copy is
         % not this call's file, so it is warned about and left out.

         [proj, src] = testCase.makeLocalInstallFixture();
         mkdir(fullfile(proj, "private"))
         writelines("old", fullfile(proj, "private", "gs_test_helper.m"))

         % An unreadable source makes the copy fail. Read permission is
         % taken with chmod, which fileattrib cannot do on this platform,
         % so the case runs on the Unix-like hosts the suite runs on.
         testCase.assumeFalse(ispc, "chmod is not available on Windows.");
         sourcefile = char(fullfile(src, "lib", "gs_test_helper.m"));
         system(['chmod 000 "' sourcefile '"']);
         testCase.addTeardown(@() system(['chmod 644 "' sourcefile '"']));

         names = testCase.verifyWarning(@() ...
            groupstats.internal.installRequiredFiles( ...
            "gs_test_helper.m", projectPath = proj, ...
            localSourcePath = src, ...
            installPath = fullfile(proj, "private"), Source = "local"), ...
            'installRequiredFiles:installFailed');

         returned = names;
         expected = strings(0, 1);
         testCase.verifyEqual(returned, expected);
      end

      function testCheckdependenciesAcceptsARelativeToolboxFolder(testCase)
         % A relative ToolboxFolder is made absolute before the scan, so
         % the helper the fixture live script reaches inside the folder is
         % not reported, while the one outside still is.

         tb = fullfile(testCase.ScratchDir, "tb");
         [~, outside] = testCase.placeLiveScriptHelpers(tb);
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'groupstats:checkdependencies:missingDependencies'));
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(testCase.ScratchDir)

         missing = groupstats.internal.checkdependencies( ...
            ToolboxFolder = "tb");

         returned = missing;
         expected = outside;
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesLocalCopiesFromTheSource(testCase)
         % Source="local" copies each required file from the local source
         % checkout into the install folder, with no network and no GitHub
         % user name, and reports the source paths.

         [proj, src] = testCase.makeLocalInstallFixture();

         [names, from] = groupstats.internal.installRequiredFiles( ...
            projectPath = proj, localSourcePath = src, ...
            installPath = fullfile(proj, "private"), ...
            ignoreFolder = "nosuchfolder", Source = "local");

         returned = names;
         expected = "gs_test_helper.m";
         testCase.verifyEqual(returned, expected);

         returned = from;
         expected = string(fullfile(src, "lib", "gs_test_helper.m"));
         testCase.verifyEqual(returned, expected);

         returned = isfile(fullfile(proj, "private", "gs_test_helper.m"));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesLocalLooksUpAShadowedName(testCase)
         % A copy elsewhere on the path can shadow the source checkout's
         % copy. The file is then looked up by name under the source, so
         % the checkout's copy is what gets vendored.

         [proj, src] = testCase.makeLocalInstallFixture();

         % A shadow copy that resolves first on the path.
         shadow = fullfile(testCase.ScratchDir, "shadow");
         mkdir(shadow)
         writelines("function gs_test_helper(), end", ...
            fullfile(shadow, "gs_test_helper.m"))
         addpath(shadow)
         testCase.addTeardown(@() rmpath(shadow))

         [~, from] = groupstats.internal.installRequiredFiles( ...
            projectPath = proj, localSourcePath = src, ...
            installPath = fullfile(proj, "private"), ...
            ignoreFolder = "nosuchfolder", Source = "local");

         returned = from;
         expected = string(fullfile(src, "lib", "gs_test_helper.m"));
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesLocalSkipsANameNotUnderTheSource(testCase)
         % A required name with no copy under the source is skipped with a
         % warning, and nothing is installed for it.

         [proj, src] = testCase.makeLocalInstallFixture();

         names = testCase.verifyWarning(@() ...
            groupstats.internal.installRequiredFiles( ...
            "gs_test_no_such_file.m", projectPath = proj, ...
            localSourcePath = src, ...
            installPath = fullfile(proj, "private"), Source = "local"), ...
            'installRequiredFiles:notUnderLocalSource');

         returned = names;
         expected = strings(0, 1);
         testCase.verifyEqual(returned, expected);

         returned = isfile(fullfile(proj, "private", ...
            "gs_test_no_such_file.m"));
         expected = false;
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesReferenceListCountsAsPresent(testCase)
         % A folder named as the reference counts as present, so a call
         % into it is not vendored. This is how the +internal folder is
         % scanned against the whole toolbox.

         [proj, src] = testCase.makeLocalInstallFixture();

         % A second project folder whose file calls the first project's
         % caller. With the first project as the reference, only the
         % helper under the source is missing.
         proj2 = fullfile(testCase.ScratchDir, "proj2");
         mkdir(proj2)
         writelines("function gs_test_second(), gs_test_caller(), end", ...
            fullfile(proj2, "gs_test_second.m"))
         addpath(proj2)
         testCase.addTeardown(@() rmpath(proj2))

         [names, ~] = groupstats.internal.installRequiredFiles( ...
            projectPath = proj2, referenceList = proj, ...
            localSourcePath = src, ...
            installPath = fullfile(proj2, "private"), ...
            ignoreFolder = "nosuchfolder", Source = "local");

         returned = names;
         expected = "gs_test_helper.m";
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesSkipsAMatlabFileQuietly(testCase)
         % A MATLAB file under matlabroot is not a dependency to vendor,
         % and it is common enough that no warning should name it.

         [proj, src] = testCase.makeLocalInstallFixture();
         matlabfile = fullfile(matlabroot, "toolbox", "local", "userpath.m");

         names = testCase.verifyWarningFree(@() ...
            groupstats.internal.installRequiredFiles(matlabfile, ...
            projectPath = proj, localSourcePath = src, ...
            installPath = fullfile(proj, "private"), Source = "local"));

         returned = names;
         expected = strings(0, 1);
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesSkipsANameWithSeveralCopies(testCase)
         % Two copies under the source leave no one file to vendor, so the
         % name is skipped with a warning that lists them.

         [proj, src] = testCase.makeLocalInstallFixture();
         mkdir(fullfile(src, "lib2"))
         copyfile(fullfile(src, "lib", "gs_test_helper.m"), ...
            fullfile(src, "lib2", "gs_test_helper.m"))

         names = testCase.verifyWarning(@() ...
            groupstats.internal.installRequiredFiles( ...
            "gs_test_helper.m", projectPath = proj, ...
            localSourcePath = src, ...
            installPath = fullfile(proj, "private"), Source = "local"), ...
            'installRequiredFiles:severalUnderLocalSource');

         returned = names;
         expected = strings(0, 1);
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesFillsTheThreeFolders(testCase)
         % A toolbox tree whose public function, explicit name, and
         % +internal tool each need a file from the source gets each copy
         % in the folder its caller reaches, and the list names all three.

         [tb, src] = testCase.makeVendorFixture();

         [installed, sources] = groupstats.internal.vendordependencies( ...
            tb, src, Explicit = "gs_vendor_explicit.m");

         returned = sort(installed);
         expected = sort([
            fullfile("+gsv", "private", "gs_vendor_pub.m")
            fullfile("+gsv", "+internal", "gs_vendor_explicit.m")
            fullfile("+gsv", "+internal", "private", "gs_vendor_int.m")
            fullfile("+gsv", "+internal", "private", "gs_vendor_deep.m")
            ]);
         testCase.verifyEqual(returned, expected);

         returned = numel(sources);
         expected = 4;
         testCase.verifyEqual(returned, expected);

         returned = sort(groupstats.internal.vendoredfiles(tb));
         expected = sort(fullfile(tb, [
            fullfile("+gsv", "private", "gs_vendor_pub.m")
            fullfile("+gsv", "+internal", "gs_vendor_explicit.m")
            fullfile("+gsv", "+internal", "private", "gs_vendor_int.m")
            fullfile("+gsv", "+internal", "private", "gs_vendor_deep.m")
            ]));
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesRepeatRunIsTheSame(testCase)
         % A second run deletes the previous copies first, so it finds the
         % same requirements and writes the same list, and a copy a change
         % stopped needing goes away.

         [tb, src] = testCase.makeVendorFixture();
         first = groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m");

         % Drop the +internal tool's call, so its helper has no caller,
         % then run again.
         writelines("function gs_vendor_tool(), end", ...
            fullfile(tb, "+gsv", "+internal", "gs_vendor_tool.m"))
         second = groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m");

         returned = sort(second);
         expected = sort(first(~contains(first, "gs_vendor_int") ...
            & ~contains(first, "gs_vendor_deep")));
         testCase.verifyEqual(returned, expected);

         returned = isfile(fullfile(tb, "+gsv", "+internal", "private", ...
            "gs_vendor_int.m"));
         expected = false;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesFindsASourceOffThePath(testCase)
         % The source folders are on the path only during the scan, so a
         % checkout that is not on the caller's path still resolves, and
         % the caller's path is put back afterwards.

         [tb, src] = testCase.makeVendorFixture();
         rmpath(fullfile(src, "lib"))
         before = path();

         installed = groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty());

         returned = any(contains(installed, "gs_vendor_pub.m"));
         expected = true;
         testCase.verifyEqual(returned, expected);

         returned = path();
         expected = before;
         testCase.verifyEqual(returned, expected);
         addpath(fullfile(src, "lib"))
      end

      function testVendordependenciesResolvesARelativeSource(testCase)
         % A relative source such as ../matfunclib is made absolute before
         % the previous copies are deleted, so the scan's absolute paths
         % compare with it and every copy lands.

         [tb, src] = testCase.makeVendorFixture();
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(testCase.ScratchDir)

         [installed, sources] = groupstats.internal.vendordependencies( ...
            tb, "src", Explicit = string.empty());

         returned = any(contains(installed, "gs_vendor_pub.m"));
         expected = true;
         testCase.verifyEqual(returned, expected);

         returned = all(startsWith(sources, src));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesNeedsEveryExplicitName(testCase)
         % An explicit name no scan can rediscover must resolve under the
         % source, or the list would be written without it.

         [tb, src] = testCase.makeVendorFixture();
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'installRequiredFiles:notUnderLocalSource'));

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_nosuch.m"), ...
            'groupstats:vendordependencies:unresolved');
      end

      function testVendordependenciesRejectsARootLevelCaller(testCase)
         % A file directly under the toolbox folder cannot reach a private
         % folder either, so its call into the source is reported.

         [tb, src] = testCase.makeVendorFixture();
         writelines("gs_vendor_pub()", fullfile(tb, "gs_vendor_root.m"))

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty()), ...
            'groupstats:vendordependencies:unreachableCaller');
      end

      function testInstallRequiredFilesLeavesAFailedCopyOut(testCase)
         % A copy that did not land is warned about and left out of the
         % returned lists, so a caller never records it as installed.

         [proj, src] = testCase.makeLocalInstallFixture();

         % A folder where the copy should land is a failure before any
         % write, so no nested copy appears inside it either.
         inTheWay = fullfile(proj, "private", "gs_test_helper.m");
         mkdir(inTheWay)

         names = testCase.verifyWarning(@() ...
            groupstats.internal.installRequiredFiles( ...
            projectPath = proj, localSourcePath = src, ...
            installPath = fullfile(proj, "private"), ...
            ignoreFolder = "nosuchfolder", Source = "local"), ...
            'installRequiredFiles:installFailed');

         returned = names;
         expected = strings(0, 1);
         testCase.verifyEqual(returned, expected);

         % The folder guard stops the copy before copyfile could write a
         % nested file into the folder, which nothing would list.
         returned = isfile(fullfile(inTheWay, "gs_test_helper.m"));
         expected = false;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesRestoresCopiesWhenARunFails(testCase)
         % A failed run puts the previous copies back and leaves the list
         % as it was, so a diagnostic run never leaves the toolbox broken.

         [tb, src] = testCase.makeVendorFixture();
         first = groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m");
         listbefore = readlines(fullfile(tb, "vendored.txt"));

         % A demo that calls the source makes the next run fail.
         mkdir(fullfile(tb, "examples"))
         writelines("gs_vendor_pub()", ...
            fullfile(tb, "examples", "gs_vendor_demo.m"))
         addpath(fullfile(tb, "examples"))
         testCase.addTeardown(@() rmpath(fullfile(tb, "examples")))

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m"), ...
            'groupstats:vendordependencies:unreachableCaller');

         returned = all(isfile(fullfile(tb, first)));
         expected = true;
         testCase.verifyEqual(returned, expected);

         returned = readlines(fullfile(tb, "vendored.txt"));
         expected = listbefore;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesRollsBackAFailedInstall(testCase)
         % A copy that does not land makes the run fail, and the run then
         % puts every previous copy back and leaves the list as it was.

         [tb, src] = testCase.makeVendorFixture();
         first = groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m");
         listbefore = readlines(fullfile(tb, "vendored.txt"));

         % A folder where the +internal helper's copy should land makes
         % that copy fail.
         blocked = fullfile(tb, "+gsv", "+internal", "private", ...
            "gs_vendor_int.m");
         delete(blocked)
         mkdir(blocked)
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'installRequiredFiles:installFailed'));

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m"), ...
            'groupstats:vendordependencies:installFailed');

         rmdir(blocked, "s")
         others = first(~contains(first, "gs_vendor_int.m"));
         returned = all(isfile(fullfile(tb, others)));
         expected = true;
         testCase.verifyEqual(returned, expected);

         returned = readlines(fullfile(tb, "vendored.txt"));
         expected = listbefore;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesRemovesWhatAFailedRunCopied(testCase)
         % A run that copies a new file and then fails removes that file
         % too, so the toolbox never holds a copy the list does not name.

         [tb, src] = testCase.makeVendorFixture();
         groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m");

         % A new public dependency, and an Explicit name that cannot be
         % found so the run fails after copying it.
         writelines("function gs_vendor_pub2(), end", ...
            fullfile(src, "lib", "gs_vendor_pub2.m"))
         writelines("function gs_vendor_fcn2(), gs_vendor_pub2(), end", ...
            fullfile(tb, "+gsv", "gs_vendor_fcn2.m"))
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'installRequiredFiles:notUnderLocalSource'));

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_nosuch.m"), ...
            'groupstats:vendordependencies:unresolved');

         returned = isfile(fullfile(tb, "+gsv", "private", ...
            "gs_vendor_pub2.m"));
         expected = false;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesWritesSourcesRelativeToTheCheckout(testCase)
         % The list names each copy's source relative to the checkout, so
         % it reads the same on every machine.

         [tb, src] = testCase.makeVendorFixture();
         groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty());

         lines = readlines(fullfile(tb, "vendored.txt"));
         lines = lines(~startsWith(lines, "#") & strlength(lines) > 0);
         returned = any(contains(lines, src));
         expected = false;
         testCase.verifyEqual(returned, expected);

         returned = any(endsWith(lines, "<- lib/gs_vendor_pub.m"));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesRejectsACollision(testCase)
         % A file already at a destination that the list does not name is
         % not a previous copy, so it is reported rather than overwritten,
         % and it survives.

         [tb, src] = testCase.makeVendorFixture();
         mine = fullfile(tb, "+gsv", "+internal", "gs_vendor_explicit.m");
         writelines("function gs_vendor_explicit(), disp('mine'), end", mine)

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = "gs_vendor_explicit.m"), ...
            'groupstats:vendordependencies:collision');

         returned = any(contains(readlines(mine), "mine"));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesCopiesFromAPrefixSiblingSource(testCase)
         % A source folder whose name starts with the toolbox folder's
         % name is not inside the toolbox, so its files are copied.

         [tb, src] = testCase.makeVendorFixture();
         sibling = tb + "-copy";
         copyfile(fullfile(src, "lib"), fullfile(sibling, "lib"))
         rmpath(fullfile(src, "lib"))
         testCase.addTeardown(@() addpath(fullfile(src, "lib")))
         addpath(fullfile(sibling, "lib"))
         testCase.addTeardown(@() rmpath(fullfile(sibling, "lib")))

         [installed, sources] = groupstats.internal.vendordependencies( ...
            tb, sibling, Explicit = string.empty());

         returned = any(contains(installed, "gs_vendor_pub.m"));
         expected = true;
         testCase.verifyEqual(returned, expected);

         returned = all(startsWith(sources, sibling));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesRejectsAnUnresolvedName(testCase)
         % A required file with no copy under the source cannot be
         % vendored, so the run stops before any write, and the toolbox
         % holds no copy afterwards.

         [tb, src] = testCase.makeVendorFixture();
         delete(fullfile(src, "lib", "gs_vendor_deep.m"))
         writelines("function gs_vendor_deep(), end", ...
            fullfile(testCase.ScratchDir, "gs_vendor_deep.m"))
         addpath(testCase.ScratchDir)
         testCase.addTeardown(@() rmpath(testCase.ScratchDir))
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'installRequiredFiles:notUnderLocalSource'));

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty()), ...
            'groupstats:vendordependencies:unresolved');

         returned = isfile(fullfile(tb, "+gsv", "private", ...
            "gs_vendor_pub.m"));
         expected = false;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesRejectsAnOrdinaryNamespaceSubfolderCaller(testCase)
         % An ordinary folder under the namespace, such as a vendored
         % third-party folder, cannot reach the namespace private folder
         % either, so its call into the source is reported.

         [tb, src] = testCase.makeVendorFixture();
         mkdir(fullfile(tb, "+gsv", "thirdparty"))
         writelines("function gs_vendor_third(), gs_vendor_pub(), end", ...
            fullfile(tb, "+gsv", "thirdparty", "gs_vendor_third.m"))
         addpath(fullfile(tb, "+gsv", "thirdparty"))
         testCase.addTeardown(@() rmpath(fullfile(tb, "+gsv", "thirdparty")))

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty()), ...
            'groupstats:vendordependencies:unreachableCaller');
      end

      function testVendoredfilesReturnsAbsolutePathsForARelativeFolder(testCase)
         % A relative folder gives the same absolute paths as the absolute
         % one, so a caller that changes folders afterwards reads the
         % right files.

         [tb, src] = testCase.makeVendorFixture();
         groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty());
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(testCase.ScratchDir)

         returned = groupstats.internal.vendoredfiles("tb");
         expected = groupstats.internal.vendoredfiles(tb);
         testCase.verifyEqual(returned, expected);

         returned = all(startsWith(returned, tb));
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesNeedsOneNamespace(testCase)
         % The namespace folder is the one +folder under the toolbox
         % folder. Two leave the destination undefined.

         [tb, src] = testCase.makeVendorFixture();
         mkdir(fullfile(tb, "+other"))

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src), ...
            'groupstats:vendordependencies:oneNamespace');
      end

      function testVendordependenciesDefaultSourceReadsTheEnvironment(testCase)
         % MATLAB_FUNCTION_PATH names the checkout when it is set.

         [tb, src] = testCase.makeVendorFixture();
         saved = getenv("MATLAB_FUNCTION_PATH");
         testCase.addTeardown(@() setenv("MATLAB_FUNCTION_PATH", saved));
         setenv("MATLAB_FUNCTION_PATH", src)

         [~, sources] = groupstats.internal.vendordependencies(tb, ...
            Explicit = string.empty());

         % The fixture's three helpers are the copies, so the sources are
         % those three files under the checkout, and nothing else.
         returned = sort(sources);
         expected = sort(fullfile(src, "lib", ["gs_vendor_pub.m"; ...
            "gs_vendor_int.m"; "gs_vendor_deep.m"]));
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesDefaultSourceFallsBackToDealout(testCase)
         % Without MATLAB_FUNCTION_PATH the checkout is the folder two
         % levels above dealout.m. A stub dealout in the fixture's
         % functools folder stands in for the checkout's.

         [tb, src] = testCase.makeVendorFixture();
         saved = getenv("MATLAB_FUNCTION_PATH");
         testCase.addTeardown(@() setenv("MATLAB_FUNCTION_PATH", saved));
         setenv("MATLAB_FUNCTION_PATH", "")

         % The stub must shadow any dealout already on the path.
         mkdir(fullfile(src, "functools"))
         writelines("function dealout(), end", ...
            fullfile(src, "functools", "dealout.m"))
         addpath(fullfile(src, "functools"))
         testCase.addTeardown(@() rmpath(fullfile(src, "functools")))

         [~, sources] = groupstats.internal.vendordependencies(tb, ...
            Explicit = string.empty());

         % The fixture's three helpers are the copies, so the sources are
         % those three files under the checkout, and nothing else.
         returned = sort(sources);
         expected = sort(fullfile(src, "lib", ["gs_vendor_pub.m"; ...
            "gs_vendor_int.m"; "gs_vendor_deep.m"]));
         testCase.verifyEqual(returned, expected);
      end

      function testVendordependenciesWithoutASourceErrors(testCase)
         % No environment variable and no dealout on the path leaves no
         % checkout to copy from.

         [tb, ~] = testCase.makeVendorFixture();
         saved = getenv("MATLAB_FUNCTION_PATH");
         testCase.addTeardown(@() setenv("MATLAB_FUNCTION_PATH", saved));
         setenv("MATLAB_FUNCTION_PATH", "")

         % Take every dealout off the path for the call, then put the
         % folders back.
         savedpath = path();
         testCase.addTeardown(@() path(savedpath));
         while ~isempty(which("dealout"))
            rmpath(fileparts(which("dealout")))
         end

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, ...
            Explicit = string.empty()), ...
            'groupstats:vendordependencies:noSource');
      end

      function testVendordependenciesRejectsAnUnreachableCaller(testCase)
         % A demo in examples/ cannot reach a private folder, so a call
         % from it into the source is reported instead of vendored where
         % the demo cannot see it.

         [tb, src] = testCase.makeVendorFixture();
         mkdir(fullfile(tb, "examples"))
         writelines("gs_vendor_pub()", ...
            fullfile(tb, "examples", "gs_vendor_demo.m"))
         addpath(fullfile(tb, "examples"))
         testCase.addTeardown(@() rmpath(fullfile(tb, "examples")))

         testCase.verifyError(@() ...
            groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty()), ...
            'groupstats:vendordependencies:unreachableCaller');
      end

      function testInstallRequiredFilesMatchesTheSourceOnFolderBoundaries(testCase)
         % A folder named like the source with a suffix is not under it,
         % so a copy there is a shadow and the source's copy is used.

         [proj, src] = testCase.makeLocalInstallFixture();

         shadow = fullfile(testCase.ScratchDir, "src-copy");
         mkdir(shadow)
         writelines("function gs_test_helper(), end", ...
            fullfile(shadow, "gs_test_helper.m"))
         addpath(shadow)
         testCase.addTeardown(@() rmpath(shadow))

         [~, from] = groupstats.internal.installRequiredFiles( ...
            projectPath = proj, localSourcePath = src, ...
            installPath = fullfile(proj, "private"), ...
            ignoreFolder = "nosuchfolder", Source = "local");

         returned = from;
         expected = string(fullfile(src, "lib", "gs_test_helper.m"));
         testCase.verifyEqual(returned, expected);
      end

      function testInstallRequiredFilesHandlesAFileAtTheSourceRoot(testCase)
         % A required file directly in the source folder has no subfolder
         % in its url, and the local copy still works.

         [proj, src] = testCase.makeLocalInstallFixture();
         movefile(fullfile(src, "lib", "gs_test_helper.m"), ...
            fullfile(src, "gs_test_helper.m"))
         addpath(src)
         testCase.addTeardown(@() rmpath(src))

         [names, from] = groupstats.internal.installRequiredFiles( ...
            projectPath = proj, localSourcePath = src, ...
            installPath = fullfile(proj, "private"), ...
            ignoreFolder = "nosuchfolder", Source = "local");

         returned = names;
         expected = "gs_test_helper.m";
         testCase.verifyEqual(returned, expected);

         returned = from;
         expected = string(fullfile(src, "gs_test_helper.m"));
         testCase.verifyEqual(returned, expected);
      end

      function testVendoredfilesRejectsAnEntryOutsideTheToolbox(testCase)
         % The caller moves and deletes what the list names, so an entry
         % that leaves the toolbox folder is an error, not a path.

         tb = fullfile(testCase.ScratchDir, "tb");
         mkdir(tb)
         writelines(["+x/private/a.m <- lib/a.m"; "../escape.m <- lib/b.m"], ...
            fullfile(tb, "vendored.txt"))

         testCase.verifyError(@() groupstats.internal.vendoredfiles(tb), ...
            'groupstats:vendoredfiles:badEntry');

         writelines("/abs/a.m <- lib/a.m", fullfile(tb, "vendored.txt"))

         testCase.verifyError(@() groupstats.internal.vendoredfiles(tb), ...
            'groupstats:vendoredfiles:badEntry');

         writelines("+x\..\..\escape.m <- lib/b.m", ...
            fullfile(tb, "vendored.txt"))

         testCase.verifyError(@() groupstats.internal.vendoredfiles(tb), ...
            'groupstats:vendoredfiles:badEntry');
      end

      function testVendordependenciesVendorsWhatALiveScriptReaches(testCase)
         % A live script directly in the namespace reaches the namespace
         % private folder, and the .m scan does not read it, so what it
         % reaches under the source is vendored by path. The fixture live
         % script sits in the namespace; both helpers live in the source.

         [tb, src] = testCase.makeVendorFixture();
         copyfile(testCase.liveScriptFixture(), fullfile(tb, "+gsv"))
         writelines("function gs_live_inside(), end", ...
            fullfile(src, "lib", "gs_live_inside.m"))
         writelines("function gs_live_outside(), end", ...
            fullfile(src, "lib", "gs_live_outside.m"))

         installed = groupstats.internal.vendordependencies(tb, src, ...
            Explicit = string.empty());

         % The fixture's three helpers plus the live script's two, and
         % nothing else.
         returned = sort(installed);
         expected = sort([
            fullfile("+gsv", "private", "gs_vendor_pub.m")
            fullfile("+gsv", "private", "gs_live_inside.m")
            fullfile("+gsv", "private", "gs_live_outside.m")
            fullfile("+gsv", "+internal", "private", "gs_vendor_int.m")
            fullfile("+gsv", "+internal", "private", "gs_vendor_deep.m")
            ]);
         testCase.verifyEqual(returned, expected);
      end

      function testVendoredfilesIsEmptyWithoutAList(testCase)
         % A checkout before the first dependencies run has no list.

         returned = groupstats.internal.vendoredfiles(testCase.ScratchDir);
         expected = strings(0, 1);
         testCase.verifyEqual(returned, expected);
      end

      function testGetcontentsRecursesIntoEveryFolder(testCase)
         % A recursive call returns every file below the folder, at any
         % depth, so the per-folder gathering matches a flat search.

         getcontents = groupstats.internal.privatefunction('getcontents');
         root = fullfile(testCase.ScratchDir, "walk");
         mkdir(fullfile(root, "a", "deep"))
         mkdir(fullfile(root, "b"))
         writelines("1", fullfile(root, "top.txt"))
         writelines("1", fullfile(root, "a", "mid.txt"))
         writelines("1", fullfile(root, "a", "deep", "low.txt"))
         writelines("1", fullfile(root, "b", "side.txt"))

         [returned, dirflag] = getcontents(char(root), 'rec', true, ...
            'sort', true);
         expected = {
            'a'
            fullfile('a', 'deep')
            fullfile('a', 'deep', 'low.txt')
            fullfile('a', 'mid.txt')
            'b'
            fullfile('b', 'side.txt')
            'top.txt'
            };
         testCase.verifyEqual(returned, expected);

         % The flags travel with the names through the same gathering,
         % so they line up entry by entry.
         returned = dirflag;
         expected = [true; true; false; false; true; false; false];
         testCase.verifyEqual(returned, expected);
      end

      function testGetcontentsUnsortedOrderIsLevelByLevel(testCase)
         % Without sorting, the recursive walk lists every folder of one
         % level before any folder below it, the order a queue gives.

         getcontents = groupstats.internal.privatefunction('getcontents');
         root = fullfile(testCase.ScratchDir, "levels");
         mkdir(fullfile(root, "a", "deep"))
         mkdir(fullfile(root, "b"))
         writelines("1", fullfile(root, "a", "mid.txt"))
         writelines("1", fullfile(root, "a", "deep", "low.txt"))
         writelines("1", fullfile(root, "b", "side.txt"))

         [returned, dirflag] = getcontents(char(root), 'rec', true);
         expected = {
            'a'
            'b'
            fullfile('a', 'deep')
            fullfile('a', 'mid.txt')
            fullfile('b', 'side.txt')
            fullfile('a', 'deep', 'low.txt')
            };
         testCase.verifyEqual(returned, expected);

         returned = dirflag;
         expected = [true; true; true; false; false; false];
         testCase.verifyEqual(returned, expected);
      end

      function testListfoldersReturnsEveryLevel(testCase)
         % The relative paths of every folder at every level come back in
         % one list, the top level first and each folder's subfolders after
         % it, which the per-folder gathering must not drop or reorder.

         listfolders = groupstats.internal.privatefunction('listfolders');
         root = fullfile(testCase.ScratchDir, "levels");
         mkdir(fullfile(root, "one", "two", "three"))
         mkdir(fullfile(root, "solo"))

         returned = listfolders(char(root), -1, 'relativepaths');
         expected = {'one'; 'solo'; 'one/two'; 'one/two/three'};
         testCase.verifyEqual(returned, expected);
      end

      function testUpdatecontentsListsEveryFolderAndFile(testCase)
         % Every folder that holds a file gets a name row. Every file gets
         % a row with its H1 line, at every depth. A folder with no file
         % gets no row. The per-folder gathering must keep every row and
         % the order.

         updatecontents = groupstats.internal.privatefunction('updatecontents');
         root = fullfile(testCase.ScratchDir, "pkg");
         mkdir(fullfile(root, "sub"))
         writelines(["function alpha()"; "%ALPHA First line."], ...
            fullfile(root, "alpha.m"))
         writelines(["function beta()"; "%BETA Second line."], ...
            fullfile(root, "sub", "beta.m"))
         mkdir(fullfile(root, "empty"))
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(root)

         updatecontents(char(root));

         % Each file's row pairs its name with its own H1 line, and the
         % subfolder's rows follow the top folder's, so the per-folder
         % gathering kept names and lines aligned and in order.
         lines = readlines(fullfile(root, "Contents.m"));
         alpha = find(startsWith(lines, "%   alpha"), 1);
         sub = find(endsWith(lines, "PKG/SUB") | endsWith(lines, "PKG\SUB"), 1);
         beta = find(startsWith(lines, "%   beta"), 1);

         returned = [endsWith(lines(alpha), "- First line"); ...
            endsWith(lines(beta), "- Second line"); ...
            alpha < sub; sub < beta; ~any(contains(lines, "EMPTY"))];
         expected = true(5, 1);
         testCase.verifyEqual(returned, expected);
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

      function testHelpReturnsTheLandingPagePath(testCase)
         % With an output requested, help returns the page path and opens
         % no browser, so a test can check the page headless. A shadow of
         % web on the path errors if it is called, which proves the
         % output form never reaches it.

         testCase.shadowWeb();

         returned = groupstats.help();
         expected = groupstats.internal.docpath("groupstats_welcome");
         testCase.verifyEqual(returned, expected);
      end

      function testHelpReturnsANamedPagePath(testCase)
         % A named page resolves through the same search as the default,
         % and the output form opens nothing for it either.

         testCase.shadowWeb();

         returned = groupstats.help("groupstats_welcome");
         expected = groupstats.internal.docpath("groupstats_welcome");
         testCase.verifyEqual(returned, expected);
      end

      function testHelpWithNoOutputOpensThePage(testCase)
         % With no output, help hands the page to web. The shadow reports
         % the call, so the test sees it without a browser.

         testCase.shadowWeb();

         testCase.verifyError(@() callWithNoOutput(@groupstats.help), ...
            'groupstats_test:webCalled');

         % The shadow keeps the page it was handed.
         returned = string(getappdata(groot, 'groupstats_test_web'));
         expected = groupstats.internal.docpath("groupstats_welcome");
         testCase.verifyEqual(returned, expected);
      end

      function testTablecompletionsListsTheVariables(testCase)
         % functionSignatures.json calls groupstats.internal.tablecompletions
         % from the base workspace, so the copy in +internal must resolve
         % and answer with the table's variable names.

         tbl = table(1, "a", categorical("c"), ...
            'VariableNames', {'x', 'g', 'c'});

         returned = groupstats.internal.tablecompletions(tbl);
         expected = {'x', 'g', 'c'};
         testCase.verifyEqual(returned, expected);

         returned = groupstats.internal.tablecompletions(tbl, ...
            'selectby', 'g');
         expected = "a";
         testCase.verifyEqual(returned, expected);

         % The vartype form is what the dropcats signature calls.
         returned = groupstats.internal.tablecompletions(tbl, ...
            'vartype', 'categorical');
         expected = {'c'};
         testCase.verifyEqual(returned, expected);
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

         % makecontents rewrites every Contents.m under the toolbox it is
         % given, so it runs on a scratch copy of the toolbox and the
         % working tree is never written.
         tb = testCase.copyToolbox();
         package = fullfile(tb, '+groupstats', '+tmpcontents');
         mkdir(package);

         writelines([
            "function value = tmpfunction()"
            "   %TMPFUNCTION Stand in for a newly added package member."
            "   value = 1;"
            "end"
            ], fullfile(package, 'tmpfunction.m'));

         groupstats.internal.makecontents("-nobackup", Folder = tb);

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

         % Both runs work on a scratch copy of the toolbox, so the working
         % tree is never written.
         tb = testCase.copyToolbox();

         groupstats.internal.makecontents(Folder = tb);

         returned = numel(dir(fullfile(tb, '**', 'Contents_*.m')));
         expected = 0;
         testCase.verifyEqual(returned, expected);

         % An explicit backup still writes nothing into the toolbox.
         groupstats.internal.makecontents('-backup', Folder = tb);

         returned = numel(dir(fullfile(tb, '**', 'Contents_*.m')));
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

      function testVendordependenciesShipsAThirdPartyLicense(testCase)
         % A file in a folder of its own under the source, with a
         % license.txt beside it, is a third-party file: its license is
         % copied as <name>_LICENSE.txt beside the copy and listed. The
         % checkout's own root license.txt is not copied, even for a file
         % that lives in that root.

         [tb, src] = testCase.makeVendorFixture();
         mkdir(fullfile(src, "lib", "fex"))
         writelines("function gs_vendor_fex(), end", ...
            fullfile(src, "lib", "fex", "gs_vendor_fex.m"))
         writelines("Copyright (c) 2010, Someone. All rights reserved.", ...
            fullfile(src, "lib", "fex", "license.txt"))
         writelines("The checkout's own license.", ...
            fullfile(src, "license.txt"))
         writelines("function gs_vendor_root(), end", ...
            fullfile(src, "gs_vendor_root.m"))
         writelines("function gs_vendor_fcn(), gs_vendor_pub(), " + ...
            "gs_vendor_fex(), gs_vendor_root(), end", ...
            fullfile(tb, "+gsv", "gs_vendor_fcn.m"))

         [installed, sources] = groupstats.internal.vendordependencies( ...
            tb, src, Explicit = string.empty());

         license = fullfile(tb, "+gsv", "private", "gs_vendor_fex_LICENSE.txt");
         returned = {any(installed == fullfile("+gsv", "private", ...
            "gs_vendor_fex_LICENSE.txt")); isfile(license); ...
            string(fileread(license)); ...
            any(endsWith(sources, fullfile("fex", "license.txt"))); ...
            any(installed == fullfile("+gsv", "private", ...
            "gs_vendor_pub_LICENSE.txt")); ...
            any(groupstats.internal.vendoredfiles(tb) == license); ...
            any(installed == fullfile("+gsv", "private", "gs_vendor_root.m")); ...
            any(installed == fullfile("+gsv", "private", ...
            "gs_vendor_root_LICENSE.txt"))};
         expected = {true; true; ...
            "Copyright (c) 2010, Someone. All rights reserved." + newline; ...
            true; false; true; true; false};
         testCase.verifyEqual(returned, expected);
      end

   end

   methods (Access = private)

      function [tb, src] = makeVendorFixture(testCase)
         %MAKEVENDORFIXTURE A toolbox tree and a source tree for vendoring.
         %
         % tb/+gsv/gs_vendor_fcn.m calls gs_vendor_pub; tb/+gsv/+internal/
         % gs_vendor_tool.m calls gs_vendor_int, which calls
         % gs_vendor_deep; src/lib also holds gs_vendor_explicit. The
         % source folder goes on the path for the test, so the fixture
         % resolves like a checkout the caller has activated.

         tb = fullfile(testCase.ScratchDir, "tb");
         src = fullfile(testCase.ScratchDir, "src");
         mkdir(fullfile(tb, "+gsv", "+internal"))
         mkdir(fullfile(src, "lib"))
         writelines("function gs_vendor_fcn(), gs_vendor_pub(), end", ...
            fullfile(tb, "+gsv", "gs_vendor_fcn.m"))
         writelines("function gs_vendor_tool(), gs_vendor_int(), end", ...
            fullfile(tb, "+gsv", "+internal", "gs_vendor_tool.m"))
         writelines("function gs_vendor_pub(), end", ...
            fullfile(src, "lib", "gs_vendor_pub.m"))
         writelines("function gs_vendor_int(), gs_vendor_deep(), end", ...
            fullfile(src, "lib", "gs_vendor_int.m"))
         writelines("function gs_vendor_deep(), end", ...
            fullfile(src, "lib", "gs_vendor_deep.m"))
         writelines("function gs_vendor_explicit(), end", ...
            fullfile(src, "lib", "gs_vendor_explicit.m"))
         addpath(tb, fullfile(src, "lib"))
         testCase.addTeardown(@() rmpath(tb, fullfile(src, "lib")))
      end

      function shadowWeb(testCase)
         %SHADOWWEB Put a web function on the path that reports its call.
         %
         % help hands a page to web, which would open a browser. The shadow
         % errors instead, so a test sees whether web was reached and no
         % browser opens. The folder leaves the path at teardown.

         folder = fullfile(testCase.ScratchDir, "shadowweb");
         mkdir(folder)
         writelines([
            "function varargout = web(varargin)"
            "   setappdata(groot, 'groupstats_test_web', varargin{1})"
            "   error('groupstats_test:webCalled', 'web was called')"
            "end"
            ], fullfile(folder, "web.m"))
         testCase.applyFixture( ...
            matlab.unittest.fixtures.PathFixture(folder));
         testCase.addTeardown(@() rmappdata(groot, 'groupstats_test_web'));
         setappdata(groot, 'groupstats_test_web', "")
      end

      function tb = copyToolbox(testCase)
         %COPYTOOLBOX Copy the toolbox folder into the scratch folder.
         %
         % A tool that rewrites files under the toolbox runs on the copy,
         % so the working tree is never written.

         tb = groupstats.test.copytoolbox( ...
            fullfile(testCase.ScratchDir, "toolbox"));
      end

      function file = liveScriptFixture(~)
         %LIVESCRIPTFIXTURE The path of the fixture live script.
         %
         % tests/fixtures/gs_livescript.mlx calls gs_live_inside and
         % gs_live_outside. The path comes from this file, so the suite
         % runs from any folder.

         file = fullfile(fileparts(mfilename('fullpath')), "fixtures", ...
            "gs_livescript.mlx");
      end

      function [inside, outside] = placeLiveScriptHelpers(testCase, tb)
         %PLACELIVESCRIPTHELPERS Build a scratch toolbox around the fixture.
         %
         % The fixture live script goes into tb/examples, gs_live_inside
         % into tb, and gs_live_outside beside tb. Both helpers go on the
         % path for the case, so the scan can resolve the calls, and come
         % off at teardown. The two helper paths are returned so a case
         % can tell which the scan reported.

         mkdir(fullfile(tb, "examples"))
         copyfile(testCase.liveScriptFixture(), fullfile(tb, "examples"))
         inside = string(fullfile(tb, "gs_live_inside.m"));
         outside = string(fullfile(testCase.ScratchDir, "gs_live_outside.m"));
         writelines("function gs_live_inside(), end", inside)
         writelines("function gs_live_outside(), end", outside)
         testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
            [string(tb), string(testCase.ScratchDir)]));
      end

      function [proj, src] = makeLocalInstallFixture(testCase)
         %MAKELOCALINSTALLFIXTURE A project calling a helper in a source tree.
         %
         % proj/gs_test_caller.m calls gs_test_helper, which lives in
         % src/lib. Both folders go on the path for the test and come off
         % at teardown, so the static scan can resolve the call.

         proj = fullfile(testCase.ScratchDir, "proj");
         src = fullfile(testCase.ScratchDir, "src");
         mkdir(proj)
         mkdir(fullfile(src, "lib"))
         writelines("function gs_test_caller(), gs_test_helper(), end", ...
            fullfile(proj, "gs_test_caller.m"))
         writelines("function gs_test_helper(), end", ...
            fullfile(src, "lib", "gs_test_helper.m"))
         addpath(proj, fullfile(src, "lib"))
         testCase.addTeardown(@() rmpath(proj, fullfile(src, "lib")))
      end
   end

end

function callWithNoOutput(fcn, varargin)
   %CALLWITHNOOUTPUT Invoke FCN as a statement, requesting no output.

   fcn(varargin{:});
end
