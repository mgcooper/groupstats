function ycoords = boxchartydata(data, varargin)
   %BOXCHARTYDATA Compute y coordinates of boxchart
   %
   %  YCOORDS = BOXCHARTYDATA(DATA)
   %  YCOORDS = BOXCHARTYDATA(DATA, _)
   %
   % Description
   %  YCOORDS = BOXCHARTYDATA(DATA) returns the y coordinates boxchart draws
   %  for the vector DATA, as a struct. Pair it with
   %  groupstats.boxchartxdata, which returns the matching x coordinates, to
   %  annotate or shade a box chart.
   %
   %  Any trailing argument is passed to median, which sets the box line.
   %
   %  NaN values are removed first, matching what boxchart plots.
   %
   % Output fields
   %  boxline   The median, which is the line inside the box.
   %  boxedge   The 25th and 75th percentiles, which are the box edges.
   %  iqrange   The interquartile range, boxedge(2) minus boxedge(1).
   %  whiskers  The inner fences: the smallest and largest values still within
   %            1.5 interquartile ranges of the box edges. These are the
   %            whisker tips boxchart draws, not the outlier extent.
   %  notches   The notch bounds, boxline plus or minus
   %            1.57 * iqrange / sqrt(N).
   %  outliers  The values beyond the inner fences, which boxchart draws as
   %            separate points.
   %
   % Example
   %  ycoords = groupstats.boxchartydata([1 2 3 4 100]);
   %  ycoords.whiskers   % [1 4], not [100 100]
   %
   % See also: groupstats.boxchartxdata, boxchart, quantile

   data = data(:);
   data = data(~isnan(data));
   N = numel(data);

   boxline = median(data, varargin{:});
   boxedge = [quantile(data, 0.25) quantile(data, 0.75)];
   iqrange = diff(boxedge);

   % Element-wise or, not short-circuit or. The short-circuit form requires
   % scalar operands and errors on a vector, so no vector input reached the
   % rest of this function.
   isoutlier = data < boxedge(1) - 1.5 * iqrange ...   % lower outliers
      | data > boxedge(2) + 1.5 * iqrange;             % upper outliers
   outliers = data(isoutlier);

   % The whiskers reach the most extreme values inside the fences, which is
   % what boxchart draws. Taking the outlier extent instead would put the
   % whisker tips beyond the fences, on the points boxchart plots separately.
   inside = data(~isoutlier);
   if isempty(inside)
      whiskers = [NaN NaN];
   else
      whiskers = [min(inside) max(inside)];
   end

   notches = boxline + [-(1.57 * iqrange)/sqrt(N) (1.57 * iqrange)/sqrt(N)];

   ycoords.boxline = boxline;
   ycoords.boxedge = boxedge;
   ycoords.notches = notches;
   ycoords.iqrange = iqrange;
   ycoords.whiskers = whiskers;
   ycoords.outliers = outliers;
end
