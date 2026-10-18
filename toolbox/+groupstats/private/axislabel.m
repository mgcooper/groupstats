function label = axislabel(tbl, varname, opts)
   %AXISLABEL Axis label for a table variable, from the table's metadata.
   %
   %  LABEL = AXISLABEL(TBL, VARNAME)
   %  LABEL = AXISLABEL(TBL, VARNAME, Units=false)
   %
   % LABEL is the variable's VariableDescriptions entry when the table sets
   % one, else its name with underscores as spaces. Its VariableUnits
   % entry follows in parentheses when set. A table that describes its
   % variables therefore gets labels that say what is plotted, with units.
   % A name that is not a table variable, such as the row times of a
   % timetable, gets its name. Units=false leaves the units out, for a
   % quantity such as a count that does not carry the variable's units.
   %
   % See also: groupstats.barchartcats, groupstats.boxchartcats,
   % groupstats.scatter, groupstats.histogram, groupstats.groupheatmap

   arguments
      tbl tabular
      varname (1, 1) string
      opts.Units (1, 1) logical = true
   end

   label = strrep(varname, "_", " ");
   props = tbl.Properties;
   index = find(string(props.VariableNames) == varname, 1);
   if isempty(index)
      return
   end

   % Both properties hold an empty cell when the table sets none, and an
   % empty entry for a variable the caller left blank.
   if ~isempty(props.VariableDescriptions) ...
         && strlength(props.VariableDescriptions{index}) > 0
      label = string(props.VariableDescriptions{index});
   end
   if opts.Units && ~isempty(props.VariableUnits) ...
         && strlength(props.VariableUnits{index}) > 0
      label = label + " (" + props.VariableUnits{index} + ")";
   end
end
