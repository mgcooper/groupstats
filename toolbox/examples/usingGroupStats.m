%[text] # Using Group Stats
%[text] This demo walks through the toolbox using one example table, showing how to summarize and chart grouped data.
%[text] The example table holds data representing the magnitude of river flood peaks at the outlet of the Delaware River Basin and the nine sub-basins upstream of the basin outlet. The data were simulated by a hydrological model under five climate scenarios. The table is organized by one row per scenario, basin, and month, with a flood peak magnitude and one logical column per sub-basin marking which ones flooded together (together means their flood peaks occurred within a joint 4-day window).
data = groupstats.test.generateTestData('info');

Info = data.Info;
basins = data.basins;

head(Info, 5)
%%
%[text] ## Summarize by group
%[text] `groupstats.groupsummary` extends the built-in `groupsummary` function. It takes the grouping variables, the methods, and the data variable. It returns the built-in's summary joined with the group counts and percents.
G = groupstats.groupsummary(Info, ["scenario", "basin"], ...
   {'mean', 'median'}, "peak");

head(G, 5)
%%
%[text] Passing in an anonymous function for `method` returns a table with a new variable named after the function rather than the built-in function's `fun1_peak`:
G = groupstats.groupsummary(Info, "basin", {@iqr}, "peak");

G.Properties.VariableNames
%%
%[text] ## Percents within a set
%[text] Use the `GroupSets` argument to name the variable whose members define a set. The percents then sum to 100 within each set rather than across the whole table.
P = groupstats.grouppercent(Info, ["scenario", "basin"], GroupSets = "scenario");

head(P, 5)
%%
%[text] ## Select rows by group membership
%[text] `groupstats.groupselect` finds the variable holding the members you name, so you do not have to say which one it is.
subset = groupstats.groupselect(Info, ["basin", "scenario"], basins(1:2));

unique(subset.basin)
%%
%[text] ## Apply a function to each group
%[text] `groupstats.groupmap` splits the table, applies a function to each group, and recombines the results with the group variable first.
counts = groupstats.groupmap(Info, "scenario", ...
   @(tbl) sum(tbl.peak > 12));

disp(counts)
%%
%[text] ## Conditional probabilities between two sets of labels
%[text] `groupstats.groupbayes` counts co-occurrences between two sets of labels and reports the marginal, joint, and conditional probabilities.
%[text] Here: given a flood at a sub-basin, how likely is one at the outlet?
B = groupstats.groupbayes(Info, "Outlet", basins, "basin");

B(:, ["GroupA", "GroupB", "P_A", "P_B", "P_B_GIVEN_A", "P_A_GIVEN_B"])
%%
%[text] `Population` chooses the denominator of the marginals. The conditionals are count ratios, so they do not change with it.
B = groupstats.groupbayes(Info, "Outlet", basins, "basin", ...
   Population = "withingroup");

B(:, ["GroupA", "GroupB", "P_A", "P_B"])
%%
%[text] ## Charts
%[text] Every chart takes the same shape: the table, the data variable, then the grouping variables.
figure
groupstats.boxchartcats(Info, "peak", "basin", "scenario")
%%
%[text] `barchartcats` summarizes the data first, and can draw the spread and shade the groups:
figure
groupstats.barchartcats(Info, "peak", "basin", ...
   method = "mean", PlotError = true, ShadeGroups = true)
%%
%[text] Order the groups explicitly. Naming one puts it first and leaves the rest behind it:
figure
groupstats.boxchartcats(Info, "peak", "basin", "scenario", ...
   XGroupOrder = "Outlet")
%%
%[text] `groupstats.histogram` takes the built-in's call shape for categorical data, and a table with a grouping variable as the third argument. This section counts the months when a large flood, one with a peak above 13.5, reached the outlet, so the bar heights differ:
floods = Info(Info.basin == "Outlet" & Info.peak > 13.5, :);

figure
groupstats.histogram(floods.month, ["Jan", "Feb", "Mar"])

figure
groupstats.histogram(floods, "month", "scenario", ...
   Normalization = "probability")
%%
%[text] `groupstats.scatter` colors by one group and sizes by another:
figure
groupstats.scatter(Info, "peak", "peak", "basin")
%%
%[text] ## Option values
%[text] Every name-value option reads the valid values from a namelist function, used for function validators and tab completions.
groupstats.namelists.populationoption()

groupstats.namelists.sortorder()

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
