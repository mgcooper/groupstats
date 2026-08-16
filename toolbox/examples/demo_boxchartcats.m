%% Grouped box charts with groupstats.boxchartcats
%
% boxchartcats draws the distribution of one numeric variable over a
% categorical x-group, and optionally a second categorical that colors the
% boxes within each x-group. Where barchartcats reduces each group to one
% number, boxchartcats shows the spread.
%
% See also: groupstats.boxchartcats, groupstats.barchartcats,
% groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');
Info = data.Info;

%% The two basic shapes

% One box per x-group.
figure
groupstats.boxchartcats(Info, "peak", "month");
title("Peak distribution by month")

% A color group draws one box per color group within each x-group.
figure
groupstats.boxchartcats(Info, "peak", "month", "scenario");
title("Peak distribution by month and scenario")

%% Restrict the groups
%
% XGroupMembers and CGroupMembers select the members and set their order.
% Leaving them unset draws every member.

figure
groupstats.boxchartcats(Info, "peak", "month", "scenario", ...
   XGroupMembers = ["Jan", "Feb", "Mar"], ...
   CGroupMembers = ["1980-2020-WRF-DIST", "SSP585-HOT-FAR"]);
title("Three months, two scenarios")

%% Group means
%
% PlotMeans overlays the mean of each box as a symbol, because a box chart
% shows the median by default and the two differ for a skewed group. It is on
% by default, so this section shows it turned off.

figure
groupstats.boxchartcats(Info, "peak", "month", PlotMeans = false);
title("Medians only, no mean symbols")

%% Connect the group centers
%
% ConnectMeans and ConnectMedians draw a line through the group centers,
% which makes a trend across the x-groups easier to read.

figure
groupstats.boxchartcats(Info, "peak", "month", ConnectMeans = true);
title("Means connected across months")

figure
groupstats.boxchartcats(Info, "peak", "month", ConnectMedians = true);
title("Medians connected across months")

% With a color group, each line follows one color across the x-ticks.
figure
groupstats.boxchartcats(Info, "peak", "month", "scenario", ...
   ConnectMeans = true);
title("One line per scenario across the months")

%% Sort the x-groups

figure
groupstats.boxchartcats(Info, "peak", "month", SortBy = "ascend");
title("Months sorted by ascending group value")

%% Name an explicit order
%
% XGroupOrder and CGroupOrder move named members to the front and leave the
% rest in their existing order.

figure
groupstats.boxchartcats(Info, "peak", "month", XGroupOrder = ["Jul", "Jan"]);
title("Jul and Jan moved to the front")

figure
groupstats.boxchartcats(Info, "peak", "month", "scenario", ...
   CGroupOrder = "SSP585-HOT-FAR");
title("SSP585-HOT-FAR drawn first")

%% Shade the x-groups
%
% ShadeGroups is on by default here, unlike barchartcats. This section turns
% it off so the difference is visible.

figure
groupstats.boxchartcats(Info, "peak", "month", "scenario", ...
   ShadeGroups = false);
title("Group shading turned off")

%% Select rows before grouping

figure
groupstats.boxchartcats(Info, "peak", "month", "scenario", ...
   RowSelectVar = "basin", RowSelectMembers = "basinA");
title("basinA rows only")

%% Legend and graphics properties
%
% Any BoxChart property passes through, so BoxWidth and MarkerStyle reach the
% underlying boxchart call.

figure
groupstats.boxchartcats(Info, "peak", "month", "scenario", ...
   LegendOrientation = "horizontal", BoxWidth = 0.6);
title("Horizontal legend, narrower boxes")

figure
groupstats.boxchartcats(Info, "peak", "month", "scenario", Legend = "off");
title("Legend turned off")
