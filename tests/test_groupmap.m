classdef test_groupmap < matlab.unittest.TestCase
   %TEST_GROUPMAP Test groupstats.groupmap.
   %
   % These cases pin the settled rule for groupmap output. The group column
   % is categorical and comes first in the returned table. That matches
   % MATLAB's own groupsummary and groupcounts.
   %
   % The eight grouping cases differ only in the type of the group variable
   % and the shape of the applied function's result. They run as one
   % parameterized test rather than eight near-copies.
   %
   % See also: groupstats.groupmap, groupstats.test.generateTestData

   properties (TestParameter)
      % One parameter per grouping case. The case data lives in
      % generateTestData so demos and scripts can use the same tables.
      groupcase = buildGroupCases()
   end

   methods (Test)

      function testGroupResult(testCase, groupcase)
         % Apply the case's function and compare against its expected table.

         returned = groupstats.groupmap(groupcase.tbl, groupcase.groupvar, ...
            groupcase.fcn, groupcase.args{:});

         if isnumeric(groupcase.expected)
            % The array-output case checks only class and size, because the
            % point is that groupmap wraps a non-table result in a table.
            testCase.verifyClass(returned, 'table');
            testCase.verifySize(returned, groupcase.expected);
         else
            expected = groupcase.expected;
            testCase.verifyEqual(returned, expected);
         end
      end

      function testGroupColumnIsFirst(testCase, groupcase)
         % The group column comes first. This is the rule that separates the
         % settled behavior from appending the group column last.

         returned = groupstats.groupmap(groupcase.tbl, groupcase.groupvar, ...
            groupcase.fcn, groupcase.args{:});

         expected = groupcase.groupvar;
         testCase.verifyEqual(returned.Properties.VariableNames{1}, expected);
      end

      function testOrdinalGroupKeepsItsOrder(testCase)
         % An ordinal group variable keeps its Ordinal flag and its category
         % order, so a relational comparison on the returned column works.
         % Rewrapping an already-categorical value in categorical() would
         % reset both.

         months = ["Mar", "Jan", "Feb", "Jan", "Mar"];
         order = ["Jan", "Feb", "Mar"];
         tbl = table( ...
            categorical(months(:), order, 'Ordinal', true), ...
            [1; 2; 3; 4; 5], 'VariableNames', {'Month', 'Value'});

         returned = groupstats.groupmap(tbl, 'Month', @(t) mean(t.Value));

         testCase.verifyTrue(isordinal(returned.Month));
         testCase.verifyEqual(categories(returned.Month), cellstr(order(:)));
         testCase.verifyEqual(nnz(returned.Month < "Mar"), 2);
      end

      function testUnusedCategoriesSurvive(testCase)
         % A categorical group variable keeps the categories no row uses.
         % groupsummary keeps them too, and dropcats is the function that
         % removes them on request.

         tbl = table(categorical({'a'; 'b'}), [1; 2], ...
            'VariableNames', {'Group', 'Value'});
         tbl.Group = addcats(tbl.Group, 'c');

         returned = groupstats.groupmap(tbl, 'Group', @(t) mean(t.Value));

         expected = {'a'; 'b'; 'c'};
         testCase.verifyEqual(categories(returned.Group), expected);
      end

      function testNameConflictErrors(testCase, groupcase)
         % A function that returns a variable named like the group variable is
         % an error. Inserting the group column over it would drop its data.

         conflicting = @(t, varargin) table(mean(t.Value), ...
            'VariableNames', {groupcase.groupvar});

         testCase.verifyError( ...
            @() groupstats.groupmap(groupcase.tbl, groupcase.groupvar, ...
            conflicting), ...
            'groupstats:groupmap:groupVariableNameConflict');
      end

      function testGroupColumnIsCategorical(testCase, groupcase)
         % The group column is coerced to categorical whatever its input type.
         % The docstring promises this and scenarioDeltas' numeric-variable
         % sweep depends on it.

         returned = groupstats.groupmap(groupcase.tbl, groupcase.groupvar, ...
            groupcase.fcn, groupcase.args{:});

         testCase.verifyClass(returned.(groupcase.groupvar), 'categorical');
      end
   end
end

function cases = buildGroupCases()
   %BUILDGROUPCASES Return the grouping cases as a name-keyed struct.
   %
   % matlab.unittest names each parameterized run after the field name, so the
   % cases are keyed by their case name rather than indexed.

   data = groupstats.test.generateTestData('groupmap');
   cases = struct();
   for n = 1:numel(data.cases)
      cases.(data.cases(n).name) = data.cases(n);
   end
end
