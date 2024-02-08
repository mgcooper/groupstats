function varargout = histogram(tbl, datavar, Opts, Props)
   %HISTOGRAM Histogram grouped data.
   %
   % h = groupstats.histogram(tbl, datavar)
   % h = groupstats.histogram(tbl, datavar, "GroupVar", groupvar)
   % h = groupstats.histogram(tbl, categoricalvar)
   % h = groupstats.histogram(_, "GroupMembers", members)
   % h = groupstats.histogram(_, "RowSelectVar", varname)
   % h = groupstats.histogram(_, "RowSelectMembers", members)
   % h = groupstats.histogram(_, "MergeGroupMembers", members)
   % h = groupstats.histogram(_, "Parent", figure_handle)
   % h = groupstats.histogram(_, "LegendText", legend_text)
   % h = groupstats.histogram(_, "LegendOrientation", orientation)
   % h = groupstats.histogram(_, HistogramProperty, PropertyValue)
   %
   % The Name-Value pairs can be any accepted by HISTOGRAM
   % h = groupstats.histogram(_, "NumBins", numbins)
   % h = groupstats.histogram(_, "BinEdges", edges)
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
   % h = groupstats.histogram(tbl, datavar, groupvar) groups the data in the
   % vector tbl.(datavar) according to the unique values the data and plots
   % each group of data as separate (possibly overlapping) histograms.
   %
   % h = groupstats.histogram(tbl, datavar, groupvar, "GroupMembers", members)
   % plots one histogram for each group member specified by MEMBERS. Use this
   % option to selectively plot specific groups without first subsetting the
   % input TBL.
   %
   % h = groupstats.histogram(_, Name, Value) specifies additional chart options
   % using one or more name-value pair arguments. For a list of properties, see
   % Histogram Properties.
   %
   % Input Arguments
   %
   % tbl: A table containing the data to be plotted.
   %
   % datavar: The name of the variable in the table tbl that contains the data
   % values for the histogram.
   %
   % groupvar: The name of the categorical variable in the table tbl used to
   % define groups.
   %
   % members: A cell array of categories to be used for the x-axis grouping.
   %
   % Output Argument
   %
   % H: A handle to the created histogram.
   %
   % Example
   %
   % This example reads data from a CSV file into a table tbl, and plots a
   % histogram of the Value variable, grouped by the CategoryX variable. The
   % x-axis grouping includes categories 'Cat1', 'Cat2', and 'Cat3'.
   %
   % tbl = readtable('data.csv');
   % datavar = 'Value';
   % groupvar = 'CategoryX';
   % groupuse = {'Cat1', 'Cat2', 'Cat3'};
   %
   % h = groupstats.histogram(tbl, datavar, groupvar, "GroupMembers", groupuse);
   %
   % Matt Cooper, https://github.com/mgcooper
   %
   % See also reordergroups, reordercats, barchart

   % Histogram is unique. It has an option to plot data, or an option to plot
   % categorical data, where one bar is plotted for each category member. Say I
   % have a table with tbl.GroupName and each row is a group member, then
   % histogram(tbl.GroupName) creates a histogram of the occurrences of each group
   % member. In contrast, my other grouped plot functions would

   % TODO: if the first input is a categorical array, use the "C" syntax from
   % histogram. if the first input is an array and the second is a groupvar,
   % then use it, in both cases the user would pass in tbl.(varname) direclty

   % see plotGroupedHist in:
   % fullfile(matlabroot, ...
   % 'toolbox/matlab/specgraph/+matlab/+graphics/+chart/@ScatterHistogramChart')

   % If I make groupvar Opts.GroupVar, then if GroupVar is specified, datavar
   % will be grouped by GroupVar, optionally only for GroupMembers. If datavar
   % is categorical and GroupVar is not specified but GroupMembers is, then
   % GroupMembers becomes the "Categories" input to histogram.

   arguments
      tbl tabular
      datavar (1,1) string {mustBeNonempty}
      Opts.GroupVar string = string.empty()
      Opts.GroupMembers string = string.empty()
      Opts.RowSelectVar string = string.empty()
      Opts.RowSelectMembers string = string.empty()
      Opts.Parent (1,1) { mustBeA(Opts.Parent, ...
         "matlab.graphics.axis.AbstractAxes") } = gca
      Opts.MergeGroupVar string = string.empty()
      Opts.MergeGroupMembers (:,1) = string.empty()
      Opts.LegendString = string.empty()
      Opts.LegendOrientation (1, 1) string = "vertical"
      Props.?matlab.graphics.chart.primitive.Histogram
   end

   % These are the histogram properties, but some won't work if the data is
   % categorical e.g. NumBins.
   %    'BarWidth', 'BinCounts', 'BinCountsMode', 'BusyAction', 'ButtonDownFcn',
   %    'Categories', 'ContextMenu', 'CreateFcn', 'Data', 'DataTipTemplate',
   %    'DeleteFcn', 'DisplayName', 'DisplayOrder', 'DisplayStyle', 'EdgeAlpha',
   %    'EdgeColor', 'FaceAlpha', 'FaceColor', 'HandleVisibility', 'HitTest',
   %    'Interruptible', 'LineStyle', 'LineWidth', 'Normalization',
   %    'NumDisplayBins', 'Orientation', 'Parent', 'PickableParts', 'Selected',
   %    'SelectionHighlight', 'SeriesIndex', 'ShowOthers', 'Tag', 'UserData',
   %    'Visible'

   % Import groupstats functions.
   import groupstats.groupselect
   import groupstats.prepareTableGroups

   Props = namedargs2cell(Props);

   % Special validation for categorical histogram
%    makeCategoricalHistogram = iscategorical(tbl.(datavar)) && ...
%       isempty(Opts.GroupVar) && ~isempty(Opts.GroupMembers);
   
   makeCategoricalHistogram = iscategorical(tbl.(datavar)) && ...
      isempty(Opts.GroupVar);

   if makeCategoricalHistogram
      % Equivalent to GroupVar=datavar with GroupMembers
      Opts.GroupVar = datavar;
   end

   % Prepare input data.
   tbl = prepareTableGroups(tbl, datavar, string.empty(), Opts.GroupVar, ...
      string.empty(), Opts.GroupMembers, string.empty(), ...
      Opts.RowSelectVar, Opts.RowSelectMembers);

   % Create a categorical histogram
   if makeCategoricalHistogram
      % prepareTableGroups removes the rows that are not in GroupMembers, so all
      % that's needed is a call to histogram.
      H = histogram(tbl.(datavar), Props{:}, 'Parent', Opts.Parent);
   else

      % Set the default legend string to the unique group members
      if isempty(Opts.LegendString)
         Opts.LegendString = string(unique(tbl.(Opts.GroupVar)));
      end

      % Assign the data to plot
      XData = tbl.(Opts.GroupVar);
      YData = tbl.(datavar);

      % Custom group merging
      if ~isempty(Opts.MergeGroupMembers)
         [YData, Opts] = mergeGroups(Opts, YData);
      end

      % Create the figure
      H = createHistogram(XData, YData, Opts, Props);
      L = createLegend(Opts);
   end
   
   formatHistogram(H)

   if nargout > 0
      varargout{1} = H;
   end
   if nargout == 2
      varargout{2} = L;
   end
end

%% Create the histogram
function H = createHistogram(XData, YData, Opts, Props)
   groupMembers = unique(XData);
   hold on
   for n = 1:numel(groupMembers)
      ingroup = XData == groupMembers(n);
      H = histogram(YData(ingroup), Props{:}, 'Parent', Opts.Parent);
   end
   hold off
end

%% Format the plot
function formatHistogram(H)
   ylabel(H.Normalization);
   set(gca, "XMinorTick", "on", "Box", "on");
   % set(get(gca, 'XAxis'), 'TickLength', [0 0]);
end

%% Create the legend
function L = createLegend(Opts)
   try
      withwarnoff('MATLAB:legend:IgnoringExtraEntries');
      L = legend(Opts.LegendString, ...
         'Location', 'northwest', ...
         'AutoUpdate', 'off', ...
         'Orientation', Opts.LegendOrientation, ...
         'FontSize', 12);
   catch
   end
end

%% Merge groups
function [NewYData, opts] = mergeGroups(opts, YData)
   %MERGEGROUPS

   % mergegroups is the YData column indices to merge, so the new YData needs to
   % contain the unmerged groups and the merged groups. The new YData are
   % ordered with the merged groups in the position of the smallest index for
   % that group and the unmerged groups in their original position relative to
   % the smallest index of the merged groups.
   members = opts.MergeGroups;
   dontmerge = setdiff(1:size(YData, 2), horzcat(members{:}));
   NewYData = nan(size(YData));
   NewYData(:, dontmerge) = YData(:, dontmerge);
   for n = 1:numel(members)
      NewYData(:, min(members{n})) = mean(YData(:, members{n}), 2);
   end
   NewYData = NewYData(:, ~all(isnan(NewYData)));
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
