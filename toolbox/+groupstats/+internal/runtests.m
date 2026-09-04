function varargout = runtests(varargin)
   %RUNTESTS Run all tests in the test suite.
   %
   %  result = groupstats.internal.runtests()
   %  result = groupstats.internal.runtests(_, 'Debug', true)
   %
   % Description
   %  result = groupstats.internal.runtests() Runs all tests in the tests/
   %  and/or test/ folder.
   %
   %  result = groupstats.internal.runtests(TESTS) Runs all tests in the
   %  specified folder(s).
   %
   %  result = groupstats.internal.runtests(_, 'Debug', true) Runs all tests in
   %  verbose debug mode.
   %
   % Note: The only name-value argument currently supported is 'Debug', and in
   % this mode, debugging is configured using the following plugins:
   %
   %  matlab.unittest.Verbosity
   %  matlab.unittest.plugins.StopOnFailuresPlugin
   %
   % Thus the results and/or behavior may differ from those returned by
   % runtests(tests, 'Debug', true).
   %
   % For a coverage report, run `buildtool test` with the environment
   % variable GROUPSTATS_COVERAGE set to a folder path.
   %
   % See also: runtests, runperf, testsuite

   % Parse the test/ path(s) and optional name-value pairs
   if mod(nargin, 2) == 0
      tests = {};
      kwargs = varargin;
   else
      tests = varargin(1);
      kwargs = varargin(2:end);
   end
   tests = parseTestPaths(tests);

   % Run each test suite
   for n = numel(tests):-1:1
      result{n} = runOneSuite(tests{n}, kwargs{:});
   end

   % Parse output. A folder can hold m-files and still define no TestCase,
   % which +groupstats/+test does: it ships runners, helpers, and fixtures.
   % That suite comes back empty, and keeping it would leave the output a
   % cell of TestResult arrays rather than one TestResult array.
   result = result(~cellfun(@isempty, result));
   if isscalar(result)
      result = result{1};
   elseif ~isempty(result)
      result = [result{:}];
   end
   if nargout
      varargout{1} = result;
   end
end

function result = runOneSuite(testname, varargin)

   % Import necessary classes
   import matlab.unittest.TestSuite
   import matlab.unittest.TestRunner
   import matlab.unittest.Verbosity
   import matlab.unittest.plugins.StopOnFailuresPlugin

   % Note: testname is always a test folder path. On R2025b, fromFolder on
   % a +pkg folder and fromPackage with its dotted name return the same
   % suite, so one fromFolder call covers packages too.
   suite = TestSuite.fromFolder(testname, 'IncludingSubfolders', true);

   if nargin < 2
      % Run parameterized test suite
      result = transpose(suite.run());

      % Print the results to the screen
      for n = 1:numel(result)
         if result(n).Passed == true
            disp(['Passed Test ' int2str(n)])
         else
            disp(['Failed Test ' int2str(n)])
         end
      end
   else
      % For verbose and/or debugging
      validatestring(lower(varargin{1}), {'debug'}, mfilename)

      % Create a test runner with detailed text output
      runner = TestRunner.withTextOutput('Verbosity', Verbosity.Detailed);

      % Add a plugin to stop execution and enter debug mode when a test fails
      runner.addPlugin(StopOnFailuresPlugin)

      % Run the test suite using the configured runner
      result = runner.run(suite);
   end

end

function tests = parseTestPaths(tests)

   if isempty(tests)

      % Define the default test/ folders, where <+pkg> is this toolbox's
      % package folder:
      % projectpath/test
      % projectpath/tests
      % projectpath/toolbox/<+pkg>/+test
      % projectpath/toolbox/<+pkg>/+tests
      %
      % Derive the package folder rather than hard-coding it, so a project
      % stamped from the toolbox template finds its own test package without
      % editing this file.
      [~, withplus] = mpackagename();

      tests_ = fullfile(projectpath(), ...
         {'test', ...
         'tests', ...
         fullfile('toolbox', withplus, '+test'), ...
         fullfile('toolbox', withplus, '+tests')} ...
         );

      % Determine which of the default test folders exist
      tests = tests_(isfolder(tests_));

      % Keep only the folders that hold an m-file. An empty folder contributes
      % an empty result, which makes the output a cell array of TestResult
      % arrays rather than one TestResult array.
      hasmfiles = cellfun( ...
         @(folder) ~isempty(dir(fullfile(folder, '**', '*.m'))), tests);
      tests = tests(hasmfiles);

      if isempty(tests)
         error(['No test/ or tests/ folder found in top level directory ' ...
            'or toolbox +test directory. ' ...
            'Supply the path as the first argument to this function'])
      end
   else
      % Cast char or string to cellstr
      if isStringScalar(tests)
         tests = {char(tests)};
      elseif isstring(tests)
         tests = cellstr(tests);
      end

      % The suite comes from TestSuite.fromFolder, so every entry must be a
      % folder. Assert that here rather than let fromFolder fail deeper in.
      % Non-folder test specifiers are not supported.
      assert(all(isfolder(tests)))
   end
end
