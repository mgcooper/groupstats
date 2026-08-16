function names = sortdirection()
   %SORTDIRECTION Valid sort directions.
   %
   %  names = groupstats.namelists.sortdirection()
   %
   % Description
   %  Returns the directions the toolbox passes to sort. A chart that also
   %  accepts a no-sort value takes its list from
   %  groupstats.namelists.sortorder instead.
   %
   % See also: groupstats.namelists.sortorder, sort

   names = [
      "ascend"
      "descend"
      ];
end
