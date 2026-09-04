function validategroupsets(groupsets)
   %VALIDATEGROUPSETS Reject a scalar "none" as a groupsets value.
   %
   %  VALIDATEGROUPSETS(GROUPSETS)
   %
   % Description
   %  string.empty() is the one no-selection sentinel across the groupstats
   %  family. The string "none" is a real enumerated value only in the
   %  groupbins binning scheme and the SortBy sort order. A scalar groupsets
   %  of "none" is therefore a mistake. This validator rejects it with the
   %  rewrite. Downstream code then never treats it as a variable name.
   %
   % See also: groupstats.groupsummary, groupstats.grouppercent

   arguments
      groupsets (1, :) string
   end

   % groupsummary and grouppercent share this check, so the rejection reads
   % the same from every entry point.
   if isscalar(groupsets) && groupsets == "none"
      error('groupstats:validategroupsets:noneIsNotASentinel', ...
         ['groupsets = "none" is not accepted. Pass string.empty() or ' ...
         'omit the argument to request no groupsets.'])
   end
end
