%% Grouped confidence intervals with groupstats.groupci
%
% groupci returns the confidence interval of each group's center as a
% table, one row per pairing of an x-group member with a color-group
% member. Method="mean" gives the Student t interval of the mean.
% Method="median" gives the notch that boxchartcats draws. barchartcats
% draws the same intervals as error bars with ErrorBar="ci".
%
% This demo shows the interval table, compares the median interval with
% the boxchartcats notch, and draws both intervals as bar error bars.
%
% See also: groupstats.groupci, groupstats.boxchartcats,
% groupstats.barchartcats, groupstats.boxchartydata,
% groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');
Info = data.Info;
months = ["Jan", "Feb", "Mar"];

%% The interval table
%
% groupci takes the grouping arguments of the cats charts. Each row holds
% the number of non-missing values N, the mean, and the bounds of its 95%
% interval. The rows follow the category order of month, then scenario.

ci = groupstats.groupci(Info, "peak", "month", "scenario", ...
   XGroupMembers = months);
disp(ci)

%% Set the level of the mean interval
%
% Alpha is the significance level, 0.05 by default. Alpha = 0.10 gives a
% 90% interval, which is narrower than the 95% one.

ci95 = groupstats.groupci(Info, "peak", "month", XGroupMembers = months);
ci90 = groupstats.groupci(Info, "peak", "month", XGroupMembers = months, ...
   Alpha = 0.10);
widths = table(ci95.month, ci95.CIUpper - ci95.CILower, ...
   ci90.CIUpper - ci90.CILower, ...
   'VariableNames', ["month", "Width95", "Width90"]);
disp(widths)

%% The median interval is the boxchartcats notch
%
% Method="median" returns the notch, median +/- 1.57 * IQR / sqrt(N). It is
% a comparison interval: when two notches do not overlap, the medians
% differ at about the 5% level. Its level is fixed, so it takes no Alpha.
%
% boxchartcats draws the notches. The triangles mark the groupci bounds,
% and each one sits on a notch end.

cimedian = groupstats.groupci(Info, "peak", "month", ...
   XGroupMembers = months, Method = "median");
disp(cimedian)

figure
[H, ~, ax] = groupstats.boxchartcats(Info, "peak", "month", ...
   XGroupMembers = months, PlotMeans = false);
xlocs = groupstats.boxchartxdata(H);
hold(ax, "on")
scatter(ax, xlocs, cimedian.CILower, 60, "k", "^", "filled")
scatter(ax, xlocs, cimedian.CIUpper, 60, "k", "v", "filled")
hold(ax, "off")
title("groupci median bounds on the boxchartcats notches")

% boxchartydata returns the same notch for one box's values.
notch = groupstats.boxchartydata(Info.peak(Info.month == "Jan")).notches;
disp(notch)

%% Draw the interval as a bar error bar
%
% PlotError=true with ErrorBar="ci" draws the groupci interval as the
% whisker of each bar. The whisker tips equal the CILower and CIUpper of
% the table. The default ErrorBar="spread" keeps the standard deviation
% whisker. PlotError needs one bar per x-tick, so omit the color group.

figure
groupstats.barchartcats(Info, "peak", "month", ...
   PlotError = true, ErrorBar = "ci");
title("Mean peak with 95% confidence interval whiskers")

figure
groupstats.barchartcats(Info, "peak", "month", ...
   Method = "median", PlotError = true, ErrorBar = "ci");
title("Median peak with notch whiskers")

%% Empty pairings, one value, and missing data
%
% A pairing with no values is a row with N = 0 and NaN bounds. One value
% gives its value as the estimate and NaN bounds, because one value has no
% spread. NaN values do not count in N. A chart draws no box or whisker
% for these rows.

small = table( ...
   categorical(["a"; "a"; "a"; "b"; "b"]), ...
   categorical(["x"; "x"; "x"; "x"; "y"]), ...
   [1; NaN; 3; 5; NaN], ...
   'VariableNames', ["Site", "Sensor", "Reading"]);

cismall = groupstats.groupci(small, "Reading", "Site", "Sensor");
disp(cismall)
