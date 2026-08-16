function tbl = groupselect(tbl, varnames, groupmembers)
   %GROUPSELECT Select rows of table by variable name and group members.
   %
   %  TBL = GROUPSELECT(TBL, VARNAMES, GROUPMEMBERS)
   %
   % Description
   %  TBL = GROUPSELECT(TBL, VARNAMES, GROUPMEMBERS) returns the rows of TBL
   %  whose value in one of the VARNAMES variables is a member of
   %  GROUPMEMBERS. Exactly one of VARNAMES must hold every member of
   %  GROUPMEMBERS. That is the variable the rows are selected by.
   %
   %  Searching several variable names lets a caller pass a member list
   %  without knowing which variable carries it.
   %
   % Example
   %  tbl = table(["a";"b";"c"], [1;2;3], 'VariableNames', {'Group','Value'});
   %  groupselect(tbl, "Group", ["a" "b"])   % the first two rows
   %
   % Errors
   %  groupstats:groupselect:noMembersRequested - GROUPMEMBERS is empty.
   %  groupstats:groupselect:noMatchingVariable - No variable holds every
   %  requested member.
   %  groupstats:groupselect:ambiguousVariable - More than one variable holds
   %  every requested member, so the selection variable is ambiguous.
   %
   % See also: groupstats.prepareTableGroups, ismember

   arguments
      tbl tabular
      varnames (:, 1) string
      groupmembers (:, 1) string
   end

   % all([]) is true, so an empty member set matches every variable. Report
   % the empty request it is, rather than an ambiguous match between
   % variables that hold nothing in common.
   if isempty(groupmembers)
      error('groupstats:groupselect:noMembersRequested', ...
         'Requested no members. Name at least one member to select rows by.')
   end

   % Find which groupvar contains the groupvarselect
   tf = arrayfun(@(var) all(ismember(groupmembers, string(unique(tbl.(var))))), ...
      varnames);

   % enforce one groupvar for downselection
   if sum(tf) > 1
      error('groupstats:groupselect:ambiguousVariable', ...
         ['only one groupvar can be downselected using %s. ' ...
         'These hold every requested member: %s.'], ...
         mfilename, strjoin(varnames(tf), ', '))
   end

   % Name the members and the variables searched, so the caller can see which
   % side of the lookup was wrong.
   if ~any(tf)
      error('groupstats:groupselect:noMatchingVariable', ...
         ['No variable holds every member of the requested set. ' ...
         'Requested: %s. Variables searched: %s.'], ...
         strjoin(groupmembers, ', '), strjoin(varnames, ', '))
   end

   % Remove members of groupvars that are "groupvarselect"
   tbl = tbl(ismember(string(tbl.(varnames(tf))), groupmembers), :);
end
