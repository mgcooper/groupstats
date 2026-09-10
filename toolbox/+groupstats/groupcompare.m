function [stats, samples] = groupcompare(tbl, groupvar, datavar, opts)
   %GROUPCOMPARE Compare each group member against a reference member.
   %
   %  STATS = GROUPCOMPARE(TBL, GROUPVAR, DATAVAR)
   %  STATS = GROUPCOMPARE(_, ReferenceGroup=MEMBER)
   %  STATS = GROUPCOMPARE(_, ConditionVar=NAME)
   %  STATS = GROUPCOMPARE(_, Pooled=TRUE)
   %  STATS = GROUPCOMPARE(_, Test=NAME, Tail=TAIL, Alpha=A)
   %  [STATS, SAMPLES] = GROUPCOMPARE(_, Bootstrap=TRUE)
   %
   % Description
   %  STATS = GROUPCOMPARE(TBL, GROUPVAR, DATAVAR) tests DATAVAR in every
   %  member of GROUPVAR against the reference member and returns one row
   %  per comparison, every column plain. The reference member is the first
   %  in category order, or the one ReferenceGroup names.
   %
   %  ConditionVar names a second grouping variable. The comparisons then
   %  run once per member of that variable, and STATS gains a Set column.
   %  A member with no rows in a set has no comparison there.
   %
   %  Pooled=true compares the reference against every other member
   %  combined, one comparison per set, with Group naming the pooled
   %  members. Pooling is within each ConditionVar set: the sets are what
   %  the comparison is conditioned on, so there is no option to pool
   %  across them. To pool across sets, omit ConditionVar.
   %
   %  Test names the test, and is never inferred from the data:
   %   "ranksum"     (default) the two-sample rank-sum test of the
   %                 reference data against the group data.
   %   "signrank"    the one-sample sign-rank test of the group data
   %                 against the median of the reference data. With an
   %                 all-zero reference that is a test against zero.
   %   "permutation" the cluster-based permutation test of the vendored
   %                 permutest, on the two samples as independent trials
   %                 of one data point, with NumPermutations permutations.
   %                 The single point is the one cluster, and its p-value
   %                 is reported. When the point does not reach the cluster
   %                 threshold Alpha there is no cluster: P is NaN and H is
   %                 false. permutest counts the possible permutations
   %                 with the nchoosek warning off, and warns, with the two
   %                 sample sizes and the count, only when the samples
   %                 allow fewer permutations than NumPermutations; it
   %                 then uses the count. Eight values a side allow 12870.
   %  Tail is read against the reference: "both" (default) the medians
   %  differ, "right" the reference median is greater, "left" it is less.
   %  Alpha is the significance level of every test and interval. H is
   %  true when P is at or below Alpha.
   %
   %  Bootstrap=true adds the bootstrapped signed median difference, group
   %  minus reference, with its Alpha confidence interval. The columns are
   %  MedianDiff, CILower, CIUpper, and HBootstrap, true when the interval
   %  excludes zero. NumBootstrap sets the resample count.
   %
   % Outputs
   %  STATS    One row per comparison: Set (with ConditionVar), Reference,
   %           Group, DataVar, Test, P, H, and with Bootstrap the four
   %           bootstrap columns.
   %  SAMPLES  NumBootstrap-by-height(STATS) bootstrapped signed median
   %           differences, one column per row of STATS, for plotting the
   %           difference distribution. Empty without Bootstrap.
   %
   % Errors
   %  groupstats:groupcompare:badReferenceGroup - ReferenceGroup is not a
   %  member of GROUPVAR.
   %  groupstats:groupcompare:emptyReferenceGroup - the reference member
   %  has no values in one of the ConditionVar sets, or, without
   %  ConditionVar, every one of its DATAVAR values is missing.
   %  groupstats:groupcompare:multiColumnDataVar - DATAVAR names a matrix
   %  variable.
   %  groupstats:prepareTableGroups:unknownVariable and
   %  groupstats:prepareTableGroups:multiColumnGroupVar, from the shared
   %  preprocessing groupsamples runs, pass through unchanged.
   %
   %  A table with no usable row gives STATS with no rows.
   %
   % Example
   %  tbl = table(categorical([repmat("ctrl", 8, 1); repmat("a", 8, 1); ...
   %     repmat("b", 8, 1)]), ...
   %     [randn(8, 1); randn(8, 1) + 1; randn(8, 1) + 2], ...
   %     'VariableNames', {'Group', 'Value'});
   %  stats = groupstats.groupcompare(tbl, "Group", "Value", ...
   %     ReferenceGroup="ctrl", Bootstrap=true);
   %  stats(:, ["Group", "P", "H", "MedianDiff"])
   %
   % Dependencies
   %  ranksum, signrank, and quantile need the Statistics and Machine
   %  Learning Toolbox. Test="permutation" runs the vendored permutest,
   %  which needs that toolbox too, for tinv, and the Image Processing
   %  Toolbox, for bwconncomp.
   %
   % See also: groupstats.groupsamples, ranksum, signrank,
   % groupstats.namelists.comparetest, groupstats.namelists.testtail

   arguments
      tbl tabular
      groupvar (1, 1) string {mustBeNonempty}
      datavar (1, 1) string {mustBeNonempty}
      opts.ReferenceGroup string {mustBeScalarOrEmpty} = string.empty()
      opts.ConditionVar string {mustBeScalarOrEmpty} = string.empty()
      opts.Pooled (1, 1) logical = false
      opts.Test (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Test, "comparetest")} ...
         = "ranksum"
      opts.Tail (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Tail, "testtail")} = "both"
      opts.Alpha (1, 1) double ...
         {mustBeInRange(opts.Alpha, 0, 1, "exclusive")} = 0.05
      opts.Bootstrap (1, 1) logical = false
      opts.NumBootstrap (1, 1) double {mustBeInteger, mustBePositive} = 10000
      opts.NumPermutations (1, 1) double {mustBeInteger, mustBePositive} ...
         = 10000
   end

   import groupstats.groupsamples

   % The reshape, reference first within each set. groupsamples reports
   % its checks under its own identifiers; a caller of this function pins
   % this function's, so they are renamed on the way through.
   try
      S = groupsamples(tbl, groupvar, datavar, ...
         ReferenceGroup = opts.ReferenceGroup, ...
         ConditionVar = opts.ConditionVar, Pooled = opts.Pooled);
   catch e
      if startsWith(e.identifier, "groupstats:groupsamples:")
         error(replace(e.identifier, "groupstats:groupsamples:", ...
            "groupstats:groupcompare:"), '%s', e.message)
      end
      rethrow(e)
   end

   % Walk the sets. Without ConditionVar there is one, holding every row;
   % a table with no usable row has none.
   if height(S) == 0
      setrows = {};
   elseif isempty(opts.ConditionVar)
      setrows = {(1:height(S))'};
   else
      sets = unique(S.Set, 'stable');
      setrows = arrayfun(@(s) find(S.Set == s), sets, ...
         'UniformOutput', false);
   end

   % One block of rows per set. The reference is the set's first sample
   % and every other sample is one comparison. Each comparison gets its
   % test result, then the set's rows are assembled with their labels.
   rows = cell(numel(setrows), 1);
   drawn = cell(1, numel(setrows));
   for m = 1:numel(setrows)
      refdata = S.Data{setrows{m}(1)};
      others = setrows{m}(2:end);
      ncomp = numel(others);

      P = zeros(ncomp, 1);
      for n = 1:ncomp
         P(n) = runTest(refdata, S.Data{others(n)}, opts);
      end
      H = P <= opts.Alpha;

      rows{m} = table(repmat(S.Group(setrows{m}(1)), ncomp, 1), ...
         S.Group(others), repmat(datavar, ncomp, 1), ...
         repmat(opts.Test, ncomp, 1), P, H, 'VariableNames', ...
         {'Reference', 'Group', 'DataVar', 'Test', 'P', 'H'});
      if ~isempty(opts.ConditionVar)
         rows{m} = addvars(rows{m}, S.Set(others), ...
            'NewVariableNames', 'Set', 'Before', 1);
      end

      % The bootstrap runs on the same samples, reference first.
      if opts.Bootstrap
         boot = bootmediandiff([{refdata}; S.Data(others)]', ...
            NumBootstrap = opts.NumBootstrap, Alpha = opts.Alpha);
         rows{m}.MedianDiff = boot.MedianDiff(:);
         rows{m}.CILower = boot.CILower(:);
         rows{m}.CIUpper = boot.CIUpper(:);
         rows{m}.HBootstrap = boot.H(:);
         drawn{m} = boot.Differences;
      end
   end
   % Start from the schema, so no sets still returns the documented table.
   stats = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
      strings(0, 1), zeros(0, 1), false(0, 1), 'VariableNames', ...
      {'Reference', 'Group', 'DataVar', 'Test', 'P', 'H'});
   if ~isempty(opts.ConditionVar)
      stats = addvars(stats, strings(0, 1), 'NewVariableNames', 'Set', ...
         'Before', 1);
   end
   if opts.Bootstrap
      stats.MedianDiff = zeros(0, 1);
      stats.CILower = zeros(0, 1);
      stats.CIUpper = zeros(0, 1);
      stats.HBootstrap = false(0, 1);
   end
   stats = vertcat(stats, rows{:});

   % One column per row of stats, NumBootstrap rows even when there are no
   % comparisons; empty without Bootstrap.
   if opts.Bootstrap
      samples = [zeros(opts.NumBootstrap, 0), horzcat(drawn{:})];
   else
      samples = [];
   end
end

function p = runTest(refdata, groupdata, opts)
   %RUNTEST Run the named test of one group against the reference.
   %
   % Tail is read against the reference throughout. ranksum reads its tail
   % against its first argument, the reference here. signrank tests the
   % group data against the reference median, so its first argument is the
   % group and the tail flips. permutest's one-sided test detects a larger
   % first argument, so the argument order carries the tail.

   switch opts.Test
      case "ranksum"
         p = ranksum(refdata, groupdata, 'alpha', opts.Alpha, ...
            'tail', opts.Tail);
      case "signrank"
         p = signrank(groupdata, median(refdata), 'alpha', opts.Alpha, ...
            'tail', flipTail(opts.Tail));
      case "permutation"
         % permutest takes trials along the last dimension, so each sample
         % is one row: one data point, one trial per value. With no cluster
         % (the point's t-statistic is below the threshold) tsums is empty
         % and pvalues keeps its initial value, so read tsums.
         if opts.Tail == "left"
            [~, pvalues, tsums] = permutest(groupdata(:)', refdata(:)', ...
               false, opts.Alpha, opts.NumPermutations, false);
         else
            [~, pvalues, tsums] = permutest(refdata(:)', groupdata(:)', ...
               false, opts.Alpha, opts.NumPermutations, opts.Tail == "both");
         end
         if isempty(tsums)
            p = NaN;
         else
            p = pvalues(1);
         end
   end
end

function tail = flipTail(tail)
   %FLIPTAIL Swap right and left; both stays.

   switch tail
      case "right"
         tail = "left";
      case "left"
         tail = "right";
   end
end
