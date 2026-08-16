%% Grouped bar charts with groupstats.barchartcats
%
% barchartcats summarizes one numeric variable over a categorical x-group,
% and optionally a second categorical that colors the bars within each
% x-group. Every option below changes what the chart shows, so run the
% sections and compare the figures.
%
% See also: groupstats.barchartcats, groupstats.boxchartcats,
% groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');
Info = data.Info;

%% The two basic shapes

% One bar per x-group. The bar height is the group mean.
figure
groupstats.barchartcats(Info, "peak", "month");
title("Mean peak by month")

% Adding a color group draws one bar per color group within each x-group.
figure
groupstats.barchartcats(Info, "peak", "month", "scenario");
title("Mean peak by month and scenario")

%% Restrict the groups
%
% XGroupMembers and CGroupMembers are name-value arguments. They select which
% members appear, and they also set the order the members are drawn in.

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", ...
   XGroupMembers = ["Jan", "Feb", "Mar"], ...
   CGroupMembers = ["1980-2020-WRF-DIST", "SSP585-HOT-FAR"]);
title("Three months, two scenarios")

%% Change the statistic
%
% method selects what the bar height means. "mean" is the default.

figure
groupstats.barchartcats(Info, "peak", "month", method = "median");
title("Median peak by month")

%% Sort the x-groups
%
% SortBy orders the x-groups by their computed value rather than by category
% order. Compare against the first figure above, which is in month order.

figure
groupstats.barchartcats(Info, "peak", "month", SortBy = "ascend");
title("Months sorted by ascending mean peak")

figure
groupstats.barchartcats(Info, "peak", "month", SortBy = "descend");
title("Months sorted by descending mean peak")

%% Sort by one color group
%
% With a color group, SortGroupMembers names which series the sort reads.
% Here the x-order follows the SSP585-HOT-FAR bars alone.

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", ...
   SortBy = "ascend", SortGroupMembers = "SSP585-HOT-FAR");
title("Sorted by the SSP585-HOT-FAR series only")

%% Name an explicit order
%
% XGroupOrder and CGroupOrder move named members to the front and leave the
% rest in their existing order. Check that each bar keeps its own height: a
% defect here paired every bar with another group's value.

figure
groupstats.barchartcats(Info, "peak", "month", XGroupOrder = ["Jul", "Jan"]);
title("Jul and Jan moved to the front")

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", ...
   CGroupOrder = "SSP585-HOT-FAR");
title("SSP585-HOT-FAR drawn first")

%% Error bars
%
% PlotError draws the spread of each group. For method "mean" that is the
% standard deviation, and for "median" the interquartile range. It needs one
% bar per x-tick, because a categorical axis puts every whisker on the tick
% center, so omit the color group.

figure
groupstats.barchartcats(Info, "peak", "month", PlotError = true);
title("Mean peak with standard deviation whiskers")

figure
groupstats.barchartcats(Info, "peak", "month", ...
   method = "median", PlotError = true);
title("Median peak with interquartile whiskers")

%% Shade the x-groups
%
% ShadeGroups puts an alternating band behind each x-group, which helps when
% many color groups make the group boundaries hard to see.

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", ...
   ShadeGroups = true);
title("Alternating group shading")

%% Merge color groups
%
% MergeGroups takes the YData column indices to combine. The merged bar
% carries the mean of its parts and its name joins the names it replaces.
% Merging discards the spread, so PlotError cannot be set with it.

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", ...
   MergeGroups = {[2, 3]});
title("The two future scenarios merged into one bar")

%% Select rows before grouping
%
% RowSelectVar and RowSelectMembers restrict the table before the summary,
% which is different from restricting the groups that get drawn.

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", ...
   RowSelectVar = "basin", RowSelectMembers = "basinA");
title("basinA rows only")

%% Legend and graphics properties
%
% Legend and LegendOrientation control the legend. Any Bar property passes
% through, so BarWidth and FaceAlpha reach the underlying bar call.

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", ...
   LegendOrientation = "horizontal", BarWidth = 0.6);
title("Horizontal legend, narrower bars")

figure
groupstats.barchartcats(Info, "peak", "month", "scenario", Legend = "off");
title("Legend turned off")
