function tbl = restoregroupvarnames(tbl, groupvars)
   %RESTOREGROUPVARNAMES Give the group columns of a builtin result their names.
   %
   %  TBL = RESTOREGROUPVARNAMES(TBL, GROUPVARS)
   %
   % groupcounts and groupsummary put one column per group variable first,
   % in GROUPVARS order. They rename a binned variable: disc_<name> for bin
   % edges or a bin count, and <bin>_<name> for a named time bin, such as
   % month_Time. Renaming the leading columns by position gives a caller the
   % same name whether or not groupbins was used, for every kind of bin.
   % No other column is renamed, so a variable the caller named
   % disc_something keeps its name.
   %
   % See also: groupstats.groupsummary, groupstats.grouppercent

   tbl.Properties.VariableNames(1:numel(groupvars)) = cellstr(groupvars);
end
