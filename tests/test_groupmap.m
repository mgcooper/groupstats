function tests = test_groupmap()
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   % Add the directory containing groupmap to the path
   testCase.TestData.origPath = path;
   addpath(fileparts(which('groupmap')));
end

function teardownOnce(testCase)
   % Restore the original path
   path(testCase.TestData.origPath);
end

% THESE ARE FAILING - NEED TO CONFIRM HOW TO COMPARE EQUALITY OF TABLES
% also, had to use reordervars to make the vars be in alphabetical order, may
% need to do the same to all other tests.

function testNumericGrouping(testCase)
   T = table([1;2;1;2;3], [10;20;30;40;50], 'VariableNames', {'Group', 'Value'});
   fcn = @(t) mean(t.Value);
   result = groupmap(T, 'Group', fcn);
   result = reordervars(result, sort(result.Properties.VariableNames));

   expected = table([1;2;3], [20;30;50], 'VariableNames', {'Group', 'Var1'});
   testCase.verifyEqual(result, expected);
end

function testCategoricalGrouping(testCase)
   T = table(categorical({'A';'B';'A';'B';'C'}), [1;2;3;4;5], ...
      'VariableNames', {'Category', 'Value'});
   fcn = @(t) mean(t.Value);
   result = groupmap(T, 'Category', fcn);

   expected = table(categorical({'A';'B';'C'}), [2;3;5], 'VariableNames', {'Category', 'Var1'});
   testCase.verifyEqual(result, expected);
end

function testCellArrayGrouping(testCase)
   T = table({'Red';'Blue';'Red';'Green';'Blue'}, [1;2;3;4;5], 'VariableNames', {'Color', 'Value'});
   fcn = @(t) mean(t.Value);
   result = groupmap(T, 'Color', fcn);

   expected = table({'Blue';'Green';'Red'}, [3.5;4;2], 'VariableNames', {'Color', 'Var1'});
   testCase.verifyEqual(result, expected);
end

function testLogicalGrouping(testCase)
   T = table([true;false;true;false;true], [1;2;3;4;5], 'VariableNames', {'Flag', 'Value'});
   fcn = @(t) mean(t.Value);
   result = groupmap(T, 'Flag', fcn);

   expected = table([false;true], [3;3], 'VariableNames', {'Flag', 'Var1'});
   testCase.verifyEqual(result, expected);
end

function testCustomFunction(testCase)
   T = table({'A';'B';'A';'B';'C'}, [1;2;3;4;5], 'VariableNames', {'Group', 'Value'});
   fcn = @(t) table(min(t.Value), max(t.Value), mean(t.Value), 'VariableNames', {'Min', 'Max', 'Mean'});
   result = groupmap(T, 'Group', fcn);

   expected = table({'A';'B';'C'}, [1;2;5], [3;4;5], [2;3;5], 'VariableNames', {'Group', 'Min', 'Max', 'Mean'});
   testCase.verifyEqual(result, expected);
end

function testEmptyGroup(testCase)
   T = table({'A';'B';'A'}, [1;2;3], 'VariableNames', {'Group', 'Value'});
   fcn = @(t) mean(t.Value);
   result = groupmap(T, 'Group', fcn);

   expected = table({'A';'B'}, [2;2], 'VariableNames', {'Group', 'Var1'});
   testCase.verifyEqual(result, expected);
end

function testAdditionalArguments(testCase)
   T = table({'A';'B';'A';'B';'C'}, [1;2;3;4;5], 'VariableNames', {'Group', 'Value'});
   fcn = @(t, factor) mean(t.Value) * factor;
   result = groupmap(T, 'Group', fcn, 2);

   expected = table({'A';'B';'C'}, [4;6;10], 'VariableNames', {'Group', 'Var1'});
   testCase.verifyEqual(result, expected);
end

function testNonTableOutput(testCase)
   T = table({'A';'B';'A';'B';'C'}, [1;2;3;4;5], 'VariableNames', {'Group', 'Value'});
   fcn = @(t) mean(t.Value);
   result = groupmap(T, 'Group', fcn);

   testCase.verifyClass(result, 'table');
   testCase.verifySize(result, [3 2]);
end
