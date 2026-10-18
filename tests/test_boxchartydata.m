classdef test_boxchartydata < matlab.unittest.TestCase
   %TEST_BOXCHARTYDATA Test groupstats.boxchartydata.
   %
   % boxchartydata returns the y coordinates boxchart draws. These cases pin
   % the two defects the audit named: a short-circuit or that errored for any
   % vector input, and whiskers that reported the outlier extent rather than
   % the inner fences. They also pin a third defect: a whisker tip inside the
   % box, where boxchart draws the tip on the box edge.
   %
   % The expected quartiles are hand values from the default quantile rule.
   % For N values, the sorted value k sits at (k - 0.5) / N, and a quartile
   % between two positions is linear between their values.
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
         %
         % Hand values: Q1 = 1 + 0.75 * (2 - 1) = 1.75 and
         % Q3 = 4 + 0.25 * (100 - 4) = 28. The upper fence is
         % 28 + 1.5 * 26.25 = 67.375, so 100 is an outlier. The largest
         % inside value, 4, lies inside the box, so boxchart draws the upper
         % tip at the box top, 28. A probe of the drawn whisker vertices on
         % R2024b and R2025b shows [1 28].

         y = groupstats.boxchartydata([1 2 3 4 100]);

         returned = y.whiskers;
         expected = [1 28];
         testCase.verifyEqual(returned, expected);
      end

      function testUpperTipStopsAtTheBoxTop(testCase)
         % Q1 = 1 and Q3 = 1 + 0.25 * (5 - 1) = 2. The upper fence is
         % 2 + 1.5 * 1 = 3.5, so 5 is an outlier. Every inside value is 1,
         % which lies below the box top, so the upper tip is Q3 = 2.

         y = groupstats.boxchartydata([1 1 1 1 5]);

         returned = y.whiskers;
         expected = [1 2];
         testCase.verifyEqual(returned, expected);
      end

      function testLowerTipStopsAtTheBoxBottom(testCase)
         % Q1 = -100 + 0.75 * (1 - -100) = -24.25 and
         % Q3 = 3 + 0.25 * (4 - 3) = 3.25. The lower fence is
         % -24.25 - 1.5 * 27.5 = -65.5, so -100 is an outlier. The smallest
         % inside value, 1, lies above the box bottom, so the lower tip is
         % Q1 = -24.25.

         y = groupstats.boxchartydata([-100 1 2 3 4]);

         returned = y.whiskers;
         expected = [-24.25 4];
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-12);
      end

      function testAValueOnTheFenceIsInside(testCase)
         % Q1 = 0 and Q3 = 1 + 0.25 * (5 - 1) = 2, so the upper fence is
         % 2 + 1.5 * 2 = 5. The value 5 sits on the fence. boxchart treats it
         % as inside and draws the upper tip on it.

         y = groupstats.boxchartydata([0 0 0 1 5]);

         returned = y.whiskers;
         expected = [0 5];
         testCase.verifyEqual(returned, expected);
         testCase.verifyEmpty(y.outliers);
      end

      function testOneValueGivesZeroLengthWhiskersAndNotch(testCase)
         % One value is its own median and both quartiles, so boxchart draws
         % a zero-height box with zero-length whiskers and a zero-width
         % notch.

         y = groupstats.boxchartydata(7);

         testCase.verifyEqual(y.whiskers, [7 7]);
         testCase.verifyEqual(y.notches, [7 7]);
      end

      function testNoDataGivesNaNWhiskers(testCase)
         % With no values there is no box, so every tip is NaN, as is every
         % other coordinate.

         y = groupstats.boxchartydata([NaN NaN]);

         returned = y.whiskers;
         expected = [NaN NaN];
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
