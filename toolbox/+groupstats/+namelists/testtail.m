function names = testtail()
   %TESTTAIL Valid values for the tail of a rank test.
   %
   %  names = groupstats.namelists.testtail()
   %
   % Description
   %  Returns the values signrank and ranksum accept for their tail option:
   %
   %    both  - the medians differ. The default.
   %    right - the first median is greater.
   %    left  - the first median is less.
   %
   % See also: groupstats.groupdifference, signrank, ranksum

   names = [
      "both"
      "right"
      "left"
      ];
end
