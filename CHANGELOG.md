# Changelog

All notable changes to this toolbox are recorded in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the toolbox follows [Semantic Versioning](https://semver.org/). The
version the package carries is in `toolbox/version.txt`.

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
