function plan = buildfile

   % Create a plan from the task functions
   plan = buildplan(localfunctions);

   % Make the "test" task the default task in the plan
   plan.DefaultTasks = "test";

   % Make the "release" task dependent on the "check", "test", and "docs"
   % tasks, so a release ships pages built from the code it packages. The
   % "dependencies" task is not a dependency: it copies files into the
   % tree, so the maintainer runs it after a change adds or removes a call
   % into matfunclib, then checks the result in.
   plan("release").Dependencies = ["check" "test" "docs"];

   % Notes: buildplan accepts a cell vector of function handles. So you can
   % send localfunctions to it, or something like this:
   % buildplan({@compileTask,@testTask})
   %
   % Task functions are local functions in the build file whose names end with
   % the word "Task", which is case insensitive. A task function must accept a
   % TaskContext object as its first input, even if the task ignores it.
   %
   % The build tool generates task names from task function names by removing
   % the "Task" suffix. For example, a task function testTask results in a task
   % named "test". Additionally, the build tool treats the first help text line,
   % often called the H1 line, of the task function as the task description. The
   % code in the task function corresponds to the action performed when the task
   % runs.

end

function checkTask(context)
   % Identify code issues and confirm the toolbox is self-contained
   %
   % Checks every file the toolbox ships, including the demos, and the
   % tests. A repo-root sweep also reads sandbox/ scratch, which this
   % project does not style.
   %
   % The bar is zero issues. Keep it there: fix what a change introduces
   % rather than adding a suppression.
   %
   % The last assertion is that no shipped file calls a function outside
   % the package. Run the dependencies task to vendor a new call.
   %
   root = context.Plan.RootFolder;
   toolboxfolder = fullfile(root, "toolbox");
   files = [
      listMFiles(toolboxfolder)
      listMFiles(fullfile(root, "tests"))
      ];

   % permutest is vendored third-party code with its own license.
   files = files(~endsWith(files, fullfile("+groupstats", "private", ...
      "permutest.m")));

   % The vendored matfunclib copies are byte-identical to their source and
   % are not restyled here, the same rule permutest follows. The
   % dependencies task lists them.
   addpath(toolboxfolder)
   files = files(~ismember(files, ...
      groupstats.internal.vendoredfiles(toolboxfolder)));

   issues = codeIssues(files);

   assert(isempty(issues.Issues), formattedDisplayText( ...
      issues.Issues(:, ["Location" "Severity" "Description"])))

   % A suppression hides an issue instead of fixing it, so none is
   % allowed in the files checked above.
   suppressed = files(arrayfun(@(f) any(contains(readlines(f), "%#ok")), ...
      files));
   assert(isempty(suppressed), "These files carry a %#ok suppression: " ...
      + strjoin(suppressed, ", "))

   % A file the package needs and does not ship would fail on a clean
   % path. checkdependencies scans toolbox/ against itself.
   missing = groupstats.internal.checkdependencies();
   assert(isempty(missing), ...
      "The toolbox calls files it does not ship. Run " + ...
      "buildtool dependencies. Missing: " + strjoin(missing, ", "))
end

function dependenciesTask(context)
   % Vendor the matfunclib files the toolbox calls
   %
   % Copies each required file from the local matfunclib checkout into the
   % private folder its callers reach, with no network, and writes
   % toolbox/vendored.txt, the list the check task excludes from lint.
   % groupstats.internal.vendordependencies does the work and documents
   % the three destinations. Run this task after a change adds or removes
   % a call into matfunclib, then run check, and commit the copies with
   % the change.

   arguments
      context (1, 1) matlab.buildtool.TaskContext
   end

   toolboxfolder = fullfile(context.Plan.RootFolder, "toolbox");
   addpath(toolboxfolder)

   installed = groupstats.internal.vendordependencies(toolboxfolder);
   fprintf("Vendored %d files; see %s\n", numel(installed), ...
      fullfile(toolboxfolder, "vendored.txt"))
end

function contentsTask(context)
   % Regenerate every Contents.m
   %
   % Run this after adding, renaming, or removing a function, so the
   % generated listings do not go stale.

   addpath(fullfile(context.Plan.RootFolder, "toolbox"))
   groupstats.internal.makecontents("-nobackup");
end

function files = listMFiles(folder)
   % Return every m-file under a folder, as a string column.

   found = dir(fullfile(folder, "**", "*.m"));
   files = string(fullfile({found.folder}, {found.name}))';
end

function testTask(context)
   % Run unit tests
   %
   % Runs the test classes in tests/.
   %
   % Set the environment variable GROUPSTATS_COVERAGE to a folder path to also
   % write an HTML code coverage report there. The report is diagnostic. No
   % coverage threshold gates this task.

   import matlab.unittest.TestSuite
   import matlab.unittest.TestRunner
   import matlab.unittest.plugins.CodeCoveragePlugin
   import matlab.unittest.plugins.codecoverage.CoverageReport

   % The tests call the toolbox by its namespaced name.
   addpath(fullfile(context.Plan.RootFolder, "toolbox"))

   suite = TestSuite.fromFolder(fullfile(context.Plan.RootFolder, "tests"));
   runner = TestRunner.withTextOutput(OutputDetail = "terse");

   coveragefolder = getenv("GROUPSTATS_COVERAGE");
   if ~isempty(coveragefolder)
      runner.addPlugin(CodeCoveragePlugin.forPackage("groupstats", ...
         IncludingSubpackages = true, ...
         Producing = CoverageReport(coveragefolder, ...
         MainFile = "groupstatsCoverage.html")))
   end

   results = runner.run(suite);
   assertSuccess(results);
end

function docsTask(context)
   % Publish the Help browser pages into toolbox/docs/html

   % makedocs publishes the demos, so the toolbox and the examples must be
   % on the path; the pages go to the help_location toolbox/info.xml names.
   root = context.Plan.RootFolder;
   addpath(fullfile(root, "toolbox"))
   addpath(fullfile(root, "toolbox", "examples"))
   groupstats.internal.makedocs()
end

function releaseTask(context)
   % Create toolbox release

   root = context.Plan.RootFolder;
   releasefolder = fullfile(root, "release");

   % releaseoptions reads the Package Toolbox task and sets the version. It
   % is a namespace function rather than a local one here, so a test can read
   % the same options without packaging a toolbox.
   addpath(fullfile(root, "toolbox"))
   opts = groupstats.internal.releaseoptions(root);

   % Create the release directory, if needed
   if ~isfolder(releasefolder)
      mkdir(releasefolder)
   end

   % Package the toolbox, then read the version back from the package: a
   % stale project field or a wrong output file cannot ship unnoticed.
   matlab.addons.toolbox.packageToolbox(opts);
   groupstats.internal.assertpackagedversion(opts.OutputFile, ...
      opts.ToolboxVersion)
end
