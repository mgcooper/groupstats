%% Group comparison with groupcompare and groupsamples
%
% This demo compares one group against a reference with groupcompare, one
% titled section per option: the three tests, the reference-relative tail,
% the ConditionVar sets, pooling, and the bootstrap. groupsamples, the
% reshape groupcompare runs first, opens the demo. Each section prints the
% table it builds; the bootstrap section draws one figure.
%
% See also: groupstats.groupcompare, groupstats.groupsamples,
% groupstats.test.generateTestData

% The Info fixture holds one row per scenario, basin, and month, with a
% numeric peak that rises with the scenario. The scenarios are the groups,
% the first one is the reference, and the basins are the condition sets.
data = groupstats.test.generateTestData('info');
Info = data.Info;
reference = data.scenarios(1);

% The bootstrap draws random resamples; seed them so the printed numbers
% repeat from run to run.
rng(1)

%% groupsamples: the data of each group, reference first
%
% groupsamples(tbl, groupvar, datavar) returns one row per member with
% that member's values in a cell, the reference member first. It is the
% table-facing way to hand two samples to a test of your own.

S = groupstats.groupsamples(Info, "scenario", "peak", ...
   ReferenceGroup = reference);
disp(S)
fprintf('%d peaks in the reference sample\n', numel(S.Data{1}))

%% groupcompare: one row per comparison
%
% groupcompare(tbl, groupvar, datavar) tests every other member against
% the reference. The default test is the two-sample rank-sum test. Every
% column is plain: Reference, Group, DataVar, Test, P, and H.

stats = groupstats.groupcompare(Info, "scenario", "peak", ...
   ReferenceGroup = reference);
disp(stats)

%% Test: rank-sum, sign-rank, or permutation
%
% Test names the test and is never inferred from the data. "signrank" is
% the one-sample sign-rank test of each group against the reference
% median. "permutation" is the cluster-based permutation test of the
% vendored permutest, on the two samples as independent trials of one data
% point; NumPermutations sets how many permutations it draws. permutest
% counts the possible permutations with nchoosek, which warns once the two
% samples together hold more than about 56 values, so this section runs on
% the outlet rows alone: twelve peaks per scenario.

outlet = Info(Info.basin == "Outlet", :);
for testname = ["ranksum", "signrank", "permutation"]
   stats = groupstats.groupcompare(outlet, "scenario", "peak", ...
      ReferenceGroup = reference, Test = testname, NumPermutations = 2000);
   disp(stats(:, ["Group", "Test", "P", "H"]))
end

%% Tail: read against the reference
%
% "both" (default) asks whether the medians differ. "right" asks whether
% the reference median is greater, "left" whether it is less, whichever
% test runs. The later scenarios have higher peaks, so "left" is the
% direction with the small p-values.

for tail = ["both", "right", "left"]
   stats = groupstats.groupcompare(Info, "scenario", "peak", ...
      ReferenceGroup = reference, Tail = tail);
   fprintf('Tail = %-5s  P = %s\n', tail, mat2str(stats.P', 3))
end

%% ConditionVar: one block of comparisons per set
%
% ConditionVar names a second grouping variable. The comparisons then run
% once per member of that variable, within its rows, and a Set column
% leads the table. Here each basin is compared on its own.

stats = groupstats.groupcompare(Info, "scenario", "peak", ...
   ReferenceGroup = reference, ConditionVar = "basin");
disp(stats(:, ["Set", "Group", "P", "H"]))

%% Pooled: the reference against every other member combined
%
% Pooled=true pools the non-reference members into one sample, so each set
% has one comparison and Group names the pooled members. Pooling is within
% each ConditionVar set: the sets are what the comparison is conditioned
% on, so there is no option to pool across them. To pool across sets,
% omit ConditionVar, as the second call does.

stats = groupstats.groupcompare(Info, "scenario", "peak", ...
   ReferenceGroup = reference, ConditionVar = "basin", Pooled = true);
disp(stats(:, ["Set", "Group", "P", "H"]))

stats = groupstats.groupcompare(Info, "scenario", "peak", ...
   ReferenceGroup = reference, Pooled = true);
disp(stats(:, ["Group", "P", "H"]))

%% Bootstrap: the signed median difference and its interval
%
% Bootstrap=true adds the bootstrapped median difference, group minus
% reference, with its Alpha confidence interval and HBootstrap, true when
% the interval excludes zero. The second output holds the bootstrapped
% differences, one column per row of stats, for a look at the
% distribution. NumBootstrap sets the resample count.

[stats, samples] = groupstats.groupcompare(Info, "scenario", "peak", ...
   ReferenceGroup = reference, Bootstrap = true, NumBootstrap = 2000);
disp(stats(:, ["Group", "MedianDiff", "CILower", "CIUpper", "HBootstrap"]))

figure
histogram(samples(:, 1), 40)
hold on
xline(stats.MedianDiff(1), "k", LineWidth = 1.5)
xline([stats.CILower(1), stats.CIUpper(1)], "k--")
hold off
xlabel("bootstrapped median difference in peak")
ylabel("count")
title("Bootstrapped median difference, " + stats.Group(1) + " minus " + ...
   stats.Reference(1))
