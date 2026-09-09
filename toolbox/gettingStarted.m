%[text] # Getting Started with Group Stats
%[text] A MATLAB toolbox for grouped statistics on tables.
%[text] Data often falls naturally into groups: measurements labeled by site, scenario, month, or treatment. MATLAB summarizes it well but charts it poorly. This toolbox fills the second gap, and provides additional summaries of grouped data the built-in MATLAB functions leave out. Every function accepts a table and the names of grouping variables, making grouped statistics and visualizations intuitive and convenient.
%[text] ## Installation
%[text] Choose one:
%[text] - Add the `toolbox` folder to the path.
%[text] - Run `setupfile.m` from the repository root.
%[text] - Build and install the package with `buildtool release`, then double-click  `release/GroupStatsToolbox.mltbx`. \
%[text] Functions are in the +groupstats namespace, so either import the namespace or call them directly e.g., `groupstats.groupsummary`.
%[text] ## System requirements
%[text] The code requires R2021a+ for `arguments` blocks and `props.?Class` property validation. The test suite passes on R2024b and R2025b.
%[text] `groupstats.groupcompare` and `groupstats.scatter` require the Statistics and Machine Learning Toolbox. The permutation test in `groupcompare` requires the Image Processing Toolbox.
%[text] ## A first example
%[text] Every function accepts a table and the names of its grouping variables.
data = groupstats.test.generateTestData('info');
Info = data.Info;

head(Info, 5)
%%
%[text] Create a boxchart with one box per sub-basin, colored by scenario, in a single call:
figure
groupstats.boxchartcats(Info, "peak", "basin", "scenario")
%%
%[text] ## Features
%[text] **Grouped statistics**
%[text] - `groupstats.groupsummary` extends the built-in `groupsummary` with function-handle naming, a joined percent column, and within-set percents.
%[text] - `groupstats.grouppercent` computes frequencies within a group set.
%[text] - `groupstats.groupbayes` computes conditional probabilities between two sets of labeled groups.
%[text] - `groupstats.groupselect` returns the rows matching a group member list.
%[text] - `groupstats.groupmap` applies a function to each group and recombines the results into a new table. \
%[text] **Charts for grouped data**
%[text] - `groupstats.boxchartcats` and `groupstats.barchartcats` extend the built-in `boxchart` and `bar` functions to conveniently group bars along the x-axis and apply colors to members within each group.
%[text] - `groupstats.scatter` extends the built-in `scatter` function, applying colors and symbol sizes by group.
%[text] - `groupstats.histogram` extends the built-in `histogram` function with convenient grouping and row selection. \
%[text] ## Where to go next
%[text] - `toolbox/examples/usingGroupStats.m` works through the toolbox in more detail.
%[text] - The demos in `toolbox/examples/` provide more detail on each function.
%[text] - `groupstats.help()` opens the documentation. \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
