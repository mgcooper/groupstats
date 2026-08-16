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

         testCase.verifyError(@() groupstats.histogram(randn(20, 1), ...
            MergeGroupMembers = {["a", "b"]}), ...
            'groupstats:histogram:mergeWithoutGroupVar');
      end

      function testExplicitLegendOnIsKept(testCase)
         % One ungrouped group turns the legend off by default. A caller
         % who asks for one outright still gets it.

         [~, L] = groupstats.histogram(randn(20, 1), Legend = "on");

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

         testCase.verifyWarningFree(@() groupstats.histogram(zeros(0, 1)));
      end

      function testUngroupedNumericDataDrawsNoLegend(testCase)
         % histogram(x) is one group, and the built-in shows no legend.
         % With no GroupVar there is one group holding every row, and the
         % legend it would carry says nothing.

         [H, L] = groupstats.histogram(randn(50, 1));

         testCase.verifyTrue(isgraphics(H));
         testCase.verifyEmpty(L);
      end

      function testUngroupedTableVariableDrawsNoLegend(testCase)
         % The same path, reached through a table and a variable name.

         tbl = table(randn(30, 1), 'VariableNames', {'Value'});

         [H, L] = groupstats.histogram(tbl, "Value");

         testCase.verifyTrue(isgraphics(H));
         testCase.verifyEmpty(L);
      end

      function testUngroupedLegendStringStillDrawsALegend(testCase)
         % Turning the legend off for one group must not override a caller
         % who named the entry.

         [~, L] = groupstats.histogram(randn(30, 1), ...
            LegendString = "MySeries");

         testCase.verifyNotEmpty(L);
      end

      function testLegendOffReturnsNoLegend(testCase)
         % The other three charts take Legend="off". Its absence here also
         % made the name ambiguous against LegendString and
         % LegendOrientation.

         data = groupstats.test.generateTestData('info');

         [~, L] = groupstats.histogram(data.Info, "month", ...
            GroupVar = "scenario", Legend = "off");

         testCase.verifyEmpty(L);
      end


      function testAcceptsAnArrayLikeTheBuiltIn(testCase)
         % histogram(x) is the built-in's call shape. Supporting it means a
         % caller does not have to build a table for the simple case.

         data = groupstats.test.generateTestData('info');

         H = groupstats.histogram(data.Info.month);

         % A categorical histogram is its own class, so check the handle
         % rather than name a class.
         testCase.verifyTrue(isgraphics(H));
         testCase.verifyEqual(numel(H.BinCounts), ...
            numel(categories(removecats(data.Info.month))));
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
            GroupVar = "scenario");

         returned = numel(H);
         expected = numel(unique(testCase.Info.scenario));
         testCase.verifyEqual(returned, expected);
      end

      function testGroupedModeReturnsALegend(testCase)
         % The legend covers the groups.

         [~, L] = groupstats.histogram(testCase.Info, "month", ...
            GroupVar = "scenario");

         testCase.verifyClass(L, 'matlab.graphics.illustration.Legend');
      end

      function testGroupMembersRestrictTheGroups(testCase)
         % Naming members keeps only their rows, so only they get a bar set.

         members = testCase.Scenarios(1:2);
         H = groupstats.histogram(testCase.Info, "month", ...
            GroupVar = "scenario", GroupMembers = members);

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
            GroupVar = "scenario", MergeGroupMembers = {merged});

         returned = numel(H);
         expected = numel(testCase.Scenarios) - 1;
         testCase.verifyEqual(returned, expected);
      end

      function testMergingKeepsACallerNamedLegendString(testCase)
         % The default legend text is built from the group members. Building
         % it before the merge named the unmerged groups, so the merge path
         % overwrote it, and a caller who named LegendString lost their text.
         % The default is built after the merge instead.

         merged = testCase.Scenarios(1:2);

         [~, L] = groupstats.histogram(testCase.Info, "month", ...
            GroupVar = "scenario", MergeGroupMembers = {merged}, ...
            LegendString = ["MERGED"; "OTHER"]);

         returned = string(L.String{1});
         expected = "MERGED";
         testCase.verifyEqual(returned, expected);
      end

      function testMergeGroupMembersNamesTheMergedGroup(testCase)
         % The merged group takes the joined member names.

         merged = testCase.Scenarios(1:2);
         [~, L] = groupstats.histogram(testCase.Info, "month", ...
            GroupVar = "scenario", MergeGroupMembers = {merged});

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

         [H, L] = groupstats.histogram(tbl, "v", GroupVar = "g", ...
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
