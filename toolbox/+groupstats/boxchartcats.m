function varargout = boxchartcats(tbl, ydatavar, xgroupvar, cgroupvar, opts, props)
   %BOXCHARTCATS Box chart by groups along x-axis and by color within groups.
   %
   % Description
   %
   % This function creates a box chart of the data grouped by categories.
   %
   % Syntax
   %
   % h = boxchartcats(tbl, ydatavar) creates a box chart, or box plot, for column
   % DATAVAR in table tbl. If tbl.(DATAVAR) is a vector, then boxchart creates a
   % single box chart. In this mode, BOXCHARTCATS behaves exactly like
   % BOXCHART(ydata) where ydata = tbl.(ydatavar).
   %
   % h = boxchartcats(tbl, ydatavar, xgroupvar) groups the data in the vector
   % tbl.(DATAVAR) according to the unique values in tbl.(xgroupvar) and plots each
   % group of data as a separate box chart. xgroupdata determines the position
   % of each box chart along the x-axis. ydata must be a vector, and xgroupdata
   % must have the same length as ydata.
   %
   % h = boxchartcats(tbl, ydatavar, xgroupvar, cgroupvar, xgroupuse, cgroupuse)
   % uses color to differentiate between box charts. The software groups the
   % data in the vector ydata according to the unique value combinations in
   % xgroupdata (if specified) and cgroupdata, and plots each group of data as a
   % separate box chart. The vector cgroupdata then determines the color of each
   % box chart. ydata must be a vector, and cgroupdata must have the same length
   % as ydata. Specify the 'GroupByColor' name-value pair argument after any of
   % the input argument combinations in the previous syntaxes.
   %
   % h = boxchartcats(_, Name, Value) specifies additional chart options using
   % one or more name-value pair arguments. For example, you can compare sample
   % medians using notches by specifying 'Notch','on'. Specify the name-value
   % pair arguments after all other input arguments. For a list of properties,
   % see BoxChart Properties.
   %
   % Input Arguments
   %
   % tbl: A table containing the data to be plotted.
   % ydatavar: The name of the variable in the table tbl that contains the data
   % values for the box chart.
   % xgroupvar: The name of the categorical variable in the table tbl used to
   % define groups along the x-axis.
   % cgroupvar: The name of the categorical variable in the table tbl used to
   % define groups for the colors of the boxes.
   % xgroupuse: A cell array of categories to be used for the x-axis grouping.
   % cgroupuse: A cell array of categories to be used for the color grouping.
   % varargin: Additional optional arguments for the boxchart function.
   %
   % MergeGroupMembers: A cell array of string vectors. Each cell names the
   % color-group members to pool into one box group, matching
   % groupstats.histogram. A bare string vector is one merge group. The
   % merged group's label joins the member names with " and ", and it takes
   % the position of its first member in the current category order.
   % CGroupMembers reads original names; CGroupOrder and the legend read
   % post-merge names.
   %
   % Parent: The axes to draw into. The default is gca, so repeated calls
   % reuse the current axes. The boxes, the mean symbols, the shading, the
   % legend, and the axis formatting all go into this axes, and the
   % current axes is not touched when another one is named.
   %
   % LegendString: Replacement legend entries, one per color-group member.
   % LegendString(i) names the i-th member in category order after member
   % filtering and merging. CGroupOrder permutes the entries with the
   % series, so an entry stays on its member. SortBy orders the x-groups
   % and leaves the legend as it is.
   %
   % ShadeGroups: Shade alternating x-tick groups to tell one group of
   % boxes from the next. Defaults to true when cgroupvar is given and
   % false otherwise, because the shading marks a boundary between
   % colored boxes that a single-series chart does not have. Pass
   % ShadeGroups=true to shade a single-series chart anyway.
   %
   % Note: a box holding one observation collapses to a zero-height box
   % with zero-length whiskers, so the mean symbol is its only visible
   % mark. The chart warns when every box is like that.
   %
   % Output Arguments
   %
   % H: A handle to the created box chart.
   % L: The legend, or an empty graphics placeholder when the legend could
   %    not be created.
   % AX: The axes the chart was drawn into.
   %
   % Example
   %
   % Plot the peak variable of the fixture table, grouped along the x-axis
   % by month and by color within each group by scenario.
   %
   %  data = groupstats.test.generateTestData('info');
   %  h = groupstats.boxchartcats(data.Info, "peak", "month", "scenario");
   %
   % Restrict the groups to named members. XGroupMembers and CGroupMembers are
   % name-value arguments, not positional ones.
   %
   %  h = groupstats.boxchartcats(data.Info, "peak", "month", "scenario", ...
   %     XGroupMembers = ["Jan", "Feb", "Mar"], ...
   %     CGroupMembers = data.scenarios(1:2));
   %
   % Sort the x-groups by their group mean and pass BoxChart properties
   % through:
   %
   %  h = groupstats.boxchartcats(data.Info, "peak", "month", "scenario", ...
   %     SortBy = "ascend", Notch = "on", MarkerStyle = "none");
   %
   % Sorting
   %
   % SortBy orders the x-groups by their group mean, "ascend" or "descend".
   % The sorted grouping is always xgroupvar. SortGroupMembers names the
   % cgroupvar members whose rows enter each x-group's mean; omitted, or
   % string.empty(), it uses every row. It needs cgroupvar, and each name
   % must be one of its members (post-merge names after a merge). An x-group with no
   % rows in the named members sorts last. XGroupOrder names the order
   % directly and takes precedence over SortBy.
   %
   % Dependencies
   %
   % These ship in +groupstats/private, vendored from matfunclib and
   % listed in toolbox/vendored.txt, so no separate path is needed:
   %
   %  defaultcolors (libplot)      colors the mean symbols like the boxes
   %  makevalidvarnames (libtable) builds the y-axis label
   %  naninterp1 (libstats)        fills gaps in the group shading bounds
   %  dealout (functools)          splits the outputs
   %
   % Errors and warnings
   %
   % groupstats:boxchartcats:mergeWithoutGroupVar - MergeGroupMembers was
   % given without cgroupvar.
   % groupstats:boxchartcats:sortGroupMembersWithoutGroupVar -
   % SortGroupMembers was given without cgroupvar.
   % groupstats:boxchartcats:allDataMissing - every value of ydatavar in
   % the selected rows is missing, so there is nothing to draw.
   % groupstats:boxchartcats:allBoxesSingleObservation - a warning. Every
   % (x-group, color-group) box holds exactly one observation, so the boxes
   % collapse to points, as described in the Note above.
   %
   % Matt Cooper, 29-Nov-2022, https://github.com/mgcooper
   %
   % See also: reordergroups, reordercats, boxchart,
   % groupstats.barchartcats, groupstats.namelists.sortorder

   % Note, the columns need to be categorical, but the 'x/cgroupvar' and
   % 'xgroupuse/c' inputs can be strings/chars/cellstr or categorical.
   % Specifying 'string' in the arguments block performs an implicit conversion
   % to string, and ismember('someCategoricalVariable','someStringVariable')
   % works but iff the string is scalar (or cell array of chars), so the
   % approach taken here is to convert to string. In a few places, attention is
   % needed to convert to string if non-scalar string/categorical comparisons
   % are made.

   arguments
      tbl tabular
      ydatavar (1,1) string { mustBeNonempty }
      xgroupvar (1,1) string { mustBeNonempty }
      % One color grouping or none. A vector would name two groupings,
      % which the chart has no second color axis for.
      cgroupvar string {mustBeScalarOrEmpty} = string.empty()

      % These four came from barchartcats, where they were named CustomOpts.
      % All four default to empty, which prepareTableGroups reads as every
      % member, so none of them calls groupmembers to build a default.
      opts.XGroupMembers (:, 1) string = string.empty()
      opts.CGroupMembers (:, 1) string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers (:, 1) string = string.empty()

      % Untyped because a cell array of string vectors is one valid shape.
      opts.MergeGroupMembers (:, 1) = string.empty()

      % Empty means no row selection. prepareTableGroups raises
      % rowSelectVarWithoutMembers when RowSelectVar is named and this is
      % empty, because selecting no rows leaves an empty chart.

      opts.XGroupOrder (:,1) string = "none"
      opts.CGroupOrder (:,1) string = "none"
      % Axes to draw into. The default is gca, so repeated calls reuse the
      % current axes, as scatter does.
      opts.Parent (1,1) {mustBeA(opts.Parent, ...
         "matlab.graphics.axis.AbstractAxes")} = gca
      opts.SortBy (1,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.SortBy, ...
         "sortorder") } = "none"
      % SortGroupMembers names the cgroupvar members whose rows compute
      % each x-group's sort value when SortBy is set, the same option
      % barchartcats has. Empty, the family's no-selection sentinel, uses
      % every row of the x-group. A word such as "all" cannot be the
      % sentinel, because a member can carry that name.
      opts.SortGroupMembers (:,1) string = string.empty()
      opts.PlotMeans (1,1) logical = true
      % ShadeGroups marks the boundary between x-tick groups of several
      % colored boxes, so it is pointless with one box per tick. The
      % sentinel logical.empty() means "unset": resolved right after this
      % block to true when cgroupvar is given and false otherwise. An
      % explicit true or false is not the sentinel and always wins, so
      % ShadeGroups=true still shades a single-series chart.
      opts.ShadeGroups logical {mustBeScalarOrEmpty} = logical.empty()
      opts.ConnectMeans (1,1) logical = false
      opts.ConnectMedians (1,1) logical = false
      opts.Legend (1,1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Legend, ...
         "legendvisibility")} = "on"
      opts.LegendString string = string.empty()
      % Every chart in the family defaults to a vertical legend. The
      % legend still sits above the axes; horizontal remains available for
      % a wide row of entries.
      opts.LegendOrientation (1, 1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.LegendOrientation, ...
         "legendorientation") } = "vertical"
      props.?matlab.graphics.chart.primitive.BoxChart
   end

   % H, L, and the axes are the outputs.
   nargoutchk(0, 3)

   % Import groupstats package
   import groupstats.groupselect
   import groupstats.boxchartxdata
   import groupstats.prepareTableGroups

   % Resolve the ShadeGroups sentinel. The shading tells one x-tick group
   % of colored boxes apart from the next, which only matters when a tick
   % holds more than one box, so it defaults on with cgroupvar and off
   % without it. An explicit true or false is not the sentinel and wins.
   if isempty(opts.ShadeGroups)
      opts.ShadeGroups = ~isempty(cgroupvar);
   end

   % Override default BoxChart settings
   ResetFields = {'JitterOutliers','Notch'};
   ResetValues = {true,'on'};
   for n = 1:numel(ResetFields)
      if ~ismember(ResetFields{n},fieldnames(props))
         props.(ResetFields{n}) = ResetValues{n};
      end
   end
   varargs = namedargs2cell(props);

   % Merging pools members of the color-group variable, so without one
   % there is nothing to pool.
   if isempty(cgroupvar) && ~isempty(opts.MergeGroupMembers)
      error('groupstats:boxchartcats:mergeWithoutGroupVar', ...
         ['MergeGroupMembers was given without cgroupvar. Name the color ' ...
         'group variable whose members are pooled.'])
   end

   % SortGroupMembers names color-group members, so without a color group
   % there are none to name. Empty stands for every member.
   if isempty(cgroupvar) && ~isempty(opts.SortGroupMembers)
      error('groupstats:boxchartcats:sortGroupMembersWithoutGroupVar', ...
         ['SortGroupMembers was given without cgroupvar. Name the color ' ...
         'group variable whose members compute the sort value.'])
   end
   sortmembers = ~isempty(opts.SortGroupMembers);

   % validate inputs
   tbl = prepareTableGroups(tbl, ydatavar, ...
      XGroupVar = xgroupvar, ...
      XGroupMembers = opts.XGroupMembers, ...
      CGroupVar = cgroupvar, ...
      CGroupMembers = opts.CGroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers);

   % Merge after member filtering, so CGroupMembers reads original names
   % and the ordering below reads post-merge names. The shared helper
   % validates the member names and relabels the rows.
   if ~isempty(opts.MergeGroupMembers)
      tbl.(cgroupvar) = mergegroupmembers( ...
         tbl.(cgroupvar), opts.MergeGroupMembers);
   end

   % Assign the data to plot
   XData = tbl.(xgroupvar);
   YData = tbl.(ydatavar);
   try
      CData = tbl.(cgroupvar);
   catch
      CData = true(size(YData));
   end

   % SortGroupMembers names post-merge members, so check it after the
   % merge, and whatever SortBy is: a name that matches no member is a
   % caller error even when no sort runs, as barchartcats treats it.
   if sortmembers
      validatemember(opts.SortGroupMembers, CData, 'BOXCHARTCATS', ...
         'SortGroupMembers')
   end

   % A box holding one observation collapses to a zero-height box with
   % zero-length whiskers, so the mean symbol is its only visible mark.
   % When every box is like that, the selection was almost surely a
   % mistake, so report it. Any box with two or more rows means the shape
   % was chosen, so no report then. boxchart omits missing YData, so count
   % only the rows a box renders.
   plotted = ~ismissing(YData);

   % boxchart draws nothing from all-missing data, and the helpers that
   % read the drawn boxes then index with NaN. Report the empty selection
   % instead of failing inside them.
   if ~any(plotted)
      error('groupstats:boxchartcats:allDataMissing', ...
         ['Every value of %s in the selected rows is missing, so there ' ...
         'is nothing to draw. Select rows that hold data.'], ydatavar)
   end

   boxcounts = groupcounts( ...
      table(XData(plotted), CData(plotted), ...
      'VariableNames', ["xgroup", "cgroup"]), ["xgroup", "cgroup"]);
   if ~isempty(boxcounts.GroupCount) && all(boxcounts.GroupCount == 1)
      warning('groupstats:boxchartcats:allBoxesSingleObservation', ...
         ['Every (x-group, color-group) box holds exactly one ' ...
         'observation, so the boxes collapse to points. Pool more rows ' ...
         'per box, or use groupstats.scatter.'])
   end

   % main function
   ax = opts.Parent;
   hold(ax, 'off') % repeated calls create problems

   % Custom ordering along x-axis
   XData = reorderGroups(opts, XData, YData, CData, sortmembers);

   % Create the box chart and legend
   % Order the color groups before drawing, because boxchart reads their
   % order from the categories of CData. LegendString moves with them.
   [CData, opts] = reorderCGroups(opts, CData);

   [H, L] = categoricalBoxChart(XData, YData, CData, ydatavar, opts, varargs);

   % If "markerstyle", "none" is in varargin, clip the ylimits to the data
   setboxchartylim(ax, H, XData, YData, CData);

   % Add the means if requested
   plotboxchartstats(opts,H,XData,YData,CData);

   % Add shaded bars to distinguish groups if requested
   shadeboxchartgroups(opts,H);

   if opts.Legend == "off"
      legend(ax, 'off')
   end
   hold(ax, 'off')

   % The third output is the axes the chart was drawn into, matching the
   % other charts' (H, L, ax) signature.
   [varargout{1:nargout}] = dealout(H, L, ax);
end

%% Local Functions
function [H, L] = categoricalBoxChart(XData, YData, CData, YDataVar, CustomOpts, varargs)

   % Create the box chart, in the caller's axes
   ax = CustomOpts.Parent;
   H = boxchart(ax, XData, YData, 'GroupByColor', CData, varargs{:});

   % Add the legend
   withwarnoff('MATLAB:legend:IgnoringExtraEntries');
   legendtxt = CustomOpts.LegendString;
   if isempty(legendtxt)
      legendtxt = unique(CData);
   end
   % One column per entry lays the entries out in a row; one column stacks
   % them. Either way the legend sits above the axes.
   if CustomOpts.LegendOrientation == "horizontal"
      numcolumns = numel(legendtxt);
   else
      numcolumns = 1;
   end

   try
      L = legend(ax, legendtxt, ...
         'Orientation', CustomOpts.LegendOrientation, ...
         'Location', 'northoutside', ...
         'AutoUpdate', 'off', ...
         'numcolumns', numcolumns );
   catch
      % A legend failure must still assign L. An empty graphics
      % placeholder matches the other charts' legend-failure value.
      L = gobjects(0);
   end

   % Add a ylabel
   ylabel(ax, makevalidvarnames(YDataVar))

   % Format the plot
   set(ax, "YGrid", "off", "XGrid", "off", "XMinorTick", "off", "box", ...
      "on", "TickLength", [0 0]);
end

function [CData, opts] = reorderCGroups(opts, CData)
   %REORDERCGROUPS Order the color groups, and with them the legend.
   %
   % boxchart draws one series per category of the GroupByColor data, in
   % category order, so ordering the categories orders both the boxes within
   % each x-tick group and the legend. A caller's LegendString binds to the
   % members in category order, so it is permuted the same way and stays on
   % its data.

   if isscalar(opts.CGroupOrder) && opts.CGroupOrder == "none"
      return
   end

   if ~iscategorical(CData)
      % No color grouping was requested, so there is nothing to order.
      return
   end

   members = string(categories(removecats(CData)));

   idx = reordergroupmembers(opts.CGroupOrder, members, ...
      "boxchartcats", "CGroupOrder");

   CData = reordercats(CData, members(idx));
   if numel(opts.LegendString) == numel(members)
      opts.LegendString = opts.LegendString(idx);
   end
end

function XData = reorderGroups(opts, XData, YData, CData, sortmembers)
   %REORDERGROUPS Reorder the x-axis (tick) groups.
   %
   % An explicit XGroupOrder wins. Otherwise SortBy orders the x-groups by
   % their group mean over the rows SortGroupMembers selects. SORTMEMBERS
   % is true when the caller named members.

   if opts.XGroupOrder == "none"
      % Sort the x-groups by their group mean. YData here is the raw column,
      % not a summary matrix as in barchartcats, so the mean per x-group comes
      % from groupsummary rather than from a column mean.
      switch opts.SortBy
         case {"ascend", "descend"}
            members = string(categories(removecats(XData)));

            % Keep the rows of the named color-group members. The names
            % were checked against the members above.
            rows = true(size(YData));
            if sortmembers
               rows = ismember(string(CData), opts.SortGroupMembers);
            end

            % An x-group with no selected rows is absent from the summary,
            % so place each mean in its member's slot and leave the rest
            % NaN, which sort puts last.
            [groupmean, found] = groupsummary(YData(rows), XData(rows), ...
               "mean");
            stat = nan(size(members));
            [~, loc] = ismember(string(found), members);
            stat(loc) = groupmean;

            [~, idx] = sort(stat, opts.SortBy, 'MissingPlacement', 'last');
            XData = reordercats(XData, members(idx));
         otherwise
            % "none" leaves the category order as it is.
      end
   else
      % A partial order names some x-groups and leaves the rest behind
      % them, the way CGroupOrder does.
      members = string(categories(removecats(XData)));
      Locb = reordergroupmembers(opts.XGroupOrder, members, ...
         "boxchartcats", "XGroupOrder");

      % reordercats changes the display order and leaves the rows where
      % they are, so XData and YData stay paired row by row.
      XData = reordercats(XData, members(Locb));
   end
end

function plotboxchartstats(opts,H,XData,YData,CData)

   ax = opts.Parent;
   hold(ax, 'on');

   % Load default colors to match the mean symbols to the boxcharts
   colors = defaultcolors;

   % Get the x-coordinate of each boxchart center and the mean of each boxchart
   [mu, med, xlocs] = boxchartstats(H, XData, YData, CData);

   % Plot the means
   if opts.PlotMeans
      arrayfun(@(n) scatter(ax, xlocs(n,:), mu(n,:), 30, colors(n, :), ...
         'filled', 's'), 1:numel(H));
   end

   % Connect the means. plot reads each column as one line, and xlocs holds
   % one row per color group, so transpose. Without it each line joined the
   % color groups inside one x-tick instead of following one color across
   % the ticks.
   if opts.ConnectMeans == true
      plot(ax, xlocs', mu', '-', 'Color', [0.5 0.5 0.5], ...
         'HandleVisibility', 'off')
   end

   % Connect the medians.
   if opts.ConnectMedians
      plot(ax, xlocs', med', '-', 'Color', [0.5 0.5 0.5], ...
         'HandleVisibility', 'off')
   end
end

% Translation between boxchart and groupsummary
%  boxchart    groupsummary(tbl,...)     groupsummary(A,...)
% ----------  --------------------     -------------------
% xgroupdata   groupvars{1} (varname)  groupvars(:,1) (column vector)
% cgroupdata   groupvars{2} (varname)  groupvars(:,2) (column vector)
% ydata        datavars     (varname)  A              (column vector)
% N/A          method
% N/A          groupbins = actual bin edges or method, for both tbl and A syntax
function [mumat, medmat, xlocs] = boxchartstats(H, XData, YData, CData)

   % Import each package member this local function requires.
   import groupstats.boxchartxdata

   % Get the x-coordinate of each boxchart center
   [xlocs] = boxchartxdata(H);

   % Summarize over both groupings. A cell grouping spec keeps the two apart.
   % Concatenating them as [XData CData] fails when one is an ordinal
   % categorical and the other is not, which the ordinary two-group call is.
   [mu, uv] = groupsummary(YData, {XData, CData}, "mean");
   med = groupsummary(YData, {XData, CData}, "median");

   % Place each summarized pair in its own slot. xlocs holds one row
   % per color group and one column per x-tick. A combination with no rows is
   % absent from uv, so it stays NaN here rather than shifting every later
   % value onto the wrong box.
   xmembers = groupmemberlist(XData);
   cmembers = groupmemberlist(CData);
   [~, ix] = ismember(string(uv{1}), string(xmembers));
   [~, ic] = ismember(string(uv{2}), string(cmembers));

   mumat = nan(size(xlocs));
   medmat = nan(size(xlocs));
   keep = ix > 0 & ic > 0;
   slot = sub2ind(size(xlocs), ic(keep), ix(keep));
   mumat(slot) = mu(keep);
   medmat(slot) = med(keep);
end

function members = groupmemberlist(data)
   %GROUPMEMBERLIST Ordered members of a grouping vector, as boxchart draws it.
   %
   % boxchart lays out its ticks and its color series in category order for a
   % categorical. CData is logical when no color group was named, and unique
   % returns those in the same sorted order boxchart uses.

   if iscategorical(data)
      members = categories(removecats(data));
   else
      members = unique(data);
   end
end

function shadeboxchartgroups(CustomOpts, H)

   % Import each package member this local function requires.
   import groupstats.boxchartxdata

   if CustomOpts.ShadeGroups == false
      return
   end

   % Get the x-coordinate of the bounds of each boxchart group (the
   % left/right-most x-coordinate of each xtick group)
   [~, xleft, xright] = boxchartxdata(H);

   % Get the y-coordinate of the plot bounds, in the caller's axes
   ax = CustomOpts.Parent;
   [ylow, yhigh] = bounds(ylim(ax));

   % The x-tick grid is regular, so interpolate the NaN bounds. naninterp1
   % needs at least two known points to interpolate between, so a grid with
   % too few filled x-tick groups gets no shading rather than an error.
   if nnz(~isnan(xleft)) < 2 || nnz(~isnan(xright)) < 2
      return
   end
   xleft = naninterp1(1:numel(xleft),xleft,'linear','extrap');
   xright = naninterp1(1:numel(xright),xright,'linear','extrap');

   % To extend the shaded region halfway between each group:
   try
      dx = mean((xleft(2:end) - xright(1:end-1)),'omitnan') / 2;
   catch
      % Defensive catch for an unexpected indexing or arithmetic failure in
      % the gap computation; half the box width stands in for dx. The guard
      % above already returns when fewer than two bounds are known.
      dx = (xright - xleft) / 2;
   end

   xleft = xleft - dx;
   xright = xright + dx;

   idxodd = 1:2:numel(xleft);
   xpatch = [xleft(idxodd); xright(idxodd); xright(idxodd); xleft(idxodd); xleft(idxodd)];
   ypatch = repmat([ylow; ylow; yhigh; yhigh; ylow], 1, numel(idxodd));

   P = patch(ax, xpatch, ypatch, 'k', ...
      'FaceColor', [0.5 0.5 0.5], ...
      'FaceAlpha', 0.1, ...
      'EdgeColor', 'none' );

   % Set up a listener for changes in the YLim property
   addlistener(ax, 'YLim', 'PostSet', @(src, evt) updateshadedbounds(P, ax));

   function updateshadedbounds(P, ax)
      P.YData = repmat([ax.YLim(1); ax.YLim(1); ax.YLim(2); ax.YLim(2); ax.YLim(1)], ...
         1, size(P.Faces,1));
   end
end

function setboxchartylim(ax, H, XData, YData, CData)
   %SETBOXCHARTYLIM Fit the y limits to the whiskers when outliers are hidden.
   %
   % With MarkerStyle "none" boxchart draws no outlier points, so the visible
   % extent is the whisker tips. Fitting the limits to the plotted data
   % instead leaves empty space wherever an outlier was suppressed.
   %
   % The whiskers come from groupstats.boxchartydata, which computes them from
   % the data. Reading them off H(n).NodeChildren(4).VertexData instead
   % depends on undocumented graphics internals and needs a drawnow first.

   import groupstats.boxchartydata

   if ~all({H.MarkerStyle} == "none")
      return
   end

   % One box per pairing of an x-group member with a color-group member.
   xmembers = unique(XData);
   cmembers = unique(CData);
   whiskers = nan(numel(xmembers) * numel(cmembers), 2);

   k = 0;
   for x = 1:numel(xmembers)
      for c = 1:numel(cmembers)
         k = k + 1;
         inbox = XData == xmembers(x) & CData == cmembers(c);
         if any(inbox)
            whiskers(k, :) = boxchartydata(YData(inbox)).whiskers;
         end
      end
   end

   ywhiskers = whiskers(~isnan(whiskers));
   if isempty(ywhiskers)
      return
   end

   % Compute axis limits with padding. Pad by a fixed amount when every
   % whisker sits at the same value, because ylim rejects a zero-width range.
   bounds = [min(ywhiskers) max(ywhiskers)];
   padding = 0.01 * diff(bounds);
   if padding == 0
      padding = max(abs(bounds(1)), 1) * 0.01;
   end
   ylim(ax, bounds + [-padding padding]);
end

%% LICENSE
%
% BSD 3-Clause License
%
% Copyright (c) 2023, Matthew Guy Cooper (mgcooper) All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from this
%    software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
