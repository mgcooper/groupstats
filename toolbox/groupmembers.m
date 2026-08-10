function vars = groupmembers(tbl, GroupVar, PreferredEmptyValue)
   %GROUPMEMBERS Return unique members of a table column (variable)
   %
   %
   %
   % See also: table, tablecompletions
   if isempty(GroupVar)
      vars = string.empty();
   else
      vars = unique(tbl.(GroupVar));
   end
end
