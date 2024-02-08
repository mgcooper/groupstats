function [stats, samples, result] = groupdifference(T, groupvar, datavar, opts)
   %
   %
   %
   % Note: pooling is applied across groupars, within the condition var sets, so
   % pay attention to the difference if you want to specify pooled true 
   % 
   % See also:
   arguments
      T tabular
      groupvar (1, 1) string
      datavar (1, 1) string
      opts.conditionvar string = string.empty()
      opts.pooled (1, 1) logical = false
      opts.tail (1, 1) string = "both"
   end

   if isempty(opts.conditionvar)
      stats = oneSetDifferences(T, groupvar, datavar, opts);
   else
      stats = allSetDifferences(T, groupvar, datavar, opts.conditionvar, opts);
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
function stats = oneSetDifferences(T, groupvar, datavar, opts)

   members = unique(T.(groupvar));

   % Collect all of the data
   grpdata = arrayfun(@(grpmember) ...
      T{T.(groupvar) == grpmember, datavar}, members, 'Uniform', 0);

   % Pool all the non-reference data
   if opts.pooled
      grpdata = [grpdata(1) vertcat(grpdata{2:end})];
   end

   % This works whether the data is pooled or not.
   if all(grpdata{1} == 0)
      % Test if the data are different from zero
      [p, h] = cellfun(@(x) signrank(x, 0, 'tail', opts.tail), grpdata(2:end));
      testname = 'signrank';
   else
      % Test if the data are different from the first (reference) dataset
      [p, h] = cellfun(@(grpmember) ...
         ranksum(grpdata{1}, grpmember, 'tail', opts.tail), grpdata(2:end));
      testname = 'ranksum';
   end

   % Use bootdiff to determine if the median is different
   stats = bootdiff(grpdata);

   % Add the p-values and hypothesis test result to result struct
   stats.("p" + "_" + testname) = p;
   stats.("h" + "_" + testname) = h;

   % Add a human-readable result
   stats.result = repmat("", numel(members)-1, 1);
   for n = 1:numel(grpdata)-1
      if h(n) == 0
         stats.result(n) = "The two samples come from the same distribution.";
      else
         stats.result(n) = "The two samples come from different distributions.";
      end
   end
   stats.datavar = datavar;
   stats.ingroup = string(members(1));
   stats.outgroup = string(members(2:end));
end

%%
function stats = allSetDifferences(T, groupvar, datavar, groupsets, opts)

   sets = unique(T.(groupsets));
   members = unique(T.(groupvar));
   results = cell(numel(sets), 1);

   % Demo
   % refData = T{ T.(groupvar) == members(1) & T.(groupsets) == sets(1), datavar };
   % pooledData = T{ T.(groupvar) ~= members(1) & T.(groupsets) == sets(1), datavar };
   % median(refData) - median(pooledData);
   % results = bootdiff({refData, pooledData});
   % Demo

   for m = 1:numel(sets)

      % Each iteration of arrayfun is doing a comparison like this:
      % T1 = T( T.(groupvar) == members(1) & T.(groupsets) == sets(m), : );
      % T2 = T( T.(groupvar) == members(2) & T.(groupsets) == sets(m), : );

      % Or, specifically on this data:
      % d1 = T{ T.(groupvar) == members(1) & T.(groupsets) == sets(m), datavar };
      % d2 = T{ T.(groupvar) == members(2) & T.(groupsets) == sets(m), datavar };

      % Collect all of the data for bootdiff
      grpdata = arrayfun(@(grpmember) ...
         T{T.(groupvar) == grpmember & T.(groupsets) == sets(m), datavar}, ...
         members, 'Uniform', 0);

      % The reference group is the same whethe the data is pooled or not.
      refgroupidx = T.(groupvar) == members(1) & T.(groupsets) == sets(m);

      % Compare member 1 to all other members within this groupset
      % In my test case, it compares ROS (sets(1)) in the historical scenario
      % (members(1)) to all other members (members ~= members(1)).
      if opts.pooled
         grpdata = [grpdata(1) vertcat(grpdata{2:end})];
      end

      % In this case what I want is to pool the data across the condition var
      % but I still want to 
      
      % If the first data is all zeros, it means we want to compare all of
      % the other datasets to the null hypothesis that they come from a
      % distribution with median zero, which is the signrank test.

      % This works whether the data is pooled or not.
      if all(grpdata{1} == 0)
         % Test if the data are different from zero
         [p, h] = cellfun(@(x) signrank(x, 0, 'tail', opts.tail), grpdata(2:end));
         testname = 'signrank';
      else
         % Test if the data are different from the first (reference) dataset
         [p, h] = cellfun(@(grpmember) ...
            ranksum(grpdata{1}, grpmember, 'tail', opts.tail), grpdata(2:end));
         testname = 'ranksum';
      end

      % Use bootdiff to determine if the median is different. Note that bootdiff
      % works for both cases because it computes the bootstrapped differences,
      % so if the first dataset is all zeros, it tests whether the data is
      % significantly different from zero, and if not, it tests whether the
      % differences between the first dataset and others are differnet from zero

      % [result, samples] = bootdiff(grpdata);
      stats = bootdiff(grpdata);

      % I added this to diagnose something, not sure it should be added in
      % general
      % result.grpdata = grpdata;

      % Add the p-values and hypothesis test result to result struct
      stats.("p" + "_" + testname) = p;
      stats.("h" + "_" + testname) = h;

      % Add a human-readable result
      stats.result = repmat("", numel(grpdata)-1, 1);
      for n = 1:numel(grpdata)-1
         if h(n) == 0
            stats.result(n) = "The two samples come from the same distribution.";
         else
            stats.result(n) = "The two samples come from different distributions.";
         end
      end

      results{m} = stats;
      % Try limiting the sample size of each draw
      % result = bootdiff(scores, [], 0.05, 1000);

      % Test for different medians using bootstrap replacement
      % nboot = 1000;
      % stat1 = bootstrp(nboot, @median, fcs1);
      % stat2 = bootstrp(nboot, @median, fcs2);
      % median(stat2-stat1)

      % figure;
      % histogram(T{groupvar == members(1), datavar}); hold on;
      % histogram(T{groupvar == members(2), datavar});
      % boxchart([fcs1 fcs2])
      % boxchart(scenarios([1 5]), [fcs1 fcs2])
   end

   stats = vertcat(results{:});

   for n = 1:numel(sets)
      % For each set, there can be multiple comparisons. In the test case, I
      % only compare SR to ROS, so below would work, but in general, each
      % "result" will have one p-value and one h-value for each SR vs ROS, LR,
      % etc., wehreas
      stats(n).datavar = datavar;
      stats(n).ingroup = string(members(1));
      stats(n).outgroup = string(members(2:end));
      stats(n).set = string(sets(n));
   end
end
