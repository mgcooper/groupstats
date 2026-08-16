function varargout = generateTestData(whichfunction)
   %GENERATETESTDATA Generate data for unit tests, demos, and scripts.
   %
   %  data = groupstats.test.generateTestData(casename)
   %  [data, expected] = groupstats.test.generateTestData(casename)
   %
   % Description
   %  data = GENERATETESTDATA(CASENAME) returns a struct of input data for the
   %  named case. Every field is a ready-to-use argument for the function the
   %  case is named after.
   %
   %  [data, expected] = GENERATETESTDATA(CASENAME) also returns a struct of
   %  expected results, for the cases that define them.
   %
   %  Cases:
   %
   %   "groupbayes" A ten-row event table with two groupA members and two
   %                groupB members. The label set exhausts the table, so the
   %                row-based and column-based population counts agree.
   %   "groupmap"   A struct array of eight grouping cases, one per group
   %                variable type: numeric, categorical, cellstr, logical, a
   %                multi-column result, a repeated group, an extra function
   %                argument, and a plain class-and-size check.
   %   "dropcats"   A two-variable categorical table with one unused category
   %                added to each variable.
   %   "info"       An event table shaped like the icom-msd table this toolbox
   %                was developed against. See the "info" case below for the
   %                variables and for which label sets exhaust the table.
   %   "groupsummary" A table with three group variables and two numeric data
   %                variables, sized so every group holds more than one row.
   %                Serves groupsummary and grouppercent.
   %   "groupdifference" A table with three groups and two condition sets. The
   %                reference group is not the alphabetically first member, and
   %                one set has an all-zero reference. Those two properties
   %                make the reference-group choice and the mixed rank-test
   %                case observable.
   %
   %  This function is the one place test data is defined. Demos and scripts
   %  call it too, so no fixture class or demo may define its own copy.
   %
   % See also: groupstats.test.test_groupbayes, groupstats.test.test_groupmap

   arguments
      whichfunction (1, 1) string
   end

   % One list of case names so the error message cannot drift from the switch.
   knowncases = ["groupbayes", "groupmap", "dropcats", "info", ...
      "groupdifference", "groupsummary"];

   switch lower(whichfunction)

      case 'groupbayes'

         % A table representing events. Each row is one event, labeled by the
         % group it belongs to. Each logical column says whether that event
         % also occurred for the group the column is named after.
         groupvar = 'Group';
         groupA = {'A1', 'A2'};
         groupB = {'B1', 'B2'};
         tbl = table({'A1'; 'A2'; 'B1'; 'B2'; 'A1'; 'B2'; 'A1'; 'B1'; 'A2'; 'B2'}, ...
            [true; false; true; true; true; false; true; false; true; true], ...
            [false; true; true; false; true; true; false; true; false; false], ...
            [true; true; false; false; true; true; false; false; true; true], ...
            [false; false; true; true; false; true; true; false; false; true], ...
            'VariableNames', {groupvar, 'A1', 'A2', 'B1', 'B2'});

         TestData.tbl = tbl;
         TestData.groupvar = groupvar;
         TestData.groupA = groupA;
         TestData.groupB = groupB;
         ExpectedResult.P_A = [0.3 0.3 0.2 0.2];
         ExpectedResult.P_B = [0.2 0.3 0.2 0.3];

         % Expected Result:
         % GroupA    GroupB     P_A       P_B       P_A_AND_B    P_B_GIVEN_A    P_A_GIVEN_B
         % 'A1'      'B1'       0.3       0.2       0.2          0.6667         1.0000
         % 'A1'      'B2'       0.3       0.3       0.1          0.3333         0.3333
         % 'A2'      'B1'       0.2       0.2       0.2          1.0000         1.0000
         % 'A2'      'B2'       0.2       0.3       0            0.0000         0.0000

      case 'groupmap'

         [TestData, ExpectedResult] = groupmapCases();

      case 'dropcats'

         % Two categorical variables, each carrying one category that no row
         % uses. Those are the categories dropcats must remove.
         tbl = table(categorical({'a'; 'b'; 'c'}), categorical({'x'; 'y'; 'z'}));
         tbl.Var1 = addcats(tbl.Var1, 'd');
         tbl.Var2 = addcats(tbl.Var2, 'w');

         expected = tbl;
         expected.Var1 = removecats(expected.Var1, 'd');
         expected.Var2 = removecats(expected.Var2, 'w');

         TestData.tbl = tbl;
         TestData.noncategorical = table(1, 2, 3);
         ExpectedResult.tbl = expected;

      case 'info'

         [TestData, ExpectedResult] = infoCase();

      case 'groupdifference'

         [TestData, ExpectedResult] = groupdifferenceCase();

      case 'groupsummary'

         [TestData, ExpectedResult] = groupsummaryCase();

      otherwise

         error('groupstats:test:generateTestData:unknownCase', ...
            'No test data case named "%s". Known cases: %s.', ...
            whichfunction, strjoin(knowncases, ', '))
   end

   switch nargout
      case 1
         varargout{1} = TestData;
      case 2
         varargout{1} = TestData;
         varargout{2} = ExpectedResult;
   end
end

function [TestData, ExpectedResult] = groupmapCases()
   %GROUPMAPCASES Build the eight groupmap grouping cases.
   %
   % Each case pairs an input table and function handle with the table groupmap
   % must return. Every expected table follows the settled rule for groupmap
   % output: the group column is categorical and comes first, matching
   % groupsummary and groupcounts.

   mean_ = @(t) mean(t.Value);

   % Numeric group variable.
   cases(1).name = "numeric";
   cases(1).tbl = table([1; 2; 1; 2; 3], [10; 20; 30; 40; 50], ...
      'VariableNames', {'Group', 'Value'});
   cases(1).groupvar = 'Group';
   cases(1).fcn = mean_;
   cases(1).args = {};
   cases(1).expected = table(categorical([1; 2; 3]), [20; 30; 50], ...
      'VariableNames', {'Group', 'Var1'});

   % Categorical group variable.
   cases(2).name = "categorical";
   cases(2).tbl = table(categorical({'A'; 'B'; 'A'; 'B'; 'C'}), [1; 2; 3; 4; 5], ...
      'VariableNames', {'Category', 'Value'});
   cases(2).groupvar = 'Category';
   cases(2).fcn = mean_;
   cases(2).args = {};
   cases(2).expected = table(categorical({'A'; 'B'; 'C'}), [2; 3; 5], ...
      'VariableNames', {'Category', 'Var1'});

   % Cell array of char group variable.
   cases(3).name = "cellstr";
   cases(3).tbl = table({'Red'; 'Blue'; 'Red'; 'Green'; 'Blue'}, ...
      [1; 2; 3; 4; 5], 'VariableNames', {'Color', 'Value'});
   cases(3).groupvar = 'Color';
   cases(3).fcn = mean_;
   cases(3).args = {};
   cases(3).expected = table(categorical({'Blue'; 'Green'; 'Red'}), ...
      [3.5; 4; 2], 'VariableNames', {'Color', 'Var1'});

   % Logical group variable.
   cases(4).name = "logical";
   cases(4).tbl = table([true; false; true; false; true], [1; 2; 3; 4; 5], ...
      'VariableNames', {'Flag', 'Value'});
   cases(4).groupvar = 'Flag';
   cases(4).fcn = mean_;
   cases(4).args = {};
   cases(4).expected = table(categorical([false; true]), [3; 3], ...
      'VariableNames', {'Flag', 'Var1'});

   % A function that returns a multi-column table.
   cases(5).name = "multicolumn";
   cases(5).tbl = table({'A'; 'B'; 'A'; 'B'; 'C'}, [1; 2; 3; 4; 5], ...
      'VariableNames', {'Group', 'Value'});
   cases(5).groupvar = 'Group';
   cases(5).fcn = @(t) table(min(t.Value), max(t.Value), mean(t.Value), ...
      'VariableNames', {'Min', 'Max', 'Mean'});
   cases(5).args = {};
   cases(5).expected = table(categorical({'A'; 'B'; 'C'}), [1; 2; 5], ...
      [3; 4; 5], [2; 3; 5], ...
      'VariableNames', {'Group', 'Min', 'Max', 'Mean'});

   % A group that repeats, to confirm rows collapse to one row per member.
   cases(6).name = "repeatedgroup";
   cases(6).tbl = table({'A'; 'B'; 'A'}, [1; 2; 3], ...
      'VariableNames', {'Group', 'Value'});
   cases(6).groupvar = 'Group';
   cases(6).fcn = mean_;
   cases(6).args = {};
   cases(6).expected = table(categorical({'A'; 'B'}), [2; 2], ...
      'VariableNames', {'Group', 'Var1'});

   % An extra argument forwarded to the applied function.
   cases(7).name = "extraargument";
   cases(7).tbl = table({'A'; 'B'; 'A'; 'B'; 'C'}, [1; 2; 3; 4; 5], ...
      'VariableNames', {'Group', 'Value'});
   cases(7).groupvar = 'Group';
   cases(7).fcn = @(t, factor) mean(t.Value) * factor;
   cases(7).args = {2};
   cases(7).expected = table(categorical({'A'; 'B'; 'C'}), [4; 6; 10], ...
      'VariableNames', {'Group', 'Var1'});

   % A function returning a plain array, checked by class and size only.
   cases(8).name = "arrayoutput";
   cases(8).tbl = table({'A'; 'B'; 'A'; 'B'; 'C'}, [1; 2; 3; 4; 5], ...
      'VariableNames', {'Group', 'Value'});
   cases(8).groupvar = 'Group';
   cases(8).fcn = mean_;
   cases(8).args = {};
   cases(8).expected = [3 2]; % size only

   TestData.cases = cases;
   ExpectedResult.cases = cases;
end

function [TestData, ExpectedResult] = groupsummaryCase()
   %GROUPSUMMARYCASE Build a table for groupsummary and grouppercent.
   %
   % Twelve rows over three group variables. Grp has three members of four
   % rows each, Sub has two of six, and Set has two of six. Every group holds
   % more than one row, so a within-group percent differs from a whole-table
   % percent and the two are told apart.
   %
   % Two numeric data variables, so a call that omits datavar has more than
   % one variable to resolve.

   grp = repelem(["a"; "b"; "c"], 4, 1);
   sub = repmat(["x"; "y"], 6, 1);
   set = repelem(["p"; "q"], 6, 1);

   TestData.tbl = table(categorical(grp), categorical(sub), ...
      categorical(set), (1:12)', (101:112)', ...
      'VariableNames', {'Grp', 'Sub', 'Set', 'Value', 'Other'});
   TestData.groupvars = ["Grp", "Sub", "Set"];
   TestData.datavars = ["Value", "Other"];

   ExpectedResult.members.Grp = ["a"; "b"; "c"];
   ExpectedResult.members.Sub = ["x"; "y"];
   ExpectedResult.members.Set = ["p"; "q"];
   ExpectedResult.rowsPerGrp = 4;
   ExpectedResult.height = 12;
end

function [TestData, ExpectedResult] = groupdifferenceCase()
   %GROUPDIFFERENCECASE Build a table with three groups and two condition sets.
   %
   % Two properties make groupdifference's choices observable:
   %
   %  1. The intended reference group is "ctrl", which sorts after "aaa", so
   %     the default reference and the named one differ.
   %  2. Set "s2" holds an all-zero reference, so it takes the signrank path
   %     while set "s1" takes the ranksum path. The per-set results must
   %     concatenate across that difference.

   n = 12;
   group = repmat(["ctrl"; "aaa"; "zzz"], n / 3, 1);
   group = [group; group];
   set = [repmat("s1", n, 1); repmat("s2", n, 1)];

   value = [(1:n)'; zeros(n, 1)];
   value(group == "aaa" & set == "s2") = 5;
   value(group == "zzz" & set == "s2") = 7;

   TestData.tbl = table(categorical(group), categorical(set), value, ...
      'VariableNames', {'Group', 'Set', 'Value'});
   TestData.groupvar = "Group";
   TestData.datavar = "Value";
   TestData.conditionvar = "Set";
   TestData.reference = "ctrl";

   ExpectedResult.alphabeticalReference = "aaa";
   ExpectedResult.members = ["aaa"; "ctrl"; "zzz"];
   ExpectedResult.sets = ["s1"; "s2"];
   ExpectedResult.testnames = ["ranksum"; "signrank"];
end

function [TestData, ExpectedResult] = infoCase()
   %INFOCASE Build an event table shaped like the icom-msd table.
   %
   % The toolbox was developed against an icom-msd table named Info. Several
   % demos and the pairwise groupbayes tests assume it. This is a fabricated
   % stand-in with the same shape, so those files run without icom-msd.
   %
   % Variables:
   %
   %   scenario  categorical, three climate scenario names
   %   basin     categorical, the basin the event row belongs to
   %   month     categorical, ordinal, Jan through Dec
   %   Outlet    logical, true when the event also occurred at that label
   %   basinA    logical, same
   %   basinB    logical, same
   %   basinC    logical, same
   %
   % Label sets: ["Outlet" "basinA" "basinB" "basinC"] exhausts the basin
   % column, so the row-based and column-based population counts agree.
   % ["basinA" "basinB" "basinC"] does not, so the two counts differ. Use the
   % second set to pin how groupbayes counts its population.
   %
   % The data is generated from modular arithmetic, not from rand, so every
   % run produces the same table.

   scenarios = ["1980-2020-WRF-DIST", "SSP245-WARM-NEAR", "SSP585-HOT-FAR"];
   labels = ["Outlet", "basinA", "basinB", "basinC"];
   months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", ...
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

   % One row per scenario, month, and basin label.
   [iScenario, iMonth, iLabel] = ndgrid( ...
      1:numel(scenarios), 1:numel(months), 1:numel(labels));
   iScenario = iScenario(:);
   iMonth = iMonth(:);
   iLabel = iLabel(:);
   nrows = numel(iScenario);

   Info = table();
   Info.scenario = categorical(scenarios(iScenario)', scenarios);
   Info.basin = categorical(labels(iLabel)', labels);
   Info.month = categorical(months(iMonth)', months, 'Ordinal', true);

   % Each label column is true when that label co-occurs with the row's event.
   % A row is always true in its own label column, so the diagonal holds. The
   % off-diagonal pattern varies with scenario and month, which gives the
   % conditional probabilities something to separate.
   for n = 1:numel(labels)
      cooccurs = mod(iMonth + iLabel + n + 2 * iScenario, 3) == 0;
      Info.(labels(n)) = cooccurs | iLabel == n;
   end

   % A deterministic peak magnitude, seasonal and rising with the scenario
   % index. A demo that filters on it gets monthly counts that differ, which
   % a full grid of one row per combination cannot show on its own.
   season = cos(2 * pi * (iMonth - 1) / numel(months));
   Info.peak = 10 + 4 * season + iScenario + 0.5 * iLabel;

   TestData.Info = Info;
   TestData.scenarios = scenarios;
   TestData.basins = labels(2:end);
   TestData.labels = labels;
   TestData.months = months;

   ExpectedResult.height = nrows;
   ExpectedResult.exhaustiveLabels = labels;
   ExpectedResult.nonExhaustiveLabels = labels(2:end);

   % The icom-msd production pattern: one outlet against every subbasin. The
   % two sets are disjoint and together account for every row, so the
   % marginals partition the population.
   ExpectedResult.partitionGroupA = labels(1);
   ExpectedResult.partitionGroupB = labels(2:end);
end
