function validatemember(GroupMembers, ValidMembers, FunctionName, ArgName)

   GroupMembers = string(unique(GroupMembers));
   ValidMembers = string(unique(ValidMembers));

   % This requires all GroupMembers be members of ValidMembers, but not the
   % reverse
   arrayfun(@(str) validatestring(str, ValidMembers, FunctionName, ArgName), ...
      GroupMembers);

   % could add this, but would need to remove the unique from the input, or keep
   % it, in which case I would not be able to use this in the manner I do to get
   % the table rows that should be kept, but it would still be useful
   % functionality
   % [ia, ib] = ismember(string(ValidMembers), XGroupMembers);
end
