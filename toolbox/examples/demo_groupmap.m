%% Apply a function to each group of a table with groupmap
%
% groupmap splits a table by a grouping variable, applies a function to each
% group, and stacks the results with the group label in the first column.
%
% The Info fixture holds one row per scenario, basin, and month, and one
% logical column per basin naming the basins that flood in that row.
%
% See also: groupstats.groupmap, groupstats.groupbayes,
% groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');

Info = data.Info;
basins = data.basins;
scenarios = data.scenarios;

%% Call groupmap with an anonymous function
%
% The function receives one scenario's rows and returns a table.

fcn = @(tbl) groupstats.groupbayes(tbl, basins, basins, "basin");

P = groupstats.groupmap(Info, "scenario", fcn);

disp(head(P, 4));

%% Call groupmap with a function handle and trailing arguments
%
% groupmap passes the trailing arguments to the function after the table.
% This is the same computation as above.

P = groupstats.groupmap(Info, "scenario", @groupstats.groupbayes, ...
   basins, basins, "basin");

%% The equivalent loop
%
% groupmap replaces this. The loop is here to show what it does.

byscenario = cell(numel(scenarios), 1);
for n = 1:numel(scenarios)
   tbl = Info(Info.scenario == scenarios(n), :);
   byscenario{n} = groupstats.groupbayes(tbl, basins, basins, "basin");
   byscenario{n}.scenario = categorical( ...
      repmat(scenarios(n), height(byscenario{n}), 1));
end
expected = stacktables(byscenario{:});

fprintf('groupmap rows: %d, loop rows: %d\n', height(P), height(expected));
