function plan = buildfile

   % Create a plan from the task functions
   plan = buildplan(localfunctions);

   % Make the "test" task the default task in the plan
   plan.DefaultTasks = "test";

   % Make the "release" task dependent on the "check" and "test" tasks
   plan("release").Dependencies = ["check" "test"];

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
   %
   % I am not sure if projectfile can be adapted using buildplan

end

function checkTask(context)
   % Identify code issues
   %
   % Checks every file the toolbox ships, including the demos, and the
   % tests. A repo-root sweep also reads sandbox/ scratch, which this
   % project does not style.
   %
   % The bar is zero issues. Keep it there: fix what a change introduces
   % rather than adding a suppression.
   %
   root = context.Plan.RootFolder;
   files = [
      listMFiles(fullfile(root, "toolbox"))
      listMFiles(fullfile(root, "tests"))
      ];

   % permutest is vendored third-party code with its own license.
   files = files(~contains(files, fullfile("+groupstats", "permutest")));

   % demo_groupbayes_counts.m holds the author's scratch work verbatim, so
   % that production code can stay clean without losing it. Its subfunctions
   % print at a debug prompt and assign values nothing reads, which is what
   % they were written to do.
   files = files(~endsWith(files, fullfile("examples", ...
      "demo_groupbayes_counts.m")));

   issues = codeIssues(files);

   assert(isempty(issues.Issues), formattedDisplayText( ...
      issues.Issues(:, ["Location" "Severity" "Description"])))
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

   % Package the toolbox
   matlab.addons.toolbox.packageToolbox(opts);
end
