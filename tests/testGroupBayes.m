function tests = testGroupBayes

% FUNCTIONAL TEST: groupbayes
%
% This functional test ensures that the groupbayes function is working properly.
%
% This test ensures that the function returns the correct results for a
% variety of inputs.

   tests = functiontests(localfunctions);
end

function testDefaultCase(testCase)

% Ensure that the function returns the correct sum for positive numbers
[TestData, Expected] = groupstats.test.generateTestData('groupbayes');

% Use the function groupbayes to calculate conditional probabilities
Actual = groupstats.groupbayes(TestData.T, TestData.groupvar, TestData.groupA, TestData.groupB);

% Verify the function returns the expected result
verifyEqual(testCase, Actual.P_A(:), Expected.P_A(:));
verifyEqual(testCase, Actual.P_B(:), Expected.P_B(:));
end

% function testInputValidation(testCase)
% % Ensure that the function raises an error when given non-scalar inputs
% verifyError(testCase, @()add([1,2],3), "MATLAB:validation:IncompatibleSize");
% 
% % Ensure that the function raises an error when given non-numeric inputs
% verifyError(testCase, @()add(1,"2"), "MATLAB:validators:mustBeNumeric");
% 
% % Ensure that the function raises an error when not given enough input
% % arguments
% verifyError(testCase, @()add(1), "MATLAB:minrhs");
% end