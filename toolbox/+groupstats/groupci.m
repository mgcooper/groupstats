function ci = groupci(tbl, ydatavar, xgroupvar, cgroupvar, opts)
   %GROUPCI Confidence interval of the center of each group.
   %
   %  CI = GROUPCI(TBL, YDATAVAR, XGROUPVAR)
   %  CI = GROUPCI(TBL, YDATAVAR, XGROUPVAR, CGROUPVAR)
   %  CI = GROUPCI(_, Name=Value)
   %
   % Description
   %  CI = GROUPCI(TBL, YDATAVAR, XGROUPVAR) returns a table with one row
   %  per member of XGROUPVAR. Each row holds the mean of YDATAVAR in that
   %  member and its confidence interval.
   %
   %  CI = GROUPCI(TBL, YDATAVAR, XGROUPVAR, CGROUPVAR) returns one row per
   %  pairing of an XGROUPVAR member with a CGROUPVAR member. The rows
   %  follow the category order of XGROUPVAR, then CGROUPVAR. A pairing
   %  with no values is a row with N = 0.
   %
   %  The grouping arguments are those of the cats charts. The same call to
   %  groupstats.boxchartcats draws one box for each row with N of 1 or
   %  more, in the same order.
   %
   % Name-value arguments
   %  XGroupMembers      Members of XGROUPVAR to keep. Empty keeps them all.
   %  CGroupMembers      Members of CGROUPVAR to keep. Empty keeps them all.
   %  RowSelectVar       A variable that selects rows. Give it together
   %                     with RowSelectMembers.
   %  RowSelectMembers   The members of RowSelectVar whose rows to keep.
   %  MergeGroupMembers  CGROUPVAR members to pool into one group, as in
   %                     the cats charts. Give a cell array of string
   %                     vectors; a bare string vector is one merge group.
   %                     The merged label joins the names with " and ".
   %                     Its interval uses the pooled rows. CGroupMembers
   %                     reads the original names.
   %  Method             "mean" (default) or "median".
   %  Alpha              The significance level of the mean interval, in
   %                     the open interval (0, 1). Empty, the default,
   %                     means 0.05. The median interval takes no Alpha.
   %
   % Output
   %  CI has the grouping variables first, as categorical columns with
   %  their input names. Then come these columns:
   %
   %   N         The number of non-missing YDATAVAR values in the pairing.
   %   Estimate  The mean or the median of those values.
   %   CILower   The lower bound of the interval.
   %   CIUpper   The upper bound of the interval.
   %
   % Intervals
   %  Method="mean" gives the Student t interval
   %
   %     mean +/- t(1 - Alpha/2, N - 1) * s / sqrt(N),
   %
   %  where s is the sample standard deviation with the N - 1 denominator.
   %  The t quantile needs only base MATLAB.
   %
   %  Method="median" gives the notch that groupstats.boxchartcats draws,
   %
   %     median +/- 1.57 * IQR / sqrt(N),
   %
   %  with the quartiles from the default quantile rule. The notch is a
   %  comparison interval (McGill, Tukey, and Larsen, 1978). When two
   %  notches do not overlap, the medians differ at about the 5% level.
   %  This holds approximately for roughly normal data with similar group
   %  sizes and spreads. The notch is not a 95% interval for one median,
   %  and its level is fixed. For very small N it can reach past the data.
   %
   % Missing values, small groups, and weights
   %  groupci drops a row with a missing group value. It excludes NaN values
   %  of YDATAVAR, so N counts the values that the interval uses.
   %
   %  - N = 0: Estimate, CILower, and CIUpper are NaN.
   %  - N = 1: Estimate is the value, and both bounds are NaN. Note:
   %    boxchart draws a zero-width notch for one value, and
   %    groupstats.boxchartydata returns it. groupci returns NaN bounds.
   %  - N >= 2 with equal values: the bounds have zero width. The median
   %    bounds equal the value. The mean bounds can differ from it by
   %    rounding error.
   %
   %  The intervals are unweighted. No option accepts weights. A numeric
   %  or logical YDATAVAR converts to double.
   %
   % Timetables
   %  XGROUPVAR or CGROUPVAR can name the time dimension of a timetable.
   %  Each distinct time is one member, and the result is a table.
   %
   % Example
   %  data = groupstats.test.generateTestData('groupsummary');
   %  ci = groupstats.groupci(data.tbl, "Value", "Grp", "Sub")
   %  % Pairing a-x holds 1 and 3: Estimate 2, bounds -10.7062 and 14.7062.
   %
   %  ci = groupstats.groupci(data.tbl, "Value", "Grp", "Sub", ...
   %     Method = "median")
   %  % Pairing a-x: bounds -0.2203 and 4.2203, the notch boxchartcats draws.
   %
   % Errors
   %  groupstats:groupci:nonNumericData - YDATAVAR is not numeric or
   %  logical. A categorical YDATAVAR raises it, even with numeric labels.
   %  groupstats:groupci:alphaWithMedian - Alpha was given with
   %  Method="median", whose level is fixed.
   %  groupstats:groupci:mergeWithoutGroupVar - MergeGroupMembers was given
   %  without CGROUPVAR.
   %  groupstats:groupci:reservedName - A grouping variable is named N,
   %  Estimate, CILower, or CIUpper, which are the result columns.
   %
   % See also: groupstats.boxchartcats, groupstats.barchartcats,
   % groupstats.boxchartydata, groupstats.groupcompare

   arguments
      tbl tabular
      ydatavar (1, 1) string {mustBeNonempty}
      xgroupvar (1, 1) string {mustBeNonempty}
      % One color grouping or none, as in the cats charts.
      cgroupvar string {mustBeScalarOrEmpty} = string.empty()

      % Empty selects every member, which prepareTableGroups reads as no
      % filter.
      opts.XGroupMembers (:, 1) string = string.empty()
      opts.CGroupMembers (:, 1) string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers (:, 1) string = string.empty()

      % Untyped because a cell array of string vectors is one valid shape.
      opts.MergeGroupMembers (:, 1) = string.empty()

      opts.Method (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Method, ...
         "centralstatistic")} = "mean"

      % Empty means unset, so the interval helper applies its one default.
      opts.Alpha double {mustBeScalarOrEmpty, ...
         mustBeGreaterThan(opts.Alpha, 0), ...
         mustBeLessThan(opts.Alpha, 1)} = []
   end

   import groupstats.prepareTableGroups

   % The median interval is the boxchart notch, whose level is fixed. An
   % Alpha would name a level that the interval does not have.
   if opts.Method == "median" && ~isempty(opts.Alpha)
      error('groupstats:groupci:alphaWithMedian', ...
         ['Alpha was given with Method="median". The median interval is ' ...
         'the boxchart notch, whose level is fixed. Omit Alpha, or use ' ...
         'Method="mean".'])
   end

   % Merging pools members of the color-group variable, so without one
   % there is nothing to pool.
   if isempty(cgroupvar) && ~isempty(opts.MergeGroupMembers)
      error('groupstats:groupci:mergeWithoutGroupVar', ...
         ['MergeGroupMembers was given without cgroupvar. Name the color ' ...
         'group variable whose members are pooled.'])
   end

   % The grouping columns share the result table with the interval
   % columns, so a grouping variable cannot take one of their names.
   resultvars = ["N" "Estimate" "CILower" "CIUpper"];
   validategroupvarnames([xgroupvar cgroupvar], resultvars, "groupci")

   % Select rows and prepare the groupings as the cats charts do, so the
   % same arguments give the same pairings.
   tbl = prepareTableGroups(tbl, ydatavar, ...
      XGroupVar = xgroupvar, ...
      XGroupMembers = opts.XGroupMembers, ...
      CGroupVar = cgroupvar, ...
      CGroupMembers = opts.CGroupMembers, ...
      RowSelectVar = opts.RowSelectVar, ...
      RowSelectMembers = opts.RowSelectMembers, ...
      ConvertDataVar = false);

   % Merge after member filtering, as the charts do, so CGroupMembers
   % reads the original names and the result reads the merged ones.
   if ~isempty(opts.MergeGroupMembers)
      tbl.(cgroupvar) = mergegroupmembers( ...
         tbl.(cgroupvar), opts.MergeGroupMembers);
   end

   % ConvertDataVar=false keeps a categorical ydatavar categorical, so this
   % check rejects it. A categorical or text value has no mean or median to
   % bound, even when its labels look like numbers.
   y = tbl.(ydatavar);
   if ~(isnumeric(y) || islogical(y))
      error('groupstats:groupci:nonNumericData', ...
         ['%s is %s. groupci needs numeric or logical data to compute ' ...
         'an interval.'], ydatavar, class(y))
   end

   % Number the pairings x-major: pairing (x - 1) * nc + c, from the
   % category codes. That is the row order of the result, and it includes
   % every pairing, even one with no rows. Without cgroupvar every row is
   % in the one color group.
   [xlevels, xcode] = grouplevels(tbl.(xgroupvar));
   if isempty(cgroupvar)
      clevels = true;
      ccode = ones(size(xcode));
   else
      [clevels, ccode] = grouplevels(tbl.(cgroupvar));
   end
   nc = numel(clevels);
   pairing = (xcode - 1) * nc + ccode;

   % Compute each interval through the helper that barchartcats uses, so a
   % table row and a drawn whisker agree.
   npairs = numel(xlevels) * nc;
   [N, Estimate, CILower, CIUpper] = deal(nan(npairs, 1));
   for k = 1:npairs
      [Estimate(k), bounds, N(k)] = sampleci(y(pairing == k), ...
         opts.Method, opts.Alpha);
      CILower(k) = bounds(1);
      CIUpper(k) = bounds(2);
   end

   % Repeat the members to the x-major row order: each x member once per
   % color group, and the color groups in turn within each x member.
   [cidx, xidx] = ndgrid(1:nc, 1:numel(xlevels));
   ci = table(xlevels(xidx(:)), N, Estimate, CILower, CIUpper, ...
      'VariableNames', [xgroupvar resultvars]);
   if ~isempty(cgroupvar)
      ci = addvars(ci, clevels(cidx(:)), 'After', xgroupvar, ...
         'NewVariableNames', cgroupvar);
   end
end

function [levels, code] = grouplevels(group)
   %GROUPLEVELS One categorical element per category, and each row's code.
   %
   % LEVELS holds every category of GROUP once, in category order, with the
   % ordinal flag of GROUP. CODE is each row's category number, which
   % double returns for a categorical. prepareTableGroups made GROUP
   % categorical and removed its missing values, so every code is valid.

   names = categories(group);
   levels = categorical(names, names, 'Ordinal', isordinal(group));
   code = double(group);
end
