function names = populationoption()
   %POPULATIONOPTION Valid values for the groupbayes Population option.
   %
   %  names = groupstats.namelists.populationoption()
   %
   % Description
   %  Returns the values groupbayes accepts for Population, which chooses the
   %  denominator of the reported marginal probabilities:
   %
   %    union       - rows in group A or group B. The default.
   %    table       - every row of the table.
   %    withingroup - rows in the group each probability describes.
   %
   %  The conditional probabilities are count ratios, so they do not change
   %  with this option.
   %
   % See also: groupstats.groupbayes

   names = [
      "union"
      "table"
      "withingroup"
      ];
end
