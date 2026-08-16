# Group Stats Toolbox

`groupstats` is a MATLAB&reg; toolbox for grouped statistics on tables.

## Getting Started

Thanks for checking it out. If you're just getting started, here's what we recommend:

* First, open the live script `gettingStarted.mlx` for instructions on installing the toolbox.
* Next, work through the tutorials, beginning with `toolbox/examples/usingGroupStats.mlx`.
* Then run the demos in `toolbox/examples/`. The chart demos open one figure
  per option, so the effect of each option is visible side by side:

  ```matlab
  addpath('toolbox'); addpath('toolbox/examples')

  demo_barchartcats     % grouped bar charts, one figure per option
  demo_boxchartcats     % grouped box charts
  demo_scatter          % grouped scatter charts
  demo_histogram        % grouped categorical histograms

  demo_all              % every demo, figures left open
  demo_all("-close")    % every demo, closing between each
  ```

  The remaining demos print tables: `demo_groupmap`, `demo_groupbayes`,
  `demo_bayes`, `demo_pairwise_bayes`, and `demo_groupbayes_counts`.

To get more help:

* `groupstats.help()`

To contribute:

* Open an issue: https://github.com/mgcooper/groupstats/issues

To run the test suite:

* Tests are located in `tests/`
* From a matlab command window, type `runtests('tests')` and press enter.

* To build the toolbox installation file, run `buildtool release`. It is
  written to `release/`, which is not part of the repository.

## Installation

Choose one:

* Add the `toolbox/` folder to the path:

  ```matlab
  addpath(fullfile('/path/to/groupstats', 'toolbox'))
  ```

* Or run `setupfile.m` from the repository root, which adds every folder and
  sets the project environment variables.

* Or build and install the toolbox package. `release/` is not in the
  repository, so build it first:

  ```matlab
  buildtool release
  ```

  Then double-click `release/GroupStatsToolbox.mltbx`.

Call the functions by their namespace, such as `groupstats.groupsummary`.

## Requirements

* MATLAB. The test suite passes on R2024b and R2025b, which are the releases
  the toolbox is developed against. Older releases are untested. The shipped
  code uses `arguments` blocks (R2019b), `props.?Class` property validation
  (R2021a), and name-value syntax in the form `name = value` (R2021a).
  R2021a is therefore the earliest release that can run it.
* Building the toolbox needs more than running it does: `buildtool` (R2022b)
  and `codeIssues` (R2023a). Packaging a release needs R2025a, which added
  the Package Toolbox task `buildtool release` reads from the MATLAB
  Project. Running the toolbox does not need R2025a.
* `groupstats.groupdifference` needs the Statistics and Machine Learning
  Toolbox, for `signrank` and `ranksum`. `groupstats.scatter` needs it too,
  for `gscatter`. The rest of the toolbox needs no MathWorks toolbox beyond
  MATLAB.
* `toolbox/+groupstats/permutest/` is vendored third-party code, kept for a
  permutation test. No function in this toolbox calls it yet.

Some functions call helpers from the author's other repositories, which must
be on the path to use those functions:

All of them live in `matfunclib`:

* `stacktables`, `dealout`, `mcallername`, `tablecompletions` (tab completion
  reads it), `bootdiff` (`groupstats.groupdifference` calls it)
* `defaultcolors` and `distinguishable_colors`, in `matfunclib/libplot`

To list the ones that are missing:

```matlab
groupstats.internal.checkdependencies()
```

## Toolbox Features

Grouped statistics for MATLAB tables:

* Group-wise summary statistics (`groupstats.groupsummary`)
* Group-wise frequencies and percentages, including groupsets (`groupstats.grouppercent`)
* Group-wise conditional (Bayesian) probabilities (`groupstats.groupbayes`)
* Group difference estimation by rank test and bootstrapped median difference (`groupstats.groupdifference`)
* Row selection by group membership (`groupstats.groupselect`)
* Apply a function to each group in a table and recombine the results (`groupstats.groupmap`)

Charts for categorical (grouped) table data:

* Bar and box charts grouped along the x-axis and colored within groups (`groupstats.barchartcats`, `groupstats.boxchartcats`)
* Grouped scatter charts and histograms (`groupstats.scatter`, `groupstats.histogram`)

Every option that takes a fixed set of values reads that set from
`groupstats.namelists`, so the validators and the tab completions cannot
disagree.

## Contributing

Open an issue at https://github.com/mgcooper/groupstats/issues before sending a
change, so the work can be discussed first.

Before you send a change:

* Run the tests: `runtests('tests')`, or `buildtool test`.
* Run the static analysis: `buildtool check`. The bar is zero issues.
* Regenerate the function listings if you added, renamed, or removed a
  function: `buildtool contents`.

The code style is in `STYLE.md` and `STYLE.local.md`.

## License

The license is available in the license.txt file in this GitHub repository.
