function varargout = scatter(tbl, xdatavar, ydatavar, cgroupvar, ...
      sgroupvar, Opts, Props)
   %SCATTER scatter chart categorical table data
   %
   %
   % See also: boxchartcats, barchartcats

   % see scatterplot in:
   % fullfile(matlabroot, ...
   % 'toolbox/matlab/specgraph/+matlab/+graphics/+chart/@ScatterHistogramChart')

   % PARSE INPUTS
   arguments
      tbl table
      xdatavar (1, 1) string { mustBeNonempty(xdatavar) }
      ydatavar (1, 1) string { mustBeNonempty(ydatavar) }
      cgroupvar (1, 1) string { mustBeNonempty(cgroupvar) }
      sgroupvar string = string.empty()
      Opts.CGroupMembers string = groupmembers(tbl, cgroupvar)
      Opts.SGroupMembers string = groupmembers(tbl, sgroupvar)
      Opts.RowSelectVar string = string.empty()
      Opts.RowSelectMembers string = string.empty()
      Opts.SortGroup (1, 1) string {mustBeMember(Opts.SortGroup, ...
         ["cgroupvar", "sgroupvar"])} = "cgroupvar"
      Opts.SortVar (1, 1) string {mustBeMember(Opts.SortVar, ...
         ["xdatavar", "ydatavar"])} = "xdatavar"
      Opts.SortBy (1, 1) string {mustBeMember(Opts.SortBy, ...
         ["ascend", "descend"])} = "ascend"
      %       Opts.Parent (1,1) { mustBeA(Opts.Parent, ...
      %          "matlab.graphics.axis.AbstractAxes") } = gca
      Opts.Legend (1, 1) string = "on"
      Opts.LegendString (:, 1) string = string.empty()
      Opts.LegendOrientation (1, 1) string = "vertical"
      Props.?matlab.graphics.chart.primitive.Scatter
   end

   if Opts.SortVar == "ydatavar"
      Opts.SortBy = "descend";
   end

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
   tbl = prepareTableGroups(tbl, ydatavar, xdatavar, sgroupvar, cgroupvar, ...
      Opts.SGroupMembers, Opts.CGroupMembers, ...
      Opts.RowSelectVar, Opts.RowSelectMembers);

   % Assign the data to plot
   XData = tbl.(xdatavar);
   YData = tbl.(ydatavar);
   CData = tbl.(cgroupvar); % this should

   if isempty(sgroupvar)
      SData = true(size(YData));
   else
      SData = tbl.(sgroupvar);
   end

   SGrps = unique(SData);
   CGrps = unique(CData);

   % Make the figure using gscatter
   [H, L] = createGScatterPlot1(XData, YData, CData, SData, CGrps, ...
      SGrps, Opts);

   %    % Make the figure using plot
   %    [H, L] = createGScatterPlot2(XData, YData, CData, SData, CGrps, ...
   %       SGrps, Opts);

   % replace underscores with spaces

   xlabel(strrep(xdatavar, '_', ' '));
   ylabel(strrep(ydatavar, '_', ' '));

   hold off
   switch nargout
      case 1
         varargout{1} = H;
      case 2
         varargout{1} = H;
         varargout{2} = L;
   end
end

%%
function [H, L] = createGScatterPlot1(XData, YData, CData, SData, CGrps, ...
      SGrps, Opts)

   [colors, symbols, sizes] = getPlotDecorators(CGrps);

   H = gobjects(numel(CGrps), numel(SGrps));

   figure; hold on;
   for m = 1:numel(SGrps)
      I = ismember(SData, SGrps(m));

      try
         H(:, m) = gscatterOneGroup(XData(I), YData(I), CData(I), colors, ...
            symbols{m}, sizes(m));
      catch
         h = gscatterOneGroup(XData(I), YData(I), CData(I), colors, ...
            symbols{m}, sizes(m));
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

   order = legendOrder(XData, YData, CData, SData, Opts);

   if Opts.SortGroup == "cgroupvar"
      L = groupLegend(cleg(order), sleg, CGrps(order), SGrps);
      % L = groupLegend(cleg, sleg, CGrps, SGrps);
   elseif Opts.SortGroup == "sgroupvar"
      L = groupLegend(cleg, sleg(order), CGrps, SGrps(order));
   end
end

%%
function [H, L] = createGScatterPlot2(XData, YData, CData, SData, CGrps, ...
      SGrps, Opts)

   [colors, symbols, sizes] = getPlotDecorators(CGrps);

   figure; hold on;

   % Create two series, one for colors, one for symbols
   H = gobjects(numel(CGrps), numel(SGrps));
   cleg = gobjects(numel(CGrps), 1);
   sleg = gobjects(numel(SGrps), 1);

   % TODO: put the loop back in the if-else so for logicalscalar we dont ned
   % the dummy patch cleg, we use the default symbol so the lgend only has one
   % symbol and all the colors, but check the other function to see if celg and
   % sleg are reversed in order

   % Create scatter plot varying symbols within groups and colors across groups
   for n = 1:numel(CGrps)
      % dummy plot for CData legend entries (colors)
      cleg(n) = patch(nan, nan, colors(n,:), 'EdgeColor', 'none');
      for m = 1:numel(SGrps)
         sleg(m) = plotOneMember(XData, YData, CData, SData, CGrps(n), ...
            SGrps(m), colors(n, :), symbols{m}, sizes(m));
      end
   end

   % If there are no Sgrps, call gscatter
   if islogicalscalar(SGrps)
      % H = gscatter(XData, YData, CData, colors, [], 30, 'filled');
      % cleg = H;
      sleg = gobjects().empty;
      SGrps = [];
   else

   end
   hold off

   order = legendOrder(XData, YData, CData, SData, Opts);

   L = legend([cleg(order); sleg], [CGrps(order); SGrps], 'Location', 'eastoutside');

   % This creates one legend
   L = groupLegend(cleg(order), sleg, CGrps(order), SGrps);
end

%%
function order = legendOrder(XData, YData, CData, SData, Opts)

   % This appears to assume that whatever is assigned to sortdata is numeric or
   % otherwise compatible with grpstats(sortdata, sortgroup, 'mean');
   % specifically with "mean", so I added a default dummy order ... but its
   % creating problems

   if Opts.SortVar == "ydatavar"
      % order the legend from high to low along the y axis
      sortdata = YData;
   elseif Opts.SortVar == "xdatavar"
      % order the legend from low to high along the x axis
      sortdata = XData;
   end

   % Default order (appears it needs to be sortgroups not sortdata)
   % order = 1:numel(unique(sortdata));

   if Opts.SortGroup == "cgroupvar"
      % order the legend according to the mean within CData groups
      sortgroup = CData;
   elseif Opts.SortGroup == "sgroupvar"
      % order the legend according to the mean within SData groups
      sortgroup = SData;
   end

   % Default order
   order = 1:numel(unique(sortgroup));

   % Check if sortdata is sortable (numeric or categorical/ordinal)
   issortable = isordinal(sortdata) || isnumeric(sortdata);

   try
      mu = grpstats(sortdata, sortgroup, 'mean');
      [~, order] = sort(mu, Opts.SortBy);
   catch e
      switch e.identifier
         case 'MATLAB:license:checkouterror'

            members = unique(sortgroup);
            mu = nan(numel(members), 1);
            for m = members(:)'
               mu(m) = mean(sortdata(ismember(sortgroup, m)));
            end
            [~, order] = sort(mu, Opts.SortBy);

         case 'stats:grpstats:FunctionErrorGroup'
            % probably not sortable data
            if issortable
               % do something with the ordinality, fix later
            else

            end
            % For now, return the default order

         otherwise
            rethrow(e)
      end
   end

   %    switch Opts.SortVar
   %       case "ydatavar"
   %          % order the legend from high to low along the y axis
   %          if Opts.SortGroup == "cgroupvar"
   %             mu = grpstats(YData, CData, 'mean');
   %          elseif Opts.SortGroup == "sgroupvar"
   %             mu = grpstats(YData, SData, 'mean');
   %          end
   %       case "xdatavar"
   %          % order the legend from low to high along the x axis
   %          mu = grpstats(XData, CData, 'mean');
   %    end
   %    [~, order] = sort(mu, Opts.SortBy);
end

%%
function h = plotOneMember(XData, YData, CData, SData, CMember, ...
      SMember, color, symbol, size)

   % h is the dummy plot handle for SData legend entries (symbols)
   h = plot(nan, nan, 'Marker', symbol, 'MarkerSize', 12, 'LineStyle', ...
      'none', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'k');

   I = ismember(CData, CMember) & ismember(SData, SMember);
   p = plot(XData(I), YData(I), 'Marker', symbol, 'MarkerSize', size, ...
      'LineStyle','none');

   if any(strcmp(symbol, {'x', '+', '*'}))
      set(p, 'MarkerFaceColor', 'none', 'MarkerEdgeColor', color);
   else
      set(p, 'MarkerFaceColor', color, 'MarkerEdgeColor', 'none');
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
function L = groupLegend(cleg, sleg, CGrps, SGrps, Opts)

   % This creates one legend
   L = legend([cleg; sleg], [CGrps; SGrps], 'Location', 'eastoutside');

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
   %    legendtxt = Opts.LegendString;
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
