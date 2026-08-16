function vars = groupmembers(tbl, GroupVar, PreferredEmptyValue)
   %GROUPMEMBERS Return unique members of a table column (variable)
   %
   %  MEMBERS = GROUPMEMBERS(TBL, GROUPVAR)
   %  MEMBERS = GROUPMEMBERS(TBL, GROUPVAR, PREFERREDEMPTYVALUE)
   %
   % Description
   %  MEMBERS = GROUPMEMBERS(TBL, GROUPVAR) returns the unique values of
   %  TBL.(GROUPVAR), keeping the type that variable holds. An empty GROUPVAR
   %  returns string.empty().
   %
   %  MEMBERS = GROUPMEMBERS(TBL, GROUPVAR, PREFERREDEMPTYVALUE) returns
   %  PREFERREDEMPTYVALUE when GROUPVAR is empty. Pass the empty value of the
   %  type the caller expects, so the return type does not depend on which
   %  branch runs. An arguments-block default such as
   %  `opts.Members (:,1) string = groupmembers(tbl, groupvar)` needs this
   %  when the caller validates the result against a class.
   %
   % Example
   %  tbl = table(categorical(["a"; "b"; "a"]), 'VariableNames', {'Group'});
   %  groupmembers(tbl, "Group")            % categorical a, b
   %  groupmembers(tbl, string.empty())     % string.empty()
   %  groupmembers(tbl, string.empty(), categorical.empty())
   %  % returns categorical.empty()
   %
   % See also: table, unique, tablecompletions

   arguments
      tbl tabular
      GroupVar string = string.empty()
      PreferredEmptyValue = string.empty()
   end

   if isempty(GroupVar)
      vars = PreferredEmptyValue;
   else
      vars = unique(tbl.(GroupVar));
   end
end
