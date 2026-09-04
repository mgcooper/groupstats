classdef test_dropcats < matlab.unittest.TestCase
   %TEST_DROPCATS Test groupstats.dropcats.
   %
   % dropcats removes categories that no row of a table variable uses. These
   % cases cover the three ways to name the variables and every documented
   % error identifier.
   %
   % See also: groupstats.dropcats, groupstats.test.generateTestData

   properties
      % The input table and the table dropcats must return. The names avoid
      % the bare word "expected" so a test body can use it for the value it
      % compares against, as STYLE.md requires.
      InputTable
      ExpectedTable
      % A table with no categorical variable, for the error case.
      NonCategoricalTable
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         % Fetch the shared fixture. Each test gets a fresh copy so one test
         % cannot mutate another's table.
         [data, expectedData] = groupstats.test.generateTestData('dropcats');
         testCase.InputTable = data.tbl;
         testCase.NonCategoricalTable = data.noncategorical;
         testCase.ExpectedTable = expectedData.tbl;
      end
   end

   methods (Test)

      function testOneVariableName(testCase)
         % Naming one variable drops that variable's unused category only.

         returned = groupstats.dropcats(testCase.InputTable, 'Var1');

         expected = testCase.ExpectedTable.Var1;
         testCase.verifyEqual(returned.Var1, expected);
      end

      function testOneVariableNameLeavesOthers(testCase)
         % Naming one variable leaves the other variable untouched.

         returned = groupstats.dropcats(testCase.InputTable, 'Var1');

         expected = testCase.InputTable.Var2;
         testCase.verifyEqual(returned.Var2, expected);
      end

      function testMultipleVariableNames(testCase)
         % Naming both variables drops both unused categories.

         returned = groupstats.dropcats(testCase.InputTable, ["Var1", "Var2"]);

         expected = testCase.ExpectedTable;
         testCase.verifyEqual(returned, expected);
      end

      function testDefaultVariableNames(testCase)
         % With no variable named, dropcats treats every categorical variable.

         returned = groupstats.dropcats(testCase.InputTable);

         expected = testCase.ExpectedTable;
         testCase.verifyEqual(returned, expected);
      end

      function testUnknownVariableNameErrors(testCase)
         % A variable name the table does not carry is an error, not a no-op.

         testCase.verifyError( ...
            @() groupstats.dropcats(testCase.InputTable, 'Var3'), ...
            'groupstats:dropcats:badVariableName');
      end

      function testNonTextVariableNameErrors(testCase)
         % A numeric variable name reports the same identifier as an unknown
         % name, because both fail the same name lookup.

         testCase.verifyError( ...
            @() groupstats.dropcats(testCase.InputTable, 123), ...
            'groupstats:dropcats:badVariableName');
      end

      function testNonCategoricalVariableErrors(testCase)
         % Naming a variable that is not categorical is an error.

         testCase.verifyError( ...
            @() groupstats.dropcats(testCase.NonCategoricalTable, 'Var1'), ...
            'groupstats:dropcats:nonCategoricalVar');
      end

      function testNonTableInputErrors(testCase)
         % The first argument must convert to a table.

         testCase.verifyError( ...
            @() groupstats.dropcats('invalid', 'Var1'), ...
            'MATLAB:validation:UnableToConvert');
      end

      function testTooManyInputsErrors(testCase)
         % dropcats takes at most two arguments.

         testCase.verifyError( ...
            @() groupstats.dropcats(testCase.InputTable, 'Var1', 123), ...
            'MATLAB:TooManyInputs');
      end

      function testNoInputsErrors(testCase)
         % The table argument is required.

         testCase.verifyError(@() groupstats.dropcats(), 'MATLAB:minrhs');
      end
   end
end
