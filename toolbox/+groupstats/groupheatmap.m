function h = groupheatmap(tbl, ydatavar, xgroupvar, cgroupvar, opts, props)
   %GROUPHEATMAP Heatmap of a grouped summary, one cell per pairing.
   %
   %  H = GROUPHEATMAP(TBL, YDATAVAR, XGROUPVAR, CGROUPVAR)
   %  H = GROUPHEATMAP(_, Name=Value)
   %  H = GROUPHEATMAP(_, HeatmapChartProperty=Value)
   %
   % Description
   %  H = GROUPHEATMAP(TBL, YDATAVAR, XGROUPVAR, CGROUPVAR) draws a heatmap
   %  with one column per member of XGROUPVAR and one row per member of
   %  CGROUPVAR. The color of each cell is the mean of YDATAVAR over the
   %  rows of that pairing. H is the built-in HeatmapChart.
   %
   %  The chart has two grouping axes, so all four arguments are required.
   %  The grouping arguments are those of the cats charts, so the same
   %  selection and merge give the same pairings.
   %
   % Name-value arguments
   %  XGroupMembers      Members of XGROUPVAR to keep. Empty keeps them all.
   %  CGroupMembers      Members of CGROUPVAR to keep. Empty keeps them all.
   %  RowSelectVar       A variable that selects rows. Give it together
   %                     with RowSelectMembers.
   %  RowSelectMembers   The members of RowSelectVar whose rows to keep.
   %  MergeGroupMembers  CGROUPVAR members to pool into one row, as in the
   %                     cats charts. Give a cell array of string vectors; a
   %                     bare string vector is one merge group. The merged
   %                     label joins the names with " and ", and the merged
   %                     row takes the position of its first member. Each
   %                     merged cell uses the pooled rows. CGroupMembers
   %                     reads the original names; the orders read the
   %                     merged names.
   %  Method             The statistic of each cell: "mean" (default),
   %                     "median", "count", "sum", "min", or "max". "count"
   %                     counts the non-missing YDATAVAR values.
   %  XGroupOrder        XGROUPVAR members in the column order to show.
   %                     Named members come first, and the rest keep their
   %                     order. "none" (default) keeps the category order.
   %  CGroupOrder        CGROUPVAR members in the row order to show, as
   %                     XGroupOrder does for the columns.
   %  SortBy             "ascend", "descend", or "none" (default). Orders
   %                     the columns by the mean of their cell values over
   %                     the SortGroupMembers rows. The mean ignores NaN, and
   %                     a column with no value goes last. ColorScaling does
   %                     not change the sort. An XGroupOrder wins over SortBy.
   %  SortGroupMembers   CGROUPVAR members whose rows enter the sort mean.
   %                     Empty, the default, uses every row. Give merged
   %                     names after a merge.
   %  Parent             A figure, panel, tab, or tiled chart layout. The
   %                     chart replaces the current axes or chart in that
   %                     container, and other figures stay as they are. In a
   %                     tiled layout, call nexttile before each chart, as
   %                     with heatmap. Without Parent, the chart replaces the
   %                     current axes or chart of the current figure.
   %
   %  Any other name-value argument sets that HeatmapChart property, for
   %  example Title, Colormap, ColorLimits, CellLabelFormat,
   %  MissingDataColor, ColorbarVisible, or Interpreter. groupheatmap sets
   %  Interpreter="none", so variable names show as they are; a caller value
   %  wins. The built-in title and axis labels stay. groupheatmap sets the
   %  data properties from the inputs above, so passing one raises an error
   %  that names its input.
   %
   % Empty pairings and missing values
   %  The built-in heatmap removes rows with a NaN YDATAVAR value before it
   %  summarizes. A pairing with no values shows NaN for "mean", "median",
   %  "min", and "max", which draws in MissingDataColor. It shows 0 for
   %  "count" and "sum". A pairing with some NaN values shows the statistic
   %  of the others. groupheatmap drops a row with a missing group value.
   %
   % Colors
   %  The heatmap colormap colors the cells, and the colorbar takes the
   %  place of a legend. The family's categorical palette, defaultcolors,
   %  does not apply.
   %
   % Timetables
   %  XGROUPVAR or CGROUPVAR can name the time dimension of a timetable.
   %  Each distinct time is one member.
   %
   % Example
   %  data = groupstats.test.generateTestData('groupsummary');
   %  h = groupstats.groupheatmap(data.tbl, "Value", "Grp", "Sub");
   %  h.ColorDisplayData   % [2 6 10; 3 7 11]
   %
   %  h = groupstats.groupheatmap(data.tbl, "Value", "Grp", "Sub", ...
   %     Method = "count", Title = "Rows per pairing");
   %  h.ColorDisplayData   % [2 2 2; 2 2 2]
   %
   % Errors
   %  groupstats:groupheatmap:nonNumericData - YDATAVAR is not numeric or
   %  logical after the conversion that the cats charts apply. A categorical
   %  whose categories are numbers converts to double; text does not. The
   %  error comes before any graphics exist.
   %  groupstats:groupheatmap:dataProperty - A data property of the
   %  HeatmapChart was passed. The message names the input that sets it.
   %
   % See also: heatmap, groupstats.boxchartcats, groupstats.barchartcats,
   % groupstats.groupci

   arguments
      tbl tabular
      ydatavar (1, 1) string {mustBeNonempty}
      xgroupvar (1, 1) string {mustBeNonempty}
      % Required: a heatmap has a second axis, so it needs a second
      % grouping.
      cgroupvar (1, 1) string {mustBeNonempty}

      % Empty selects every member, which prepareTableGroups reads as no
      % filter.
      opts.XGroupMembers (:, 1) string = string.empty()
      opts.CGroupMembers (:, 1) string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers (:, 1) string = string.empty()

      % Untyped because a cell array of string vectors is one valid shape.
      opts.MergeGroupMembers (:, 1) = string.empty()

      opts.Method (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Method, ...
         "heatmapmethod")} = "mean"
      opts.XGroupOrder (:, 1) string = "none"
      opts.CGroupOrder (:, 1) string = "none"
      opts.SortBy (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.SortBy, ...
         "sortorder")} = "none"
      % Empty, the family's no-selection sentinel, uses every row.
      opts.SortGroupMembers (:, 1) string = string.empty()

      % No default: without Parent the built-in uses the current figure,
      % and a default here would have to create one.
      opts.Parent (1, 1) {mustBeA(opts.Parent, ["matlab.ui.Figure", ...
         "matlab.ui.container.Panel", "matlab.ui.container.Tab", ...
         "matlab.graphics.layout.TiledChartLayout"])}

      props.?matlab.graphics.chart.HeatmapChart
   end

   % H is the only output: a HeatmapChart has no legend and no axes.
   nargoutchk(0, 1)

   import groupstats.prepareTableGroups

   % groupheatmap sets these properties from its own inputs. A caller value
   % would draw a chart that the inputs do not describe, so name the input.
   dataprops = struct( ...
      SourceTable = "tbl", ...
      XVariable = "xgroupvar", ...
      YVariable = "cgroupvar", ...
      ColorVariable = "ydatavar", ...
      ColorMethod = "Method", ...
      XData = "xgroupvar and XGroupMembers", ...
      YData = "cgroupvar and CGroupMembers", ...
      ColorData = "ydatavar and Method", ...
      XDisplayData = "XGroupOrder or SortBy", ...
      YDisplayData = "CGroupOrder");
   given = intersect(fieldnames(props), fieldnames(dataprops));
   if ~isempty(given)
      error('groupstats:groupheatmap:dataProperty', ...
         ['%s is a data property that groupheatmap sets. Give %s ' ...
         'instead.'], given{1}, dataprops.(given{1}))
   end

   % Select rows and prepare the groupings as the cats charts do, so the
   % same arguments give the same pairings and the same data conversion.
   tbl = prepareTableGroups(tbl, ydatavar, ...
      XGroupVar = xgroupvar, ...
      XGroupMembers = opts.XGroupMembers, ...
      CGroupVar = cgroupvar, ...
      CGroupMembers = opts.CGroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers);

   % Merge after member filtering, as the charts do, so CGroupMembers reads
   % the original names. mergecats puts the merged category at its first
   % member's position, which sets the merged row's position.
   if ~isempty(opts.MergeGroupMembers)
      tbl.(cgroupvar) = mergegroupmembers( ...
         tbl.(cgroupvar), opts.MergeGroupMembers);
   end

   % A cell color needs a number. prepareTableGroups converts a categorical
   % whose categories are numbers, so check after it, and before any
   % graphics exist, so an error leaves no chart.
   y = tbl.(ydatavar);
   if ~(isnumeric(y) || islogical(y))
      error('groupstats:groupheatmap:nonNumericData', ...
         ['%s is %s. groupheatmap needs numeric or logical data to ' ...
         'color a cell.'], ydatavar, class(y))
   end
   tbl.(ydatavar) = double(y);

   % SortGroupMembers names cgroupvar members, after any merge, so check it
   % against the merged names. A name that matches no member would sort by
   % nothing and report nothing.
   if ~isempty(opts.SortGroupMembers)
      validatemember(opts.SortGroupMembers, tbl.(cgroupvar), ...
         'GROUPHEATMAP', 'SortGroupMembers')
   end

   % The built-in computes each cell from the table rows. Interpreter goes
   % before the caller's properties, so a caller value wins.
   parent = {};
   if isfield(opts, 'Parent')
      parent = {opts.Parent};
   end
   varargs = namedargs2cell(props);
   h = heatmap(parent{:}, tbl, xgroupvar, cgroupvar, ...
      'ColorVariable', ydatavar, ...
      'ColorMethod', opts.Method, ...
      'Interpreter', 'none', ...
      varargs{:});

   % Order the rows and columns through the display data, which leaves the
   % cell values as the built-in computed them.
   orderRows(h, opts);
   orderColumns(h, opts);
end

function orderRows(h, opts)
   %ORDERROWS Apply CGroupOrder to the rows, as the cats charts do.
   %
   % A partial order names some members and leaves the rest behind them.

   if isscalar(opts.CGroupOrder) && opts.CGroupOrder == "none"
      return
   end
   members = string(h.YData);
   idx = reordergroupmembers(opts.CGroupOrder, members, ...
      "groupheatmap", "CGroupOrder");
   h.YDisplayData = cellstr(members(idx));
end

function orderColumns(h, opts)
   %ORDERCOLUMNS Apply XGroupOrder, or else SortBy, to the columns.
   %
   % An explicit XGroupOrder wins, as in the cats charts. SortBy reads the
   % cell values in ColorData, whose rows and columns follow YData and
   % XData. ColorScaling changes only the drawn colors, so it does not
   % change the sort.

   members = string(h.XData);
   if ~(isscalar(opts.XGroupOrder) && opts.XGroupOrder == "none")
      idx = reordergroupmembers(opts.XGroupOrder, members, ...
         "groupheatmap", "XGroupOrder");
   elseif opts.SortBy ~= "none"
      % The mean of each column over the selected rows. A column with no
      % value there is NaN, which sort puts last.
      rows = true(numel(h.YData), 1);
      if ~isempty(opts.SortGroupMembers)
         rows = ismember(string(h.YData), opts.SortGroupMembers);
      end
      stat = mean(h.ColorData(rows, :), 1, 'omitnan');
      [~, idx] = sort(stat, opts.SortBy, 'MissingPlacement', 'last');
   else
      return
   end
   h.XDisplayData = cellstr(members(idx));
end
