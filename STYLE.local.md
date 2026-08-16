# Project-specific code style — groupstats

Conventions specific to this project, extending the canonical `STYLE.md` (and any
language conventions merged into it). This file is project-owned — `--update` never
overwrites it.

## Naming

- Function-name casing follows canonical `STYLE.md` (MATLAB conventions).
- Public functions belong in `toolbox/+groupstats/`. Build and maintenance
  utilities belong in `toolbox/+groupstats/+internal/`. Helpers used by a
  single folder belong in that folder's `private/` directory.
- Table arguments must be named `tbl`, never `T`. Rename any remaining or
  reintroduced `T` table variable to `tbl` on contact. Positional arguments
  are lowercase (`ydatavar`, `xgroupvar`, `cgroupvar`). Name-value option
  fields are PascalCase (`XGroupMembers`, `PlotMeans`, `LegendOrientation`);
  the `arguments`-block structs that hold them are named `opts` (options) and
  `props` (graphics pass-through properties).
- Test classes must be named `test_<subject>.m` and live in `tests/`,
  matching `test_dropcats.m`, `test_groupbayes.m`, and `test_groupmap.m`.
  There are no exceptions.
- `toolbox/+groupstats/+test/` holds test runners, helpers, and fixtures that
  ship with the toolbox, not test classes. `generateTestData.m` lives there
  because demos and scripts call it.

## Formatting

- Indent with 3 spaces (canonical `STYLE.md` delegates indent width to this
  file). Never use tabs (`getCases.m` is a legacy exception).
- Indent `...` continuation lines by 6 spaces (double indent).
- Preserve the commented BSD 3-Clause footer blocks in files that carry them.
  Do not add license footers to new files.

## Idioms and patterns

- Use `arguments` blocks for input validation in all new code, including
  `props.?matlab.graphics.chart.primitive.BoxChart`-style declarations for
  graphics property pass-through. `inputParser` survives only in two legacy
  internals (`getRequiredFiles.m`, `replacePackagePrefix.m`); it must not
  appear in new code.
- Import namespace functions at the top of a function body
  (`import groupstats.groupselect`) instead of fully qualifying every call.
- Route grouped-table preprocessing through `groupstats.prepareTableGroups`;
  do not re-implement group/member validation inside individual functions.
- Use the cleanup-object helpers `withwarnoff` and `withcd` for temporary
  warning-state and directory changes.

## Other project conventions

- MATLAB launchers on this machine: `matlab` on `PATH` is a symlink to
  `/Applications/MATLAB_R2025b.app/bin/matlab`; R2024b is also installed at
  `/Applications/MATLAB_R2024b.app/bin/matlab`. Develop and test against
  these releases.
- Language-feature floor already in use: `arguments` blocks (R2019b+),
  `props.?Class` validation (R2021a+), `buildtool` (R2022b+), and
  `codeIssues` (R2023a+). Releasing needs R2025a, for the Package Toolbox
  task, but that is a maintainer step and not a floor for using the toolbox.
- `toolbox/+groupstats/permutest/` is vendored third-party code with its own
  `license.txt`; never edit, restyle, or lint it to project conventions.

## Prose examples

Rewrite this:

> and somehow I overlooked this simple solution to simply loop over the
> groupsets members. But note that the main part below loops over groupsets, so
> maybe this won't work when multiple groupsets are provided, but that seems
> like something I wont support

as this:

> This branch loops over the groupset members. The main branch below also
> loops over groupsets. Note: multiple groupsets are untested here and are not
> supported.
