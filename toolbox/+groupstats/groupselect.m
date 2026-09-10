function tbl = groupselect(tbl, groupvars, groupmembers)
   %GROUPSELECT Select rows of table by variable name and group members.
   %
   %  TBL = GROUPSELECT(TBL, GROUPVARS, GROUPMEMBERS)
   %
   % Description
   %  TBL = GROUPSELECT(TBL, GROUPVARS, GROUPMEMBERS) returns the rows of TBL
   %  whose value in one of the GROUPVARS variables is a member of
   %  GROUPMEMBERS. Exactly one of GROUPVARS must hold every member of
   %  GROUPMEMBERS. That is the variable the rows are selected by.
   %
   %  Searching several variable names lets a caller pass a member list
   %  without knowing which variable carries it.
   %
   % Example
   %  tbl = table(["a";"b";"c"], [1;2;3], 'VariableNames', {'Group','Value'});
   %  groupstats.groupselect(tbl, "Group", ["a" "b"])   % the first two rows
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
      groupvars (:, 1) string
      groupmembers (:, 1) string
   end

   % all([]) is true, so an empty member set matches every variable. Report
   % the empty request it is, rather than an ambiguous match between
   % variables that hold nothing in common.
   if isempty(groupmembers)
      error('groupstats:groupselect:noMembersRequested', ...
         'Requested no members. Name at least one member to select rows by.')
   end

   % Find which group variable contains every requested member
   tf = arrayfun(@(var) all(ismember(groupmembers, string(unique(tbl.(var))))), ...
      groupvars);

   % enforce one group variable for downselection
   if sum(tf) > 1
      error('groupstats:groupselect:ambiguousVariable', ...
         ['only one group variable can be downselected using %s. ' ...
         'These hold every requested member: %s.'], ...
         mfilename, strjoin(groupvars(tf), ', '))
   end

   % Name the members and the variables searched, so the caller can see which
   % side of the lookup was wrong.
   if ~any(tf)
      error('groupstats:groupselect:noMatchingVariable', ...
         ['No variable holds every member of the requested set. ' ...
         'Requested: %s. Variables searched: %s.'], ...
         strjoin(groupmembers, ', '), strjoin(groupvars, ', '))
   end

   % Keep the rows whose selected variable's value is a requested member
   tbl = tbl(ismember(string(tbl.(groupvars(tf))), groupmembers), :);
end
