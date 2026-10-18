function [estimate, bounds, n] = sampleci(y, method, alpha)
   %SAMPLECI Center of one sample and its confidence interval.
   %
   %  [ESTIMATE, BOUNDS, N] = SAMPLECI(Y, METHOD)
   %  [ESTIMATE, BOUNDS, N] = SAMPLECI(Y, METHOD, ALPHA)
   %
   % Description
   %  Returns the center of the values Y, its interval BOUNDS as a 1-by-2
   %  row, and the number of values N. SAMPLECI removes NaN values first, so
   %  N counts the values that remain. It converts Y to double, so integer
   %  and logical values work. No value carries a weight.
   %
   %  METHOD "mean" gives the mean and the Student t interval
   %
   %     mean +/- t(1 - ALPHA/2, N - 1) * s / sqrt(N),
   %
   %  where s is the sample standard deviation with the N - 1 denominator.
   %  ALPHA defaults to 0.05, and an empty ALPHA also means 0.05.
   %
   %  METHOD "median" gives the median and the notch that boxchart draws,
   %
   %     median +/- 1.57 * IQR / sqrt(N),
   %
   %  read from groupstats.boxchartydata. The notch level is fixed, so ALPHA
   %  does not apply.
   %
   %  With N = 0, ESTIMATE and BOUNDS are NaN. With N = 1, ESTIMATE is the
   %  value and BOUNDS are NaN. Note: boxchart draws a zero-width notch for
   %  one value, which boxchartydata returns.
   %
   %  groupstats.groupci and groupstats.barchartcats compute every interval
   %  here, so a table row and a drawn whisker always agree.
   %
   % Example
   %  [estimate, bounds, n] = sampleci(1:8, "mean")   % 4.5, [2.4522 6.5478], 8
   %
   % See also: groupstats.groupci, groupstats.boxchartydata, tcritical

   arguments
      y {mustBeNumericOrLogical}
      method (1, 1) string
      alpha double {mustBeScalarOrEmpty} = []
   end

   % This is the one place the default level lives, so a caller that leaves
   % Alpha unset passes it through empty.
   if isempty(alpha)
      alpha = 0.05;
   end

   % The mean of an integer type rounds, so compute in double. NaN marks a
   % missing value, which no interval uses.
   y = double(y(:));
   y = y(~isnan(y));
   n = numel(y);

   % One value has no spread, and its t quantile, with N - 1 = 0 degrees of
   % freedom, is undefined. Keep these NaN bounds for N < 2, so the t
   % quantile is never computed for them.
   bounds = [NaN NaN];

   switch method
      case "mean"
         estimate = mean(y);
         if n > 1
            halfwidth = tcritical(alpha, n - 1) * std(y) / sqrt(n);
            bounds = estimate + [-halfwidth halfwidth];
         end
      case "median"
         % The notch is the interval boxchartcats draws, so read it from the
         % helper that computes the drawn coordinates rather than repeat the
         % 1.57 rule here.
         ycoords = groupstats.boxchartydata(y);
         estimate = ycoords.boxline;
         if n > 1
            bounds = ycoords.notches;
         end
   end
end
