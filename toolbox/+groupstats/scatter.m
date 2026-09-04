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
   CData = tbl.(cgroupvar);

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
   elseif opts.SortGroup == "sgroupvar"
      L = groupLegend(cleg, sleg(order), CGrps, SGrps(order), opts);
   end
end

%%
function order = legendOrder(XData, YData, CData, SData, opts)

   if opts.SortVar == "ydatavar"
      % order the legend from high to low along the y axis
      sortdata = YData;
   elseif opts.SortVar == "xdatavar"
      % order the legend from low to high along the x axis
      sortdata = XData;
   end

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
   end
end

%%
function h = gscatterOneGroup(XData, YData, CData, colors, symbol, size)

   h = gscatter(XData, YData, CData, colors, symbol, size, 'filled');

   repm = find(~ismember({h.Marker}, {'x', '+', '*'}));
   for n = repm(:)'
      h(n).MarkerEdgeColor = "none";
   end

   legend off
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

   % One combined legend holds the color entries then the symbol entries.
   L = legend(opts.Parent, [cleg(:); sleg(:)], entries, ...
      'Location', 'eastoutside', ...
      'Orientation', opts.LegendOrientation);
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
