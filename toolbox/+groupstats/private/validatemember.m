function validatemember(GroupMembers, ValidMembers, FunctionName, ArgName)
   %VALIDATEMEMBER Confirm every group member is an exact valid member.
   %
   %  VALIDATEMEMBER(GROUPMEMBERS, VALIDMEMBERS, FUNCTIONNAME, ARGNAME)
   %
   % Description
   %  VALIDATEMEMBER(GROUPMEMBERS, VALIDMEMBERS, FUNCTIONNAME, ARGNAME) raises
   %  an error if any element of GROUPMEMBERS is absent from VALIDMEMBERS.
   %  FUNCTIONNAME and ARGNAME name the calling function and the argument in
   %  the error message. The check is one-way: VALIDMEMBERS may hold members
   %  that GROUPMEMBERS does not name.
   %
   %  Matching is exact. A partial match such as "Jan" against "January" is
   %  an error, because the caller selects its rows with an exact ismember and
   %  a partial match would select none of them.
   %
   % Example
   %  validatemember("Jan", ["Jan" "Feb"], 'BOXCHARTCATS', 'XGroupMembers')
   %  validatemember("Jan", ["January" "February"], 'BOXCHARTCATS', 'X')
   %  % The second call errors.
   %
   % See also: ismember, groupmembers, groupstats.prepareTableGroups

   GroupMembers = string(unique(GroupMembers));
   ValidMembers = string(unique(ValidMembers));

   % This requires all GroupMembers be members of ValidMembers, but not the
   % reverse
   notfound = GroupMembers(~ismember(GroupMembers, ValidMembers));

   if ~isempty(notfound)
      error('groupstats:validatemember:notAMember', ...
         ['%s: %s must name members of the group variable. ' ...
         'Not found: %s. Valid members: %s.'], ...
         FunctionName, ArgName, strjoin(notfound, ', '), ...
         strjoin(ValidMembers, ', '))
   end

   % could add this, but would need to remove the unique from the input, or keep
   % it, in which case I would not be able to use this in the manner I do to get
   % the table rows that should be kept, but it would still be useful
   % functionality
   % [ia, ib] = ismember(string(ValidMembers), XGroupMembers);
end
