# Group Stats Toolbox

`groupstats` is a MATLAB&reg; toolbox for grouped statistics on tables.
Thanks for checking it out.

If you're just getting started, here's what
we recommend:

- First, open the live script `toolbox/gettingStarted.m` for instructions
  on installing the toolbox, or see [Installation](#installation).
- Next, work through the examples, beginning with
  `toolbox/examples/usingGroupStats.m`.
- Use `groupstats.help()` to open the toolbox pages in the Help browser, or
  pass a function name to see it's help page:
  `groupstats.help("groupsummary")`. The help pages are under Supplemental
  Software in the Help browser once the package is installed.

## Why Group Stats?

Data often falls naturally into groups: measurements labeled by site, scenario,
month, or treatment. MATLAB provides built-in tools to summarize and chart
grouped data. GroupStats provides a consistent API around those tools, allowing
you to quickly summarize and plot tabular data by group in fewer lines of code.
Every function takes a table and the names of its grouping variables, and every
function lives in the `+groupstats` namespace.

## Toolbox features

Grouped statistics for MATLAB tables:

- Group-wise summary statistics (`groupstats.groupsummary`)
- Group-wise frequencies and percentages, including group sets
  (`groupstats.grouppercent`)
- Group-wise conditional (Bayesian) probabilities (`groupstats.groupbayes`)
- Group comparison by rank-sum, sign-rank, or permutation test, with an
  optional bootstrapped median difference (`groupstats.groupcompare`), and
  the grouped samples it reads (`groupstats.groupsamples`)
- Row selection by group membership (`groupstats.groupselect`)
- Apply a function to each group in a table and recombine the results
  (`groupstats.groupmap`)

Charts for categorical (grouped) table data:

- Bar and box charts grouped along the x-axis and colored within groups
  (`groupstats.barchartcats`, `groupstats.boxchartcats`)
- Grouped scatter charts and histograms (`groupstats.scatter`,
  `groupstats.histogram`)

## Requirements

- MATLAB R2021a or later. The code uses `arguments` blocks (R2019b),
  `props.?Class` property validation (R2021a), and `name = value` syntax
  (R2021a). The test suite passes on R2024b and R2025b, the same releases
  the toolbox is developed on. Older releases are untested.
- `groupstats.groupcompare` needs the Statistics and Machine Learning
  Toolbox for `ranksum`, `signrank`, `tinv`, and `quantile`. Its
  `Test="permutation"` option also needs the Image Processing
  Toolbox.
- `groupstats.scatter` needs the Statistics and Machine Learning Toolbox
  for `gscatter`. The rest of the toolbox requires only base MATLAB.

## Installation

Use any of these methods to install the toolbox:

- Add the `toolbox/` folder to the path:

  ```matlab
  addpath(fullfile('/path/to/groupstats', 'toolbox'))
  ```

- [Build and install](#building) the toolbox package. From the repository root:

  ```matlab
  buildtool release
  ```

  Then double-click `release/GroupStatsToolbox.mltbx`.

- Run `setupfile.m` from the repository root. It adds every folder to the path
  and sets the project environment variables. It's a developer convenience,
  most users won't need it.

## Building

The build tasks are in `buildfile.m`, run it from the repository root.
Building requirements: `buildtool` (R2022b), `codeIssues` (R2023a), and
R2025a for `docs` and `release`. The docs build exports the plain-text
live scripts, and the release reads the Package Toolbox task.

```matlab
buildtool check          % run codeIssues on the code and the tests
buildtool test           % run the test suite in tests/
buildtool contents       % regenerate every Contents.m file
buildtool dependencies   % refresh dependencies from a local checkout (developer only; see below)
buildtool docs           % publish the Help browser pages into toolbox/docs/html
buildtool release        % check, test, docs, then package release/GroupStatsToolbox.mltbx
```

`buildtool dependencies` resolves dependencies from a local [`matfunclib`](https://github.com/mgcooper/matfunclib)
checkout using the `MATLAB_FUNCTION_PATH` environment variable.
`buildtool docs` uses m2html from the `GROUPSTATS_M2HTML` environment variable,
or from the path, and needs R2025a or later. The pages it writes are not in the
repository; `buildtool release` builds them before it packages, and the
packaged toolbox carries them. To find missing dependencies, try:

```matlab
groupstats.internal.checkdependencies()
```

To run the tests without `buildtool`:

```matlab
addpath('toolbox'); results = runtests('tests'); assertSuccess(results)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Open an issue at
<https://github.com/mgcooper/groupstats/issues> before sending a change.
The changes in each release are described in [CHANGELOG.md](CHANGELOG.md).

## License

See `license.txt` in this repository.
