function mustBeMemberOf(value, listname)
   %MUSTBEMEMBEROF Validate a value against a named list in this package.
   %
   %  groupstats.namelists.mustBeMemberOf(value, listname)
   %
   % Description
   %  Errors when VALUE is not a member of the list that the function
   %  LISTNAME in this package returns.
   %
   %  Use this in an arguments block. A validator's arguments can only be
   %  literals, the argument being validated, or an earlier positional
   %  argument, so mustBeMember(x, populationoption()) is rejected. Pass the
   %  list name, which is a literal:
   %
   %    opts.Population (1, 1) string ...
   %       {groupstats.namelists.mustBeMemberOf(opts.Population, ...
   %       "populationoption")} = "union"
   %
   % Errors
   %  groupstats:namelists:unknownList - no function of that name exists in
   %  this package.
   %
   % See also: mustBeMember, groupstats.namelists.populationoption

   arguments
      value
      listname (1, 1) string
   end

   if isempty(which("groupstats.namelists." + listname))
      error('groupstats:namelists:unknownList', ...
         'No namelist named %s. Add %s.m to +groupstats/+namelists.', ...
         listname, listname)
   end

   names = feval("groupstats.namelists." + listname);

   % mustBeMember reports the value and the whole list, which is the message
   % a caller needs.
   mustBeMember(value, names)
end
