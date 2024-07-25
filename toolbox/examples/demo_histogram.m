
% This shows how to create a categorical histogram

%% Compare categorical histogram using built in versus groupstats

% For a simple categorical histogram, groupstats.histogram behaves exactly like
% the built in histogram function
figure(1)
histogram(Info.month, members)

figure(2)
groupstats.histogram(Info, "month")

%% Restrict the categories

% For a categorical histogram restricted to specific categories,
% groupstats.histogram can replicate the built in histogram function, but
% requires different calling syntax

members = {'Jan', 'Feb', 'Mar', 'Apr'};

figure;
histogram(Info.month, members)

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




