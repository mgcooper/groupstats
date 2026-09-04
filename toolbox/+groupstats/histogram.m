function varargout = histogram(tbl, datavar, opts, props)
   %HISTOGRAM Histogram grouped data.
   %
   % h = groupstats.histogram(data)
   % h = groupstats.histogram(data, categories)
   % h = groupstats.histogram(tbl, datavar)
   % h = groupstats.histogram(tbl, categoricalvar)
   % h = groupstats.histogram(_, GroupVar = groupvar)
   % h = groupstats.histogram(_, GroupMembers = members)
   % h = groupstats.histogram(_, RowSelectVar = varname)
   % h = groupstats.histogram(_, RowSelectMembers = members)
   % h = groupstats.histogram(_, MergeGroupMembers = members)
   % h = groupstats.histogram(_, GroupOrder = members)
   % h = groupstats.histogram(_, SortBy = order)
   % h = groupstats.histogram(_, Parent = axes_handle)
   % h = groupstats.histogram(_, Legend = "on" or "off")
   % h = groupstats.histogram(_, LegendString = legend_text)
   % h = groupstats.histogram(_, LegendOrientation = orientation)
   % [h, l, ax] = groupstats.histogram(_)
   %
   % The Name-Value pairs can be any accepted by HISTOGRAM
   % h = groupstats.histogram(_, NumBins = numbins)
   % h = groupstats.histogram(_, BinEdges = edges)
   %
   % Description
   %
   % This function creates a histogram of tabular data grouped by categories.
   %
   % Syntax
   %
   % h = groupstats.histogram(tbl, datavar) creates a histogram of the data in
   % column tbl.(datavar). If tbl.(datavar) is a vector, then HISTOGRAM creates
   % one histogram. In this mode, GROUPSTATS.HISTOGRAM behaves exactly like
   % built-in HISTOGRAM(ydata) where ydata = tbl.(datavar).
   %
   % h = groupstats.histogram(tbl, datavar, GroupVar = groupvar) groups the
   % data in the vector tbl.(datavar) according to the unique values of
   % tbl.(groupvar) and plots each group of data as separate (possibly
   % overlapping) histograms. One Histogram object comes back per group.
   %
   % h = groupstats.histogram(_, GroupMembers = members) plots one histogram
   % for each group member specified by MEMBERS. Use this option to
   % selectively plot specific groups without first subsetting the input TBL.
   %
   % h = groupstats.histogram(_, MergeGroupMembers = members) pools the named
   % members into one group. MEMBERS is a cell array, one cell per merge
   % group; a bare string vector is one merge group. The merged group's
   % label joins the member names with " and ", and it takes the position
   % of its first member in the current category order. In categorical mode
   % the named categories of the data variable pool into one bar.
   %
   % [h, l, ax] = groupstats.histogram(_) also returns the legend and the
   % axes. In categorical mode there is no legend, so l is an empty
   % graphics placeholder.
   %
   % h = groupstats.histogram(_, Name, Value) specifies additional chart options
   % using one or more name-value pair arguments. For a list of properties, see
   % Histogram Properties. In categorical mode, bin properties such as
   % NumBins or BinEdges do not apply.
   %
   % Input Arguments
   %
   % tbl: A table containing the data to be plotted.
   %
   % datavar: The name of the variable in the table tbl that contains the data
   % values for the histogram.
   %
   % GroupVar: The name of the categorical variable in the table tbl used to
   % define groups.
   %
   % GroupMembers: The categories of GroupVar to keep.
   %
   % Parent: The axes to plot into. The default is gca.
   %
   % GroupOrder: A partial order of the group members. Named members come
   % first; the rest keep their order. It overrides SortBy. After a merge, name
   % the merged labels.
   %
   % SortBy: "ascend", "descend", or "none" (default). Orders the groups
   % by the group mean of the data variable, or by the category counts in
   % categorical mode. "none" keeps the order the groups already have.
   %
   % Legend: "on" or "off". The default is "on", except with no GroupVar and
   % no LegendString, where the built-in shows no legend either. That
   % unset-by-default state is deliberate: an ungrouped histogram has one
   % series and needs no legend.
   %
   % data, categories: the call shape the built-in takes. HISTOGRAM(data) and
   % HISTOGRAM(data, categories) work here, so a caller does not have to
   % build a table for the simple case.
   %
   % Output Arguments
   %
   % H: A handle to the created histogram, one per group.
   % L: The legend, or an empty graphics placeholder when there is none.
   % AX: The axes the chart was drawn into.
   %
   % Example
   %
   % Plot a histogram of the Value variable, grouped by CategoryX, for three
   % of its categories.
   %
   % tbl = readtable('data.csv');
   % h = groupstats.histogram(tbl, "Value", GroupVar = "CategoryX", ...
   %    GroupMembers = ["Cat1", "Cat2", "Cat3"]);
   %
   % Plot one bar per category of a categorical variable. The variable stays
   % categorical, so the bars are discrete rather than binned.
   %
   % h = groupstats.histogram(tbl, "CategoryX");
   %
   % Matt Cooper, https://github.com/mgcooper
   %
   % See also reordergroups, reordercats, barchart,
   % groupstats.namelists.legendorientation

   arguments
      tbl
      datavar = string.empty()
      opts.GroupVar string = string.empty()
      opts.GroupMembers string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers string = string.empty()
      opts.Parent (1,1) { mustBeA(opts.Parent, ...
         "matlab.graphics.axis.AbstractAxes") } = gca
      opts.MergeGroupMembers (:,1) = string.empty()
      opts.GroupOrder (:, 1) string = "none"
      opts.SortBy (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.SortBy, ...
         "sortorder")} = "none"
      opts.Legend (:, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Legend, ...
         "legendvisibility")} = string.empty()
      opts.LegendString (:, 1) string = string.empty()
      opts.LegendOrientation (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.LegendOrientation, ...
         "legendorientation")} = "vertical"
      props.?matlab.graphics.chart.primitive.Histogram
   end

   % Import groupstats functions.
   import groupstats.groupselect
   import groupstats.prepareTableGroups

   % Accept the built-in's call shape as well as a table and a variable
   % name: histogram(Info.month) and histogram(Info.month, members). Wrap the
   % array in a one-variable table, and read the second argument as the
   % categories to keep, which is what the built-in does with it.
   if ~istabular(tbl)
      [tbl, datavar, opts] = wrapArrayInput(tbl, datavar, opts);
   end

   mustBeNonempty(datavar)
   datavar = string(datavar);

   % H, L, and the axes are the outputs.
   nargoutchk(0, 3)

   % A categorical data variable with no GroupVar is the categorical
   % histogram, where GroupMembers names the categories to keep. Anywhere
   % else the pair needs both, and prepareTableGroups would report it as
   % XGroupVar and XGroupMembers, which name nothing documented here.
   if ~iscategorical(tbl.(datavar)) && isempty(opts.GroupVar) ...
         && ~isempty(opts.GroupMembers)
      error('groupstats:histogram:membersWithoutGroupVar', ...
         ['GroupMembers was given without GroupVar. Name the group ' ...
         'variable too, or leave both out.'])
   end

   % Merging pools members of the group variable, so without one there is
   % nothing to pool, and the request would have no effect. The categorical
   % histogram is the exception: its data variable is the group variable.
   if ~iscategorical(tbl.(datavar)) && isempty(opts.GroupVar) ...
         && ~isempty(opts.MergeGroupMembers)
      error('groupstats:histogram:mergeWithoutGroupVar', ...
         ['MergeGroupMembers was given without GroupVar. Name the group ' ...
         'variable whose members are pooled.'])
   end

   props = namedargs2cell(props);

   % A categorical data variable with no GroupVar selects categorical mode.
   makeCategoricalHistogram = iscategorical(tbl.(datavar)) && ...
      isempty(opts.GroupVar);

   if makeCategoricalHistogram
      % Equivalent to GroupVar=datavar with GroupMembers
      opts.GroupVar = datavar;
   end

   % Prepare input data.
   tbl = prepareTableGroups(tbl, datavar, ...
      XGroupVar = opts.GroupVar, ...
      XGroupMembers = opts.GroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers, ...
      ConvertDataVar = ~makeCategoricalHistogram);

   % The legend covers every group, so L must exist on both branches.
   L = gobjects(0);

   % Create a categorical histogram
   if makeCategoricalHistogram
      % prepareTableGroups removes the rows that are not in GroupMembers.
      % Relabeling the data variable pools any merged categories into one
      % bar, so a merge works on this call shape too. Then all that's
      % needed is a call to histogram.
      if ~isempty(opts.MergeGroupMembers)
         tbl.(datavar) = mergegroupmembers( ...
            tbl.(datavar), opts.MergeGroupMembers);
      end

      % Order the categories: an explicit GroupOrder first, otherwise
      % SortBy orders them by their counts.
      tbl.(datavar) = orderGroups(tbl.(datavar), opts.GroupOrder, ...
         opts.SortBy, []);

      H = histogram(tbl.(datavar), props{:}, 'Parent', opts.Parent);
   else

      % With no GroupVar there is one group holding every row, which is
      % what histogram(x) means. The chart family does the same.
      if isempty(opts.GroupVar)
         XData = true(height(tbl), 1);

         % One group needs no legend, and the built-in shows none. A caller
         % that named a LegendString, or asked for one outright, wants one.
         if isempty(opts.Legend) && isempty(opts.LegendString)
            opts.Legend = "off";
         end
      else
         XData = tbl.(opts.GroupVar);
      end

      % Assign the data to plot
      YData = tbl.(datavar);

      % Custom group merging. The shared helper validates the member names
      % and relabels the rows, so every chart merges the same way.
      if ~isempty(opts.MergeGroupMembers)
         XData = mergegroupmembers(XData, opts.MergeGroupMembers);
      end

      % Order the groups after any merge, so GroupOrder and SortBy read
      % post-merge names, and before the legend default below reads the
      % order. SortBy orders the groups by the group mean of the data.
      % With no GroupVar, XData is logical and there is nothing to order.
      if iscategorical(XData)
         XData = orderGroups(XData, opts.GroupOrder, opts.SortBy, YData);
      end

      % Set the default legend string to the group members, after any merge,
      % because merging renames the groups. createHistogram plots one object
      % per unique(XData) member in that order, and legend assigns entries to
      % objects in creation order, so read the entries from the same call and
      % a merged group's label lands on its own bars. A caller who named
      % LegendString keeps it.
      if ~isempty(opts.GroupVar) && isempty(opts.LegendString)
         opts.LegendString = string(unique(XData));
      end

      % Create the figure
      H = createHistogram(XData, YData, opts, props);
      L = createLegend(opts);
   end

   formatHistogram(H, opts.Parent)

   % The third output is the axes the chart was drawn into, matching the
   % other charts' (H, L, ax) signature.
   ax = opts.Parent;
   [varargout{1:nargout}] = dealout(H, L, ax);
end

%% Create the histogram
function H = createHistogram(XData, YData, opts, props)
   groupMembers = unique(XData);

   % An empty data vector has no group members, so the loop below would draw
   % nothing and return an empty placeholder. The built-in histogram returns
   % a Histogram object for empty input, and this function takes the same
   % call, so draw the one empty chart.
   if isempty(groupMembers)
      H = histogram(YData, props{:}, 'Parent', opts.Parent);
      return
   end

   % One Histogram object per group, all returned. Overwriting H each pass
   % returns the last group's handle while the legend covers every group.
   H = gobjects(numel(groupMembers), 1);

   % hold on would target gca. With a Parent that is not the current axes,
   % that leaves the target on NextPlot="replace", so each group deletes the
   % one before it and H(1) becomes an invalid handle.
   washeld = ishold(opts.Parent);
   hold(opts.Parent, "on")

   for n = 1:numel(groupMembers)
      ingroup = XData == groupMembers(n);
      H(n) = histogram(YData(ingroup), props{:}, 'Parent', opts.Parent);
   end

   if ~washeld
      hold(opts.Parent, "off")
   end
end

%% Format the plot
function formatHistogram(H, parent)
   % Every Histogram in H carries the same Normalization, so read the first.
   % Empty data means no Histogram to read a Normalization from. The
   % built-in accepts empty data, so this must not error either.
   if isempty(H)
      return
   end

   ylabel(parent, H(1).Normalization);
   set(parent, "XMinorTick", "on", "Box", "on");
end

%% Create the legend
function L = createLegend(opts)
   L = gobjects(0);

   % An unset Legend means the default, which is on.
   if isempty(opts.Legend)
      opts.Legend = "on";
   end

   % Legend="off" is how the other three charts turn it off.
   if opts.Legend == "off"
      return
   end

   try
      withwarnoff('MATLAB:legend:IgnoringExtraEntries');
      L = legend(opts.Parent, opts.LegendString, ...
         'Location', 'northwest', ...
         'AutoUpdate', 'off', ...
         'Orientation', opts.LegendOrientation, ...
         'FontSize', 12);
   catch
   end
end

%% Order groups
function column = orderGroups(column, grouporder, sortby, metric)
   %ORDERGROUPS Order the group categories by an explicit order or SortBy.
   %
   % An explicit GroupOrder overrides SortBy, the same rule the cats charts
   % apply. GroupOrder is a partial order: named members come first, and
   % the rest keep their order. SortBy orders the categories by the group
   % mean of METRIC, or by the group counts when METRIC is empty, which is
   % the categorical histogram's case.

   members = string(categories(removecats(column)));

   if ~(isscalar(grouporder) && grouporder == "none")
      idx = reordergroupmembers(grouporder, members, ...
         "histogram", "GroupOrder");
      column = reordercats(column, cellstr(members(idx)));
      return
   end

   if sortby == "none"
      return
   end

   % countcats and groupsummary both return one value per category in
   % category order, so the sorted indices pair with members. The metric
   % keeps its own type: a mean of datetime or duration data is defined,
   % and double() is not.
   if isempty(metric)
      stat = countcats(removecats(column));
   else
      stat = groupsummary(metric, removecats(column), "mean");
   end
   [~, idx] = sort(stat, sortby);
   column = reordercats(column, cellstr(members(idx)));
end

%% LICENSE
%
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

function [tbl, datavar, opts] = wrapArrayInput(data, categories, opts)
   %WRAPARRAYINPUT Read the built-in's call shape into this function's shape.
   %
   % histogram(x) and histogram(x, categories) name no table, so build one.
   % The second argument is the category list the built-in keeps, which is
   % GroupMembers here.

   datavar = "Data";
   tbl = table(data(:), 'VariableNames', {char(datavar)});

   if isempty(categories)
      return
   end

   % The built-in reads a numeric second argument as a bin count or bin
   % edges, not as categories. Say so, rather than treat the number as a
   % category name and fail somewhere further in.
   if isnumeric(categories)
      error('groupstats:histogram:numericBinsNotSupported', ...
         ['A numeric second argument means bin counts or bin edges to the ' ...
         'built-in. Pass NumBins or BinEdges by name instead.'])
   end

   if ~isempty(opts.GroupMembers)
      error('groupstats:histogram:categoriesGivenTwice', ...
         ['Categories were given positionally and as GroupMembers. ' ...
         'Use one or the other.'])
   end

   opts.GroupMembers = string(categories);
end
