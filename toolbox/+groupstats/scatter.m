function varargout = scatter(tbl, xdatavar, ydatavar, cgroupvar, ...
      sgroupvar, opts, props)
   %SCATTER Scatter chart categorical table data.
   %
   %  H = SCATTER(TBL, XDATAVAR, YDATAVAR, CGROUPVAR)
   %  H = SCATTER(TBL, XDATAVAR, YDATAVAR, CGROUPVAR, SGROUPVAR)
   %  [H, L, AX] = SCATTER(_)
   %  [___] = SCATTER(_, Name = Value)
   %
   % Description
   %  H = SCATTER(TBL, XDATAVAR, YDATAVAR, CGROUPVAR) plots TBL.(YDATAVAR)
   %  against TBL.(XDATAVAR), coloring each point by its CGROUPVAR member.
   %
   %  H = SCATTER(_, SGROUPVAR) also varies the marker symbol and size by
   %  SGROUPVAR member, so one chart shows two groupings at once.
   %
   %  [H, L, AX] = SCATTER(_) also returns the legend and the axes. H is a
   %  matrix with one row per color group and one column per size group.
   %
   % Name-value arguments
   %  CGroupMembers    Members of CGROUPVAR to keep. Rows outside them go.
   %  SGroupMembers    Members of SGROUPVAR to keep.
   %  RowSelectVar     Name of a variable used only to select rows.
   %  RowSelectMembers Members of RowSelectVar to keep.
   %  MergeGroupMembers A cell array of string vectors. Each cell names the
   %                   CGROUPVAR members to pool into one color group,
   %                   matching groupstats.histogram. A bare string vector
   %                   is one merge group. The merged group's label joins
   %                   the member names with " and ", and it takes the
   %                   position of its first member in the current category
   %                   order. CGroupMembers reads original names; the
   %                   legend reads post-merge names.
   %  SortGroup        Which grouping the legend order follows, "cgroupvar"
   %                   or "sgroupvar". Inert until SortBy is set.
   %  SortVar          Which data variable the legend order sorts on,
   %                   "xdatavar" or "ydatavar". Inert until SortBy is set.
   %  SortBy           "ascend", "descend", or "none" (default). "none"
   %                   keeps the legend in the group order. The direction
   %                   sorts the legend by the group mean of SortVar within
   %                   the SortGroup groups.
   %  CGroupOrder      A partial order of CGROUPVAR members. Named members
   %                   come first; the rest keep their order. Reorders the
   %                   draw and legend order and overrides SortBy.
   %  SGroupOrder      A partial order of SGROUPVAR members, the same way.
   %  Parent           Axes to plot into. The default is gca, so repeated
   %                   calls reuse the current axes rather than opening a
   %                   figure each time.
   %  Legend           "on" or "off".
   %  LegendString     Replacement legend entries. The default is the group
   %                   member names.
   %  LegendOrientation "vertical" or "horizontal".
   %
   %  Any Line property may also be passed by name. gscatter draws the
   %  points as Line objects, so H holds Line handles and takes Line
   %  properties such as MarkerSize, not Scatter properties such as
   %  SizeData.
   %
   % Example
   %  tbl = readtable('data.csv');
   %  h = groupstats.scatter(tbl, "X", "Y", "Category");
   %  h = groupstats.scatter(tbl, "X", "Y", "Category", "Site", ...
   %     SortVar = "ydatavar", SortBy = "descend", Legend = "off");
   %
   % Positional order
   %  scatter charts two continuous data variables in the built-in
   %  scatter(x, y) order, so xdatavar comes before ydatavar. The cats
   %  charts put ydatavar second because their second axis is a grouping,
   %  not a data variable; there is no xgroupvar here to reconcile to.
   %  cgroupvar is required. This order is deliberate.
   %
   % Dependencies
   %  These come from matfunclib and must be on the path:
   %
   %   distinguishable_colors, defaultcolors, defaultmarkers (libplot)
   %   dealout (functools)
   %
   % See also: boxchartcats, barchartcats, gscatter,
   % groupstats.namelists.sortorder

   % see scatterplot in:
   % fullfile(matlabroot, ...
   % 'toolbox/matlab/specgraph/+matlab/+graphics/+chart/@ScatterHistogramChart')

   % PARSE INPUTS
   arguments
      tbl tabular
      xdatavar (1, 1) string { mustBeNonempty(xdatavar) }
      ydatavar (1, 1) string { mustBeNonempty(ydatavar) }
      cgroupvar (1, 1) string { mustBeNonempty(cgroupvar) }
      sgroupvar string = string.empty()
      opts.CGroupMembers string = string.empty()
      opts.SGroupMembers string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers string = string.empty()
      % Untyped because a cell array of string vectors is one valid shape.
      opts.MergeGroupMembers (:, 1) = string.empty()
      opts.SortGroup (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.SortGroup, ...
         "sortgroupvar")} = "cgroupvar"
      opts.SortVar (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.SortVar, ...
         "sortdatavar")} = "xdatavar"
      opts.SortBy (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.SortBy, ...
         "sortorder")} = "none"
      opts.CGroupOrder (:, 1) string = "none"
      opts.SGroupOrder (:, 1) string = "none"
      opts.Parent (1,1) { mustBeA(opts.Parent, ...
         "matlab.graphics.axis.AbstractAxes") } = gca
      opts.Legend (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Legend, ...
         "legendvisibility")} = "on"
      opts.LegendString (:, 1) string = string.empty()
      opts.LegendOrientation (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.LegendOrientation, ...
         "legendorientation")} = "vertical"
      % gscatter returns Line objects, not Scatter objects, so a Line
      % property is what a caller can set here.
      props.?matlab.graphics.primitive.Line
   end

   % H, L, and the axes are the outputs.
   nargoutchk(0, 3)

   %    ScatterChartDefaults = metaclassDefaults( ...
   %       ScatterChartOpts, ?matlab.graphics.chart.primitive.Scatter);
   %
   %    LegendDefaults = struct();
   %    LegendDefaults = metaclassDefaults( ...
   %       LegendDefaults, ?matlab.graphics.illustration.Legend);

   % cgroupvar = groupvar
   % sgroupvar = withingroupvar

   % for boxchartcats, there is no xdata, there is xgroupdata which defines the
   % unique groups along the xaxis. In barchartcats, that
   % note: sgroupvar would become the stacked bar data

   % import groupstats package
   import groupstats.groupselect
   import groupstats.boxchartxdata
   import groupstats.prepareTableGroups

   %---------------------- validate inputs
   % The size group variable takes the XGroup slot: scatter groups by marker
   % size where the bar and box charts group along the x-axis.
   tbl = prepareTableGroups(tbl, ydatavar, ...
      XDataVar = xdatavar, ...
      XGroupVar = sgroupvar, ...
      XGroupMembers = opts.SGroupMembers, ...
      CGroupVar = cgroupvar, ...
      CGroupMembers = opts.CGroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers);

   % Merge after member filtering, so CGroupMembers reads original names
   % and the legend below reads post-merge names. The shared helper
   % validates the member names and relabels the rows. cgroupvar is a
   % required argument, so no merge-without-group guard is needed here.
   if ~isempty(opts.MergeGroupMembers)
      tbl.(cgroupvar) = mergegroupmembers( ...
         tbl.(cgroupvar), opts.MergeGroupMembers);
   end

   % Assign the data to plot
   XData = tbl.(xdatavar);
   YData = tbl.(ydatavar);
   CData = tbl.(cgroupvar); % this should

   if isempty(sgroupvar)
      SData = true(size(YData));
   else
      SData = tbl.(sgroupvar);
   end

   % Explicit member orders beat SortBy, the same rule the cats charts
   % apply. Reordering the categories reorders the draw and legend order,
   % and the colors and symbols follow the new positions. SData is logical
   % when no sgroupvar was given, so there is nothing to order. The cats
   % charts skip a group-less order the same way, with no error.
   if iscategorical(CData) ...
         && ~(isscalar(opts.CGroupOrder) && opts.CGroupOrder == "none")
      members = string(categories(removecats(CData)));
      idx = reordergroupmembers(opts.CGroupOrder, members, ...
         "scatter", "CGroupOrder");
      CData = reordercats(CData, cellstr(members(idx)));
   end
   if iscategorical(SData) ...
         && ~(isscalar(opts.SGroupOrder) && opts.SGroupOrder == "none")
      members = string(categories(removecats(SData)));
      idx = reordergroupmembers(opts.SGroupOrder, members, ...
         "scatter", "SGroupOrder");
      SData = reordercats(SData, cellstr(members(idx)));
   end

   SGrps = unique(SData);
   CGrps = unique(CData);

   % Make the figure using gscatter
   [H, L] = createGScatterPlot1(XData, YData, CData, SData, CGrps, ...
      SGrps, opts);

   % Apply any Line property the caller named. gscatter takes positional
   % arguments only, so the properties go on the returned objects.
   varargs = namedargs2cell(props);
   if ~isempty(varargs)
      set(H(isgraphics(H)), varargs{:});
   end

   %    % Make the figure using plot
   %    [H, L] = createGScatterPlot2(XData, YData, CData, SData, CGrps, ...
   %       SGrps, opts);

   % replace underscores with spaces

   % Name the axes. createGScatterPlot1 restores the caller's current axes
   % as it returns, so an unqualified call here labels whichever axes was
   % current before, and leaves opts.Parent held.
   xlabel(opts.Parent, strrep(xdatavar, '_', ' '));
   ylabel(opts.Parent, strrep(ydatavar, '_', ' '));

   hold(opts.Parent, 'off')

   % The third output is the axes the chart was drawn into, matching the
   % other charts' (H, L, ax) signature.
   ax = opts.Parent;
   [varargout{1:nargout}] = dealout(H, L, ax);
end

%%
function [H, L] = createGScatterPlot1(XData, YData, CData, SData, CGrps, ...
      SGrps, opts)

   [colors, symbols, sizes] = getPlotDecorators(CGrps);

   H = gobjects(numel(CGrps), numel(SGrps));

   % Make the caller's axes current. gscatter plots into gca and takes no
   % Parent argument, and opening a figure here would ignore Parent and make
   % every call a new window. Put the caller's current figure and axes back
   % afterward, so a later unguarded plot lands where the caller expects.
   fig = ancestor(opts.Parent, 'figure');
   previousfigure = get(groot, 'CurrentFigure');
   previousaxes = get(fig, 'CurrentAxes');
   restore = onCleanup(@() restoreCurrent(previousfigure, fig, previousaxes));

   set(groot, 'CurrentFigure', fig);
   set(fig, 'CurrentAxes', opts.Parent);
   hold(opts.Parent, 'on');
   for m = 1:numel(SGrps)
      I = ismember(SData, SGrps(m));

      h = gscatterOneGroup(XData(I), YData(I), CData(I), colors, ...
         symbols{m}, sizes(m));

      if numel(h) == numel(CGrps)
         H(:, m) = h;
      else
         % gscatter returns one handle per category code, from code 1 up
         % to the highest code the subset holds, with a data-less
         % placeholder line for each unused lower code. Handle k is
         % therefore category k, so align by code. A present-value mask
         % here miscounted whenever an unused code sat below a used one.
         % The remaining rows keep their preallocated placeholders.
         H(1:numel(h), m) = h;
      end
   end

   if numel(SGrps) > 1
      [cleg, sleg] = legendhandles(CGrps, SGrps, colors, symbols, sizes);
   else
      cleg = H;
      sleg = gobjects().empty;
      SGrps = [];
   end

   order = legendOrder(XData, YData, CData, SData, opts);

   if opts.SortGroup == "cgroupvar"
      L = groupLegend(cleg(order), sleg, CGrps(order), SGrps, opts);
      % L = groupLegend(cleg, sleg, CGrps, SGrps);
   elseif opts.SortGroup == "sgroupvar"
      L = groupLegend(cleg, sleg(order), CGrps, SGrps(order), opts);
   end
end

%%
% TODO: createGScatterPlot2 is an unfinished alternative to
% createGScatterPlot1. It builds the legend handles while plotting rather
% than from separate dummy plots. Two things are unfinished: the
% islogicalscalar branch has an empty else, and L is assigned twice so the
% first assignment is discarded. Finish those before switching the call
% site above to it.
%
% function [H, L] = createGScatterPlot2(XData, YData, CData, SData, CGrps, ...
%       SGrps, opts)
%
%    [colors, symbols, sizes] = getPlotDecorators(CGrps);
%
%    figure; hold on;
%
%    % Create two series, one for colors, one for symbols
%    H = gobjects(numel(CGrps), numel(SGrps));
%    cleg = gobjects(numel(CGrps), 1);
%    sleg = gobjects(numel(SGrps), 1);
%
%    % TODO: put the loop back in the if-else so for logicalscalar we dont ned
%    % the dummy patch cleg, we use the default symbol so the lgend only has one
%    % symbol and all the colors, but check the other function to see if celg and
%    % sleg are reversed in order
%
%    % Create scatter plot varying symbols within groups and colors across groups
%    for n = 1:numel(CGrps)
%       % dummy plot for CData legend entries (colors)
%       cleg(n) = patch(nan, nan, colors(n,:), 'EdgeColor', 'none');
%       for m = 1:numel(SGrps)
%          sleg(m) = plotOneMember(XData, YData, CData, SData, CGrps(n), ...
%             SGrps(m), colors(n, :), symbols{m}, sizes(m));
%       end
%    end
%
%    % If there are no Sgrps, call gscatter
%    if islogicalscalar(SGrps)
%       % H = gscatter(XData, YData, CData, colors, [], 30, 'filled');
%       % cleg = H;
%       sleg = gobjects().empty;
%       SGrps = [];
%    else
%
%    end
%    hold off
%
%    order = legendOrder(XData, YData, CData, SData, opts);
%
%    L = legend([cleg(order); sleg], [CGrps(order); SGrps], 'Location', 'eastoutside');
%
%    % This creates one legend
%    L = groupLegend(cleg(order), sleg, CGrps(order), SGrps);
% end

%%
function order = legendOrder(XData, YData, CData, SData, opts)

   % This appears to assume that whatever is assigned to sortdata is numeric or
   % otherwise compatible with a group mean, specifically with "mean", so I
   % added a default dummy order ... but its creating problems

   if opts.SortVar == "ydatavar"
      % order the legend from high to low along the y axis
      sortdata = YData;
   elseif opts.SortVar == "xdatavar"
      % order the legend from low to high along the x axis
      sortdata = XData;
   end

   % Default order (appears it needs to be sortgroups not sortdata)
   % order = 1:numel(unique(sortdata));

   if opts.SortGroup == "cgroupvar"
      % order the legend according to the mean within CData groups
      sortgroup = CData;
   elseif opts.SortGroup == "sgroupvar"
      % order the legend according to the mean within SData groups
      sortgroup = SData;
   end

   % Default order
   order = 1:numel(unique(sortgroup));

   % SortBy "none", the default, keeps the groups in the order they have.
   % An explicit member order on the sorted grouping also wins over
   % SortBy, the same rule the cats charts apply.
   orderedc = ~(isscalar(opts.CGroupOrder) && opts.CGroupOrder == "none");
   ordereds = ~(isscalar(opts.SGroupOrder) && opts.SGroupOrder == "none");
   if opts.SortBy == "none" ...
         || (opts.SortGroup == "cgroupvar" && orderedc) ...
         || (opts.SortGroup == "sgroupvar" && ordereds)
      return
   end

   % Check if sortdata is sortable (numeric or categorical/ordinal)
   issortable = isordinal(sortdata) || isnumeric(sortdata);

   try
      % groupsummary is base MATLAB. grpstats computes the same group mean but
      % needs a Statistics Toolbox license, which left this the only path a
      % caller without that license could take.
      mu = groupsummary(sortdata, sortgroup, "mean");
      [~, order] = sort(mu, opts.SortBy);
   catch
      % A group mean needs numeric or ordinal data. Keep the default order,
      % which is the order unique() returns, when the sort variable is
      % neither.
      %
      % TODO: for ordinal data, order by the category ranking rather than by
      % a mean.
      if ~issortable
         % Nothing else to try.
      end
   end

   %    switch opts.SortVar
   %       case "ydatavar"
   %          % order the legend from high to low along the y axis
   %          if opts.SortGroup == "cgroupvar"
   %             mu = grpstats(YData, CData, 'mean');
   %          elseif opts.SortGroup == "sgroupvar"
   %             mu = grpstats(YData, SData, 'mean');
   %          end
   %       case "xdatavar"
   %          % order the legend from low to high along the x axis
   %          mu = grpstats(XData, CData, 'mean');
   %    end
   %    [~, order] = sort(mu, opts.SortBy);
end

%%
% plotOneMember belongs to createGScatterPlot2 above and is preserved with it.
%
% function h = plotOneMember(XData, YData, CData, SData, CMember, ...
%       SMember, color, symbol, size)
%
%    % h is the dummy plot handle for SData legend entries (symbols)
%    h = plot(nan, nan, 'Marker', symbol, 'MarkerSize', 12, 'LineStyle', ...
%       'none', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'k');
%
%    I = ismember(CData, CMember) & ismember(SData, SMember);
%    p = plot(XData(I), YData(I), 'Marker', symbol, 'MarkerSize', size, ...
%       'LineStyle','none');
%
%    if any(strcmp(symbol, {'x', '+', '*'}))
%       set(p, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', color);
%    else
%       set(p, 'MarkerFaceColor', color, 'MarkerEdgeColor', 'none');
%    end
% end

%%
function h = gscatterOneGroup(XData, YData, CData, colors, symbol, size)

   h = gscatter(XData, YData, CData, colors, symbol, size, 'filled');

   repm = find(~ismember({h.Marker}, {'x', '+', '*'}));
   for n = repm(:)'
      h(n).MarkerEdgeColor = "none";
   end

   legend off

   % % for reference, if not called from a function and instead H(m, :) = gscatter
   % was called in main, then after that would need:
   %    for n = 1:nC
   %       for m = 1:nS
   %          if ismember(H(m, n).Marker, {'x', '+', '*'})
   %             continue
   %          end
   %          H(m, n).MarkerEdgeColor = "none";
   %       end
   %    end
end

%%
function restoreCurrent(previousfigure, fig, previousaxes)
   %RESTORECURRENT Put the caller's current figure and axes back.
   %
   % Called from an onCleanup object, so it runs whether the plotting
   % succeeded or threw. A figure or axes the caller closed meanwhile is no
   % longer valid, so check before setting either one.

   if isgraphics(fig) && isgraphics(previousaxes)
      set(fig, 'CurrentAxes', previousaxes);
   end
   if isgraphics(previousfigure)
      set(groot, 'CurrentFigure', previousfigure);
   end
end

%%
function [colors, symbols, sizes] = getPlotDecorators(CGrps)

   try
      colors = distinguishable_colors(numel(CGrps));
   catch
      colors = defaultcolors();
   end
   [symbols, sizes] = defaultmarkers();
   %symbols = symbols(~ismember(symbols, {'.', '|'}));
end

%%
function [cleg, sleg] = legendhandles(CGrps, SGrps, colors, symbols, sizes)

   % Create dummy plots for CData legend entries (colors) and SData legend
   % entries (symbols)

   cleg = gobjects(numel(CGrps), 1);
   sleg = gobjects(numel(SGrps), 1);

   hold on;
   for n = 1:numel(CGrps)
      cleg(n) = patch(nan, nan, colors(n, :), 'EdgeColor', 'none');
      for m = 1:numel(SGrps)
         sleg(m) = plot(nan, nan, 'Marker', symbols{m}, 'MarkerSize', sizes(m), ...
            'LineStyle', 'none', 'MarkerFaceColor', 'none', ...
            'MarkerEdgeColor', 'k');
      end
   end
   hold off;
end

%%
function L = groupLegend(cleg, sleg, CGrps, SGrps, opts)

   % Return an empty handle rather than no value, so a caller that asks for
   % the legend output gets something it can test.
   if opts.Legend == "off"
      L = gobjects(0);
      return
   end

   % LegendString replaces the group member names. It must cover every entry,
   % so a short list falls back to the names rather than mislabeling them.
   entries = [string(CGrps(:)); string(SGrps(:))];
   if numel(opts.LegendString) == numel(entries)
      entries = opts.LegendString(:);
   end

   % This creates one legend
   L = legend(opts.Parent, [cleg(:); sleg(:)], entries, ...
      'Location', 'eastoutside', ...
      'Orientation', opts.LegendOrientation);

   % % This creates two legends
   % ax1 = gca;
   % ax2 = axes('position', get(gca, 'position'), 'visible', 'off');
   % leg1 = legend(ax1, cleg, CGrps, 'Location','northoutside');
   % leg2 = legend(ax2, sleg, SGrps, 'Location','EastOutside');
   % title(leg1, cgroupvar);
   % title(leg2, sgroupvar);

   % % This creates one legend for either C or S groups
   % legend(cleg, CGrps, 'location', 'northoutside', 'numcolumns', 2, 'fontsize', 10)
   % legend(sleg, SGrps, 'location', 'northoutside', 'numcolumns', 2, 'fontsize', 10)

   %    % Add the legend
   %    withwarnoff('MATLAB:legend:IgnoringExtraEntries');
   %    legendtxt = opts.LegendString;
   %    if isempty(legendtxt)
   %       legendtxt = CGrps;
   %    end
   %    try
   %       legend(legendtxt, ...
   %          'Orientation', 'horizontal', ...
   %          'Location', 'northoutside', ...
   %          'AutoUpdate', 'off', ...
   %          'numcolumns', numel(legendtxt) );
   %    catch
   %    end
end

%% LICENSE

% BSD 3-Clause License
%
% Copyright (c) 2023, Matt Cooper (mgcooper) All rights reserved.
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
