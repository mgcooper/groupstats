function names = legendvisibility()
   %LEGENDVISIBILITY Valid values for a Legend option.
   %
   %  names = groupstats.namelists.legendvisibility()
   %
   % Description
   %  Returns the values that turn a legend on or off. These match the values
   %  MATLAB accepts for the Visible property, so a chart can pass the option
   %  straight through.
   %
   % See also: groupstats.boxchartcats, groupstats.scatter, legend

   names = [
      "on"
      "off"
      ];
end
