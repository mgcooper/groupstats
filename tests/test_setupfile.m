classdef test_setupfile < matlab.unittest.TestCase
   %TEST_SETUPFILE Test the project setup file.
   %
   % setupfile.m adds the project paths, sets the project environment
   % variables, and runs every m-file in userhooks/. A hook that never runs
   % leaves no trace, so these tests check that each hook is found and that a
   % hook which fails says so.
   %
   % See also: setupfile, config

   properties
      % A temporary project folder, and the environment to put back.
      ProjectPath
      OriginalPath
      OriginalEnv
   end

   methods (TestMethodSetup)

      function makeProject(testCase)
         % Build a project folder holding one hook that works and one that
         % fails. Both write to the folder, so a hook that never ran is
         % visible as a missing file.

         testCase.ProjectPath = tempname();
         mkdir(fullfile(testCase.ProjectPath, 'userhooks'));

         writelines([
            "function hook_ok()"
            "   %HOOK_OK Record that this hook ran."
            "   writelines(""ran"", fullfile(fileparts(mfilename(""fullpath"")), "".."", ""ran.txt""))"
            "end"
            ], fullfile(testCase.ProjectPath, 'userhooks', 'hook_ok.m'));

         writelines([
            "function hook_bad()"
            "   %HOOK_BAD Fail, to exercise the warning in setupfile."
            "   error('test:hook:boom', 'hook failed on purpose')"
            "end"
            ], fullfile(testCase.ProjectPath, 'userhooks', 'hook_bad.m'));

         testCase.addTeardown(@() rmdir(testCase.ProjectPath, 's'));
      end

      function prepareEnvironment(testCase)
         % setupfile changes the path, the environment variables, and a
         % preference. Put all three back after every test.

         testCase.OriginalPath = path();
         testCase.addTeardown(@() path(testCase.OriginalPath));

         % The test runner makes tests/ the current folder, and the toolbox
         % template ships its own setupfile.m. Put this repository first so
         % the calls below reach the file under test.
         reporoot = fileparts(fileparts(mfilename('fullpath')));
         addpath(reporoot, '-begin');

         names = ["MATLAB_ACTIVE_PROJECT", "MATLAB_ACTIVE_PROJECT_PATH", ...
            "MATLAB_ACTIVE_PROJECT_DATA_PATH", ...
            "MATLAB_ACTIVE_PROJECT_TESTS_PATH", ...
            "MATLAB_ACTIVE_PROJECT_TOOLBOX_PATH"];
         testCase.OriginalEnv = arrayfun(@(n) string(getenv(n)), names);
         testCase.addTeardown(@() restoreEnv(names, testCase.OriginalEnv));

         testCase.addTeardown(@() rmprefIfPresent('testproject'));
      end
   end

   methods (Test)

      function testRunsEveryUserHook(testCase)
         % The hook path must include the userhooks folder. Joining the
         % project path to the file name alone names a file that does not
         % exist, and no hook runs.

         setupfile('testproject', testCase.ProjectPath);

         returned = isfile(fullfile(testCase.ProjectPath, 'ran.txt'));

         testCase.verifyTrue(returned);
      end

      function testWarnsWhenAHookFails(testCase)
         % A broken hook must not stop the project from opening, and must
         % not fail without a trace.

         testCase.verifyWarning( ...
            @() setupfile('testproject', testCase.ProjectPath), ...
            'groupstats:setupfile:userHookFailed');
      end

      function testAddsTheProjectPath(testCase)
         % Opening the project must make its code callable.

         setupfile('testproject', testCase.ProjectPath);

         returned = contains(path(), testCase.ProjectPath);

         testCase.verifyTrue(returned);
      end

      function testSetsTheProjectEnvironmentVariables(testCase)
         % Scripts and hooks read these variables to find the project.

         setupfile('testproject', testCase.ProjectPath);

         testCase.verifyEqual(getenv('MATLAB_ACTIVE_PROJECT'), 'testproject');
         testCase.verifyEqual(getenv('MATLAB_ACTIVE_PROJECT_PATH'), ...
            testCase.ProjectPath);
      end

      function testRecordsTheInstallPath(testCase)
         % groupstats.internal.installpath reads this preference.

         setupfile('testproject', testCase.ProjectPath);

         returned = getpref('testproject', 'install_path');

         testCase.verifyEqual(returned, testCase.ProjectPath);
      end

   end
end

function restoreEnv(names, values)
   %RESTOREENV Put each environment variable back to its earlier value.

   for n = 1:numel(names)
      setenv(names(n), values(n));
   end
end

function rmprefIfPresent(group)
   %RMPREFIFPRESENT Remove a preference group when it exists.

   if ispref(group)
      rmpref(group);
   end
end

