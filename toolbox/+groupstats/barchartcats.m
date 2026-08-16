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
   % tbl.(ydatavar) according to the unique values in tbl.(xgroupvar) and plots each
   % group of data as a separate bar chart. xgroupdata determines the position
   % of each bar chart along the x-axis. ydata must be a vector, and xgroupdata
   % must have the same length as ydata.
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
   % method - the method used in the call to groupsummary to compute the values
   % plotted as bars. The default method is 'mean'. For 'mean', the standard
   % deviation is also computed in the call to groupsummary to support the
   % addition of whiskers to the bars. If 'median' is passed in as the method,
   % the whiskers represent the interquartile range. Set PlotError to draw
   % them. PlotError needs one bar per x-tick, so omit cgroupvar.
   %
   % xgroupuse - A cell array of categories to be used for the x-axis grouping.
   %
   % cgroupuse - A cell array of categories to be used for the color grouping.
   %
   % MergeGroups - A cell array of index vectors naming the color-group
   % columns to combine. Each merged group is drawn as one bar carrying the
   % mean of its parts. The bar sits at the smallest index of the group. Its
   % name joins the names it replaces. Merging discards the spread of the
   % combined groups, so PlotError cannot be set at the same time.
   %
   % Output Argument
   %
   % H: A handle to the created bar chart.
   %
   % Example
   %
   % Plot the Value variable of table tbl. Group along the x-axis by
   % CategoryX, and by color within each group by CategoryC.
   %
   % tbl = readtable('data.csv');
   % h = groupstats.barchartcats(tbl, "Value", "CategoryX", "CategoryC");
   %
   % Restrict the groups to named members. XGroupMembers and CGroupMembers are
   % name-value arguments, not positional ones.
   %
   % h = groupstats.barchartcats(tbl, "Value", "CategoryX", "CategoryC", ...
   %    XGroupMembers = ["Cat1", "Cat2", "Cat3"], ...
   %    CGroupMembers = ["Group1", "Group2"]);
   %
   % Sort the x-groups by their group mean and pass a Bar property through:
   %
   % h = groupstats.barchartcats(tbl, "Value", "CategoryX", "CategoryC", ...
   %    SortBy = "ascend", BarWidth = 0.5);
   %
   % Sorting
   %
   % SortBy orders the x-groups by their summarized value, "ascend" or
   % "descend". XGroupOrder names the order directly and takes precedence.
   % SortGroupMembers restricts which color-group members contribute to the
   % sort value.
   %
   % Dependencies
   %
   % These come from matfunclib and must be on the path:
   %
   %  dealout (functools)          splits the outputs
   %
   % Matt Cooper, 29-Nov-2022, https://github.com/mgcooper
   %
   % See also reordergroups, reordercats, barchart,
   % groupstats.boxchartcats, groupstats.namelists.sortorder

   % NOTE: "unique" is embedded all over the place e.g. in the call to
   % groupsummary in summarizeTableGroups ... which means the CGroup / YData at
   % minimum is in sorted order. This creates a possible discrepancy. Setting
   % legend text outside this function with unique(..., "stable") assumes the
   % data is in stable order, and it is not. It could also lead to errors
   % within this function, but will require time to sort out.

   % TODO:
   %
   % - add a "histogram" or "frequencies" or maybe "groupfilter" option in
   % which the xgroupvar is transformed to generate the values on the y axis. In
   % this case ydatavar and xgroupvar would be the same. The data would then
   % need to be numeric in an underlying sense, or ordinal, or otherwise
   % compatible with the transformation applied to the xgroupvar data. Could add
   % an option to use piechart instead of barchart. Or, this type of
   % functionality could go to piechartcats, and that function could have a
   % "DisplayType" option that uses bars instead of pies.
   %
   % - allow ydatavar to be a vector of strings indicating multiple columns in a
   % table? Ran into this for the case where a table is already a summary table
   % and I want to plot different vars side by side. Transform the table to
   % accomplish this. Stack the vars into one var, and add a categorical var
   % holding the original varnames.

   % Note: MergeGroups here takes column indices, while
   % groupstats.histogram takes member names through MergeGroupMembers.
   % Give the two one spelling.

   arguments
      tbl tabular
      ydatavar (1,1) string {mustBeNonempty}
      xgroupvar (1,1) string {mustBeNonempty}
      cgroupvar string = string.empty()
      opts.XGroupMembers string = string.empty()
      opts.CGroupMembers string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers string = string.empty()
      opts.method (:,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.method, ...
         "centralstatistic") } = "mean"
      opts.SortBy (1,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.SortBy, ...
         "sortorder") } = "none"
      % SortGroupMembers are members of cgroupvar to be used for computing the
      % sorting order of the xgroups. For example, say there are five xgroup
      % members, i.e. five unique values of tbl.(xgroupvar), and three cgroup
      % members. The default "ascend" computes the average of the three cgroup
      % bars in each xgroup. It then sorts the xgroups by those averages. If
      % instead you
      % want to sort by a particular cgroup member, specify them using
      % opts.SortGroupMembers.
      opts.SortGroupMembers (:,1) string = "all"
      opts.MergeGroups (:,1) = []
      opts.XGroupOrder (:,1) string = "none"
      opts.CGroupOrder (:,1) string = "none"
      % Both default off. Each was declared and never read, so turning them
      % on by default would change every existing chart.
      opts.ShadeGroups (1,1) logical = false
      opts.PlotError (1,1) logical = false
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

   varargs = namedargs2cell(props);

   % validate inputs
   tbl = prepareTableGroups(tbl, ydatavar, ...
      XGroupVar = xgroupvar, ...
      XGroupMembers = opts.XGroupMembers, ...
      CGroupVar = cgroupvar, ...
      CGroupMembers = opts.CGroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers);

   % barchartcats requires summarizing the data, unlike boxchart
   [XData, YData, CData, EData] = summarizeTableGroups( ...
      tbl, ydatavar, xgroupvar, cgroupvar, opts.method);

   % main function

   % Note: plotBarErrors reads H.XEndPoints for the whisker positions rather
   % than adapting the boxchartxdata method, because bar already computes the
   % center of every bar it draws.

   % Note: merging gives new color groups, so SortGroupMembers has to be
   % read against the merged names. mergeGroupColumns does that: it maps a
   % named member onto the merged group that contains it, and for the default
   % "all" it takes every merged column. The unmerged branch reads the
   % category order instead.

   % Need to add validation to ensure SortGroupMembers are members of CData

   % NOTE: the columns arrive in category order, because "unique" is
   % embedded all over the place e.g. in the call to groupsummary in
   % summarizeTableGroups. opts.SortColumns is built from that same order
   % below. Asking for "stable" here does not change the columns, only the
   % list read against them, which is what made the sort read the wrong one.

   % Order the color groups before merging. Merging combines columns, and
   % the order is expressed in terms of the unmerged ones.
   [YData, EData, CData] = reorderCGroups(opts, YData, EData, CData);

   % Custom group merging
   if isempty(opts.MergeGroups)
      % Find the columns to use for computing the sort. The columns are in
      % category order, and CGroupOrder permutes that order, so read the
      % categories. unique(...,"stable") gives first-appearance order and
      % marks another color group's column.
      if iscategorical(CData)
         cgroups = string(categories(removecats(CData)));
      else
         cgroups = string(unique(CData));
      end
      if opts.SortGroupMembers == "all"
         opts.SortGroupMembers = cgroups;
      end
      opts.SortColumns = ismember(cgroups, opts.SortGroupMembers);
   else
      [YData, opts, cgroups] = mergeGroupColumns(opts, YData, CData);

      % Merging combines columns. The spread of a merged group is not the
      % spread of its parts, so the merge discards EData. That leaves
      % PlotError nothing to draw, so the guard below names the conflict.
      if opts.PlotError
         error('groupstats:barchartcats:plotErrorNeedsUnmergedGroups', ...
            ['PlotError needs the spread of each group, and MergeGroups ' ...
            'combines groups whose spread does not add up. Omit ' ...
            'MergeGroups, or leave PlotError off.'])
      end
      EData = [];
   end

   % Custom ordering along x-axis
   [XData, YData, EData] = reorderXGroups(opts, XData, YData, EData);

   % Create the figure
   [H, L, ax] = createCategoricalBarChart(XData, YData, CData, cgroups, ...
      ydatavar, opts, varargs);

   % Draw the whiskers on top of the bars, then shade behind them.
   plotBarErrors(opts, H, YData, EData);
   shadebarchartgroups(opts, H);

   hold off
   [varargout{1:nargout}] = dealout(H, L, ax);
end


function [XData, YData, CData, EData] = summarizeTableGroups(tbl, ydatavar, ...
      xgroupvar, cgroupvar, method)
   %SUMMARIZETABLEGROUPS

   % TODO
   % - check if two calls to groupsummary or similar has occurred in which case
   % there may be e.g. mean_mean_<var>. This would happen if I passed in a table
   % that was created with groupsummary, in which there is no need to summarize
   % the data further.
   % - Add a method to handle missing values. In the above example, a binning
   % method may have been applied to the table outside this function. If a
   % group has no members for a bin, the table will not have the size the
   % cgroupvar and xgroupvar counts imply.

   % cgroupvar complicates this when it is "none" and I don't think we need
   % it anyway, in boxchartcats I set CData to a logical the same size as
   % XData which I think is a hack to get boxchart to act right
   % G = groupsummary(Tplot,xgroupvar, ["mean", "std"], ydatavar);
   % NEVERMIND = we do need cgroupvar, it controls how groupsummary returns
   % the groups which then implicitly gets bar to act right

   if strcmp(method,'mean')
      G = groupsummary(tbl,[cgroupvar xgroupvar], ["mean", "std"], ydatavar);
      XData = G.(xgroupvar);
      YData = G.("mean_" + ydatavar);
      EData = G.("std_" + ydatavar);
   elseif strcmp(method,'median')
      G = groupsummary(tbl,[cgroupvar xgroupvar], {"median", @iqr}, ydatavar);
      XData = G.(xgroupvar);
      YData = G.("median_" + ydatavar);

      % groupsummary names a function-handle method's column fun<N>_<var>.
      % The spread that pairs with a median is the interquartile range.
      EData = G.("fun1_" + ydatavar);
   end

   % Each column of Y needs to correspond to a group of bars. Each bar in a
   % group is a different color, and each group is a different x-tick.
   % XData = reshape(XData, [], numel(xgroupuse));
   XData = unique(XData);
   YData = reshape(YData, numel(XData), []);
   EData = reshape(EData, numel(XData), []);

   % Aug 18, 2023, Moved this from the main function when prepareTableGroups
   try
      CData = tbl.(cgroupvar);
   catch
      CData = true(size(YData));
   end
end


function [NewYData, opts, NewCGroups] = mergeGroupColumns(opts, YData, CData)
   %MERGEGROUPCOLUMNS

   % May 2024 - need a way to enforce the C-Group ordering. This created
   % difficulty when setting the legend outside of this function. The data is
   % plotted by sorted order. CGroupMember labels from
   % unique(tbl.(cgroupvar), 'stable') do not match the legend ordering.
   % Labels from unique(tbl.(cgroupvar)) do match, because that is sorted
   % order.

   % mergegroups is the YData column indices to merge, so the new YData needs to
   % contain the unmerged groups and the merged groups. Each merged group
   % takes the position of its own smallest index. Each unmerged group keeps
   % its original position relative to those smallest indices.
   mergegroups = opts.MergeGroups;
   dontmerge = setdiff(1:size(YData, 2), horzcat(mergegroups{:}));
   NewYData = nan(size(YData));
   NewCGroups = string(unique(CData));
   NewYData(:, dontmerge) = YData(:, dontmerge);
   for n = 1:numel(mergegroups)
      NewYData(:, min(mergegroups{n})) = mean(YData(:, mergegroups{n}), 2);
      NewCGroups(min(mergegroups{n})) = strjoin(NewCGroups(mergegroups{n}));

      % Clear every column the merge consumed, not just the last one. The
      % merged name sits at the smallest index, and NewYData drops the rest
      % as all-NaN. A middle name left behind makes NewCGroups longer than
      % NewYData has columns.
      NewCGroups(setdiff(mergegroups{n}, min(mergegroups{n}))) = missing;
   end
   NewYData = NewYData(:, ~all(isnan(NewYData)));
   NewCGroups = NewCGroups(~ismissing(NewCGroups));

   % Also need to adjust opts.SortGroupMembers
   % Find the columns to use for computing the sort
   if opts.SortGroupMembers == "all"
      % Not sure we need to set the members, but if so, when merging, they lose
      % their meaning
      opts.SortGroupMembers = NewCGroups;
      opts.SortColumns = 1:size(NewYData, 2);
      % sortgroups = string(unique(CData));
   else
      % Find the members of mergegroups that are also in SortGroup?
      NewSortGroups = NewCGroups;
      for n = 1:numel(NewCGroups)
         tf = ~any(ismember(opts.SortGroupMembers,strsplit(NewCGroups(n))));
         if tf
            NewSortGroups(n) = missing;
         end
      end
      opts.SortGroupMembers = NewSortGroups;
      opts.SortColumns = ismember(NewCGroups, opts.SortGroupMembers);
   end
end

function [XData, YData, EData] = reorderXGroups(opts, XData, YData, EData)
   %REORDERGROUPS Reorder the x-axis (tick) groups.
   %
   % Use this to order categorical data, or data of any type, other than by
   % the default ordinal ordering.

   if opts.XGroupOrder == "none"
      % The sortorder namelist allows ascend, descend, and none. "stable" is
      % a sort option MATLAB accepts and this one does not.

      switch opts.SortBy
         case "ascend"
            [~, idx] = sort(mean(YData(:, opts.SortColumns), 2), 'ascend');
            XData = reordercats(XData, string(XData(idx)));
         case "descend"
            [~, idx] = sort(mean(YData(:, opts.SortColumns),2), 'descend');
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
   % TODO: reorder the legend entries if custom ones provided
end

function [YData, EData, CData] = reorderCGroups(opts, YData, EData, CData)
   %REORDERCGROUPS Reorder the color groups, which are the columns of YData.
   %
   % bar draws one series per column, and the legend reads them in that
   % order. Ordering the columns orders both the bars within each x-tick
   % group and the legend.

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
      EData = EData(:, idx);
   end

   if iscategorical(CData)
      CData = reordercats(CData, members(idx));
   end
end

function plotBarErrors(opts, H, YData, EData)
   %PLOTBARERRORS Draw one whisker per bar, from the spread of its group.
   %
   % The whisker is the standard deviation for method "mean", and the
   % interquartile range for method "median". summarizeTableGroups computes
   % whichever pairs with the method.

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
   washeld = ishold();
   hold on

   errorbar(H.XEndPoints, YData(:, 1), EData(:, 1), ...
      'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1, 'CapSize', 4);

   if ~washeld
      hold off
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

   [ylow, yhigh] = bounds(ylim);

   % Extend each shaded region halfway to its neighbor, so the shading meets
   % between groups rather than leaving a gap.
   dx = mean(xleft(2:end) - xright(1:end-1), 'omitnan') / 2;
   xleft = xleft - dx;
   xright = xright + dx;

   idxodd = 1:2:numel(xleft);
   xpatch = [xleft(idxodd); xright(idxodd); xright(idxodd); ...
      xleft(idxodd); xleft(idxodd)];
   ypatch = repmat([ylow; ylow; yhigh; yhigh; ylow], 1, numel(idxodd));

   P = patch(xpatch, ypatch, 'k', ...
      'FaceColor', [0.5 0.5 0.5], ...
      'FaceAlpha', 0.1, ...
      'EdgeColor', 'none');

   % Put the shading behind the bars, and keep it out of the legend.
   uistack(P, 'bottom');
   set(get(get(P, 'Annotation'), 'LegendInformation'), ...
      'IconDisplayStyle', 'off');
end

function [H, L, ax] = createCategoricalBarChart(XData, YData, CData, ...
      cgroups, ydatavar, opts, props)
   % Create the barchart. cgroups names one color group per YData column.
   % Merging combines columns and renames them, so the caller passes the
   % names that match the columns rather than the ones CData still holds.

   % Note: "grouped" is the default. Use "BarLayout","stacked" for stacked
   H = bar( XData, YData, 'FaceColor', 'flat', props{:});

   % For colors, if there are more bars than default colors, need to generate
   % colors, so I switched to the method below that uses n=1:length(H)

   % Load default colors to match the mean symbols to the boxcharts
   % colors = defaultcolors;

   % Add a ylabel
   ylabel(ydatavar);

   % Format the plot
   ax = gca;
   set(ax, "YGrid", "on", "XGrid", "on", "XMinorTick", "off", "Box", "on");
   set(ax.XAxis, 'TickLength', [0 0]);

   % Color the bars

   % bar already took the caller's properties, so setting one here would
   % discard what they asked for. Apply each default only when they left it
   % out.
   given = string(props(1:2:end));

   for n = 1:numel(H)
      if ~ismember("LineWidth", given)
         H(n).LineWidth = 1;
      end
      if ~ismember("CData", given)
         H(n).CData = n;
      end
      if ~ismember("EdgeColor", given)
         H(n).EdgeColor = "flat";
      end
      if ~ismember("FaceAlpha", given)
         H(n).FaceAlpha = 0.75;
      end
      %H(n).FaceColor = colors(n,:);
      %H(n).FaceAlpha = 0.3;
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
   try
      L = legend(legendtxt, ...
         'Location', 'northwest', ...
         'AutoUpdate', 'off', ...
         'Orientation', opts.LegendOrientation, ...
         'FontSize', 12);
      % 'Location', 'northoutside', ...
      % 'AutoUpdate', 'off', ...
      % 'numcolumns', numel(legendtxt) );

      set(L, 'Visible', opts.Legend)
   catch
   end

   % % Note: this might work if table data is passed in with all the group data,
   % but % in my example I used the metadata table from Info which already has
   % the group % summary calculations so I cannot get the std
   %
   % % To get same order as the boxcharts, use [XData CData], not [CData XData]
   % try
   %    [mu, uv] = groupsummary(YData(:), [XData(:) CData], ["mean", "std"]); % uv = [uv{:}];
   % catch
   %    [mu, uv] = groupsummary(YData, XData, ["mean", "std"]); % uv = [uv{:}];
   % end

   % % To add labels:
   % for n = 1:numel(H)
   %    xtips = H(n).XEndPoints;
   %    ytips = H(n).YEndPoints;
   %    labels = string(H(n).YData);
   %    text(xtips,ytips,labels,'HorizontalAlignment','center',...
   %        'VerticalAlignment','bottom')
   % end

end

% mergecolumns_average, an alternative to mergeGroupColumns above, is in git
% history. It placed each merged column at the mean position of the columns it
% merged, rather than at their minimum position. The author's note on it: a
% mean position can collide with an unmerged column's position. The live code
% uses the minimum for that reason.


% % I moved anything out of here that was immediately applicable to above, whats
% left could be helpful for adding the mean +/- std idea
% function H = barchartcats(tbl,XData,YData,CData,ydatavar,method,varargs)
% % barchartcats(tbl,ydatavar,xgroupvar,cgroupvar, ...
% %    xgroupuse,cgroupuse,BoxChartOpts,opts)
%
% % Default method is 'mean'
% if nargin < 5
%    method = 'mean';
% end
%
% % Summarize the data
% if strcmp(method,'mean')
%    % [mu, uv, uc] = groupsummary(YData, [XData CData], ["mean", "std"]);
%    if istable(tbl)
%       G = groupsummary(tbl,{XData CData}, ["mean", "std"], YData);
%    else
%       G = groupsummary(tbl, [XData CData], ["mean", "std"], YData);
%    end
% elseif strcmp(method,'median')
%    % [mu, uv, uc] = groupsummary(YData, [XData CData], {"median", @iqr});
%    G = groupsummary(tbl, [XData CData], {"median", @iqr}, YData);
% end
%
% % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% X = categorical(unique(metadata.basin));
% Y = nan(numel(X), numel(scenarios));
% for n = 1:numel(scenarios)
%    Y(:,n) = metadata.threshold(metadata.scenario == scenarios(n));
% end
%
% % Reorder from low to high POT
% [~,idx] = sort(mean(Y,2));
% X = reordercats(X,string(X(idx)));
%
% % % % % % % % % % % % % % % % % % % % % % % % % % %
%
% % Create the barchart
% H = bar( XData, mu, 'FaceColor', 'flat', varargs{:} );
%
% Add error bars
% hold on
% if strcmp(method,'mean')
%    for n = 1:length(mu)
%       errorbar(n, mu(n), sigma(n), 'k', 'LineStyle', 'none');
%    end
% elseif strcmp(method,'median')
%    for n = 1:length(mu)
%       errorbar(n, mu(n), q3(n)-q1(n), 'k', 'LineStyle', 'none');
%    end
% end
% hold off
%
% end

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

% Note, the columns need to be categorical, but the 'x/cgroupvar' and
% 'xgroupuse/c' inputs can be strings/chars/cellstr or categorical. Specifying
% 'string' in the arguments block converts implicitly to string.
% ismember('someCategoricalVariable','someStringVariable') works, but only if
% the string is scalar, or a cell array of chars. The approach here converts
% to string. In a few places, attention is needed to convert to string
% if non-scalar string/categorical comparisons are made.
