function tbl = groupselect(tbl, varnames, groupmembers)
   %GROUPSELECT Select rows of table by variable name and group members.
   %
   % tbl = groupselect(tbl, groupvars, selectvars) returns tbl with rows for which
   % ismember(selectvars, tbl.(groupvars(n))) is true, for n = 1:numel(groupvars).
   %
   % See also: groupstats

   arguments
      tbl table
      varnames (:, 1) string
      groupmembers (:, 1) string
   end

   % Find which groupvar contains the groupvarselect
   tf = arrayfun(@(var) all(ismember(groupmembers, string(unique(tbl.(var))))), ...
      varnames);

   % enforce one groupvar for downselection
   assert(sum(tf) <= 1, ['only one groupvar can be downselected using ' mfilename])

   % Remove members of groupvars that are "groupvarselect"
   tbl = tbl(ismember(string(tbl.(varnames(tf))), groupmembers), :);
end
