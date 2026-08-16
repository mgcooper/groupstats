function names = sortorder()
   %SORTORDER Valid values for a SortBy option that can also skip sorting.
   %
   %  names = groupstats.namelists.sortorder()
   %
   % Description
   %  Returns the sort directions plus "none", which leaves the groups in the
   %  order they already have.
   %
   % See also: groupstats.namelists.sortdirection, groupstats.barchartcats,
   % groupstats.boxchartcats

   names = [
      groupstats.namelists.sortdirection()
      "none"
      ];
end
