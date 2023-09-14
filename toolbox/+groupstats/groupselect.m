function T = groupselect(T, varnames, groupmembers)
   %GROUPSELECT Select rows of table by variable name and group members.
   %
   % T = groupselect(T, groupvars, selectvars) returns T with rows for which
   % ismember(selectvars, T.(groupvars(n))) is true, for n = 1:numel(groupvars).
   %
   % See also: groupstats

   arguments
      T table
      varnames (:, 1) string
      groupmembers (:, 1) string
   end

   % Find which groupvar contains the groupvarselect
   tf = arrayfun(@(var) all(ismember(groupmembers, string(unique(T.(var))))), ...
      varnames);

   % enforce one groupvar for downselection
   assert(sum(tf) <= 1, ['only one groupvar can be downselected using ' mfilename])

   % Remove members of groupvars that are "groupvarselect"
   T = T(ismember(string(T.(varnames(tf))), groupmembers), :);
end
