function varargout = barchartcats(tbl, ydatavar, xgroupvar, cgroupvar, opts, props)
   %BARCHARTCATS Bar chart by groups along x-axis and by color within groups.
   %
   % Description
   %
   % This function creates a bar chart of the data grouped by specified
   % categories.
   %
   % Syntax
   %
   % h = barchartcats(tbl, ydatavar) creates a bar chart, for column ydatavar in
   % table tbl. If tbl.(ydatavar) is a vector, then barchart creates a single bar
   % chart. In this mode, BARCHARTCATS behaves exactly like BOXCHART(ydata)
   % where ydata = tbl.(ydatavar).
   %
   % h = barchartcats(tbl, ydatavar, xgroupvar) groups the data in the vector
   % tbl.(ydatavar) according to the unique values in tbl.(xgroupvar) and plots
   % each group of data as a separate bar chart. xgroupdata determines the
   % position of each bar chart along the x-axis. ydata must be a vector, and
   % xgroupdata must have the same length as ydata.
   %
   % h = barchartcats(tbl, ydatavar, xgroupvar, cgroupvar, "XGroupMembers",
   %  xgroupmembers, "CGroupMembers", cgroupmembers) uses color to differentiate
   % between bar charts. The software groups the data in the vector ydata
   % according to the unique value combinations in xgroupdata (if specified) and
   % cgroupdata. It plots each group of data as a separate bar chart. The
   % vector cgroupdata then determines the color of each bar chart. ydata must
   % be a vector, and cgroupdata must have the same length as ydata. Specify the
   % 'GroupByColor' name-value pair argument after any of the input argument
   % combinations in the previous syntaxes.
   %
   % h = barchartcats(_, Name, Value) specifies additional chart options using
   % one or more name-value pair arguments. For a list of properties, see
   % BarChart Properties.
   %
   % Input Arguments:
   %
   % tbl - A table containing the data to be plotted.
   %
   % ydatavar - The name of the variable in the table tbl that contains the data
   % values for the bar chart.
   %
   % xgroupvar - The name of the categorical variable in the table tbl used to
   % define groups along the x-axis.
   %
   % cgroupvar - The name of the categorical variable in the table tbl used to
   % define groups for the colors of the bars.
   %
   % Method - the method used in the call to groupsummary to compute the values
   % plotted as bars, "mean" (default) or "median". Give one method. For
   % 'mean', the standard deviation is also computed in the call to
   % groupsummary to support the addition of whiskers to the bars. For
   % 'median', each whisker runs from the lower quartile to the upper
   % quartile of the bar's rows. Those are the box edges
   % groupstats.boxchartcats draws, so the two arms differ for skewed data.
   % Set PlotError to draw them. PlotError needs one bar per x-tick, so
   % omit cgroupvar, or select or merge its members down to one.
   %
   % ErrorBar - what the PlotError whisker shows. "spread" (default) is the
   % spread above: the mean plus or minus the standard deviation, or the
   % lower quartile to the upper quartile around the median. "ci" is the
   % confidence interval that groupstats.groupci returns for the same rows.
   % That is the Student t interval of the mean, or the boxchart notch of
   % the median.
   % The whisker tips equal the groupci bounds. A bar with fewer than two
   % values has no interval, so it gets no whisker. ErrorBar="ci" needs
   % PlotError=true.
   %
   % Alpha - the significance level of the ErrorBar="ci" mean interval, in
   % the open interval (0, 1). Empty, the default, means 0.05. Alpha
   % applies only with ErrorBar="ci" and Method="mean", because the spread
   % and the median notch have no level to set.
   %
   % xgroupuse - A cell array of categories to be used for the x-axis grouping.
   %
   % cgroupuse - A cell array of categories to be used for the color grouping.
   %
   % Parent - The axes to draw into. The default is gca, so repeated calls
   % reuse the current axes. The bars, the whiskers, the shading, the
   % legend, and the axis formatting all go into this axes, and the
   % current axes is not touched when another one is named.
   %
   % LegendString - Replacement legend entries, one per color-group member.
   % LegendString(i) names the i-th member in category order after member
   % filtering and merging. CGroupOrder permutes the entries with the
   % series, so an entry stays on its member. SortBy orders the x-groups
   % and leaves the legend as it is.
   %
   % Legend and labels - The legend sits above the axes in up to three
   % columns, fewer when three would be wider than its tile, subplot, or
   % figure. LegendOrientation "horizontal" puts every entry in one row,
   % wrapped when that row is wider than its tile, subplot, or figure. The
   % legend text follows the axes font. The legend handle comes back as L,
   % so a caller can move it, for example to "northwest" in one column.
   % The y label names the Method and the data variable, for example "Mean
   % peak". The table's VariableDescriptions and VariableUnits for the data
   % variable replace its name when set: "Mean peak magnitude (unitless)".
   %
   % ShadeGroups - Shade alternating x-tick groups to tell one group of
   % bars from the next. Defaults to true when cgroupvar is given and
   % false otherwise, because the shading marks a boundary between
   % colored bars that a single-series chart does not have. Pass
   % ShadeGroups=true to shade a single-series chart anyway.
   %
   % MergeGroupMembers - A cell array of string vectors. Each cell names
   % the color-group members to pool into one bar, matching
   % groupstats.histogram. A bare string vector is one merge group. The
   % merged bar's label joins the member names with " and ", and the bar
   % takes the position of its first member in the current category order.
   %
   % MergeMethod - "pooled" (default) or "membermean". "pooled" summarizes
   % the pooled member rows, so the merged bar is the statistic over every
   % row of the merged members, and PlotError works. "membermean" is the
   % unweighted mean of the member bars' summary values, which weights each
   % member group equally regardless of its row count. With Method="mean"
   % and equal-sized member groups the two agree. With Method="median"
   % they can differ even then, because a pooled median is not the mean of
   % member medians. "membermean" discards the spread of the combined
   % groups, so PlotError cannot be set with it.
   %
   % Output Arguments
   %
   % H: A handle to the created bar chart.
   % L: The legend, or an empty graphics placeholder when the legend is off
   %    or could not be created. With no legend, the axes fill the figure.
   % AX: The axes the chart was drawn into.
   %
   % Example
   %
   % Plot the peak variable of the fixture table. Group along the x-axis by
   % month, and by color within each group by scenario.
   %
   %  data = groupstats.test.generateTestData('info');
   %  h = groupstats.barchartcats(data.Info, "peak", "month", "scenario");
   %
   % Restrict the groups to named members. XGroupMembers and CGroupMembers are
   % name-value arguments, not positional ones.
   %
   %  h = groupstats.barchartcats(data.Info, "peak", "month", "scenario", ...
   %     XGroupMembers = ["Jan", "Feb", "Mar"], ...
   %     CGroupMembers = data.scenarios(1:2));
   %
   % Sort the x-groups by their group mean and pass a Bar property through:
   %
   %  h = groupstats.barchartcats(data.Info, "peak", "month", "scenario", ...
   %     SortBy = "ascend", BarWidth = 0.5);
   %
   % Draw the 90% confidence interval of each month's mean as the whisker:
   %
   %  h = groupstats.barchartcats(data.Info, "peak", "month", ...
   %     PlotError = true, ErrorBar = "ci", Alpha = 0.10);
   %
   % Sorting
   %
   % SortBy orders the x-groups by their summarized value, "ascend" or
   % "descend". The sorted grouping is always xgroupvar. Each x-group's
   % sort value is the mean of its bars' heights. SortGroupMembers names
   % the cgroupvar members whose bars enter that mean; omitted, or
   % string.empty(), it uses every bar. It needs cgroupvar, and each name
   % must be one of its members (post-merge names after a merge). XGroupOrder names the order
   % directly and takes precedence over SortBy.
   %
   % Note
   %
   % Grouped data is summarized in category order, not first-appearance
   % order. An (x-group, color-group) pair with no rows gets no bar, and
   % the other bars stay on their own ticks. A table that is already a
   % groupsummary output is summarized again: name its summary column as
   % ydatavar, and each bar is then Method over that column's rows in the
   % group, with the spread of those rows as the whisker.
   %
   % Colors
   %
   % Each color group takes the next row of defaultcolors, the palette
   % boxchartcats and scatter read, so the k-th color group of any chart
   % in the family has the same color. Pass FaceColor to override it, or
   % CData to color the bars through the colormap as bar does.
   %
   % Dependencies
   %
   % These ship in +groupstats/private, vendored from matfunclib and
   % listed in toolbox/vendored.txt, so no separate path is needed:
   %
   %  defaultcolors (libplot)      colors the bars
   %  dealout (functools)          splits the outputs
   %
   % Errors
   %
   % groupstats:barchartcats:mergeWithoutGroupVar - MergeGroupMembers was
   % given without cgroupvar.
   % groupstats:barchartcats:sortGroupMembersWithoutGroupVar -
   % SortGroupMembers was given without cgroupvar.
   % groupstats:barchartcats:plotErrorNeedsUnmergedGroups - PlotError was
   % set with MergeMethod="membermean", which combines groups whose spread
   % PlotError needs.
   % groupstats:barchartcats:plotErrorNeedsOneSeries - PlotError was set
   % with more than one bar per x-tick, so the whiskers would not line up
   % with their bars. Omit cgroupvar, or leave PlotError off.
   % groupstats:barchartcats:errorBarWithoutPlotError - ErrorBar="ci" was
   % given without PlotError=true, so no whisker would show it.
   % groupstats:barchartcats:alphaWithoutMeanCI - Alpha was given without
   % both ErrorBar="ci" and Method="mean", so it would set no level.
   %
   % Matt Cooper, 29-Nov-2022, https://github.com/mgcooper
   %
   % See also reordergroups, reordercats, barchart,
   % groupstats.boxchartcats, groupstats.groupci,
   % groupstats.namelists.sortorder

   arguments
      tbl tabular
      ydatavar (1,1) string {mustBeNonempty}
      xgroupvar (1,1) string {mustBeNonempty}
      % One color grouping or none. A vector would name two groupings,
      % which the chart has no second color axis for.
      cgroupvar string {mustBeScalarOrEmpty} = string.empty()
      opts.XGroupMembers string = string.empty()
      opts.CGroupMembers string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers string = string.empty()
      % One method. Each bar is one statistic, and the whiskers pair with
      % it, so a list of methods has no single chart to draw.
      opts.Method (1,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.Method, ...
         "centralstatistic") } = "mean"
      opts.SortBy (1,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.SortBy, ...
         "sortorder") } = "none"
      % SortGroupMembers names the cgroupvar members whose bars compute
      % each x-group's sort value when SortBy is set. Empty, the family's
      % no-selection sentinel, averages every cgroup bar; name specific
      % members to sort by them alone. A word such as "all" cannot be the
      % sentinel, because a member can carry that name.
      opts.SortGroupMembers (:,1) string = string.empty()
      opts.MergeGroupMembers (:,1) = string.empty()
      opts.MergeMethod (1,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.MergeMethod, ...
         "mergemethod") } = "pooled"
      opts.XGroupOrder (:,1) string = "none"
      opts.CGroupOrder (:,1) string = "none"
      % Axes to draw into. The default is gca, so repeated calls reuse the
      % current axes, as scatter does.
      opts.Parent (1,1) {mustBeA(opts.Parent, ...
         "matlab.graphics.axis.AbstractAxes")} = gca
      % ShadeGroups marks the boundary between x-tick groups of several
      % colored bars, so it is pointless with one bar per tick. The
      % sentinel logical.empty() means "unset": resolved right after this
      % block to true when cgroupvar is given and false otherwise. An
      % explicit true or false is not the sentinel and always wins, so
      % ShadeGroups=true still shades a single-series chart. PlotError
      % stays off by default.
      opts.ShadeGroups logical {mustBeScalarOrEmpty} = logical.empty()
      opts.PlotError (1,1) logical = false
      % ErrorBar picks what the PlotError whisker shows. The default,
      % "spread", is the standard deviation or interquartile range whisker.
      opts.ErrorBar (1,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.ErrorBar, ...
         "errorbartype") } = "spread"
      % Empty means unset, so the interval helper applies its one default,
      % as in groupstats.groupci.
      opts.Alpha double {mustBeScalarOrEmpty, ...
         mustBeGreaterThan(opts.Alpha, 0), ...
         mustBeLessThan(opts.Alpha, 1)} = []
      opts.Legend (:,1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Legend, ...
         "legendvisibility")} = "on"
      opts.LegendString (:,1) string = string.empty()
      opts.LegendOrientation (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.LegendOrientation, ...
         "legendorientation")} = "vertical"
      props.?matlab.graphics.chart.primitive.Bar
   end

   % import groupstats package
   import groupstats.groupselect
   import groupstats.prepareTableGroups

   % Resolve the ShadeGroups sentinel. The shading tells one x-tick group
   % of colored bars apart from the next, which only matters when a tick
   % holds more than one bar, so it defaults on with cgroupvar and off
   % without it. An explicit true or false is not the sentinel and wins.
   if isempty(opts.ShadeGroups)
      opts.ShadeGroups = ~isempty(cgroupvar);
   end

   varargs = namedargs2cell(props);

   % H, L, and the axes are the outputs.
   nargoutchk(0, 3)

   % Merging pools members of the color-group variable, so without one
   % there is nothing to pool.
   if isempty(cgroupvar) && ~isempty(opts.MergeGroupMembers)
      error('groupstats:barchartcats:mergeWithoutGroupVar', ...
         ['MergeGroupMembers was given without cgroupvar. Name the color ' ...
         'group variable whose members are pooled.'])
   end

   % SortGroupMembers names color-group members, so without a color group
   % there are none to name. Empty stands for every member.
   if isempty(cgroupvar) && ~isempty(opts.SortGroupMembers)
      error('groupstats:barchartcats:sortGroupMembersWithoutGroupVar', ...
         ['SortGroupMembers was given without cgroupvar. Name the color ' ...
         'group variable whose members compute the sort value.'])
   end

   % PlotError draws the whiskers, so an interval asked for without it
   % would never show.
   if opts.ErrorBar == "ci" && ~opts.PlotError
      error('groupstats:barchartcats:errorBarWithoutPlotError', ...
         ['ErrorBar="ci" was given without PlotError=true, so no ' ...
         'whisker would show the interval. Set PlotError=true.'])
   end

   % Alpha sets the level of the mean t interval alone. The spread and the
   % median notch have no level, so an Alpha there would change nothing.
   if ~isempty(opts.Alpha) && ~(opts.ErrorBar == "ci" ...
         && opts.Method == "mean")
      error('groupstats:barchartcats:alphaWithoutMeanCI', ...
         ['Alpha sets the level of the mean confidence interval, so it ' ...
         'needs ErrorBar="ci" and Method="mean". The spread and the ' ...
         'median notch have no level to set.'])
   end

   % validate inputs
   tbl = prepareTableGroups(tbl, ydatavar, ...
      XGroupVar = xgroupvar, ...
      XGroupMembers = opts.XGroupMembers, ...
      CGroupVar = cgroupvar, ...
      CGroupMembers = opts.CGroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers);

   % Merge before summarizing, so the merged bar is the statistic over the
   % pooled member rows and its spread supports PlotError. The membermean
   % method instead averages the member bars after summarizing, below.
   % Member filtering above reads original names; ordering and sorting
   % below read post-merge names.
   if ~isempty(opts.MergeGroupMembers) && opts.MergeMethod == "pooled"
      tbl.(cgroupvar) = mergegroupmembers( ...
         tbl.(cgroupvar), opts.MergeGroupMembers);
   end

   % barchartcats requires summarizing the data, unlike boxchart
   [XData, YData, CData, EData] = summarizeTableGroups( ...
      tbl, ydatavar, xgroupvar, cgroupvar, opts.Method, opts.ErrorBar, ...
      opts.Alpha);

   % main function

   % Note: plotBarErrors reads H.XEndPoints for the whisker positions rather
   % than adapting the boxchartxdata method, because bar already computes the
   % center of every bar it draws.

   % NOTE: the columns arrive in category order, because "unique" is
   % embedded all over the place e.g. in the call to groupsummary in
   % summarizeTableGroups. The sort mask below is built from that same
   % order. Asking for "stable" here does not change the columns, only the
   % list read against them, which is what made the sort read the wrong one.

   % The membermean merge averages the member bars' summary columns. The
   % spread of a merged group is not the spread of its parts, so it
   % discards EData, and the guard names the PlotError conflict. The pooled
   % method above has no such conflict.
   if ~isempty(opts.MergeGroupMembers) && opts.MergeMethod == "membermean"
      if opts.PlotError
         error('groupstats:barchartcats:plotErrorNeedsUnmergedGroups', ...
            ['PlotError needs the spread of each group, and ' ...
            'MergeMethod="membermean" combines groups whose spread does ' ...
            'not add up. Use MergeMethod="pooled", omit ' ...
            'MergeGroupMembers, or leave PlotError off.'])
      end
      [CData, YData] = mergemembermean(CData, YData, opts.MergeGroupMembers);
      EData = [];
   end

   % Order the color groups. An explicit CGroupOrder names post-merge
   % labels when a merge happened. LegendString moves with the columns.
   [YData, EData, CData, opts] = reorderCGroups(opts, YData, EData, CData);

   % Find the columns to use for computing the sort. The columns are in
   % category order, and CGroupOrder permutes that order, so read the
   % categories. unique(...,"stable") gives first-appearance order and
   % marks another color group's column. SortGroupMembers names post-merge
   % labels when a merge happened.
   if iscategorical(CData)
      cgroups = string(categories(removecats(CData)));
   else
      cgroups = string(unique(CData));
   end
   if isempty(opts.SortGroupMembers)
      opts.SortGroupMembers = cgroups;
   else
      % A name that matches no member would select no column, and the sort
      % would then read a NaN mean and change nothing, with no report.
      validatemember(opts.SortGroupMembers, cgroups, 'BARCHARTCATS', ...
         'SortGroupMembers')
   end
   sortcolumns = ismember(cgroups, opts.SortGroupMembers);

   % Custom ordering along x-axis
   [XData, YData, EData] = reorderXGroups(opts, sortcolumns, ...
      XData, YData, EData);

   % Create the figure. The y label names the statistic the bars show and
   % the data variable, from the table's description and units when set.
   ylabeltext = upper(extractBefore(opts.Method, 2)) ...
      + extractAfter(opts.Method, 1) + " " + axislabel(tbl, ydatavar);
   [H, L, ax] = createCategoricalBarChart(XData, YData, CData, cgroups, ...
      ylabeltext, opts, varargs);

   % Draw the whiskers on top of the bars, then shade behind them.
   plotBarErrors(opts, H, YData, EData);
   shadebarchartgroups(opts, H);

   hold(ax, 'off')
   [varargout{1:nargout}] = dealout(H, L, ax);
end


function [XData, YData, CData, EData] = summarizeTableGroups(tbl, ydatavar, ...
      xgroupvar, cgroupvar, method, errortype, alpha)
   %SUMMARIZETABLEGROUPS Bar heights and whisker arms per pairing.
   %
   % The bar height is METHOD. With ERRORTYPE "spread", the whisker is the
   % spread that pairs with it. With ERRORTYPE "ci", it is the groupci
   % interval at level ALPHA. EData holds the lower arm on its first page
   % and the upper arm on its second, each a distance from the bar height.

   % cgroupvar leads the grouping list because it controls the row order
   % groupsummary returns, which the reshape below and bar's series
   % layout rely on.

   % groupsummary names a function-handle method's column fun<N>_<var>,
   % so read the arms by position: they are the last columns either way.
   if errortype == "ci"
      % The interval comes from the helper groupci uses, so each whisker tip
      % equals the groupci bound for the same rows.
      whisker = {@(y) cihalfwidth(y, method, alpha)};
   elseif method == "mean"
      whisker = {"std"};
   else
      % The spread that pairs with a median runs from the lower quartile to
      % the upper one, so its two arms differ for skewed data.
      whisker = {@(y) quartilearm(y, 1), @(y) quartilearm(y, 2)};
   end
   G = groupsummary(tbl, [cgroupvar xgroupvar], [{method}, whisker], ...
      ydatavar);
   XData = G.(xgroupvar);
   YData = G.(method + "_" + ydatavar);

   % A symmetric whisker has one column, which serves as both arms.
   arms = G{:, end - numel(whisker) + 1:end};
   arms = arms(:, [1 end]);

   % Each column of Y needs to correspond to a group of bars. Each bar in a
   % group is a different color, and each group is a different x-tick.
   % groupsummary returns one row per pair that has rows, so a pair with
   % none is absent. Place each row in its own slot and leave the absent
   % pairs NaN, which bar draws as no bar; a reshape would shift every
   % later value onto another pair's bar.
   XData = unique(XData);
   [~, ix] = ismember(G.(xgroupvar), XData);
   if isempty(cgroupvar)
      ic = ones(height(G), 1);
      ncols = 1;
   else
      cmembers = unique(G.(cgroupvar));
      [~, ic] = ismember(G.(cgroupvar), cmembers);
      ncols = numel(cmembers);
   end
   slot = sub2ind([numel(XData), ncols], ix, ic);
   ydata = YData;
   YData = nan(numel(XData), ncols);
   YData(slot) = ydata;

   % Each arm takes the slot of its bar. A row of the flat array is one
   % slot, so the reshape puts the lower arms on page 1 and the upper arms
   % on page 2.
   EData = nan(numel(XData) * ncols, 2);
   EData(slot, :) = arms;
   EData = reshape(EData, numel(XData), ncols, 2);

   % cgroupvar may be empty; the logical stand-in makes bar treat
   % everything as one color group, matching boxchartcats.
   if isempty(cgroupvar)
      CData = true(size(YData));
   else
      CData = tbl.(cgroupvar);
   end
end


function halfwidth = cihalfwidth(y, method, alpha)
   %CIHALFWIDTH Half-width of the groupci interval of one bar's values.
   %
   % Both intervals are symmetric about the bar height: the t interval about
   % the mean, and the notch about the median. errorbar draws the bar
   % height plus or minus this half-width, so the tips land on the bounds.
   % A bar with fewer than two values has NaN bounds, so errorbar draws no
   % whisker there.

   [~, bounds] = sampleci(y, method, alpha);
   halfwidth = diff(bounds) / 2;
end

function arm = quartilearm(y, side)
   %QUARTILEARM Distance from the median of Y to one of its quartiles.
   %
   % SIDE 1 reads the lower quartile and SIDE 2 the upper one. The
   % quartiles are the box edges groupstats.boxchartydata returns, so the
   % whisker tips equal the box edges boxchartcats draws for the same rows.
   % boxchartydata drops NaN values first, and so does the groupsummary
   % median that sets the bar height.

   % Import each package member this local function requires.
   import groupstats.boxchartydata

   ycoords = boxchartydata(y);
   arm = abs(ycoords.boxedge(side) - ycoords.boxline);
end

function [CData, YData] = mergemembermean(CData, YData, mergegroups)
   %MERGEMEMBERMEAN Average member columns of the summary matrix by name.
   %
   % The columns of YData arrive in category order of CData. Each merge
   % group's columns average into the first member's category position.
   % The shared relabel gives the merged category the same position, so
   % the columns and the categories stay paired. The merged column takes
   % the minimum member position; a mean position can collide with an
   % unmerged column's position.

   % Capture the pre-merge category order, then relabel the rows through
   % the shared helper, which also validates the member names.
   members0 = string(categories(removecats(CData)));
   CData = mergegroupmembers(CData, mergegroups);

   % A bare member list is one merge group, the same rule the helper uses.
   if ~iscell(mergegroups)
      mergegroups = {mergegroups};
   end

   % A member with no rows in an x-group holds NaN there, so the merged
   % bar averages the members that exist and is NaN only when none do.
   keep = true(1, numel(members0));
   for n = 1:numel(mergegroups)
      cols = find(ismember(members0, string(mergegroups{n})));
      YData(:, min(cols)) = mean(YData(:, cols), 2, 'omitnan');
      keep(setdiff(cols, min(cols))) = false;
   end
   YData = YData(:, keep);
end

function [XData, YData, EData] = reorderXGroups(opts, sortcolumns, ...
      XData, YData, EData)
   %REORDERGROUPS Reorder the x-axis (tick) groups.
   %
   % Use this to order categorical data, or data of any type, other than by
   % the default ordinal ordering.

   if opts.XGroupOrder == "none"
      % The sortorder namelist allows ascend, descend, and none. "stable" is
      % a sort option MATLAB accepts and this one does not.

      % A pair with no rows holds NaN, so the mean reads the bars that
      % exist, and an x-group with none of the selected bars sorts last.
      switch opts.SortBy
         case {"ascend", "descend"}
            stat = mean(YData(:, sortcolumns), 2, 'omitnan');
            [~, idx] = sort(stat, opts.SortBy, 'MissingPlacement', 'last');
            XData = reordercats(XData, string(XData(idx)));
         otherwise
            % "none", the only other value the sortorder namelist allows.
            % "stable" was considered and left out: for categories it means
            % the order they already have, which is what "none" does.
      end
   else
      % Sort by order of provided elements
      % A partial order names some x-groups and leaves the rest behind
      % them, the way CGroupOrder does.
      members = string(categories(removecats(XData)));
      idx = reordergroupmembers(opts.XGroupOrder, members, ...
         "barchartcats", "XGroupOrder");

      % reordercats changes the display order and leaves the rows where they
      % are. bar pairs XData(i) with YData(i,:), so permuting the rows too
      % would move each height onto another group's tick.
      XData = reordercats(XData, members(idx));
   end
end

function [YData, EData, CData, opts] = reorderCGroups(opts, YData, ...
      EData, CData)
   %REORDERCGROUPS Reorder the color groups, which are the columns of YData.
   %
   % bar draws one series per column, and the legend reads them in that
   % order. Ordering the columns orders both the bars within each x-tick
   % group and the legend. A caller's LegendString binds to the members in
   % category order, so it is permuted the same way and stays on its data.

   if isscalar(opts.CGroupOrder) && opts.CGroupOrder == "none"
      return
   end

   % groupsummary groups by category order, so the columns of YData are in
   % category order. unique(...,"stable") would give first-appearance order
   % and pair each label with the wrong column.
   if iscategorical(CData)
      members = string(categories(removecats(CData)));
   else
      members = string(unique(CData));
   end

   idx = reordergroupmembers(opts.CGroupOrder, members, ...
      "barchartcats", "CGroupOrder");

   YData = YData(:, idx);
   if ~isempty(EData)
      % EData holds a lower and an upper page, so keep both.
      EData = EData(:, idx, :);
   end
   if numel(opts.LegendString) == numel(members)
      opts.LegendString = opts.LegendString(idx);
   end

   if iscategorical(CData)
      CData = reordercats(CData, members(idx));
   end
end

function plotBarErrors(opts, H, YData, EData)
   %PLOTBARERRORS Draw one whisker per bar, from the spread of its group.
   %
   % The whisker shows the standard deviation for method "mean". For method
   % "median", it runs from the lower quartile to the upper quartile.
   % summarizeTableGroups computes whichever pairs with the method. With
   % ErrorBar="ci", EData holds the half-width of the groupci interval, so
   % the same call draws the interval. EData holds the lower arm on page 1
   % and the upper arm on page 2.

   if ~opts.PlotError || isempty(EData)
      return
   end

   % bar draws on a categorical ruler. That ruler converts any x it is given
   % back to a category, so a whisker cannot sit at a fractional offset from
   % its tick. With one series per tick the bar center is the tick, and the
   % whiskers land correctly. With more, they would all stack on the tick
   % center and read as belonging to the wrong bars.
   if numel(H) > 1
      error('groupstats:barchartcats:plotErrorNeedsOneSeries', ...
         ['PlotError needs one bar per x-tick, and this chart has %d. ' ...
         'A categorical x-axis places every whisker on the tick center, ' ...
         'so they would not line up with their bars. Omit cgroupvar, or ' ...
         'leave PlotError off.'], numel(H))
   end

   % XEndPoints holds the center of each bar in a series, which is where the
   % whisker belongs. Computing it by hand would repeat bar's own layout.
   % Take hold after the guard, so the error leaves the axes as it found them.
   ax = opts.Parent;
   washeld = ishold(ax);
   hold(ax, 'on')

   errorbar(ax, H.XEndPoints, YData(:, 1), EData(:, 1, 1), EData(:, 1, 2), ...
      'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1, 'CapSize', 4);

   if ~washeld
      hold(ax, 'off')
   end
end

function shadebarchartgroups(opts, H)
   %SHADEBARCHARTGROUPS Shade alternate x-tick groups, as boxchartcats does.

   if ~opts.ShadeGroups
      return
   end

   % Each series reports the center of its bars, so the leftmost and
   % rightmost across every series bound the group.
   xends = vertcat(H.XEndPoints);
   xleft = min(xends, [], 1);
   xright = max(xends, [], 1);

   if numel(xleft) < 2
      return
   end

   % XEndPoints lists each x-group in the row order XData held when bar()
   % drew it, which is data order, not left-to-right display order.
   % reordercats (SortBy or XGroupOrder) changes the display order without
   % moving XData's rows, so that order can now disagree with position on
   % the axis. Sort the left/right edges by position first, or the gap and
   % the alternating selection below read the wrong neighbors and shade
   % the wrong ticks.
   [xleft, order] = sort(xleft);
   xright = xright(order);

   [ylow, yhigh] = bounds(ylim(opts.Parent));

   % Extend each shaded region halfway to its neighbor, so the shading meets
   % between groups rather than leaving a gap.
   dx = mean(xleft(2:end) - xright(1:end-1), 'omitnan') / 2;
   xleft = xleft - dx;
   xright = xright + dx;

   idxodd = 1:2:numel(xleft);
   xpatch = [xleft(idxodd); xright(idxodd); xright(idxodd); ...
      xleft(idxodd); xleft(idxodd)];
   ypatch = repmat([ylow; ylow; yhigh; yhigh; ylow], 1, numel(idxodd));

   P = patch(opts.Parent, xpatch, ypatch, 'k', ...
      'FaceColor', [0.5 0.5 0.5], ...
      'FaceAlpha', 0.1, ...
      'EdgeColor', 'none');

   % Put the shading behind the bars, and keep it out of the legend.
   uistack(P, 'bottom');
   set(get(get(P, 'Annotation'), 'LegendInformation'), ...
      'IconDisplayStyle', 'off');
end

function [H, L, ax] = createCategoricalBarChart(XData, YData, CData, ...
      cgroups, ylabeltext, opts, props)
   % Create the barchart. cgroups names one color group per YData column.
   % It is read from the categories of CData after any merge relabeled
   % them, so the names always match the columns.

   % Note: "grouped" is the default. Use "BarLayout","stacked" for stacked
   ax = opts.Parent;
   H = bar(ax, XData, YData, props{:});

   % Add a ylabel
   ylabel(ax, ylabeltext);

   % Format the plot
   set(ax, "YGrid", "on", "XGrid", "on", "XMinorTick", "off", "Box", "on");
   set(ax.XAxis, 'TickLength', [0 0]);

   % Color the bars

   % The k-th color group takes the k-th row of defaultcolors, the palette
   % boxchartcats and scatter read, so the family colors its groups alike.
   % The palette holds 21 colors; more series than that wrap around.
   colors = defaultcolors();
   colors = colors(mod((1:numel(H)) - 1, size(colors, 1)) + 1, :);

   % bar already took the caller's properties, so setting one here would
   % discard what they asked for. Apply each default only when they left it
   % out.
   given = string(props(1:2:end));

   % A caller's CData shows only under flat coloring, so "flat" stands in
   % for the palette color when CData is given.
   for n = 1:numel(H)
      if ~ismember("LineWidth", given)
         H(n).LineWidth = 1;
      end
      if ismember("CData", given)
         palettecolor = "flat";
      else
         palettecolor = colors(n, :);
      end
      if ~ismember("FaceColor", given)
         H(n).FaceColor = palettecolor;
      end
      if ~ismember("EdgeColor", given)
         H(n).EdgeColor = palettecolor;
      end
      if ~ismember("FaceAlpha", given)
         H(n).FaceAlpha = 0.75;
      end
   end

   % Add the legend

   withwarnoff('MATLAB:legend:IgnoringExtraEntries');
   legendtxt = opts.LegendString;
   if isempty(legendtxt)

      % If no cgroupvar was provided, CData will be a vector of "true". This
      % means a legend is unnecessary, if legendtxt was not provided.
      if islogical(CData)
         legendtxt = '';
         opts.Legend = 'off';
      else
         legendtxt = cgroups;
      end

   end

   % With the legend off, make none. A hidden legend still holds its space
   % above the axes, so the axes would not fill the figure. The empty
   % placeholder is what histogram and scatter return.
   if opts.Legend == "off"
      L = gobjects(0);
      return
   end
   try
      % The family layout puts the legend above the axes in up to three
      % columns that fit its tile, subplot, or figure. The legend uses the
      % axes font.
      L = legend(ax, legendtxt, 'AutoUpdate', 'off');
      legendlayout(L, opts.LegendOrientation);
   catch
      % A legend failure must still assign L, or the (H, L, ax) return
      % throws on an unassigned output. An empty placeholder matches the
      % other charts' legend-failure value.
      L = gobjects(0);
   end

end

%%
% BSD 3-Clause License
%
% Copyright (c) 2023, Matthew Guy Cooper (mgcooper)
% All rights reserved.
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
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
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
