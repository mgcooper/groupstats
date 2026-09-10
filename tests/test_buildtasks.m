classdef test_buildtasks < matlab.unittest.TestCase
   %TEST_BUILDTASKS Test the build tasks that need no packaging release.
   %
   % test_buildfile reads the Package Toolbox task, which exists from
   % R2025a, so that class is filtered on older releases. The dependencies
   % task needs only buildtool, and every supported release runs these
   % cases.
   %
   % See also: buildfile, groupstats.internal.vendordependencies

   properties
      % Repository root, derived from this file rather than from pwd, so the
      % suite runs from any folder.
      Root
   end

   methods (TestMethodSetup)

      function findRoot(testCase)
         %FINDROOT Resolve the repository root from this file's location.

         % The root comes from the test file, not from pwd, so the cases
         % find the buildfile from any working folder.
         testCase.Root = fileparts(fileparts(mfilename('fullpath')));
      end
   end

   methods (Test)

      function testDependenciesTaskIsInThePlan(testCase)
         % The dependencies task vendors the matfunclib copies. It is
         % registered with its H1 description and is not a dependency of
         % release, because it copies files into the tree.

         % The repository's own buildfile builds the plan. Loading it
         % through the MATLAB Project would open the project, which is not
         % what this case is about.
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(testCase.Root)
         plan = buildfile();

         returned = plan("dependencies").Description;
         expected = "Vendor the matfunclib files the toolbox calls";
         testCase.verifyEqual(returned, expected);

         returned = ismember("dependencies", ...
            string(plan("release").Dependencies));
         expected = false;
         testCase.verifyEqual(returned, expected);

         % The docs task is: a release ships pages built from its code.
         returned = string(plan("release").Dependencies);
         expected = ["check", "test", "docs"];
         testCase.verifyEqual(returned, expected);
         returned = plan("docs").Description;
         expected = "Publish the Help browser pages into toolbox/docs/html";
         testCase.verifyEqual(returned, expected);
      end

      function testDependenciesTaskRunsAndLeavesTheListUnchanged(testCase)
         % Running the task refreshes every copy from the local matfunclib
         % checkout and writes the same list again. It runs on a scratch
         % copy of the repository, outside the worktree, so the checkout
         % is never written. The run needs a matfunclib checkout, so it is
         % filtered where there is none.

         addpath(fullfile(testCase.Root, "toolbox"))
         testCase.assumeTrue(~isempty(which("dealout")) || ...
            strlength(getenv("MATLAB_FUNCTION_PATH")) > 0, ...
            "The dependencies task needs a matfunclib checkout.");

         % The cleanup is registered before the first write, so a failure
         % between the two never leaks the scratch root.
         scratch = string(tempname());
         testCase.addTeardown(@() removeScratch(scratch));
         mkdir(scratch)

         % The task adds the scratch toolbox to the path. Put the path back
         % afterwards, so the copy neither shadows the checkout nor warns
         % when its folder goes.
         savedpath = path();
         testCase.addTeardown(@() path(savedpath));
         copyfile(fullfile(testCase.Root, "buildfile.m"), ...
            fullfile(scratch, "buildfile.m"))
         groupstats.test.copytoolbox(fullfile(scratch, "toolbox"));
         listbefore = readlines(fullfile(scratch, "toolbox", "vendored.txt"));

         % The scratch copy's own buildfile builds the plan, with the
         % scratch folder as its root. Loading a plan through the MATLAB
         % Project would open the project, which the copy is not.
         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(scratch)
         plan = buildfile();

         returned = string(plan.RootFolder);
         expected = scratch;
         testCase.verifyEqual(returned, expected);

         result = run(plan, "dependencies");

         returned = result.Failed;
         expected = false;
         testCase.verifyEqual(returned, expected);

         returned = readlines(fullfile(scratch, "toolbox", "vendored.txt"));
         expected = listbefore;
         testCase.verifyEqual(returned, expected);
      end


      function testCheckTaskFailsOnASuppression(testCase)
         % check asserts that no analyzer suppression marker remains in the
         % files it lints, so a shipped file that carries one fails the
         % task. The run is on a scratch copy, outside the worktree. The
         % marker is built from two pieces, so this test file never holds
         % it and passes the same scan.

         % The cleanup is registered before the first write, so a failure
         % between the two never leaks the scratch root.
         scratch = string(tempname());
         testCase.addTeardown(@() removeScratch(scratch));
         mkdir(scratch)
         savedpath = path();
         testCase.addTeardown(@() path(savedpath));
         copyfile(fullfile(testCase.Root, "buildfile.m"), ...
            fullfile(scratch, "buildfile.m"))
         groupstats.test.copytoolbox(fullfile(scratch, "toolbox"));

         % A clean function apart from the marker, so lint itself raises
         % nothing and only the suppression assertion can fail.
         marker = "%#" + "ok<NASGU>";
         writelines([
            "function gs_check_suppressed()"
            "   %GS_CHECK_SUPPRESSED A function that carries a suppression."
            ""
            "   % The value is unused on purpose, and the marker hides it."
            "   unused = 1; " + marker
            "end"
            ], fullfile(scratch, "toolbox", "+groupstats", ...
            "gs_check_suppressed.m"))

         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(scratch)
         plan = buildfile();

         result = run(plan, "check");

         returned = result.Failed;
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testCheckTaskFailsOnAMissingVendoredCopy(testCase)
         % check asserts the package is self-contained. A listed copy that
         % is not on disk is a missing file, so check fails. The run is on
         % a scratch copy, outside the worktree.

         % The cleanup is registered before the first write, so a failure
         % between the two never leaks the scratch root.
         scratch = string(tempname());
         testCase.addTeardown(@() removeScratch(scratch));
         mkdir(scratch)

         % The task adds the scratch toolbox to the path. Put the path back
         % afterwards, so the copy neither shadows the checkout nor warns
         % when its folder goes.
         savedpath = path();
         testCase.addTeardown(@() path(savedpath));
         copyfile(fullfile(testCase.Root, "buildfile.m"), ...
            fullfile(scratch, "buildfile.m"))
         groupstats.test.copytoolbox(fullfile(scratch, "toolbox"));
         % The deleted file is a listed license, which no scan resolves:
         % with matfunclib on the path, a deleted function copy would
         % resolve to the matfunclib file and fail check for that reason,
         % not through the listed-file guard this test covers.
         listed = groupstats.internal.vendoredfiles( ...
            fullfile(scratch, "toolbox"));
         license = listed(endsWith(listed, "_LICENSE.txt"));
         testCase.assertNotEmpty(license, "vendored.txt lists no license.");
         delete(license(1))

         here = pwd;
         testCase.addTeardown(@() cd(here));
         cd(scratch)
         plan = buildfile();
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'groupstats:checkdependencies:missingDependencies'));

         result = run(plan, "check");

         returned = result.Failed;
         expected = true;
         testCase.verifyEqual(returned, expected);
      end
   end
end

function removeScratch(folder)
   %REMOVESCRATCH Remove an owned scratch root, if it was created.

   if isfolder(folder)
      rmdir(folder, "s")
   end
end
