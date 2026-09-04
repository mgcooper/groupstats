function names = mergemethod()
   %MERGEMETHOD Valid values for barchartcats' MergeMethod option.
   %
   %  names = groupstats.namelists.mergemethod()
   %
   % Description
   %  Returns the two ways barchartcats computes a merged bar. "pooled"
   %  summarizes the pooled member rows, matching the other charts, which
   %  plot raw rows. "membermean" takes the unweighted mean of the member
   %  bars' summary values, which weights each member group equally
   %  regardless of its row count.
   %
   % See also: groupstats.barchartcats, groupstats.namelists.mustBeMemberOf

   names = [
      "pooled"
      "membermean"
      ];
end
