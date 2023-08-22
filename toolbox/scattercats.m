function varargout = scattercats(T, xdatavar, ydatavar, xgroupvar, ...
      cgroupvar, CustomOpts, ScatterChartOpts)
   %SCATTERCATS scatter chart categorical table data
   %
   %
   % See also: boxchartcats, barchartcats

   % PARSE INPUTS
   arguments
      T table
      xdatavar (1, 1) string { mustBeNonempty(xdatavar) }
      ydatavar (1, 1) string { mustBeNonempty(ydatavar) }
      xgroupvar (1, 1) string { mustBeNonempty(xgroupvar) }
      cgroupvar string = string.empty()
      CustomOpts.XGroupMembers string = groupmembers(T, xgroupvar)
      CustomOpts.CGroupMembers string = groupmembers(T, cgroupvar)
      CustomOpts.RowSelectVar string = string.empty()
      CustomOpts.RowSelectMembers string = string.empty()
      CustomOpts.SortVar (1, 1) string {mustBeMember(CustomOpts.SortVar, ...
         ["xdatavar", "ydatavar"])} = "xdatavar"
      CustomOpts.SortBy (1, 1) string {mustBeMember(CustomOpts.SortBy, ...
         ["ascend", "descend"])} = 'ascend'
      CustomOpts.Legend (1, 1) string = "on"
      CustomOpts.LegendText (:, 1) string = string.empty()
      ScatterChartOpts.?matlab.graphics.chart.primitive.Scatter
      % LegendOpts.?matlab.graphics.illustration.Legend
   end

   ScatterChartDefaults = metaclassDefaults( ...
      ScatterChartOpts, ?matlab.graphics.chart.primitive.Scatter);

   LegendDefaults = struct();
   LegendDefaults = metaclassDefaults( ...
      LegendDefaults, ?matlab.graphics.illustration.Legend);

   % cgroupvar = groupvar
   % xgroupvar = withingroupvar

   % for boxchartcats, there is no xdata, there is xgroupdata which defines the
   % unique groups along the xaxis. In barchartcats, that
   % note: xgroupvar would become the stacked bar data

   % import groupstats package
   import gs.groupselect
   import gs.boxchartxdata
   import gs.prepareTableGroups

   %---------------------- validate inputs
   xgroupuse = CustomOpts.XGroupMembers;
   cgroupuse = CustomOpts.CGroupMembers;
   selectvar = CustomOpts.RowSelectVar;
   selectuse = CustomOpts.RowSelectMembers;
   % groupselect = CustomOpts.GroupSelect;

   T = prepareTableGroups(T, ydatavar, xdatavar, xgroupvar, cgroupvar, ...
      xgroupuse, cgroupuse, selectvar, selectuse);

   % Assign the data to plot
   XData = T.(xdatavar);
   YData = T.(ydatavar);
   try
      SData = T.(xgroupvar);
   catch
      SData = true(size(YData));
   end
   try
      CData = T.(cgroupvar);
   catch
      CData = true(size(YData));
   end
   SGrps = unique(SData);
   CGrps = unique(CData);

   % Make the figure using gscatter
%    [H, L] = createGScatterPlot1(XData, YData, CData, SData, CGrps, SGrps);

   % Make the figure using plot
   [H, L] = createGScatterPlot2(XData, YData, CData, SData, CGrps, SGrps);
   
   % replace underscores with spaces
   
   xlabel(strrep(xdatavar, '_', ' '));
   ylabel(strrep(ydatavar, '_', ' '));
   
   switch nargout
      case 1
         varargout{1} = H;
      case 2
         varargout{1} = H;
         varargout{2} = L;
   end
end

%%
function [H, L] = createGScatterPlot1(XData, YData, CData, SData, CGrps, SGrps)

   [colors, symbols, sizes] = getPlotDecorators(CGrps);

   H = gobjects(numel(SGrps), numel(CGrps));
   
   figure; hold on;
   for m = 1:numel(SGrps)
      I = ismember(SData, SGrps(m));
      H(m, :) = gscatterOneGroup(XData(I), YData(I), CData(I), colors, ...
         symbols{m}, sizes(m));
   end
   [cleg, sleg] = legendhandles(CGrps, SGrps, colors, symbols, sizes);
   
   L = groupLegend(cleg, sleg, CGrps, SGrps);

end

%%
function [H, L] = createGScatterPlot2(XData, YData, CData, SData, CGrps, SGrps)

   [colors, symbols, sizes] = getPlotDecorators(CGrps);
   
   H = gobjects(numel(SGrps), numel(CGrps));
   
   cleg = gobjects(numel(CGrps), 1); 
   sleg = gobjects(numel(SGrps), 1);
   
   % Create scatter plot varying symbols within groups and colors across groups
   figure; hold on;
   for n = 1:numel(CGrps)
      % dummy plot for CData legend entries (colors)
      cleg(n) = patch(nan, nan, colors(n,:), 'EdgeColor', 'none');
      for m = 1:numel(SGrps)
         sleg(m) = plotOneMember(XData, YData, CData, SData, CGrps(n), ...
            SGrps(m), colors(n, :), symbols{m}, sizes(m));
      end
   end
   hold off
   
   % order the legend from high to low along the y axis
   mu = grpstats(YData, SData, 'mean');
   [~, order] = sort(mu, 'descend');
   
   % order the legend from low to high along the x axis
   mu = grpstats(XData, SData, 'mean');
   [~, order] = sort(mu, 'ascend');

   % This creates one legend
   L = groupLegend(cleg, sleg(order), CGrps, SGrps(order));
end

%%
function h = plotOneMember(XData, YData, CData, SData, CMember, ...
      SMember, color, symbol, size)

   % h is the dummy plot handle for SData legend entries (symbols)
   h = plot(nan, nan, 'Marker', symbol, 'MarkerSize', 12, 'LineStyle', ...
      'none', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'k');

   I = ismember(CData, CMember) & ismember(SData, SMember);
   p = plot(XData(I), YData(I), 'Marker', symbol, 'MarkerSize', size);

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
function L = groupLegend(cleg, sleg, CGrps, SGrps, CustomOpts)

   % This creates one legend
   L = legend([cleg; sleg], [CGrps; SGrps], 'Location', 'eastoutside');

   % % This creates two legends
   % ax1 = gca;
   % ax2 = axes('position', get(gca, 'position'), 'visible', 'off');
   % leg1 = legend(ax1, cleg, CGrps, 'Location','northoutside');
   % leg2 = legend(ax2, sleg, SGrps, 'Location','EastOutside');
   % title(leg1, cgroupvar);
   % title(leg2, xgroupvar);

   % % This creates one legend for either C or S groups
   % legend(cleg, CGrps, 'location', 'northoutside', 'numcolumns', 2, 'fontsize', 10)
   % legend(sleg, SGrps, 'location', 'northoutside', 'numcolumns', 2, 'fontsize', 10)

%    % Add the legend
%    withwarnoff('MATLAB:legend:IgnoringExtraEntries');
%    legendtxt = CustomOpts.LegendText;
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
% Copyright (c) YYYY, Matt Cooper (mgcooper) All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright
% notice,
%    this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.