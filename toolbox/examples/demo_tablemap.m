
% Jul 2024 - added dummy definition of basins to address codeissues
basins = ["basinA", "basinB", "basinC"];
scenarios = ["scenarioA", "scenarioB", "scenarioC"];

% These are equivalent:
fcn = @(tbl) groupstats.groupbayes(tbl, basins, basins, "basin");
P = groupmap(Info, "scenario", fcn);

P = groupmap(Info, "scenario", @groupstats.groupbayes, basins, basins, "basin");

P = cell(numel(scenarios), 1);
for n = 1:numel(scenarios)
   T = Info(Info.scenario == scenarios(n), :);
   P{n} = groupstats.groupbayes(T, basins, basins, "basin");
   P{n}.scenario = categorical(repmat(scenarios(n), height(P{n}), 1));
end
P = stacktables(P{:});
