%% Histograms with groupstats.histogram
%
% groupstats.histogram wraps the built-in histogram for table data and adds
% grouping: one overlaid histogram per member of a grouping variable, with
% a legend. A categorical data variable with no group variable is the
% categorical histogram, where the categories themselves define the bars.
%
% See also: groupstats.histogram, groupstats.barchartcats,
% groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');
Info = data.Info;
scenarios = data.scenarios;

% The fixture is a complete grid, so every month holds the same number of
% rows and the categorical bars would all be flat. Keep the rows whose
% peak exceeds 12, so the month counts vary with the seasonal peak cycle.
Info = Info(Info.peak > 12, :);

%% The two basic shapes

% A numeric variable with no group variable is one histogram, like the
% built-in, reached through the table and the variable name.
figure
groupstats.histogram(Info, "peak");
title("All peak values, one histogram")

% GroupVar overlays one histogram per group member, with a legend.
figure
groupstats.histogram(Info, "peak", GroupVar = "scenario");
title("Peak values, one histogram per scenario")

%% The built-in call shapes
%
% The built-in's array call shape also works: histogram(x) and
% histogram(x, categories). The first figure is the built-in itself; the
% second is the wrapper on the same array, keeping three categories.

figure
histogram(Info.month);
title("Built-in histogram of the month column")

figure
groupstats.histogram(Info.month, ["Jan", "Feb", "Mar"]);
title("Wrapper on the same array, Jan through Mar kept")

%% Restrict the categories
%
% GroupMembers keeps only the named members. On the categorical shape the
% positional categories argument means the same thing.

figure
groupstats.histogram(Info, "month", GroupMembers = ["Jan", "Feb", "Mar"]);
title("Jan through Mar only")

%% Order the groups
%
% GroupOrder is a partial order: named members come first, and the rest
% keep their order. It overrides SortBy.

figure
groupstats.histogram(Info, "peak", GroupVar = "scenario", ...
   GroupOrder = scenarios(3));
title("The far scenario drawn and listed first")

%% Sort the groups
%
% SortBy orders the groups by the group mean of the data variable, or by
% the category counts in categorical mode. The default "none" keeps the
% order the groups already have.

figure
groupstats.histogram(Info, "peak", GroupVar = "scenario", ...
   SortBy = "descend");
title("Scenarios ordered by descending mean peak")

%% Merge group members
%
% MergeGroupMembers pools the named members into one group, one cell per
% merge group. The merged label joins the member names with " and ", and
% the merged group takes the position of its first member in the current
% category order.

figure
groupstats.histogram(Info, "peak", GroupVar = "scenario", ...
   MergeGroupMembers = {scenarios(2:3)});
title("The two future scenarios pooled into one histogram")

% In categorical mode the named categories pool into one bar.
figure
groupstats.histogram(Info, "month", MergeGroupMembers = {["Jan", "Feb"]});
title("Jan and Feb pooled into one bar")

%% Select rows before grouping
%
% RowSelectVar and RowSelectMembers restrict the table before anything is
% grouped or drawn.

figure
groupstats.histogram(Info, "peak", GroupVar = "scenario", ...
   RowSelectVar = "basin", RowSelectMembers = ["basinA", "basinB"]);
title("basinA and basinB rows only")

%% Plot into an existing axes
%
% Parent names the axes: groupstats.histogram draws and formats the chart
% in that axes rather than in the current one. Each tile here shows a
% grouping no other section uses.

figure
tiles = tiledlayout(1, 2);
ax1 = nexttile(tiles);
ax2 = nexttile(tiles);
groupstats.histogram(Info, "peak", GroupVar = "basin", Parent = ax1);
groupstats.histogram(Info, "month", ...
   GroupMembers = ["Oct", "Nov", "Dec"], Parent = ax2);
title(ax1, "Peak by basin in the left tile")
title(ax2, "Oct through Dec counts in the right tile")

%% Legend options
%
% LegendString replaces the default entries, and LegendOrientation lays
% them out. Legend = "off" removes the legend.

figure
groupstats.histogram(Info, "peak", GroupVar = "scenario", ...
   LegendString = ["Historical", "Near future", "Far future"], ...
   LegendOrientation = "horizontal");
title("Renamed entries in a horizontal legend")

figure
groupstats.histogram(Info, "peak", GroupVar = "scenario", Legend = "off");
title("Legend turned off")

%% Graphics properties pass through
%
% Any Histogram property passes through, so Normalization and NumBins
% reach the underlying histogram call.

figure
groupstats.histogram(Info, "peak", GroupVar = "scenario", ...
   Normalization = "probability", NumBins = 10);
title("Probability normalization with ten bins")
