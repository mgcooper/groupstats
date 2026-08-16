%% Grouped scatter charts with groupstats.scatter
%
% groupstats.scatter plots one table variable against another, coloring each
% point by a categorical group. A second group varies the marker, so one
% chart can show two groupings at once.
%
% gscatter draws the points as Line objects, so H holds Line handles and
% takes Line properties such as MarkerSize, not Scatter properties such as
% SizeData.
%
% See also: groupstats.scatter, gscatter, groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');
Info = data.Info;

% peak against itself is not interesting, so build a second numeric variable
% that carries a trend plus noise.
rng(1)
Info.runoff = 2 * Info.peak + randn(height(Info), 1);

%% Color by one group

figure
groupstats.scatter(Info, "peak", "runoff", "scenario");
title("Runoff against peak, colored by scenario")

%% Color and marker by two groups
%
% The size group varies the marker symbol and size, so both groupings are
% readable in one chart.

figure
groupstats.scatter(Info, "peak", "runoff", "scenario", "basin");
title("Colored by scenario, marked by basin")

%% Restrict the members
%
% CGroupMembers and SGroupMembers keep only the named members. Rows outside
% them are dropped, which is different from hiding a series.

figure
groupstats.scatter(Info, "peak", "runoff", "scenario", "basin", ...
   CGroupMembers = ["1980-2020-WRF-DIST", "SSP585-HOT-FAR"], ...
   SGroupMembers = ["basinA", "basinB"]);
title("Two scenarios, two basins")

%% Select rows before plotting
%
% RowSelectVar and RowSelectMembers restrict the table before grouping.

figure
groupstats.scatter(Info, "peak", "runoff", "scenario", ...
   RowSelectVar = "month", RowSelectMembers = ["Jun", "Jul", "Aug"]);
title("Summer months only")

%% Order the legend
%
% SortGroup names which grouping the legend order follows, SortVar which
% data variable the order sorts on, and SortBy the direction. Choosing
% SortVar "ydatavar" forces "descend".

figure
groupstats.scatter(Info, "peak", "runoff", "scenario", ...
   SortGroup = "cgroupvar", SortVar = "xdatavar", SortBy = "ascend");
title("Legend ordered by ascending mean peak")

%% Legend and line properties
%
% Any Line property passes through. MarkerSize reaches the underlying
% gscatter call.

figure
groupstats.scatter(Info, "peak", "runoff", "scenario", ...
   LegendOrientation = "horizontal", MarkerSize = 12);
title("Horizontal legend, larger markers")

figure
groupstats.scatter(Info, "peak", "runoff", "scenario", Legend = "off");
title("Legend turned off")

%% Plot into an existing axes
%
% Parent defaults to gca, so repeated calls reuse the current axes rather
% than opening a figure each time.

figure
tiles = tiledlayout(1, 2);

ax1 = nexttile(tiles);
groupstats.scatter(Info, "peak", "runoff", "scenario", Parent = ax1);
title(ax1, "Colored by scenario")

ax2 = nexttile(tiles);
groupstats.scatter(Info, "peak", "runoff", "basin", Parent = ax2);
title(ax2, "Colored by basin")
