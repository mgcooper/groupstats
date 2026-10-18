function legendlayout(L, orientation)
   %LEGENDLAYOUT Place a chart legend by the chart family's rule.
   %
   %  LEGENDLAYOUT(L, ORIENTATION)
   %
   % Puts legend L above its axes. ORIENTATION "vertical" is the default of
   % each chart. It fills up to three columns, so a long list of members
   % wraps into rows instead of one tall column. "horizontal" puts every
   % entry in one row. A legend wider than the outer box of its axes would
   % clip its first column or overlap the next tile. That box is the tile
   % in a tiled layout, the subplot area of a subplot, and the whole figure
   % for a lone axes. So columns drop one at a time until the legend fits,
   % in either orientation. No font size is set, so the legend follows the
   % axes font: MATLAB draws a legend at 0.9 of the axes font size.
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

   % A caller's axes may use any units, so the loop compares both widths in
   % pixels. The legend width updates as soon as the columns change.
   ax = L.Axes;
   while L.NumColumns > 1 ...
         && pixelwidth(L, "Position") > pixelwidth(ax, "OuterPosition")
      L.NumColumns = L.NumColumns - 1;
   end
end

function w = pixelwidth(h, prop)
   %PIXELWIDTH Return the width of position property PROP of H in pixels.
   %
   % A position reads in the object's Units, so this reads it in pixels and
   % puts the caller's Units back.

   units = h.Units;
   h.Units = "pixels";
   w = h.(prop)(3);
   h.Units = units;
end
