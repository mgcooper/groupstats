# Project-specific code style — groupstats

Conventions specific to this project, extending `STYLE.md` (and any language conventions
merged into it).

## Naming

- Public functions live in `toolbox/+groupstats/`; internal utilities live
  in `+internal/`; single-folder helpers live in that folder's `private/`.
- Table arguments are named `tbl`, never `T`. Positional arguments are
  lowercase; name-value fields are PascalCase. The `arguments`-block
  structs are `opts` (options) and `props` (graphics pass-through).
- Grouping variables: a scalar is `groupvar`, a vector is `groupvars`; the
  cats charts and `scatter` use role-prefixed `xgroupvar`/`cgroupvar`/
  `sgroupvar`. A grouping variable is positional, except the second
  grouping of `groupcompare`/`groupsamples`, the name-value `ConditionVar`.
  An optional grouping variable is declared `string {mustBeScalarOrEmpty}`
  with a `string.empty()` default. `dropcats` keeps `varnames` because it
  names categorical variables, not groupings. Positional member lists are
  `groupmembers`; name-value member options are PascalCase `*Members`.
- `groupsummary`/`grouppercent` accept the standard positional inputs;
  rare or groupstats-only controls (`GroupSets`, `RowSelectVar`,
  `RowSelectMembers`) are PascalCase name-value options.
- `SortBy` sets the sort direction on all four charts. Cats charts sort
  `xgroupvar` only, so they have no `SortGroup`, but they have
  `SortGroupMembers` (which `cgroupvar` members enter the sort). `scatter`
  sorts either grouping, so it has both `SortGroup` and `SortVar`.
- Test classes are named `test_<subject>.m` in `tests/`, e.g.
  `test_dropcats.m`.
- `toolbox/+groupstats/+test/` holds test runners, helpers, and fixtures,
  not test classes; `generateTestData.m` lives there so demos and scripts
  can call it too.

## Formatting

- Indent with 3 spaces, never tabs. Indent `...` continuation lines by 6
  spaces (double indent).
- Preserve the commented BSD 3-Clause footer blocks in files that carry
  them. Do not add license footers to new files.

## Idioms and patterns

- Use `arguments` blocks for input validation in all new code, including
  `props.?Class`-style graphics pass-through. `inputParser` must not
  appear in new code.
- Import namespace functions at the top of a function body
  (`import groupstats.groupselect`) instead of fully qualifying each call.
- Route grouped-table preprocessing through `groupstats.prepareTableGroups`
  instead of reimplementing group/member validation per function.
- Use the cleanup-object helpers `withwarnoff` and `withcd` for temporary
  warning-state and directory changes.

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
