classdef test_groupbayes < matlab.unittest.TestCase
   %TEST_GROUPBAYES Test groupstats.groupbayes.
   %
   % groupbayes computes group-wise conditional probabilities from an event
   % table. These cases pin the marginals and the pairing of groupA against
   % groupB members.
   %
   % The conditional outputs, the population count, and the pairwise
   % groupA equals groupB case are covered in test_groupbayes_population.
   %
   % See also: groupstats.groupbayes, groupstats.test.generateTestData

   properties
      % The event table and the group definitions it is built for.
      tbl
      groupvar
      groupA
      groupB
      % The marginal probabilities the fixture's table produces.
      expectedPA
      expectedPB
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         % Fetch the shared fixture.
         [data, expected] = groupstats.test.generateTestData('groupbayes');
         testCase.tbl = data.tbl;
         testCase.groupvar = data.groupvar;
         testCase.groupA = data.groupA;
         testCase.groupB = data.groupB;
         testCase.expectedPA = expected.P_A;
         testCase.expectedPB = expected.P_B;
      end
   end

   methods (Test)

      function testMarginalPA(testCase)
         % P_A is the marginal probability of each groupA member.

         P = groupstats.groupbayes(testCase.tbl, testCase.groupA, ...
            testCase.groupB, testCase.groupvar);

         returned = P.P_A(:);
         expected = testCase.expectedPA(:);
         testCase.verifyEqual(returned, expected);
      end

      function testMarginalPB(testCase)
         % P_B is the marginal probability of each groupB member.

         P = groupstats.groupbayes(testCase.tbl, testCase.groupA, ...
            testCase.groupB, testCase.groupvar);

         returned = P.P_B(:);
         expected = testCase.expectedPB(:);
         testCase.verifyEqual(returned, expected);
      end

      function testOneRowPerGroupPair(testCase)
         % The result carries one row per groupA and groupB pair.

         P = groupstats.groupbayes(testCase.tbl, testCase.groupA, ...
            testCase.groupB, testCase.groupvar);

         returned = height(P);
         expected = numel(testCase.groupA) * numel(testCase.groupB);
         testCase.verifyEqual(returned, expected);
      end
   end
end
