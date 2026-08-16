%% Categorical histograms with groupstats.histogram
%
% groupstats.histogram plots a histogram of a categorical table variable,
% and adds grouping and row selection that the built in histogram does not
% have.
%
% See also: groupstats.histogram, histogram,
% groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');

% The fixture holds one row per scenario, month, and basin, so every month
% has the same number of rows. Keep the larger peaks, which are seasonal and
% grow with the scenario, so the counts differ month to month.
Info = data.Info(data.Info.peak > 12, :);

%% Compare categorical histogram using built in versus groupstats

% For a simple categorical histogram, groupstats.histogram behaves exactly like
% the built in histogram function, and takes the same call shape.
figure
histogram(Info.month)

figure
groupstats.histogram(Info.month)

% It also reads a table and a variable name, which the built in cannot.
figure
groupstats.histogram(Info, "month")

% One difference: groupstats.histogram labels the y-axis with the
% Normalization, which is "count" by default. The built in leaves it blank.

%% Restrict the categories

% For a categorical histogram restricted to specific categories,
% groupstats.histogram can replicate the built in histogram function, but
% requires different calling syntax

members = {'Jan', 'Feb', 'Mar', 'Apr'};

figure;
histogram(Info.month, members)

% groupstats.histogram takes the same positional category list.
figure;
groupstats.histogram(Info.month, members)

% The table form names the members instead.
figure;
groupstats.histogram(Info, "month", "GroupMembers", members);

%% Use grouping variables

% When additional grouping or filtering is desired, the groupstats.histogram
% function becomes much more useful.

figure
groupstats.histogram(Info, "month", "GroupVar", "scenario", ...
   "GroupMembers", "1980-2020-WRF-DIST", "Normalization", "probability")
hold on
groupstats.histogram(Info, "month", "GroupVar", "scenario", ...
   "GroupMembers", "SSP585-HOT-FAR", "Normalization", "probability")

% Or in one line:
figure
groupstats.histogram(Info, "month", "GroupVar", "scenario", ...
   "GroupMembers", ["1980-2020-WRF-DIST", "SSP585-HOT-FAR"], ...
   "Normalization", "probability")
