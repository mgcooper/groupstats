function legendlayout(L, orientation)
   %LEGENDLAYOUT Place a chart legend by the chart family's rule.
   %
   %  LEGENDLAYOUT(L, ORIENTATION)
   %
   % Puts legend L above its axes. ORIENTATION "vertical" is the default of
   % each chart. It fills up to three columns, so a long list of members
   % wraps into rows instead of one tall column. "horizontal" puts every
   % entry in one row. A legend wider than its figure would clip its first
   % column, so columns drop one at a time until it fits. No font size is
   % set, so the legend follows the axes font: MATLAB draws a legend at 0.9
   % of the axes font size.
   %
   % See also: groupstats.barchartcats, groupstats.boxchartcats,
   % groupstats.histogram, groupstats.scatter

   if isempty(L) || ~isgraphics(L)
      return
   end

   numentries = max(numel(L.String), 1);
   if orientation == "horizontal"
      numcolumns = numentries;
   else
      numcolumns = min(numentries, 3);
   end
   set(L, 'Location', 'northoutside', 'Orientation', char(orientation), ...
      'NumColumns', numcolumns);

   % The legend position is in normalized figure units unless a caller
   % changed the default, and it updates as soon as the columns change.
   while L.NumColumns > 1 && L.Units == "normalized" && L.Position(3) > 1
      L.NumColumns = L.NumColumns - 1;
   end
end
