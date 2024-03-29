
% These are equivalent:

fcn = @(tbl) groupstats.groupbayes(tbl, basins, basins, "basin");
P = tablemap(Info, "scenario", fcn);

P = tablemap(Info, "scenario", @groupstats.groupbayes, basins, basins, "basin");

P = cell(numel(scenarios), 1);
for n = 1:numel(scenarios)
   T = Info(Info.scenario == scenarios(n), :);
   P{n} = groupstats.groupbayes(T, basins, basins, "basin");
   P{n}.scenario = categorical(repmat(scenarios(n), height(P{n}), 1));
end
P = stacktables(P{:});