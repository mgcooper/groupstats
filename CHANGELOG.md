# Changelog

All notable changes to this toolbox are recorded in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the toolbox follows [Semantic Versioning](https://semver.org/). The
version the package carries is in `toolbox/version.txt`.

## [Unreleased]

### Added

- `groupstats.groupci` returns the confidence interval of each group's
  center as a table, one row per pairing of the cats-chart groupings,
  empty pairings included. `Method="mean"` gives the Student t interval,
  and `Method="median"` gives the notch that `boxchartcats` draws. It
  needs only base MATLAB.
- `demo_groupci` shows the interval table, the notch comparison, and the
  interval error bars.
- `groupstats.groupheatmap`, the fifth chart, draws a built-in
  `HeatmapChart` with one cell per pairing of `xgroupvar` and `cgroupvar`
  members. `Method` sets the cell statistic: mean, median, count, sum, min,
  or max. It takes the member, row-select, merge, and ordering options of
  the cats charts, a container `Parent`, and `HeatmapChart` properties.
- `demo_groupheatmap` shows each method, ordering, a merge, and tiled
  layouts.
- `FitPDF` on `groupstats.histogram`. `FitPDF="normal"` draws each group's
  fitted normal density over its histogram, in the group's color, scaled
  to the `Normalization`.
- `ErrorBar` and `Alpha` on `groupstats.barchartcats`. With
  `PlotError=true`, `ErrorBar="ci"` draws the `groupstats.groupci` interval
  of each bar as its whisker. `"spread"`, the default, keeps the standard
  deviation or interquartile range whisker. `Alpha` sets the level of the
  mean interval.
- `groupstats.groupsummary` takes a bare named bin such as `"month"` for
  one grouping variable, the same as `{"month"}`, as the builtin does.
  With two or more grouping variables, bare text is a `badGroupBins`
  error; give one scheme per variable in a cell.

### Changed

- `groupstats.barchartcats` takes one `Method`. A vector `Method`, which the
  code never handled, is a validation error.
- `groupstats.groupsummary` adds a `Percent_<var>` column only for each
  variable that `GroupSets` names, as its help states. A call without
  `GroupSets` returns `Percent` and no `Percent_<var>` column. Pass
  `GroupSets` to get the within-set percents.
- `groupstats.groupsummary` rejects a grouping variable named `GroupCount`
  or `Percent`, the names of its result columns
  (`groupstats:groupsummary:reservedName`). Rename the variable first.
- `groupstats.grouppercent` rejects a grouping variable named `GroupCount`
  or `Percent` (`groupstats:grouppercent:reservedName`), as
  `groupsummary` does. It read a raw table with a `GroupCount` grouping
  variable as already counted. A categorical or string one raised a type
  error, and a numeric one returned wrong percents. A `Percent` grouping
  variable took the place of the `Percent` share.
- `groupstats.grouppercent` with a `GroupSets` variable outside `groupvars`
  keeps a cellstr group or set column as cellstr, as the count without
  that variable does. It returned string.
- `groupstats.barchartcats`, `boxchartcats`, `histogram`, and `scatter` put
  the legend above the axes in up to three columns. They use fewer columns
  when three would not fit the chart's tile, subplot, or figure. The
  legend text follows the axes font. `barchartcats` and
  `histogram` drew a legend with a fixed font size of 12 at the upper
  left. `scatter` drew it to the right of the axes.
- Chart axis labels come from the table's `VariableDescriptions` and
  `VariableUnits` for the variable, else its name. The `barchartcats` y
  label names its `Method`, as in "Mean peak", and `groupstats.histogram`
  labels its x axis with the data variable.
- `groupstats.groupheatmap` takes 0.75 of the axes font size. Its colorbar
  label names the mapped quantity, as in "Mean of peak", and the new
  `ColorbarLabel` option replaces it. The chart sets no default title. For
  `Method="count"`, 16 or fewer count levels get a discrete colormap.
- `groupstats.scatter` draws its markers 1.25 times the shared default
  sizes.
- `groupstats.barchartcats` with `Method="median"` and `PlotError=true`
  draws each whisker from the lower quartile to the upper quartile of the
  bar's rows. These are the box edges `boxchartcats` draws, so the two arms
  differ for skewed data. The whisker was the median plus or minus the
  full interquartile range, twice the height of the box. For [1 2 3 10]
  it runs from 1.5 to 6.5, where it ran from -2.5 to 7.5.
- `groupstats.histogram` colors its k-th group with the k-th row of
  `defaultcolors`, as the other charts do, and each fitted curve takes its
  group's color. The groups took the axes color order, so group 8 had the
  color of group 1.
- The toolbox states R2024b as its minimum release, the oldest release the
  test suite runs on. The README, the getting-started pages, and
  `info.xml` stated R2021a, which no test covered. Base MATLAB before
  R2022a also lacks `quantile`, which the box charts and `groupci` call.
  The packaged toolbox declares no minimum release. The README and the
  `groupcompare` help name `quantile` as base MATLAB.

### Fixed

- `groupstats.boxchartydata` returns the whisker tips that `boxchart`
  draws. A tip never lies inside the box, so the whiskers of
  `[1 2 3 4 100]` are `[1 28]`, where the helper returned `[1 4]`.
- `groupstats.boxchartcats` with every `MarkerStyle` set to `"none"` fits
  its y-limits to the whisker tips, the box edges, and the notches. Limits
  fit to the whiskers alone cut off a box top or a notch.
- `groupstats.groupsummary` returns a row for a missing grouping value,
  sorted last, where it raised a key error. A missing value of a binned
  variable forms an `<undefined>` bin. `binsDoNotSpanData` counts only the
  values that lie outside the edges.
- `groupstats.groupsummary` summarizes a categorical data variable whose
  categories are numbers by those numbers, not by its category codes. One
  whose categories are names stays categorical.
- `groupstats.groupsummary` and `groupstats.grouppercent` keep the group
  variable's name for a named time bin such as `{"month"}`, on a
  timetable's row times or a datetime variable. Both raised an
  unknown-variable error there.
- `groupstats.grouppercent` gives the rows of a missing group member their
  within-member percents, where it returned NaN.
- `groupstats.grouppercent` counts the rows whose `GroupSets` value is
  missing when the set variable is outside `groupvars`. They form one set,
  after the other sets. The count left them out.
- `groupstats.groupmap` applies its function once to the rows whose group
  value is missing, and returns them in one `<undefined>` row after the
  other groups. It left those rows out and added an empty group for each
  missing value.
- `groupstats.groupmap` stacks function results that hold two char
  variables of different widths. It raised a join error.
- `groupstats.barchartcats` with `Legend="off"`, or with no color group
  and no `LegendString`, makes no legend, so the axes fill the figure. It
  made a hidden legend that kept its space above the axes.
- `groupstats.groupci` and the `ErrorBar="ci"` whiskers of
  `groupstats.barchartcats` keep the mean interval finite and accurate at
  extreme `Alpha`. The half-width was 0 as `Alpha` neared 1. It was Inf for
  a tiny `Alpha` with one or two degrees of freedom. It was inaccurate for
  an `Alpha` below about 1e-300.
- The published demo pages show each figure once. A figure could appear
  again in the section after the one that draws it.
- The Getting Started and Using GroupStats pages draw figure text at the
  proportion of the demo pages. Their text was about 1.5 times too large.
- `groupstats.boxchartcats` draws 22 or more color groups, where it raised
  an index error. Its boxes, outliers, and mean symbols take the k-th row
  of `defaultcolors`, as `barchartcats` and `scatter` do. The 22nd group
  starts over at the first color. The boxes took the axes color
  order, so past seven groups a mean symbol and its box had different
  colors. A caller's `BoxFaceColor` also colors the outliers and the means.
- `groupstats.boxchartcats` with `Legend="off"` makes no legend and
  returns the empty placeholder, as the other charts do. It returned a
  deleted legend handle.
- Tab completion lists `cgroupvar` of `barchartcats` and `boxchartcats`
  and `varnames` of `dropcats` as optional. It lists no fixed default for
  the `ShadeGroups` option of `barchartcats` or the `Legend` option of
  `histogram`, whose defaults depend on the call. It offers `Line`
  properties for `scatter`, which draws lines. It offers the `Pairwise`
  option of `groupbayes` and the `HeatmapChart` properties of
  `groupheatmap`, which it left out.

### Removed

- The empty `toolbox/+groupstats/permutest` folder and its MATLAB Project
  entries. A package built from the project listed the folder as a MATLAB
  path. The vendored `permutest` stays in `toolbox/+groupstats/private/`.

## 1.0.0 - 2026-09-09

The vendor-ready quality pass.

### Added

- `groupstats.groupcompare` compares each group member against a
  reference member, one row per comparison. Its options are an explicit
  `Test` (`"ranksum"`, `"signrank"`, `"permutation"`), a reference-relative
  `Tail`, `ConditionVar` sets, and `Pooled`. A `Bootstrap` opt-in adds the
  signed bootstrapped median difference and its interval.
- `groupstats.groupsamples` collects the data of each group member,
  reference first, once per condition set.
- `Parent` on `groupstats.barchartcats` and `groupstats.boxchartcats`. Every
  part of the chart draws into the named axes.
- `IncludedEdge` on `groupstats.groupsummary` and `groupstats.grouppercent`,
  passed to the builtin for binned group variables.
- `SortGroupMembers` on `groupstats.boxchartcats`, matching `barchartcats`.
- `groupstats.help(docname)` with an output returns the page path and opens
  nothing.
- `buildtool docs` publishes the Help browser pages with
  `groupstats.internal.makedocs`; `buildtool release` depends on it. The
  docs build and the release need R2025a: the live scripts are plain-text
  `.m` live scripts, which `export` reads from R2025a.
- `buildtool dependencies` copies every matfunclib function the shipped code
  calls into the package and records the list in `toolbox/vendored.txt`.
  The File Exchange license beside a third-party file is copied too, as
  `<name>_LICENSE.txt`. `buildtool check` fails when a shipped file calls a
  function the package does not ship.
- `groupstats.scatter` draws a categorical data variable whose categories
  are names by its category ranking, with the categories as the tick
  labels.
- Error identifiers `groupstats:groupsummary:binsDoNotSpanData`,
  `groupstats:prepareTableGroups:multiColumnGroupVar`, and
  `groupstats:boxchartcats:allDataMissing` report conditions that failed
  inside MATLAB before.

### Changed

- `groupstats.histogram` takes `datavar` as a required second argument and
  `groupvar` as the positional third argument.
- `groupstats.groupsummary` takes `(tbl, groupvars, methods, datavar,
  groupbins)` positionally. `GroupSets`, `RowSelectVar`, and
  `RowSelectMembers` are name-value options on it and on `grouppercent`.
- `groupstats.barchartcats` colors its bars from the `defaultcolors`
  palette that `boxchartcats` and `scatter` use, face and edge. A caller's
  `FaceColor` wins, and a caller's `CData` keeps the colormap path.
  Published figures drawn with the default colors change color.
- `groupstats.scatter` colors its groups from the `defaultcolors` palette
  alone, the same rows `boxchartcats` and `barchartcats` use. The palette
  holds 21 colors. A chart with more color groups starts over from the
  first row, where the `distinguishable_colors` fallback once gave each
  group its own color.
- `LegendString(i)` on `barchartcats`, `boxchartcats`, and `scatter` names
  the i-th color-group member in category order after member filtering and
  merging. It moves with the series when `CGroupOrder`, `SGroupOrder`, or
  `SortBy` reorder them.
- `groupstats.barchartcats` draws no bar for an (x-group, color-group) pair
  with no rows, and keeps the other bars on their own ticks.
- The optional grouping arguments (`cgroupvar`, `sgroupvar`, histogram's and
  groupbayes's `groupvar`, `ConditionVar`) accept one name or none; a
  vector is rejected.
- `groupstats.prepareTableGroups` leaves a categorical `XDataVar` whose
  categories are names categorical, for the chart to rank.
- `groupstats.groupmap` validates its inputs with an `arguments` block.
- The vendored `permutest` lives in `toolbox/+groupstats/private/`, where
  the package can call it.
- The package is self-contained: no other repository has to be on the path.
  The Statistics and Machine Learning Toolbox is needed by `groupcompare`
  and `scatter`; `groupcompare`'s permutation test also needs the Image
  Processing Toolbox.

### Removed

- `groupstats.groupdifference`. `groupcompare` and `groupsamples` replace
  it, with no shim.
- The `GroupVar` name-value argument and the one-argument array form
  `histogram(data)` of `groupstats.histogram`.
- The positional `groupsets` argument of `groupsummary` and `grouppercent`.

## 0.2.0 - 2026-09-04

The API unification pass, merged to `main` on that date. No release tag has
been cut for it; `toolbox/version.txt` carries the version.

### Added

- `Pairwise` on `groupstats.groupbayes`, for a declared overlap of the two
  label sets.
- `MergeGroupMembers` on all four charts, with `MergeMethod` on
  `barchartcats` (`"pooled"` default, `"membermean"` keeping the old
  arithmetic).
- `XGroupOrder`, `CGroupOrder`, and `SGroupOrder` partial-order options on
  the charts.
- Every chart returns `(H, L, ax)`.
- The `groupstats:boxchartcats:allBoxesSingleObservation` warning.
- The stable `groupstats:prepareTableGroups:unknownVariable` identifier for
  every chart's variable-name check.

### Changed

- `string.empty()` is the one no-selection sentinel across the family.
  `"none"` is a variable name, not a sentinel, and `GroupSets = "none"` is
  rejected.
- Row selection takes `RowSelectVar` and `RowSelectMembers` together;
  either one alone is an error.
- `groupstats.groupselect` takes `groupvars`.
- `SortBy` means the same direction on every chart and defaults to
  `"none"`.
- The demos draw one figure per option.

### Removed

- `MergeGroups` and `SortColumns` on the cats charts.
- `demo_groupbayes_counts` from the shipped examples.

[Unreleased]: https://github.com/mgcooper/groupstats/compare/main...dev
