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
   %  function I(NU / (NU + T^2); NU/2, 1/2). For NU below 1e4,
   %
   %     T = sqrt(NU * (1 / betaincinv(ALPHA, NU/2, 1/2) - 1)).
   %
   %  Note: betaincinv loses accuracy as NU grows. Its result is about 2e-10
   %  off at NU = 1e5 and 1.2% low at NU = 2e7. For NU of 1e4 or more, T
   %  starts from the normal quantile z = sqrt(2) * erfcinv(ALPHA). The four
   %  series terms of Abramowitz and Stegun 26.7.5 correct it. Their sum is
   %  accurate to about 1e-11 at NU = 1e4 for the usual ALPHA values, and
   %  better above it. Both branches match independent values to a relative
   %  error of 1e-8 or less.
   %
   % Example
   %  t = tcritical(0.05, 7)   % 2.3646242516
   %
   % See also: betaincinv, erfcinv, sampleci

   arguments
      alpha (1, 1) double
      nu (1, 1) double
   end

   if nu < 1e4
      % The beta form has no approximation error of its own. Its accuracy
      % is that of betaincinv, which holds below this size.
      t = sqrt(nu * (1 / betaincinv(alpha, nu / 2, 1 / 2) - 1));
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
