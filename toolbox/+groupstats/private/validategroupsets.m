function validategroupsets(groupsets)
   %VALIDATEGROUPSETS Reject a scalar "none" as a GroupSets value.
   %
   %  VALIDATEGROUPSETS(GROUPSETS)
   %
   % Description
   %  string.empty() is the one no-selection sentinel across the groupstats
   %  family. The string "none" is a real enumerated value only in the
   %  groupbins binning scheme and the SortBy sort order. A scalar GroupSets
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
         ['GroupSets = "none" is not accepted. Pass string.empty() or ' ...
         'omit the option to request no groupsets.'])
   end
end
