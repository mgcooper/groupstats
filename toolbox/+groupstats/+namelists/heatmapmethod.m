function names = heatmapmethod()
   %HEATMAPMETHOD Valid values for groupheatmap's Method option.
   %
   %  names = groupstats.namelists.heatmapmethod()
   %
   % Description
   %  Returns the statistics groupheatmap can show in a cell. Each one is a
   %  ColorMethod of the built-in heatmap, which computes it from the rows
   %  of the cell's pairing. "count" counts the non-missing values.
   %
   % See also: groupstats.groupheatmap, groupstats.namelists.mustBeMemberOf

   names = [
      "mean"
      "median"
      "count"
      "sum"
      "min"
      "max"
      ];
end
