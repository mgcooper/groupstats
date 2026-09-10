classdef test_histogram < matlab.unittest.TestCase
   %TEST_HISTOGRAM Test groupstats.histogram.
   %
   % These cases pin the behavior groupstats.histogram is required to have:
   %
   %  1. The MergeGroupMembers path read an Opts.MergeGroups field that does
   %     not exist, and indexed columns of a column vector.
   %  2. The categorical branch left L undefined, so asking for two outputs
   %     errored.
   %  3. Only the last group's handle came back, while the legend covered
   %     every group.
   %  4. Formatting went to gca rather than to Opts.Parent.
   %  5. A categorical data variable was converted to double before plotting,
   %     so numeric-like categories produced a binned histogram.
   %
   % See also: groupstats.histogram

   properties
      Info
      Scenarios
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure);
         data = groupstats.test.generateTestData('info');
         testCase.Info = data.Info;
         testCase.Scenarios = data.scenarios;
      end
   end

   methods (Test)
      function testMergeWithoutGroupVarIsReported(testCase)
         % Merging pools members of the group variable. Without one the
         % request had no effect, and nothing said so.

         tbl = table(randn(20, 1), 'VariableNames', {'Value'});

         testCase.verifyError(@() groupstats.histogram(tbl, "Value", ...
            MergeGroupMembers = {["a", "b"]}), ...
            'groupstats:histogram:mergeWithoutGroupVar');
      end

      function testExplicitLegendOnIsKept(testCase)
         % One ungrouped group turns the legend off by default. A caller
         % who asks for one outright still gets it.

         tbl = table(randn(20, 1), 'VariableNames', {'Value'});

         [~, L] = groupstats.histogram(tbl, "Value", Legend = "on");

         testCase.verifyNotEmpty(L);
      end

      function testGroupMembersWithoutGroupVarIsReported(testCase)
         % prepareTableGroups reports this pair as XGroupVar and
         % XGroupMembers, which name nothing this function documents.

         data = groupstats.test.generateTestData('info');

         testCase.verifyError(@() groupstats.histogram(data.Info, ...
            "peak", GroupMembers = "basinA"), ...
            'groupstats:histogram:membersWithoutGroupVar');
      end

      function testNumericSecondArgumentIsReported(testCase)
         % The built-in reads it as a bin count or bin edges. Treating it
         % as a category name would fail somewhere further in.

         testCase.verifyError(@() groupstats.histogram(randn(20, 1), 10), ...
            'groupstats:histogram:numericBinsNotSupported');
      end

      function testEmptyDataDoesNotError(testCase)
         % The built-in accepts empty data and returns a Histogram, so a
         % caller plotting a filtered subset that came out empty gets an
         % empty chart rather than an error.

         tbl = table(zeros(0, 1), 'VariableNames', {'Value'});

         testCase.verifyWarningFree(@() groupstats.histogram(tbl, "Value"));
      end

      function testUngroupedTableVariableDrawsNoLegend(testCase)
         % A call with no groupvar is one group holding every row, and the
         % built-in shows no legend for one series. The legend it would
         % carry says nothing.

         tbl = table(randn(30, 1), 'VariableNames', {'Value'});

         [H, L] = groupstats.histogram(tbl, "Value");

         testCase.verifyTrue(isgraphics(H));
         testCase.verifyEmpty(L);
      end

      function testUngroupedLegendStringStillDrawsALegend(testCase)
         % Turning the legend off for one group must not override a caller
         % who named the entry.

         tbl = table(randn(30, 1), 'VariableNames', {'Value'});

         [~, L] = groupstats.histogram(tbl, "Value", ...
            LegendString = "MySeries");

         testCase.verifyNotEmpty(L);
      end

      function testLegendOffReturnsNoLegend(testCase)
         % The other three charts take Legend="off". Its absence here also
         % made the name ambiguous against LegendString and
         % LegendOrientation.

         data = groupstats.test.generateTestData('info');

         [~, L] = groupstats.histogram(data.Info, "month", ...
            "scenario", Legend = "off");

         testCase.verifyEmpty(L);
      end


      function testDataVariableIsRequired(testCase)
         % datavar is required so that MATLAB never reads it as a
         % name-value name. An optional text positional followed by
         % groupvar would let histogram(tbl, "Data", "g") become
         % DataTipTemplate = "g" with no error.

         data = groupstats.test.generateTestData('info');

         testCase.verifyError(@() groupstats.histogram(data.Info), ...
            'MATLAB:minrhs');
      end

      function testAPropertyLikeGroupNameIsReadAsTheGrouping(testCase)
         % A grouping variable named like a Histogram property is the last
         % positional argument, and MATLAB reads it as groupvar, alone or
         % ahead of name-value options. Only a second optional text
         % positional after it could turn it into a name, and this
         % signature has none.

         v = (1:6)';
         Tag = categorical(["a"; "a"; "a"; "b"; "b"; "b"]);
         tbl = table(v, Tag, 'VariableNames', {'v', 'Tag'});

         H = groupstats.histogram(tbl, "v", "Tag", SortBy = "descend");

         returned = numel(H);
         expected = 2;
         testCase.verifyEqual(returned, expected);

         returned = string(H(1).Tag);
         expected = "";
         testCase.verifyEqual(returned, expected);

         % The same with the comma pair syntax, where the pairs after
         % groupvar are plain text too.
         H = groupstats.histogram(tbl, "v", "Tag", 'NumBins', 3, ...
            'Visible', 'on');

         returned = numel(H);
         expected = 2;
         testCase.verifyEqual(returned, expected);

         returned = string(H(1).Tag);
         expected = "";
         testCase.verifyEqual(returned, expected);

         returned = H(1).NumBins;
         expected = 3;
         testCase.verifyEqual(returned, expected);
      end

      function testAShortDataVariableNameIsNotReadAsAProperty(testCase)
         % "t" is a prefix of the Tag property. With the required datavar
         % it is the data variable, and "g" is the grouping.

         t = (1:6)';
         g = categorical(["a"; "a"; "a"; "b"; "b"; "b"]);
         tbl = table(t, g, 'VariableNames', {'t', 'g'});

         H = groupstats.histogram(tbl, "t", "g");

         returned = numel(H);
         expected = 2;
         testCase.verifyEqual(returned, expected);
      end

      function testAcceptsAnArrayAndCategories(testCase)
         % histogram(x, categories) keeps only those categories.

         data = groupstats.test.generateTestData('info');
         members = {'Jan', 'Feb', 'Mar'};

         H = groupstats.histogram(data.Info.month, members);

         testCase.verifyEqual(numel(H.BinCounts), numel(members));
      end

      function testCategoriesGivenTwiceIsRejected(testCase)
         % Positional categories and GroupMembers mean the same thing, so
         % taking both would leave the caller guessing which one won.

         data = groupstats.test.generateTestData('info');

         testCase.verifyError(@() groupstats.histogram(data.Info.month, ...
            {'Jan'}, GroupMembers = {'Feb'}), ...
            'groupstats:histogram:categoriesGivenTwice');
      end


      function testCategoricalModeReturnsOneHistogram(testCase)
         % With no group variable the data variable itself defines the bars.

         H = groupstats.histogram(testCase.Info, "month");

         % Categorical data gives the categorical Histogram class, which is
         % distinct from the numeric one.
         testCase.verifyClass(H, ...
            'matlab.graphics.chart.primitive.categorical.Histogram');
         testCase.verifyNumElements(H, 1);
      end

      function testCategoricalDataStaysCategorical(testCase)
         % A categorical data variable whose categories are numeric-like text
         % must stay categorical. Converting it to double turns discrete
         % category bars into a continuous binned histogram, with no report.

         tbl = table(categorical(["1"; "2"; "1"; "3"]), ...
            'VariableNames', {'code'});

         H = groupstats.histogram(tbl, "code");

         testCase.verifyClass(H.Data, 'categorical');
      end

      function testCategoricalModeReturnsTwoOutputs(testCase)
         % The legend handle was never assigned on this branch, so asking for
         % it errored on an undefined variable.

         [H, L] = groupstats.histogram(testCase.Info, "month");

         testCase.verifyNotEmpty(H);
         testCase.verifyEmpty(L);
      end

      function testGroupedModeReturnsOneHistogramPerGroup(testCase)
         % Every group's handle comes back, not only the last one.

         H = groupstats.histogram(testCase.Info, "month", ...
            "scenario");

         returned = numel(H);
         expected = numel(unique(testCase.Info.scenario));
         testCase.verifyEqual(returned, expected);
      end

      function testGroupedModeReturnsALegend(testCase)
         % The legend covers the groups.

         [~, L] = groupstats.histogram(testCase.Info, "month", ...
            "scenario");

         testCase.verifyClass(L, 'matlab.graphics.illustration.Legend');
      end

      function testGroupMembersRestrictTheGroups(testCase)
         % Naming members keeps only their rows, so only they get a bar set.

         members = testCase.Scenarios(1:2);
         H = groupstats.histogram(testCase.Info, "month", ...
            "scenario", GroupMembers = members);

         returned = numel(H);
         expected = numel(members);
         testCase.verifyEqual(returned, expected);
      end

      function testMergeGroupMembersPoolsThem(testCase)
         % Merging two members leaves one group where there were two. The
         % merge read a field that does not exist and indexed columns of a
         % column vector, so it could never run.

         merged = testCase.Scenarios(1:2);
         H = groupstats.histogram(testCase.Info, "month", ...
            "scenario", MergeGroupMembers = {merged});

         returned = numel(H);
         expected = numel(testCase.Scenarios) - 1;
         testCase.verifyEqual(returned, expected);
      end

      function testThirdOutputIsTheAxes(testCase)
         % The family signature is (H, L, ax), and the third output is the
         % axes the chart was drawn into.

         [~, ~, ax] = groupstats.histogram(testCase.Info, "peak", ...
            "scenario");

         testCase.verifyTrue(isgraphics(ax, 'axes'));
      end

      function testFourOutputsAreRejected(testCase)
         % H, L, and the axes are the only outputs.

         testCase.verifyError( ...
            @() fourHistOutputs(testCase.Info), ...
            'MATLAB:nargoutchk:tooManyOutputs');
      end

      function testMergedGroupOrderNamesTheMergedLabel(testCase)
         % GroupOrder reads post-merge names, so the merged label moves
         % its pooled group to the front and the legend follows.

         merged = testCase.Scenarios(2:3);
         label = strjoin(merged, " and ");

         [~, L] = groupstats.histogram(testCase.Info, "peak", ...
            "scenario", MergeGroupMembers = {merged}, ...
            GroupOrder = label);

         returned = string(L.String(1));
         expected = label;
         testCase.verifyEqual(returned, expected);
      end

      function testCategoricalMergeSortsByPooledCounts(testCase)
         % SortBy reads post-merge categories, so the pooled bar sorts by
         % its combined count.

         H = groupstats.histogram(testCase.Info, "month", ...
            MergeGroupMembers = {["Jan", "Feb"]}, SortBy = "descend");

         % Every month has equal counts, so the pooled pair leads.
         cats = string(categories(H.Data));
         returned = cats(1);
         expected = "Jan and Feb";
         testCase.verifyEqual(returned, expected);
      end

      function testSortByOrdersTheGroups(testCase)
         % SortBy orders the groups by the group mean of the data variable,
         % and the legend follows the draw order.

         [~, L] = groupstats.histogram(testCase.Info, "peak", ...
            "scenario", SortBy = "descend");

         G = groupsummary(testCase.Info, "scenario", "mean", "peak");
         [~, order] = sort(G.mean_peak, "descend");

         returned = string(L.String(:));
         expected = string(G.scenario(order));
         testCase.verifyEqual(returned, expected);
      end

      function testSortByOrdersDatetimeGroups(testCase)
         % A datetime data variable survives preparation, and SortBy must
         % order its groups by the group mean without converting the type,
         % because double() of datetime is not defined.

         g = categorical(["early"; "early"; "late"; "late"]);
         t = datetime(2020, 1, [1; 3; 20; 22]);
         tbl = table(g, t, 'VariableNames', {'g', 't'});

         [~, L] = groupstats.histogram(tbl, "t", "g", ...
            SortBy = "descend");

         returned = string(L.String(:));
         expected = ["late"; "early"];
         testCase.verifyEqual(returned, expected);
      end

      function testCategoricalSortByOrdersByCounts(testCase)
         % In categorical mode there is no data variable to average, so
         % SortBy orders the categories by their counts.

         g = categorical([ ...
            "Rare"; "Common"; "Common"; "Common"; "Common"; ...
            "Middle"; "Middle"]);
         tbl = table(g, 'VariableNames', {'g'});

         H = groupstats.histogram(tbl, "g", SortBy = "descend");

         returned = string(categories(H.Data));
         expected = ["Common"; "Middle"; "Rare"];
         testCase.verifyEqual(returned, expected);
      end

      function testGroupOrderBeatsSortBy(testCase)
         % GroupOrder is a partial order that wins over SortBy: the named
         % member comes first, and the rest keep their order.

         merged = testCase.Scenarios(3);

         [~, L] = groupstats.histogram(testCase.Info, "peak", ...
            "scenario", GroupOrder = merged, ...
            SortBy = "ascend");

         returned = string(L.String(1));
         expected = merged;
         testCase.verifyEqual(returned, expected);
      end

      function testCategoricalMergePoolsCategories(testCase)
         % The categorical call shape merges through the shared helper, so
         % the named categories pool into one bar at the first member's
         % category position. Bead groupstats-9gv requires this shape to
         % pool rather than ignore the request, and the
         % mergeWithoutGroupVar guard must not raise an error or warning
         % here.

         H = testCase.verifyWarningFree(@() groupstats.histogram( ...
            testCase.Info, "month", MergeGroupMembers = {["Jan", "Feb"]}));

         cats = string(categories(H.Data));
         returned = numel(cats);
         expected = 11;
         testCase.verifyEqual(returned, expected);

         returned = cats(1);
         expected = "Jan and Feb";
         testCase.verifyEqual(returned, expected);

         % The merged bar holds every Jan and Feb row.
         returned = sum(H.Data == "Jan and Feb");
         expected = sum(testCase.Info.month == "Jan") + ...
            sum(testCase.Info.month == "Feb");
         testCase.verifyEqual(returned, expected);
      end

      function testMergingKeepsACallerNamedLegendString(testCase)
         % The default legend text is built from the group members. Building
         % it before the merge named the unmerged groups, so the merge path
         % overwrote it, and a caller who named LegendString lost their text.
         % The default is built after the merge instead.

         merged = testCase.Scenarios(1:2);

         [~, L] = groupstats.histogram(testCase.Info, "month", ...
            "scenario", MergeGroupMembers = {merged}, ...
            LegendString = ["MERGED"; "OTHER"]);

         returned = string(L.String{1});
         expected = "MERGED";
         testCase.verifyEqual(returned, expected);
      end

      function testMergeGroupMembersNamesTheMergedGroup(testCase)
         % The merged group takes the joined member names.

         merged = testCase.Scenarios(1:2);
         [~, L] = groupstats.histogram(testCase.Info, "month", ...
            "scenario", MergeGroupMembers = {merged});

         returned = string(L.String);
         testCase.verifyTrue(any(returned == strjoin(merged, " and ")));
      end

      function testMergedLegendLabelsMatchTheirBars(testCase)
         % legend assigns entries to objects in creation order, and
         % createHistogram creates them in unique(XData) order. Building the
         % entries in any other order labels the wrong bars, which no error
         % reports.

         grp = repelem(["Zebra"; "Apple"; "Mango"], 4, 1);
         tbl = table(categorical(grp), (1:12)', ...
            'VariableNames', {'g', 'v'});

         [H, L] = groupstats.histogram(tbl, "v", "g", ...
            MergeGroupMembers = {["Apple", "Mango"]});

         % The merged group holds the Apple and Mango rows, values 5 to 12.
         merged = string(L.String) == "Apple and Mango";
         returned = [min(H(merged).Data) max(H(merged).Data)];
         expected = [5 12];
         testCase.verifyEqual(returned, expected);
      end

      function testParentIsHonored(testCase)
         % The chart goes to the named axes, and so does the formatting.

         ax = axes(figure('Visible', 'off'));
         cleanup = onCleanup(@() close(ax.Parent));

         H = groupstats.histogram(testCase.Info, "month", Parent = ax);

         returned = ancestor(H(1), 'axes');
         testCase.verifyEqual(returned, ax);
         testCase.verifyEqual(string(ax.XMinorTick), "on");
      end

      function testTwoGroupVariablesAreRejected(testCase)
         % groupvar names one grouping or none.

         testCase.verifyError(@() groupstats.histogram(testCase.Info, ...
            "month", ["scenario", "basin"]), ...
            'MATLAB:validators:mustBeScalarOrEmpty');
      end

      function testGroupVarWithArrayInputIsReported(testCase)
         % An array call has no table for groupvar to name a variable of.

         testCase.verifyError(@() groupstats.histogram((1:5)', ...
            string.empty(), "g"), ...
            'groupstats:histogram:groupVarWithArrayInput');
      end

      function testHistogramPropertiesPassThrough(testCase)
         % A Histogram property named in the call reaches the object.

         H = groupstats.histogram(testCase.Info, "month", ...
            Normalization = "probability");

         returned = string(H(1).Normalization);
         expected = "probability";
         testCase.verifyEqual(returned, expected);
      end
   end
end

function fourHistOutputs(Info)
   %FOURHISTOUTPUTS Ask histogram for a fourth output.
   %
   % Written as a function so the call is a statement, which is the only
   % place a four-output request is syntactically valid.

   [~, ~, ~, ~] = groupstats.histogram(Info, "peak", "scenario");
end
