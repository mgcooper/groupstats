function names = sortorder()
   %SORTORDER Valid values for the SortBy option on every chart.
   %
   %  names = groupstats.namelists.sortorder()
   %
   % Description
   %  Returns the two sort directions plus "none", which leaves the groups
   %  in the order they already have. "none" is the default on every
   %  chart.
   %
   % See also: groupstats.barchartcats, groupstats.boxchartcats,
   % groupstats.scatter, groupstats.histogram

   names = [
      "ascend"
      "descend"
      "none"
      ];
end
