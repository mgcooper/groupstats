function G = grouppercent(tbl, groupvars, groupbins, groupsets)
   %GROUPPERCENT Compute group-wise frequencies (percents) including groupsets.
   %
   %  G = GROUPPERCENT(TBL, GROUPVARS)
   %  G = GROUPPERCENT(TBL, GROUPVARS, GROUPBINS)
   %  G = GROUPPERCENT(TBL, GROUPVARS, GROUPBINS, GROUPSETS)
   %
   % Description
   %  This addresses the fact that groupsummary returns the counts for each
   %  group but not the frequencies. It also adds the "groupsets" concept from
   %  groupstats, so frequencies (and counts) are computed for "ingroups".
   %
   %  TBL is either a raw data table, one row per observation, or a table that
   %  a previous groupsummary or groupcounts call already summarized, one row
   %  per group. A GroupCount variable is what tells the two apart: a raw
   %  table has none, so this function calls groupcounts first.
   %
   %  G gains one Percent_<groupvar> variable per member of GROUPSETS. Each
   %  one holds a within-group percent: for every member of that group
   %  variable, the rows belonging to that member sum to 100. Omit GROUPSETS
   %  or pass string.empty() to use GROUPVARS. The scalar string "none" is
   %  not a groupsets value and is rejected, so a table variable literally
   %  named "none" cannot be selected this way.
   %
   %  Percent, which groupcounts produces, is a different quantity. It is each
   %  row's share of every observation in the table, so the whole column sums
   %  to 100.
   %
   %  When grouppercent computes the counts from a raw table, a binned group
   %  variable keeps its original name in G: the disc_ prefix groupcounts
   %  adds is removed. A table that already carries GroupCount is used as
   %  given, so a disc_ name in it stays.
   %
   % Example
   %  tbl = table(["a";"a";"b"], [1;2;3], 'VariableNames', {'Group', 'Value'});
   %  G = groupstats.grouppercent(tbl, "Group");
   %
   % See also: groupsummary, groupcounts, groupstats.groupsummary

   arguments
      tbl (:,:) tabular
      groupvars (1,:) string
      groupbins (1,:) = "none"
      groupsets (1,:) string = string.empty()
   end

   % groupbins has no type constraint in the arguments block: it must accept
   % the string "none" and numeric bin edges. The default "none" applies to
   % every groupvar.

   % string.empty() is the one no-groupsets sentinel across the family. The
   % shared validator rejects a scalar "none" with the rewrite.
   % groupstats.groupsummary validates before its pass-down, so this repeat
   % only guards direct callers. An empty groupsets means: use groupvars.
   validategroupsets(groupsets)
   if isempty(groupsets)
      groupsets = groupvars;
   end

   G = tbl;

   % bySet: the groupsets variable is not among groupvars, so count each
   % set's rows separately and stack them, instead of grouping directly.
   bySet = false;
   if ~any(ismember(groupsets, groupvars))
      bySet = true;
   end

   % Check if G contains 'GroupCount' variable
   if ~isvariable('GroupCount', G)

      % Assume input G is a data table and call groupcounts
      if bySet

         % Count within each set separately, then stack. groupcounts cannot
         % group by a variable that is not in groupvars, so each set's rows go
         % through it on their own and carry the set label back afterward.
         %
         % One set variable at a time. Two would need a grid over their
         % members, and no caller has asked for that.
         setvar = groupsets(1);
         if ~isscalar(groupsets)
            error('groupstats:grouppercent:multipleGroupSets', ...
               ['grouppercent counts by one groupsets variable at a time. ' ...
               'Received %d: %s.'], numel(groupsets), ...
               strjoin(groupsets, ', '))
         end

         sets = unique(G.(setvar));
         tmpG = cell(numel(sets), 1);
         for n = 1:numel(sets)
            idx = ismember(G.(setvar), sets(n));
            Gn = groupcounts(G(idx, :), groupvars, groupbins);
            Gn.(setvar) = repmat(sets(n), height(Gn), 1);
            tmpG{n} = Gn;
         end
         G = stacktables(tmpG{:});

      else

         G = groupcounts(G, groupvars, groupbins);
      end

      % Restore each binned group variable's original name, so a caller reads
      % the same name whether or not groupbins was used. Only a name built
      % from one of groupvars is renamed; a blanket substring replace would
      % also rewrite a variable the caller named disc_something.
      names = string(G.Properties.VariableNames);
      binned = "disc_" + groupvars;
      [isbinned, loc] = ismember(names, binned);
      names(isbinned) = groupvars(loc(isbinned));
      G.Properties.VariableNames = names;
   end

   % If multiple groupvars, calculate the GroupPercent for each groupvar
   for m = 1:numel(groupsets)
      groupvar = groupsets(m);
      grps = unique(G.(groupvar));

      % Convert a cellstr group column to string; indexing grps(n) and the ==
      % comparison below fail on a cell array.
      if iscell(grps) && ~isnumeric(grps{1})
         try
            grps = string(unique(G.(groupvar)));
         catch e
            rethrow(e)
         end
      end

      % Compute the within group percentages. Every member's rows sum to 100,
      % including a member holding one row, which is then 100 percent of
      % itself. Normalizing over the whole table instead would produce
      % Percent, which is a different quantity groupcounts already returns.
      G.("Percent_" + groupvar) = nan(height(G), 1);
      for n = 1:numel(grps)
         idx = G.(groupvar) == grps(n);
         G.("Percent_" + groupvar)(idx) = ...
            100 .* G.GroupCount(idx) ./ sum(G.GroupCount(idx));
      end
   end

   % Move the Percent_<ingroup> columns to the start, after Percent
   for n = numel(groupsets):-1:1
      try
         % if groupcounts was called in this function, G.Percent will exist
         G = movevars(G,"Percent_" + groupsets(n),"After","Percent");
      catch
         G = movevars(G,"Percent_" + groupsets(n),"After","GroupCount");
      end
   end
end
