function validaterowselect(rowselectvar, rowselectmembers, fname, displayname)
   %VALIDATEROWSELECT Require both halves of a row-selection request.
   %
   %  VALIDATEROWSELECT(ROWSELECTVAR, ROWSELECTMEMBERS, FNAME, DISPLAYNAME)
   %
   % Description
   %  Row selection needs the variable and the members together. A variable
   %  with no members selects no rows and leaves an empty result. Members
   %  with no variable have no column to search. Each half alone is an
   %  error. FNAME sets the identifier prefix groupstats:<FNAME>, so the
   %  identifier belongs to the throwing function. DISPLAYNAME names the
   %  user-facing function in the message.
   %
   % See also: groupstats.prepareTableGroups, groupstats.groupsummary

   arguments
      rowselectvar string
      rowselectmembers (:, 1) string
      fname (1, 1) string
      displayname (1, 1) string
   end

   % groupsummary and prepareTableGroups share this check, so the whole
   % family reads the same two errors for a half-made request.
   if ~isempty(rowselectvar) && isempty(rowselectmembers)
      error(sprintf('groupstats:%s:rowSelectVarWithoutMembers', fname), ...
         ['%s: RowSelectVar names %s, and RowSelectMembers is empty. ' ...
         'Name the members to keep, or leave both out.'], ...
         displayname, rowselectvar)
   end
   if isempty(rowselectvar) && ~isempty(rowselectmembers)
      error(sprintf('groupstats:%s:membersWithoutGroupVar', fname), ...
         ['%s: RowSelectMembers was given without RowSelectVar. ' ...
         'Name the row-selection variable too.'], displayname)
   end
end
