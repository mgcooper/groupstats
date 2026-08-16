function [stats, samples, result] = groupdifference(tbl, groupvar, datavar, opts)
   %GROUPDIFFERENCE Estimate group differences
   %
   %  [STATS, SAMPLES, RESULT] = GROUPDIFFERENCE(TBL, GROUPVAR, DATAVAR)
   %  [___] = GROUPDIFFERENCE(___, ReferenceGroup=MEMBER)
   %  [___] = GROUPDIFFERENCE(___, conditionvar=NAME)
   %  [___] = GROUPDIFFERENCE(___, pooled=TRUE)
   %  [___] = GROUPDIFFERENCE(___, tail=TAIL)
   %
   % Description
   %  STATS = GROUPDIFFERENCE(TBL, GROUPVAR, DATAVAR) compares DATAVAR in each
   %  member of GROUPVAR against the reference member. STATS holds the
   %  bootstrapped median difference from bootdiff, a rank-test p-value and
   %  hypothesis result, and the labels of the groups compared.
   %
   %  STATS has one row per condition set, not one row per comparison. With no
   %  conditionvar there is one set, so STATS has one row. A row that covers
   %  several comparisons holds them in a cell. stats.p{1} is the vector of
   %  p-values for that row's comparisons. stats.outgroup{1} names them, in
   %  the same order. Pooled mode makes one comparison per set, so its variables
   %  hold scalars rather than cells.
   %
   %  The reference member is the first member returned by unique, which sorts
   %  alphabetically. Name it with ReferenceGroup instead of relying on that
   %  order.
   %
   %  The rank test depends on the reference data. When every reference value
   %  is zero, the comparison is a one-sample signrank against a median of
   %  zero. Otherwise it is a two-sample ranksum against the reference data.
   %  The STATS variable testname records which test ran for each row, and the
   %  p and h variables hold its result. The test name is not part of the
   %  variable name, so rows from sets that chose different tests concatenate.
   %
   %  conditionvar names a second grouping variable. The comparison then runs
   %  once per member of that variable, and STATS gains a set variable naming
   %  it.
   %
   %  pooled=true compares the reference member against every other member
   %  combined, rather than one at a time, so STATS holds one row per set. The
   %  outgroup label is then the list of pooled members.
   %
   %  tail is passed through to signrank or ranksum.
   %
   % Outputs
   %  STATS    Table with one row per condition set: bootdiff's outputs,
   %           testname, p, h, datavar, ingroup, outgroup, and set when
   %           conditionvar is given.
   %  SAMPLES  The bootstrapped median differences bootdiff drew, one entry
   %           per STATS row. Use them to plot the difference distribution.
   %  RESULT   One entry per STATS row, holding a sentence per comparison that
   %           states whether the two samples come from the same distribution.
   %
   % Note: pooling is applied across groupars, within the condition var sets, so
   % pay attention to the difference if you want to specify pooled true
   %
   % Errors
   %  groupstats:groupdifference:badReferenceGroup - ReferenceGroup is not a
   %  member of GROUPVAR.
   %  groupstats:groupdifference:emptyReferenceGroup - the reference group
   %  holds no rows for one of the comparisons.
   %
   % Dependencies
   %  bootdiff (matfunclib/libstats) is the statistical engine.
   %
   % See also: bootdiff, signrank, ranksum
   arguments
      tbl tabular
      groupvar (1, 1) string
      datavar (1, 1) string
      opts.conditionvar string = string.empty()
      opts.pooled (1, 1) logical = false
      opts.tail (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.tail, "testtail")} = "both"
      opts.ReferenceGroup (:, 1) string {mustBeScalarOrEmpty} = string.empty()
   end

   if isempty(opts.conditionvar)
      stats = oneSetDifferences(tbl, groupvar, datavar, opts);
   else
      stats = allSetDifferences(tbl, groupvar, datavar, opts.conditionvar, opts);
   end

   % For now remove samples but need to update code below
   try
      stats = struct2table(stats, "AsArray", true);
   catch
      stats = struct2table(stats, "AsArray", false);
   end

   samples = stats.boot_medians;
   result = stats.result;
   stats = removevars(stats, "boot_medians");
   stats = removevars(stats, "result");
end

%%
function stats = oneSetDifferences(tbl, groupvar, datavar, opts)

   members = orderReferenceFirst(unique(tbl.(groupvar)), opts.ReferenceGroup);

   % Compare as text so a cell array of char works like a categorical or a
   % string. The == operator rejects a cell array outright.
   groupvalues = string(tbl.(groupvar));

   % Collect all of the data
   grpdata = arrayfun(@(grpmember) ...
      tbl{groupvalues == string(grpmember), datavar}, ...
      string(members), 'Uniform', 0);

   % Pool all the non-reference data
   [grpdata, outgroup] = poolOutgroups(grpdata, members, opts.pooled);

   [p, h, testname] = compareToReference(grpdata, opts.tail);

   % Use bootdiff to determine if the median is different
   stats = bootdiff(grpdata);

   % Add the p-values and hypothesis test result to result struct. The test
   % name is a value, not part of the variable name, so rows from sets that
   % chose different tests concatenate.
   stats.testname = repmat(string(testname), numel(p), 1);
   stats.p = p;
   stats.h = h;

   % Add a human-readable result
   stats.result = describeResult(h);
   stats.datavar = datavar;
   stats.ingroup = string(members(1));
   stats.outgroup = outgroup;
end

function members = orderReferenceFirst(members, ReferenceGroup)
   %ORDERREFERENCEFIRST Put the reference member first in the member list.
   %
   % Every comparison is against members(1). Without a named reference that
   % is whichever member sorts first, which is rarely the control group.

   if isempty(ReferenceGroup)
      return
   end

   isreference = string(members) == ReferenceGroup;

   if ~any(isreference)
      error('groupstats:groupdifference:badReferenceGroup', ...
         ['ReferenceGroup "%s" is not a member of the group variable. ' ...
         'Members: %s.'], ReferenceGroup, strjoin(string(members), ', '))
   end

   members = [members(isreference); members(~isreference)];
end

function [grpdata, outgroup] = poolOutgroups(grpdata, members, pooled)
   %POOLOUTGROUPS Combine the non-reference data into one sample if asked.
   %
   % Pooling changes the number of comparisons from one per member to one in
   % total, so the outgroup label has to change with it. Returning both
   % together keeps the data and its label the same length.

   if pooled
      grpdata = [grpdata(1); {vertcat(grpdata{2:end})}];
      outgroup = strjoin(string(members(2:end)), ', ');
   else
      outgroup = string(members(2:end));
   end
end

function [p, h, testname] = compareToReference(grpdata, tail)
   %COMPARETOREFERENCE Rank-test every group against the reference group.
   %
   % If the first data is all zeros, it means we want to compare all of
   % the other datasets to the null hypothesis that they come from a
   % distribution with median zero, which is the signrank test.
   %
   % This works whether the data is pooled or not.

   % all([]) is true, so an empty reference takes the all-zero branch and
   % then fails inside signrank, with no mention of the reference. Say what
   % is missing.
   if isempty(grpdata{1})
      error('groupstats:groupdifference:emptyReferenceGroup', ...
         ['The reference group holds no rows for this comparison. ' ...
         'Every comparison needs reference data.'])
   end

   if all(grpdata{1} == 0)
      % Test if the data are different from zero
      [p, h] = cellfun(@(x) signrank(x, 0, 'tail', tail), grpdata(2:end));
      testname = 'signrank';
   else
      % Test if the data are different from the first (reference) dataset
      [p, h] = cellfun(@(grpmember) ...
         ranksum(grpdata{1}, grpmember, 'tail', tail), grpdata(2:end));
      testname = 'ranksum';
   end

   % Keep the outputs as columns so they match the one-row-per-comparison
   % shape of the rest of the struct.
   p = p(:);
   h = h(:);
end

function result = describeResult(h)
   %DESCRIBERESULT Turn each hypothesis test result into a sentence.
   %
   % Sized from the number of test results. Pooled mode runs one test for
   % many members, so the member count is not the number of sentences.

   result = repmat("", numel(h), 1);
   for n = 1:numel(h)
      if h(n) == 0
         result(n) = "The two samples come from the same distribution.";
      else
         result(n) = "The two samples come from different distributions.";
      end
   end
end

%%
function stats = allSetDifferences(tbl, groupvar, datavar, groupsets, opts)

   sets = unique(tbl.(groupsets));
   members = orderReferenceFirst(unique(tbl.(groupvar)), opts.ReferenceGroup);
   results = cell(numel(sets), 1);

   % Compare as text, for the same reason as the one-set path above.
   groupvalues = string(tbl.(groupvar));
   setvalues = string(tbl.(groupsets));

   % Demo
   % refData = tbl{ tbl.(groupvar) == members(1) & tbl.(groupsets) == sets(1), datavar };
   % pooledData = tbl{ tbl.(groupvar) ~= members(1) & tbl.(groupsets) == sets(1), datavar };
   % median(refData) - median(pooledData);
   % results = bootdiff({refData, pooledData});
   % Demo

   for m = 1:numel(sets)

      % Each iteration of arrayfun is doing a comparison like this:
      % T1 = tbl( tbl.(groupvar) == members(1) & tbl.(groupsets) == sets(m), : );
      % T2 = tbl( tbl.(groupvar) == members(2) & tbl.(groupsets) == sets(m), : );

      % Or, specifically on this data:
      % d1 = tbl{ tbl.(groupvar) == members(1) & tbl.(groupsets) == sets(m), datavar };
      % d2 = tbl{ tbl.(groupvar) == members(2) & tbl.(groupsets) == sets(m), datavar };

      % Collect all of the data for bootdiff. Compare as text so a cell array
      % of char works like a categorical or a string.
      inset = setvalues == string(sets(m));
      grpdata = arrayfun(@(grpmember) ...
         tbl{groupvalues == string(grpmember) & inset, datavar}, ...
         string(members), 'Uniform', 0);

      % Compare member 1 to all other members within this groupset. The
      % reference group is the same whether the data is pooled or not; only
      % the members it is compared against change.
      % In my test case, it compares ROS (sets(1)) in the historical scenario
      % (members(1)) to all other members (members ~= members(1)).
      [grpdata, outgroup] = poolOutgroups(grpdata, members, opts.pooled);

      % In this case what I want is to pool the data across the condition var
      % but I still want to

      [p, h, testname] = compareToReference(grpdata, opts.tail);

      % Use bootdiff to determine if the median is different. bootdiff
      % works for both cases because it computes the bootstrapped differences,
      % so if the first dataset is all zeros, it tests whether the data is
      % significantly different from zero, and if not, it tests whether the
      % differences between the first dataset and others are differnet from zero

      % [result, samples] = bootdiff(grpdata);
      stats = bootdiff(grpdata);

      % I added this to diagnose something, not sure it should be added in
      % general
      % result.grpdata = grpdata;

      % Add the p-values and hypothesis test result to result struct. The
      % test name is a value, not part of the variable name, so a set that
      % chose signrank concatenates with a set that chose ranksum.
      stats.testname = repmat(string(testname), numel(p), 1);
      stats.p = p;
      stats.h = h;

      % Add a human-readable result
      stats.result = describeResult(h);

      % Label every row this set contributes.
      stats.datavar = datavar;
      stats.ingroup = string(members(1));
      stats.outgroup = outgroup;
      stats.set = string(sets(m));

      results{m} = stats;
      % Try limiting the sample size of each draw
      % result = bootdiff(scores, [], 0.05, 1000);

      % Test for different medians using bootstrap replacement
      % nboot = 1000;
      % stat1 = bootstrp(nboot, @median, fcs1);
      % stat2 = bootstrp(nboot, @median, fcs2);
      % median(stat2-stat1)

      % figure;
      % histogram(tbl{groupvar == members(1), datavar}); hold on;
      % histogram(tbl{groupvar == members(2), datavar});
      % boxchart([fcs1 fcs2])
      % boxchart(scenarios([1 5]), [fcs1 fcs2])
   end

   % For each set, there can be multiple comparisons. In the test case, I
   % only compare SR to ROS, so a per-set assignment would work, but in
   % general, each "result" will have one p-value and one h-value for each SR
   % vs ROS, LR, etc., so the labels are assigned inside the loop above.
   stats = vertcat(results{:});
end
