classdef test_bootmediandiff < matlab.unittest.TestCase
   %TEST_BOOTMEDIANDIFF Test the private bootstrap median-difference helper.
   %
   % matfunclib's bootdiff takes the absolute difference before quantiling.
   % Its interval never contains zero, and its hypothesis result is true on
   % identical distributions 20 times out of 20. This helper keeps the
   % sign. These cases pin the signed difference and the interval.
   %
   % The helper is private to the package, so the tests reach it through
   % groupstats.internal.privatefunction. The random draws are seeded, so
   % every run sees the same resamples.
   %
   % See also: groupstats.groupcompare

   properties
      % A handle to the private helper.
      bootmediandiff
   end

   methods (TestMethodSetup)

      function getHelper(testCase)
         testCase.bootmediandiff = ...
            groupstats.internal.privatefunction('bootmediandiff');
         state = rng(7);
         testCase.addTeardown(@() rng(state));
      end
   end

   methods (Test)

      function testIdenticalDistributionsRarelyReject(testCase)
         % The measured defect: 20 of 20 false positives on identical
         % distributions. With the signed difference the interval straddles
         % zero almost every time; at Alpha 0.05 three of twenty is the
         % generous bound.

         rejections = 0;
         for n = 1:20
            results = testCase.bootmediandiff( ...
               {randn(40, 1), randn(40, 1)}, NumBootstrap = 500);
            rejections = rejections + results.H;
         end

         testCase.verifyLessThanOrEqual(rejections, 3);
      end

      function testShiftedSampleGivesASignedDifference(testCase)
         % A sample shifted up by 3 has a positive median difference with an
         % interval above zero, and one shifted down is negative.

         reference = randn(50, 1);
         results = testCase.bootmediandiff( ...
            {reference, reference + 3, reference - 3}, NumBootstrap = 500);

         returned = [results.MedianDiff > 0, results.CILower > 0, ...
            results.CIUpper < 0, results.H];
         expected = [true, false, true, false, false, true, true, true];
         testCase.verifyEqual(returned, expected);
      end

      function testOutputShapesFollowTheInputs(testCase)
         % One column per comparison, NumBootstrap rows of medians.

         results = testCase.bootmediandiff({1:10, 1:10, 1:10}, ...
            NumBootstrap = 25);

         returned = {size(results.BootMedians); size(results.Differences); ...
            size(results.MedianDiff); size(results.CILower); ...
            size(results.CIUpper); size(results.H)};
         expected = {[25, 3]; [25, 2]; [1, 2]; [1, 2]; [1, 2]; [1, 2]};
         testCase.verifyEqual(returned, expected);
      end

      function testAlphaWidensOrNarrowsTheInterval(testCase)
         % A smaller Alpha gives a wider interval on the same draws.

         reference = randn(50, 1);
         state = rng;
         narrow = testCase.bootmediandiff({reference, reference + 1}, ...
            NumBootstrap = 500, Alpha = 0.2);
         rng(state);
         wide = testCase.bootmediandiff({reference, reference + 1}, ...
            NumBootstrap = 500, Alpha = 0.01);

         returned = [wide.CILower <= narrow.CILower, ...
            wide.CIUpper >= narrow.CIUpper];
         expected = [true, true];
         testCase.verifyEqual(returned, expected);
      end

      function testNumDrawsScalarAndPerSample(testCase)
         % A scalar NumDraws applies to every sample; a vector gives one
         % count each. A resample of one value is that value, so with one
         % draw every bootstrap median is a member of the sample.

         results = testCase.bootmediandiff({[1 2 3], [10 20 30]}, ...
            NumBootstrap = 20, NumDraws = 1);
         returned = all(ismember(results.BootMedians(:, 2), [10 20 30]));
         testCase.verifyTrue(returned);

         results = testCase.bootmediandiff({[1 2 3], [10 20 30]}, ...
            NumBootstrap = 20, NumDraws = [1 100]);
         returned = all(ismember(results.BootMedians(:, 1), [1 2 3]));
         testCase.verifyTrue(returned);
      end

      function testNumDrawsMismatchErrors(testCase)
         % Two values for three samples is neither one nor one each.

         testCase.verifyError(@() testCase.bootmediandiff( ...
            {1:5, 1:5, 1:5}, NumDraws = [3 3]), ...
            'groupstats:bootmediandiff:numDrawsMismatch');
      end

      function testEmptySampleErrors(testCase)
         % A resample of nothing has no median.

         testCase.verifyError(@() testCase.bootmediandiff( ...
            {1:5, double.empty(0, 1)}), ...
            'groupstats:bootmediandiff:emptySample');
      end

      function testAReferenceAloneGivesNoComparison(testCase)
         % groupcompare hands the helper one sample when a set holds only
         % the reference. Every comparison field is then empty with
         % NumBootstrap rows of medians for the one sample.

         results = testCase.bootmediandiff({1:10}, NumBootstrap = 25);

         returned = {size(results.BootMedians); size(results.Differences); ...
            size(results.MedianDiff); size(results.H)};
         expected = {[25, 1]; [25, 0]; [1, 0]; [1, 0]};
         testCase.verifyEqual(returned, expected);
      end

   end
end
