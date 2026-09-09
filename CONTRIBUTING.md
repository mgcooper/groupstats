# Contributing

Open an issue at https://github.com/mgcooper/groupstats/issues before you
send a change, so the work can be discussed first.

## Before you send a change

Run these from the repository root in MATLAB:

- The tests: `buildtool test`, or `runtests('tests')` after
  `addpath('toolbox')`. The suite passes on R2024b and R2025b.
- The static analysis: `buildtool check`. The bar is zero issues. Fix what a
  change introduces; do not add a suppression.
- The function listings, after you add, rename, or remove a function:
  `buildtool contents`.
- The vendored copies, after you call a new matfunclib function from shipped
  code: `buildtool dependencies`. `buildtool check` fails until you do.

## Conventions

- The code style is in `STYLE.md` and `STYLE.local.md`. Match the
  surrounding code first.
- Every new function has a docstring with an Example, an entry in
  `toolbox/functionSignatures.json`, and tests in `tests/` that cover every
  statement and branch.
- Every option that takes a fixed set of values reads that set from a list in
  `toolbox/+groupstats/+namelists/`. The validator and the tab completion
  then cannot disagree.
- Table arguments are named `tbl`. Positional arguments are lowercase;
  name-value options are PascalCase.
- Do not edit a vendored copy: `toolbox/vendored.txt` lists every file
  `buildtool dependencies` copies from matfunclib. Change the matfunclib
  original and rerun the task instead. Do not edit `private/permutest.m` or
  its license.

## Releases

`buildtool release` runs `check`, `test`, and `docs`, then packages
`release/GroupStatsToolbox.mltbx` from the Package Toolbox task in the MATLAB
Project, with the version read from `toolbox/version.txt`. The docs build
and the packaging need R2025a or later; the toolbox itself runs from
R2021a. `release/` is not part of the repository, and neither are the
built pages under `toolbox/docs/html` (only `helptoc.xml` there is a
source): `buildtool docs` writes them, and `release` runs it first. A
developer who rebuilds the docs needs R2025a or later and m2html (see
the README); a user of the packaged toolbox needs neither.
