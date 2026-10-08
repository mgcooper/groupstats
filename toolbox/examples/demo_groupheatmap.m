%% Grouped heatmaps with groupstats.groupheatmap
%
% groupheatmap draws one cell per pairing of an x-group member with a
% color-group member, as a built-in HeatmapChart. The columns show the
% x-group members, and the rows show the color-group members. The cell
% color is a summary of the data variable over the rows of that pairing.
%
% This demo shows each Method in a tiled layout, the rule for empty
% pairings, the ordering options, a merge, and member and row selection.
%
% See also: groupstats.groupheatmap, heatmap, groupstats.boxchartcats,
% groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');
Info = data.Info;
months = ["Jan", "Apr", "Jul", "Oct"];

%% The mean of each pairing
%
% The default Method is "mean". Each cell is the mean peak of one month and
% one scenario. The colorbar takes the place of a legend.

figure
groupstats.groupheatmap(Info, "peak", "month", "scenario", ...
   Title = "Mean peak by month and scenario");

%% Every method in a tiled layout
%
% Method sets the statistic of each cell: "mean", "median", "count",
% "sum", "min", or "max". Call nexttile before each chart and pass the
% layout as Parent, as with heatmap. "count" counts the non-missing values:
% each month and scenario holds four rows, one per basin label.

figure
layout = tiledlayout(2, 3);
for method = groupstats.namelists.heatmapmethod()'
   nexttile(layout)
   groupstats.groupheatmap(Info, "peak", "month", "scenario", ...
      XGroupMembers = months, Method = method, Parent = layout, ...
      Title = method, ColorbarVisible = "off");
end

%% Empty pairings
%
% The heatmap removes NaN values before it summarizes. Here every January
% value of one scenario is NaN, so that pairing has no values. It shows
% NaN, drawn in MissingDataColor, for "mean", "median", "min", and "max",
% and 0 for "count" and "sum".

withgap = Info;
nojan = withgap.month == "Jan" & withgap.scenario == "SSP585-HOT-FAR";
withgap.peak(nojan) = NaN;

figure
layout = tiledlayout(1, 2);
nexttile(layout)
groupstats.groupheatmap(withgap, "peak", "month", "scenario", ...
   XGroupMembers = months, Parent = layout, Title = "mean");
nexttile(layout)
groupstats.groupheatmap(withgap, "peak", "month", "scenario", ...
   XGroupMembers = months, Method = "count", Parent = layout, ...
   Title = "count");

%% Order the columns and the rows
%
% SortBy orders the columns by the mean of their cell values. CGroupOrder
% names the rows to show first; the rest keep their order. An XGroupOrder
% would win over SortBy.

figure
groupstats.groupheatmap(Info, "peak", "month", "scenario", ...
   SortBy = "descend", CGroupOrder = "SSP585-HOT-FAR", ...
   Title = "Months by descending mean peak");

%% Merge color groups
%
% MergeGroupMembers pools the rows of the named scenarios into one row,
% which takes the position of its first member. Each merged cell is the
% statistic of the pooled rows.

figure
groupstats.groupheatmap(Info, "peak", "month", "scenario", ...
   MergeGroupMembers = ["SSP245-WARM-NEAR", "SSP585-HOT-FAR"], ...
   Title = "Two future scenarios pooled");

%% Select members and rows
%
% XGroupMembers and CGroupMembers keep the named members.
% RowSelectVar and RowSelectMembers keep the rows of the named members of
% another variable, here the outlet basin label.

figure
groupstats.groupheatmap(Info, "peak", "month", "scenario", ...
   XGroupMembers = months, RowSelectVar = "basin", ...
   RowSelectMembers = "Outlet", Title = "Outlet rows only");
