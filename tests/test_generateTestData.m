classdef test_generateTestData < matlab.unittest.TestCase
   %TEST_GENERATETESTDATA Test groupstats.test.generateTestData.
   %
   % The fixture generator is test infrastructure, so a defect in it makes
   % every other test lie. These cases pin the case list, the error for an
   % unknown case, and the two properties of the Info fixture that other tests
   % rely on: it is deterministic, and one label set exhausts its group column
   % while the other does not.
   %
   % See also: groupstats.test.generateTestData

   properties (TestParameter)
      % Every case name the generator documents. Keep this list equal to the
      % generator's knowncases, which the last test in this file checks.
      casename = {'groupbayes', 'groupmap', 'dropcats', 'info', ...
         'groupdifference', 'groupsummary'}
   end

   methods (Test)

      function testEveryCaseReturnsData(testCase, casename)
         % Every documented case returns a non-empty struct of inputs.

         returned = groupstats.test.generateTestData(casename);

         testCase.verifyClass(returned, 'struct');
         testCase.verifyNotEmpty(fieldnames(returned));
      end

      function testEveryCaseReturnsExpected(testCase, casename)
         % Every documented case also returns a struct of expected results.

         [~, returned] = groupstats.test.generateTestData(casename);

         testCase.verifyClass(returned, 'struct');
         testCase.verifyNotEmpty(fieldnames(returned));
      end

      function testZeroOutputCallIsAccepted(testCase, casename)
         % A call that requests no output assigns nothing and raises nothing.
         % Demos call the generator this way while exploring.

         testCase.verifyWarningFree( ...
            @() groupstats.test.generateTestData(casename));
      end

      function testUnknownCaseErrors(testCase)
         % An unrecognized case name errors instead of falling through to an
         % unassigned output, which is what the switch did without an
         % otherwise branch.

         testCase.verifyError( ...
            @() groupstats.test.generateTestData('nosuchcase'), ...
            'groupstats:test:generateTestData:unknownCase');
      end

      function testGroupmapCaseCount(testCase)
         % The groupmap case list feeds a parameterized test, so its length is
         % part of that test's coverage.

         data = groupstats.test.generateTestData('groupmap');

         returned = numel(data.cases);
         expected = 8;
         testCase.verifyEqual(returned, expected);
      end

      function testInfoIsDeterministic(testCase)
         % Two calls return the same table. The fixture uses modular
         % arithmetic rather than rand for this reason.

         first = groupstats.test.generateTestData('info');
         second = groupstats.test.generateTestData('info');

         returned = second.Info;
         expected = first.Info;
         testCase.verifyEqual(returned, expected);
      end

      function testInfoHasEveryLabelColumn(testCase)
         % Every label in the basin column also names a logical column. That
         % pairing is what lets groupbayes read the table both by row label
         % and by column.

         data = groupstats.test.generateTestData('info');

         for label = data.labels
            testCase.verifyTrue(ismember(label, ...
               string(data.Info.Properties.VariableNames)), ...
               sprintf('Info has no column named %s.', label));
            testCase.verifyClass(data.Info.(label), 'logical');
         end
      end

      function testExhaustiveLabelsCoverEveryRow(testCase)
         % The exhaustive label set accounts for every row of the basin
         % column, so a row-based and a column-based population count agree.

         [data, expected] = groupstats.test.generateTestData('info');

         returned = sum(ismember(string(data.Info.basin), ...
            expected.exhaustiveLabels));
         testCase.verifyEqual(returned, height(data.Info));
      end

      function testNonExhaustiveLabelsLeaveRowsOut(testCase)
         % The non-exhaustive label set leaves rows out. A test of how
         % groupbayes counts its population needs a fixture where the
         % row-based and column-based counts differ.

         [data, expected] = groupstats.test.generateTestData('info');

         returned = sum(ismember(string(data.Info.basin), ...
            expected.nonExhaustiveLabels));
         testCase.verifyLessThan(returned, height(data.Info));
      end

      function testEveryGeneratorCaseIsTested(testCase)
         % A case added to the generator, and not to the casename property
         % above, would ship with no test at all.

         source = string(fileread(which('groupstats.test.generateTestData')));
         source = regexprep(source, '\.\.\.\s*\r?\n\s*', '');

         found = regexp(source, 'knowncases\s*=\s*\[([^\]]*)\]', ...
            'tokens', 'once');
         testCase.assertNotEmpty(found);

         returned = sort(string(regexp(found{1}, '"(\w+)"', 'tokens')));
         expected = sort(string(testCase.casename))';

         testCase.verifyEqual(returned(:), expected(:));
      end
   end
end
