function names = errorbartype()
   %ERRORBARTYPE Valid values for barchartcats' ErrorBar option.
   %
   %  names = groupstats.namelists.errorbartype()
   %
   % Description
   %  Returns what a barchartcats PlotError whisker shows. "spread" is the
   %  spread of the group: the standard deviation for Method="mean" and the
   %  interquartile range for Method="median". "ci" is the confidence
   %  interval that groupstats.groupci returns for the same rows.
   %
   % See also: groupstats.barchartcats, groupstats.groupci,
   % groupstats.namelists.mustBeMemberOf

   names = [
      "spread"
      "ci"
      ];
end
