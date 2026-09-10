%% Getting Started with Group Stats
% Install the toolbox, draw a first chart, and explore the toolbox features.

%% Installation
% Choose one:
%
% * Install the package: double-click |GroupStatsToolbox.mltbx|, or build
% it with |buildtool release| from the repository root and install
% |release/GroupStatsToolbox.mltbx|.
% * Add the |toolbox| folder of a repository checkout to the path:
%
%   addpath(fullfile('/path/to/groupstats', 'toolbox'))
%
% Call the functions by their namespace, such as
% |groupstats.groupsummary|. Nothing else has to be on the path, all
% dependencies are included with the toolbox.

%% Requirements
% The test suite passes on R2024b and R2025b. The toolbox needs R2021a
% or later, for |arguments| blocks and |props.?Class| property validation.
% |groupstats.groupcompare| and |groupstats.scatter| need the Statistics
% and Machine Learning Toolbox; the permutation test in |groupcompare| also
% needs the Image Processing Toolbox.

%% A first example
% The fixture table holds one row per scenario, basin, and month, with a
% numeric peak. One box per basin, colored by scenario, in one call:

data = groupstats.test.generateTestData('info');
Info = data.Info;
groupstats.boxchartcats(Info, "peak", "basin", "scenario");

%%
% The same grouping, summarized:

G = groupstats.groupsummary(Info, ["basin", "scenario"], "mean", "peak");
disp(head(G, 6))

%% Where to go next
% * <usingGroupStats.html Using Group Stats> walks through the toolbox on
% this table.
% * <groupstats_examples_contents.html Examples> lists the demos. Run
% |demo_all| to see every one, or |demo_all("-close")| to check that every
% one runs.
% * <m2html/function_index.html Functions> lists every public function.
% * |groupstats.help("groupsummary")| opens one function's page.
