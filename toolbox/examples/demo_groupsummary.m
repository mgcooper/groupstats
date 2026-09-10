%% Table statistics with groupsummary, grouppercent, groupselect, and dropcats
%
% This demo shows the table statistics family on one event table:
% group-wise statistics with groupsummary, within-group percents with
% grouppercent, row selection with groupselect, unused-category removal
% with dropcats, and prepareTableGroups, the preparation step every chart
% in the toolbox runs first. Each section prints its result.
%
% See also: groupstats.groupsummary, groupstats.grouppercent,
% groupstats.groupselect, groupstats.dropcats,
% groupstats.prepareTableGroups, groupstats.test.generateTestData

% The Info fixture holds one row per scenario, basin, and month, a numeric
% peak, and one logical column per basin naming the basins that flood in
% that row. The same table backs the chart demos.
data = groupstats.test.generateTestData('info');
Info = data.Info;

%% groupsummary: statistics per group
%
% groupsummary(tbl, groupvars, methods, datavar) is the builtin with three
% additions: a percent column for every group beside the builtin's count,
% a column named after each function-handle method, and the GroupSets and
% row-selection options shown below. The positional order is methods,
% then datavar, then groupbins; the groupsummary help explains why it
% differs from the builtin's.

G = groupstats.groupsummary(Info, ["scenario", "month"], ...
   ["mean", "max"], "peak");
disp(head(G, 6))

% A function handle names its own column, here spread_peak, after the
% local function at the end of this script.
G = groupstats.groupsummary(Info, "scenario", {@spread}, "peak");
disp(G)

%% groupsummary: bin a numeric group variable
%
% groupbins takes one binning scheme per group variable. A binned variable
% keeps its own name in the result. Here the peaks are binned, and the
% mean of the logical Outlet column is the fraction of rows in each bin
% in which the outlet floods.

G = groupstats.groupsummary(Info, "peak", "mean", "Outlet", {[0 12 14 Inf]});
disp(G)

%% groupsummary: percents within a set
%
% GroupSets names the variable whose members define the sets. Within
% every scenario the Percent_scenario column then sums to 100, where the
% Percent column is each row's share of the whole table.

G = groupstats.groupsummary(Info, ["scenario", "basin"], "mean", "peak", ...
   GroupSets = "scenario");
disp(head(G, 6))

%% groupsummary: select rows first
%
% RowSelectVar and RowSelectMembers keep only some rows before
% summarizing. Give both together; either one alone is an error.

G = groupstats.groupsummary(Info, "scenario", "mean", "peak", ...
   RowSelectVar = "basin", RowSelectMembers = ["basinA", "basinB"]);
disp(G)

%% grouppercent: frequencies within a set
%
% grouppercent(tbl, groupvars) counts the rows of every group and adds a
% Percent_<var> column per GroupSets variable, each summing to 100 within
% that variable's members. It takes the same GroupSets and row-selection
% options as groupsummary.

P = groupstats.grouppercent(Info, ["scenario", "basin"], ...
   GroupSets = "scenario");
disp(head(P, 6))

% A table that groupcounts already summarized is used as given: the
% GroupCount column tells the two inputs apart.
counted = groupcounts(Info, "month");
P = groupstats.grouppercent(counted, "month");
disp(head(P, 4))

%% groupselect: keep the rows of named members
%
% groupselect(tbl, groupvars, groupmembers) keeps the rows whose group
% value is one of the members. It is what RowSelectVar and
% RowSelectMembers call.

two = groupstats.groupselect(Info, "basin", ["basinA", "basinB"]);
fprintf('%d of %d rows kept\n', height(two), height(Info))

%% dropcats: remove the categories no row uses
%
% Selecting rows leaves the categorical variable's category list as it
% was, so a later groupsummary or chart still sees every member. dropcats
% removes the categories no row uses.

fprintf('basin categories after groupselect: %d\n', ...
   numel(categories(two.basin)))
two = groupstats.dropcats(two, "basin");
fprintf('basin categories after dropcats: %d\n', ...
   numel(categories(two.basin)))

%% prepareTableGroups: what every chart runs first
%
% The charts hand their table, data variable, and group arguments to
% prepareTableGroups. It checks that every name is a variable of the
% table, keeps the rows of the named members, converts a text or numeric
% group variable to categorical, drops the categories no row uses, and
% converts a categorical data variable to double. Calling it directly
% shows the table a chart draws from.

prepared = groupstats.prepareTableGroups(Info, "peak", ...
   XGroupVar = "month", XGroupMembers = ["Jan", "Feb", "Mar"], ...
   CGroupVar = "scenario");
fprintf('%d rows, months kept: %s\n', height(prepared), ...
   strjoin(categories(prepared.month), ', '))

%% Local function
%
% A script may hold local functions after its sections. This one is the
% statistic the function-handle example summarizes with.

function r = spread(x)
   %SPREAD The difference between the largest and the smallest value.
   r = max(x) - min(x);
end
