classdef test_boxchartydata < matlab.unittest.TestCase
   %TEST_BOXCHARTYDATA Test groupstats.boxchartydata.
   %
   % boxchartydata returns the y coordinates boxchart draws. These cases pin
   % the two defects the audit named: a short-circuit or that errored for any
   % vector input, and whiskers that reported the outlier extent rather than
   % the inner fences.
   %
   % See also: groupstats.boxchartydata, groupstats.boxchartxdata

   methods (Test)

      function testVectorInputRuns(testCase)
         % Any vector input errored, because a short-circuit or requires
         % scalar operands.

         returned = groupstats.boxchartydata([1 2 3 4 5]);

         testCase.verifyClass(returned, 'struct');
      end

      function testWhiskersAreTheInnerFences(testCase)
         % The whiskers reach the most extreme values inside the fences, which
         % is what boxchart draws. Reporting the outlier extent would put the
         % tips on the points boxchart plots separately.

         y = groupstats.boxchartydata([1 2 3 4 100]);

         returned = y.whiskers;
         expected = [1 4];
         testCase.verifyEqual(returned, expected);
      end

      function testOutliersAreBeyondTheFences(testCase)
         % A value more than 1.5 interquartile ranges outside a box edge is an
         % outlier.

         y = groupstats.boxchartydata([1 2 3 4 100]);

         returned = y.outliers;
         expected = 100;
         testCase.verifyEqual(returned, expected);
      end

      function testNoOutliersGivesTheDataRange(testCase)
         % With nothing outside the fences the whiskers reach the data range.

         y = groupstats.boxchartydata([1 2 3 4 5]);

         returned = y.whiskers;
         expected = [1 5];
         testCase.verifyEqual(returned, expected);
         testCase.verifyEmpty(y.outliers);
      end

      function testBoxLineIsTheMedian(testCase)
         % The line inside the box is the median.

         data = [1 2 3 4 100];
         y = groupstats.boxchartydata(data);

         returned = y.boxline;
         expected = median(data);
         testCase.verifyEqual(returned, expected);
      end

      function testBoxEdgesAreTheQuartiles(testCase)
         % The box spans the 25th to the 75th percentile.

         data = [1 2 3 4 100];
         y = groupstats.boxchartydata(data);

         returned = y.boxedge;
         expected = [quantile(data, 0.25) quantile(data, 0.75)];
         testCase.verifyEqual(returned, expected);
         testCase.verifyEqual(y.iqrange, diff(expected));
      end

      function testNanValuesAreRemoved(testCase)
         % boxchart ignores NaN, so these coordinates must too.

         withnan = groupstats.boxchartydata([1 2 NaN 3 4 5]);
         without = groupstats.boxchartydata([1 2 3 4 5]);

         testCase.verifyEqual(withnan.whiskers, without.whiskers);
         testCase.verifyEqual(withnan.boxline, without.boxline);
      end

      function testNotchesStraddleTheBoxLine(testCase)
         % The notch bounds sit either side of the median.

         data = (1:20)';
         y = groupstats.boxchartydata(data);

         testCase.verifyLessThan(y.notches(1), y.boxline);
         testCase.verifyGreaterThan(y.notches(2), y.boxline);
      end

      function testColumnAndRowInputAgree(testCase)
         % Orientation does not change the coordinates.

         asrow = groupstats.boxchartydata([1 2 3 4 100]);
         ascolumn = groupstats.boxchartydata([1; 2; 3; 4; 100]);

         testCase.verifyEqual(ascolumn, asrow);
      end
   end
end
