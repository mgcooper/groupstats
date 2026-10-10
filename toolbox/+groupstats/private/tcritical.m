function t = tcritical(alpha, nu)
   %TCRITICAL Two-sided critical value of the Student t distribution.
   %
   %  T = TCRITICAL(ALPHA, NU)
   %
   % Description
   %  T = TCRITICAL(ALPHA, NU) returns the two-sided critical value T. A
   %  Student t variable with NU degrees of freedom exceeds T in absolute
   %  value with probability ALPHA. T is the 1 - ALPHA/2 quantile, the value
   %  that tinv(1 - ALPHA/2, NU) returns. This function needs only base
   %  MATLAB.
   %
   %  ALPHA is a scalar in the open interval (0, 1). NU is a scalar of 1 or
   %  more, and it need not be an integer.
   %
   % Method
   %  The two-sided tail probability of T is the regularized incomplete beta
   %  function I(X; NU/2, 1/2), with X = NU / (NU + T^2), so
   %
   %     T = sqrt(NU * (1 - X) / X).
   %
   %  For NU below 1e4, X comes from one of three forms:
   %
   %  - The leading term. The tail is at least X^(NU/2) / (NU/2 * B), with B
   %    the beta function B(NU/2, 1/2), and exceeds it by a factor
   %    1 + O(X). That bound gives X in closed form. Where it puts X below
   %    eps, the closed form is exact in double. T then follows without
   %    forming X, which can underflow, or 1/X, which can overflow.
   %  - Newton steps. betaincinv loses accuracy for ALPHA below about 1e-300
   %    and fails below realmin. For ALPHA below 1e-280, Newton steps on
   %    log(X) start from the bound and use the forward betainc.
   %  - Two inversions. Otherwise betaincinv inverts the lower tail for X
   %    and the upper tail for 1 - X. Neither is found by subtraction, so T
   %    keeps its precision as ALPHA nears 1, where X nears 1.
   %
   %  Note: betaincinv loses accuracy as NU grows. Its result is about 2e-10
   %  off at NU = 1e5 and 1.2% low at NU = 2e7. For NU of 1e4 or more, T
   %  starts from the normal quantile z = sqrt(2) * erfcinv(ALPHA). The four
   %  series terms of Abramowitz and Stegun 26.7.5 correct it. Their sum is
   %  accurate to about 1e-11 at NU = 1e4 for the usual ALPHA values, and
   %  better above it.
   %
   %  For ALPHA from 1e-315 to 1 - 2^-53, both branches match independent
   %  values to a relative error of 1e-8 or less. Below 1e4 degrees of
   %  freedom, the error is 1e-10 or less. A T beyond the double range, such
   %  as NU = 1 with ALPHA below about 3.5e-309, is Inf. Note: for ALPHA below about 1e-312,
   %  erfcinv and betainc keep few significant bits. The relative error of T
   %  grows to about 1e-6 at ALPHA = 1e-320 and 1e-3 at the smallest double.
   %
   % Example
   %  t = tcritical(0.05, 7)   % 2.3646242516
   %
   % See also: betaincinv, betainc, erfcinv, sampleci

   arguments
      alpha (1, 1) double
      nu (1, 1) double
   end

   if nu < 1e4
      % The beta forms have no approximation error of their own. Their
      % accuracy is that of betaincinv and betainc, which holds below this
      % size. logx is the leading-term bound on log(X): log(ALPHA * a * B)/a
      % with a = NU/2, where log(a * B) = gammaln(a + 1) + log(pi)/2 -
      % gammaln(a + 1/2).
      a = nu / 2;
      logx = (log(alpha) + gammaln(a + 1) + log(pi) / 2 ...
         - gammaln(a + 1 / 2)) / a;
      if logx < log(eps)
         % T = sqrt(NU / X), since 1 - X is 1 in double.
         t = exp((log(nu) - logx) / 2);
      elseif alpha < 1e-280
         % From the bound, Newton converged in one or two steps on a
         % measured grid down to the smallest double, so four steps leave a
         % margin.
         % The step is the log-tail error over its slope in log(X), the
         % density times X over the tail. A deep subnormal ALPHA can
         % underflow the forward tail to 0, which makes the step NaN; then
         % the last finite X stands.
         for k = 1:4
            x = exp(logx);
            p = betainc(x, a, 1 / 2);
            step = (log(p) - log(alpha)) / ...
               exp(a * logx - log1p(-x) / 2 - betaln(a, 1 / 2) - log(p));
            if ~isfinite(step)
               break
            end
            logx = logx - step;
         end
         x = exp(logx);
         t = sqrt(nu * (1 - x)) / sqrt(x);
      else
         % 'upper' inverts the upper tail directly, so 1 - ALPHA is never
         % formed. The square roots are taken apart, so NU * (1 - X) / X
         % cannot overflow.
         x = betaincinv(alpha, a, 1 / 2);
         y = betaincinv(alpha, 1 / 2, a, 'upper');
         t = sqrt(nu * y) / sqrt(x);
      end
   else
      % Abramowitz and Stegun 26.7.5: the terms g1 to g4 of the expansion of
      % the t quantile in powers of 1/NU about the normal quantile z.
      z = sqrt(2) * erfcinv(alpha);
      g = [
         (z^3 + z) / 4
         (5*z^5 + 16*z^3 + 3*z) / 96
         (3*z^7 + 19*z^5 + 17*z^3 - 15*z) / 384
         (79*z^9 + 776*z^7 + 1482*z^5 - 1920*z^3 - 945*z) / 92160
         ];
      t = z + sum(g ./ nu .^ (1:4)');
   end
end
