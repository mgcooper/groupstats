%% Group Stats Toolbox
% A MATLAB toolbox for grouped statistics on tables.
%
% Data often falls naturally into groups: measurements labeled by site,
% scenario, month, or treatment. MATLAB provides built-in tools to summarize and
% chart grouped data. GroupStats provides a consistent API around those tools,
% allowing you to quickly summarize and plot tabular data by group in fewer
% lines of code. Every function accepts a table and the names of its grouping
% variables, and every function lives in the |groupstats| namespace.

%% Getting started
% * <groupstats_gettingStarted.html Getting Started> installs the toolbox
% and draws a first chart.
% * <usingGroupStats.html Using Group Stats> walks through the toolbox on
% one table, from summary to chart.
% * <groupstats_examples_contents.html Examples> lists the demos, one page
% each, with their figures.
% * <m2html/function_index.html Functions> lists every public function
% with its help text.

%% Grouped statistics
% * |groupstats.groupsummary| - group-wise summary statistics, with counts
% and percents joined on.
% * |groupstats.grouppercent| - group-wise frequencies and percentages,
% within group sets.
% * |groupstats.groupbayes| - conditional probabilities between two sets of
% group labels.
% * |groupstats.groupcompare| - compare each group against a reference by
% rank-sum, sign-rank, or permutation test, with an optional bootstrapped
% median difference.
% * |groupstats.groupsamples| - the data of each group, reference first.
% * |groupstats.groupselect| - select the rows matching group members.
% * |groupstats.groupmap| - apply a function to each group and recombine
% the results.
% * |groupstats.dropcats| - drop the categories no row uses.
% * |groupstats.prepareTableGroups| - the row selection and group
% preparation every chart runs first.

%% Charts for grouped data
% * |groupstats.barchartcats| - bar chart grouped along x and colored
% within groups.
% * |groupstats.boxchartcats| - box chart grouped along x and colored
% within groups.
% * |groupstats.scatter| - scatter chart colored and sized by group.
% * |groupstats.histogram| - histogram of a categorical variable, with
% grouping.
% * |groupstats.boxchartxdata| and |groupstats.boxchartydata| - the box
% coordinates, for annotating a box chart.

%% Option values
% Every option that takes a fixed set of values reads that set from
% |groupstats.namelists|, so the validators and the tab completions cannot
% disagree. To see the values an option accepts:
%
%   groupstats.namelists.sortorder()
%   groupstats.namelists.comparetest()

%% Help for one function
%
%   help groupstats.groupbayes
%   groupstats.help("groupbayes")
%
% |groupstats.help()| with no argument opens this page.

%% Requirements
% The package is self-contained: every helper it calls ships inside it.
% |groupstats.groupcompare| and |groupstats.scatter| need the Statistics
% and Machine Learning Toolbox; the permutation test of |groupcompare| also
% needs the Image Processing Toolbox. The rest needs MATLAB R2021a or later.
