function validategroupvarnames(groupvars, resultvars, fname)
   %VALIDATEGROUPVARNAMES Reject a grouping variable named like a result column.
   %
   %  VALIDATEGROUPVARNAMES(GROUPVARS, RESULTVARS, FNAME)
   %
   % Description
   %  The grouping columns share the result table with the columns a
   %  function adds, RESULTVARS. The function would read a grouping
   %  variable with one of those names as that column, or one of the two
   %  would overwrite the other. This validator rejects it with
   %  groupstats:<FNAME>:reservedName, so the identifier belongs to the
   %  throwing function.
   %
   % See also: groupstats.groupsummary, groupstats.grouppercent,
   % groupstats.groupci

   arguments
      groupvars string
      resultvars (1, :) string
      fname (1, 1) string
   end

   % groupsummary, grouppercent, and groupci share this check, so the
   % family rejects the names of its result columns the same way.
   clash = intersect(groupvars, resultvars);
   if ~isempty(clash)
      error(sprintf('groupstats:%s:reservedName', fname), ...
         ['Grouping variable "%s" has the name of a result column. ' ...
         'Rename it; the result columns are %s.'], ...
         clash(1), strjoin(resultvars, ", "))
   end
end
