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
   % Output Argument
   %
   % H: A handle to the created box chart.
   %
   % Example
   %
   % Plot the Value variable of table tbl, grouped along the x-axis by
   % CategoryX and by color within each group by CategoryC.
   %
   % tbl = readtable('data.csv');
   % h = groupstats.boxchartcats(tbl, "Value", "CategoryX", "CategoryC");
   %
   % Restrict the groups to named members. XGroupMembers and CGroupMembers are
   % name-value arguments, not positional ones.
   %
   % h = groupstats.boxchartcats(tbl, "Value", "CategoryX", "CategoryC", ...
   %    XGroupMembers = ["Cat1", "Cat2", "Cat3"], ...
   %    CGroupMembers = ["Group1", "Group2"]);
   %
   % Sort the x-groups by their group mean and pass BoxChart properties
   % through:
   %
   % h = groupstats.boxchartcats(tbl, "Value", "CategoryX", "CategoryC", ...
   %    SortBy = "ascend", Notch = "on", MarkerStyle = "none");
   %
   % Sorting
   %
   % SortBy orders the x-groups by their group mean, "ascend" or "descend".
   % XGroupOrder names the order directly and takes precedence over SortBy.
   %
   % Dependencies
   %
   % These come from matfunclib and must be on the path:
   %
   %  makevalidvarnames (libtable) builds the y-axis label
   %  naninterp1 (libstats)        fills gaps in the group shading bounds
   %  dealout (functools)          splits the outputs
   %
   % Matt Cooper, 29-Nov-2022, https://github.com/mgcooper
   %
   % See also: reordergroups, reordercats, boxchart,
   % groupstats.barchartcats, groupstats.namelists.sortorder

   % Note, if notch is off, the mean looks nice as a solid white circle. If notch
   % is on, the mean may fall outside the shaded region, so face color is needed.

   % To add custom whiskers:
   % arrayfun(@(n) set(H(n),'WhiskerLineStyle','none'),1:numel(H))
   % then plot custom ones

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
      cgroupvar string = string.empty()

      % These four came from barchartcats, where they were named CustomOpts.
      % All four default to empty, which prepareTableGroups reads as every
      % member, so none of them calls groupmembers to build a default.
      opts.XGroupMembers (:, 1) string = string.empty()
      opts.CGroupMembers (:, 1) string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers (:, 1) string = string.empty()

      % Empty means no row selection. prepareTableGroups raises
      % rowSelectVarWithoutMembers when RowSelectVar is named and this is
      % empty, because selecting no rows leaves an empty chart.

      opts.XGroupOrder (:,1) string = "none"
      opts.CGroupOrder (:,1) string = "none"
      opts.SortBy (1,1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.SortBy, ...
         "sortorder") } = "none"
      opts.PlotMeans (1,1) logical = true
      opts.ShadeGroups (1,1) logical = true
      opts.ConnectMeans (1,1) logical = false
      opts.ConnectMedians (1,1) logical = false
      opts.Legend (1,1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Legend, ...
         "legendvisibility")} = "on"
      opts.LegendString string = string.empty()
      % The legend sits above the axes, where a row of entries reads best.
      % barchartcats puts its legend inside the axes at northwest and
      % defaults to vertical for the same reason.
      opts.LegendOrientation (1, 1) string ...
         { groupstats.namelists.mustBeMemberOf(opts.LegendOrientation, ...
         "legendorientation") } = "horizontal"
      props.?matlab.graphics.chart.primitive.BoxChart
   end

   % Import groupstats package
   import groupstats.groupselect
   import groupstats.boxchartxdata
   import groupstats.prepareTableGroups

   % Override default BoxChart settings
   ResetFields = {'JitterOutliers','Notch'};
   ResetValues = {true,'on'};
   for n = 1:numel(ResetFields)
      if ~ismember(ResetFields{n},fieldnames(props))
         props.(ResetFields{n}) = ResetValues{n};
      end
   end
   varargs = namedargs2cell(props);

   % validate inputs
   tbl = prepareTableGroups(tbl, ydatavar, ...
      XGroupVar = xgroupvar, ...
      XGroupMembers = opts.XGroupMembers, ...
      CGroupVar = cgroupvar, ...
      CGroupMembers = opts.CGroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers);

   % Assign the data to plot
   XData = tbl.(xgroupvar);
   YData = tbl.(ydatavar);
   try
      CData = tbl.(cgroupvar);
   catch
      CData = true(size(YData));
   end

   % main function
   hold off % repeated calls create problems

   % Custom ordering along x-axis
   [XData, YData] = reorderGroups(opts, XData, YData);

   % Create the box chart and legend
   % Order the color groups before drawing, because boxchart reads their
   % order from the categories of CData.
   CData = reorderCGroups(opts, CData);

   [H, L] = categoricalBoxChart(XData, YData, CData, ydatavar, opts, varargs);

   % If "markerstyle", "none" is in varargin, clip the ylimits to the data
   setboxchartylim(H, XData, YData, CData);

   % Add the means if requested
   plotboxchartstats(opts,H,XData,YData,CData);

   % Add shaded bars to distinguish groups if requested
   shadeboxchartgroups(opts,H);

   % for troubleshooting
   % muTbl = groupsummary(Tplot,{xgroupvar,cgroupvar}, "mean", ydatavar);
   if opts.Legend == "off"
      legend off
   end
   hold off

   [varargout{1:nargout}] = dealout(H, L);
end

%% Local Functions
function [H, L] = categoricalBoxChart(XData, YData, CData, YDataVar, CustomOpts, varargs)

   % Create the box chart
   H = boxchart( XData, YData, 'GroupByColor', CData, varargs{:} );

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
      L = legend(legendtxt, ...
         'Orientation', CustomOpts.LegendOrientation, ...
         'Location', 'northoutside', ...
         'AutoUpdate', 'off', ...
         'numcolumns', numcolumns );
   catch
      L = [];
   end

   % Add a ylabel
   ylabel(makevalidvarnames(YDataVar))

   % Format the plot
   set(gca, "YGrid", "off", "XGrid", "off", "XMinorTick", "off", "box", ...
      "on", "TickLength", [0 0]);
end

function CData = reorderCGroups(opts, CData)
   %REORDERCGROUPS Order the color groups, and with them the legend.
   %
   % boxchart draws one series per category of the GroupByColor data, in
   % category order, so ordering the categories orders both the boxes within
   % each x-tick group and the legend.

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
end

function [XData, YData] = reorderGroups(opts, XData, YData)
   %REORDERGROUPS

   if opts.XGroupOrder == "none"
      % Sort the x-groups by their group mean. YData here is the raw column,
      % not a summary matrix as in barchartcats, so the mean per x-group comes
      % from groupsummary rather than from a column mean.
      switch opts.SortBy
         case {"ascend", "descend"}
            [groupmean, members] = groupsummary(YData, XData, "mean");
            [~, idx] = sort(groupmean, opts.SortBy);
            XData = reordercats(XData, string(members(idx)));
         otherwise
            % "none" leaves the category order as it is.
      end
   else
      % A partial order names some x-groups and leaves the rest behind
      % them, the way CGroupOrder does.
      members = string(categories(removecats(XData)));
      Locb = reordergroupmembers(opts.XGroupOrder, members, ...
         "boxchartcats", "XGroupOrder");
      XData = reordercats(XData, members(Locb));
      % YData = YData(Locb, :);
   end
   % TODO: reorder the legend entries if custom ones provided
end

function plotboxchartstats(opts,H,XData,YData,CData)

   hold on;

   % Load default colors to match the mean symbols to the boxcharts
   colors = defaultcolors;

   % Get the x-coordinate of each boxchart center and the mean of each boxchart
   [mu, med, xlocs] = boxchartstats(H, XData, YData, CData);

   % Plot the means
   if opts.PlotMeans
      arrayfun(@(n) scatter(xlocs(n,:), mu(n,:), 30, colors(n, :), 'filled', 's'), ...
         1:numel(H));
   end

   % Connect the means. plot reads each column as one line, and xlocs holds
   % one row per color group, so transpose. Without it each line joined the
   % color groups inside one x-tick instead of following one color across
   % the ticks.
   if opts.ConnectMeans == true
      plot(xlocs', mu', '-', 'Color', [0.5 0.5 0.5],'HandleVisibility','off')
   end

   % Connect the medians.
   if opts.ConnectMedians
      plot(xlocs', med', '-', 'Color', [0.5 0.5 0.5],'HandleVisibility','off')
   end
end

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
   % Table format:
   % muTbl = groupsummary(Tplot,{xgroupvar,cgroupvar}, "mean", ydatavar);

   % If there were no missing charts on any xticks:
   % mumat = reshape(mu,size(xlocs));

   % Instead, place each summarized pair in its own slot. xlocs holds one row
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

   % Get the y-coordinate of the plot bounds
   [ylow, yhigh] = bounds(ylim);

   % since we know the data is regular, fill nan's. naninterp1 needs at least
   % two known points to interpolate between, so a grid with too few filled
   % x-tick groups gets no shading rather than an error.
   if nnz(~isnan(xleft)) < 2 || nnz(~isnan(xright)) < 2
      return
   end
   xleft = naninterp1(1:numel(xleft),xleft,'linear','extrap');
   xright = naninterp1(1:numel(xright),xright,'linear','extrap');

   % To extend the shaded region halfway between each group:
   try
      dx = mean((xleft(2:end) - xright(1:end-1)),'omitnan') / 2;
   catch
      % This means there is only one box, maybe no shading?
      dx = (xright - xleft) / 2;
   end

   xleft = xleft - dx;
   xright = xright + dx;

   idxodd = 1:2:numel(xleft);
   xpatch = [xleft(idxodd); xright(idxodd); xright(idxodd); xleft(idxodd); xleft(idxodd)];
   ypatch = repmat([ylow; ylow; yhigh; yhigh; ylow], 1, numel(idxodd));

   P = patch(xpatch, ypatch, 'k', ...
      'FaceColor', [0.5 0.5 0.5], ...
      'FaceAlpha', 0.1, ...
      'EdgeColor', 'none' );

   % Set up a listener for changes in the YLim property
   ax = gca;
   addlistener(ax, 'YLim', 'PostSet', @(src, evt) updateshadedbounds(P, ax));

   function updateshadedbounds(P, ax)
      P.YData = repmat([ax.YLim(1); ax.YLim(1); ax.YLim(2); ax.YLim(2); ax.YLim(1)], ...
         1, size(P.Faces,1));
   end
end

function setboxchartylim(H, XData, YData, CData)
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
   ylim(bounds + [-padding padding]);
end

% % This was stuff in boxchartstats and/or plotboxchartmeans I did not end up using
%
% % Get the unique values on the X-axis
% uX = unique(XData);
%
% % Get the number of xticks (number of boxchart groups)
% NumX = numel(xgroupuse);
% NumG = numel(cgroupuse);
% symbols = defaultmarkers("closed");
% sizes = [8, 8, 12, 8, 12];

% % More explicit, for reference:
% unique_cats = unique(CData);
% unique_cats_vector = uv{:,2};
% notmissing = ~isnan(xlocs);
% mu_matrix = nan(size(xlocs));
% for n = 1:numel(unique_cats)
%    mu_matrix(n,notmissing(n,:)) = mu(unique_cats_vector==unique_cats(n));
% end
%
% % This was the concise form of above before I saw the final version
% ucats = unique(CData);
% mumat = nan(size(xlocs));
% for n = 1:numel(ucats)
%    mumat(n,~isnan(xlocs(n,:))) = mu(uv{:,2}==ucats(n));
% end

% just in case the version above that first allocates nan(size(xlocs)) fails
% mumat(~isnan(xlocs)) = mu(ismember(uv{:,2},unique(CData)));
% mumat = reshape(mumat,size(xlocs)); mumat(isnan(xlocs)) = NaN;



% % This does the same thing above does, but may be more useful. Note, ismember
% % works b/w categorical and string iff the string is scalar
% if any(~ismember(xgroupuse, string(unique(tbl.(xgroupvar)))))
%    error('all elements of xgroupuse must be members of the set tbl.(xgroupvar)')
% end
% if any(~ismember(cgroupuse, string(unique(tbl.(cgroupvar)))))
%    error('all elements of cgroupuse must be members of the set tbl.(cgroupvar)')
% end

% % This should not be necessary b/c I set cgroupuse/x to all values in
% c/xgroupvar for the case where they are "none",

% % Subset the rows for the cgroup and xgroup variables
% if cgroupuse == "none"
%    incgroup = true(height(tbl),1);
% else
%    incgroup = ismember(tbl.(cgroupvar),cgroupuse);
% end
%
% if xgroupuse == "none"
%    inxgroup = true(height(tbl),1);
% else
%    inxgroup = ismember(tbl.(xgroupvar),xgroupuse);
% end
%
% iplot = incgroup | inxgroup;


% % If both xgroupvar & cgroupvar are "none", there is no grouping variable
% if xgroupvar == "none" && cgroupvar == "none"
%    error('No xgroupvar or cgroupvar was specified, use boxchart')
%
%    % Could call createCategoricalBoxChart, or H = boxchart(tbl.(ydatavar))
%    % H = createCategoricalBoxChart(XData,YData,CData,ydatavar,varargs);
% end
%
% if cgroupvar == "none" % use all categorical variables
%    cgroupvar = string(gettablevarnames(tbl,'categorical'));
% end


% ypatchnew = repmat([y_limits(1) y_limits(1) y_limits(2) y_limits(2) y_limits(1)], numel(P), 1);
% ypatch = repmat([ylow; ylow; yhigh; yhigh; ylow], 1, numel(idxodd));
% P.YData = repmat(ypatch_new(i, :);

% % Function to update the patch's y-limits
% function updateshadedbounds(P, ax)
%    ypatchnew = repmat( ...
%       [ax.YLim(1); ax.YLim(1); ax.YLim(2); ax.YLim(2); ax.YLim(1)], ...
%       1, size(P.Faces,1));
%    for n = 1:size(P.Faces,1)
%       if isvalid(P(n))
%          P(n).YData = ypatchnew(:,n);
%       end
%    end
% end

% shaded bars

% function shadeboxchartgroups(shadegroups,H)
%
% if shadegroups == false
%    return
% end
%
% % Get the x-coordinate of the bounds of each boxchart group (the left/right-most
% % x-coordinate of each xtick group)
% [~,xleft,xright] = boxchartxdata(H);
%
% % get the y-coordinate of the plot bounds
% [ylow,yhigh] = bounds(ylim);
%
% % to extend the shaded region halfway between each group:
% dx = (xleft(2)-xright(1))/2;
% xleft = xleft - dx;
% xright = xright + dx;
%
% h_patch = gobjects(ceil(numel(xleft))/2,1);
% for n = 1:2:numel(xleft)
%
%    xpatch = [xleft(n) xright(n) xright(n) xleft(n) xleft(n)];
%    ypatch = [ylow ylow yhigh yhigh ylow];
%
%    h_patch(n) = patch('XData',xpatch,'YData',ypatch, ...
%       'FaceColor',[0.5 0.5 0.5], ...
%       'FaceAlpha',0.1, ...
%       'EdgeColor','none');
% end
% ax = gca;
% % Set up a listener for changes in the YLim property
% addlistener(ax, 'YLim', 'PostSet', @(src, evt) updateshadedbounds(h_patch, ax));
%
% % Function to update the line's y-limits
% function updateshadedbounds(h_patch, ax)
%     y_limits = ax.YLim;
%     h_patch.YData = y_limits;
% end
%
% % % Create a sample plot
% % x = 1:10;
% % y = rand(1, 10);
% % plot(x, y, 'o-');
% % hold on;
% %
% % % Get the current axes
% % ax = gca;
% %
% % % Plot a vertical line at x=5
% % x_line = 5;
% % y_limits = ax.YLim;
% % h_line = line([x_line, x_line], y_limits);
% end

% Translation between boxchart and groupsummary
%  boxchart    groupsummary(tbl,...)     groupsummary(A,...)
% ----------  --------------------     -------------------
% xgroupdata   groupvars{1} (varname)  groupvars(:,1) (column vector)
% cgroupdata   groupvars{2} (varname)  groupvars(:,2) (column vector)
% ydata        datavars     (varname)  A              (column vector)
% N/A          method
% N/A          groupbins = actual bin edges or method, for both tbl and A syntax
%
% For boxchart, I think the bin edges are the xvertex coordinates of each box



%% This clarifies the array vs table syntax for calling groupsummary

% % Array format: A and groupvars must have the same number of rows. groupvars can
% % have multiple columns, to create multiple groups
% A = tbl.(ydatavar);
% groupvars = tbl.(cgroupvar);
% [mu, uv] = groupsummary(A, groupvars, "mean");
%
% % This produces the data needed for boxchartcats
% A = tbl.(ydatavar);
% groupvars = [tbl.(cgroupvar) tbl.(xgroupvar)];
% [mu, uv] = groupsummary(A, groupvars, "mean");
% uv = horzcat(uv{:});
%
% % Using XData,YData,CData
% A = double(YData);
% groupvars = [CData XData];
% [mu, uv] = groupsummary(A, groupvars, "mean");
% uv = horzcat(uv{:});
%
% % Table format
% groupvars = {cgroupvar,xgroupvar};
% muTbl = groupsummary(tbl,groupvars, "mean", ydatavar);
%
% NOTE: none of these scatter/gscatter options seem to give what I want, because
% they plot the group means
%
% scatter as of r2021b can plot data from a table
% This is what we want to add to the plot, but the data are stacked vertically
% instead of jittered horizontally which would be needed to plot directly on top
% of boxchart, so probably easiest to use the method to get the boxchart verties
% figure; hold on;
% for n = 1:numel(uX)
%    idx = ismember(muTbl.scenario,uX(n));
%    scatter(muTbl(idx,:),"scenario","mean_FCS",'filled')
% end
%
% Next ones plot all the data, I think it automatically computes unique values,
% because it isn't plotting all the FCS values
%
% figure; scatter(tbl,"scenario","FCS",'filled')
%
% now we can use gscatter
% figure; gscatter(XData,double(YData),CData)


% these do not work
% figure; gscatter(XData,double(YData),{cgroupvar,xgroupvar})
% figure; gscatter(XData,double(YData),[CData XData])

% This was how I originally figured it out, I had to loop over the x vars before
% I figrued out to pass in two grouping vars as in the above examples
% for n = 1:numel(uX)
%    % [mu(n), uv(n)] = groupsummary(qpeaks, FCS, 'mean');
%
%    idx = Tplot.(xgroupvar) == uX(n);
%
%    % this works, using YData and CData
%    % [mu, uv] = groupsummary(A, groupvars, method)
%    % A = tbl.(ydatavar)
%    % [mu(:,n), uv] = groupsummary(double(YData(idx)), CData(idx), 'mean');
%
%    % this works, using array syntax + indexing into the table
%    %mu(:,n) = groupsummary(Tplot.(ydatavar)(idx),Tplot.(cgroupvar)(idx), 'mean');
%
%    % this works, using table syntax, but it returns a table
%    % mu(:,n) = groupsummary(Tplot(idx,:),cgroupvar, 'mean',ydatavar);
% end

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
