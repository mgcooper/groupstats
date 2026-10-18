function names = fitpdf()
   %FITPDF Valid values for groupstats.histogram's FitPDF option.
   %
   %  names = groupstats.namelists.fitpdf()
   %
   % Description
   %  Returns the densities groupstats.histogram can fit and overlay on each
   %  group. "none" draws no density. "normal" draws the normal PDF of each
   %  group's sample mean and standard deviation.
   %
   % See also: groupstats.histogram, groupstats.namelists.mustBeMemberOf

   names = [
      "none"
      "normal"
      ];
end
