function G = grouppercent(tbl, groupvars, groupbins, opts)
   %GROUPPERCENT Compute group-wise frequencies (percents) including groupsets.
   %
   %  G = GROUPPERCENT(TBL, GROUPVARS)
   %  G = GROUPPERCENT(TBL, GROUPVARS, GROUPBINS)
   %  G = GROUPPERCENT(_, GroupSets=NAME)
   %  G = GROUPPERCENT(_, RowSelectVar=NAME, RowSelectMembers=M)
   %  G = GROUPPERCENT(_, IncludedEdge=EDGE)
   %
   %  The positional inputs are the ones the builtin groupcounts takes, in
   %  its order. The groupstats-only controls are name-value options, the
   %  same four groupstats.groupsummary has.
   %
   % Description
   %  This addresses the fact that groupsummary returns the counts for each
   %  group but not the frequencies. It also adds the "groupsets" concept from
   %  groupstats, so frequencies (and counts) are computed for "ingroups".
   %
   %  TBL is either a raw data table, one row per observation, or a table that
   %  a previous groupsummary or groupcounts call already summarized, one row
   %  per group. A GroupCount variable is what tells the two apart: a raw
   %  table has none, so this function calls groupcounts first. A grouping
   %  variable therefore cannot be named GroupCount, or Percent, which G
   %  also holds. Either name, in GROUPVARS or in GroupSets, raises a
   %  reservedName error.
   %
   %  G gains one Percent_<groupvar> variable per member of GroupSets. Each
   %  one holds a within-group percent: for every member of that group
   %  variable, the rows belonging to that member sum to 100. Omit GroupSets
   %  or pass string.empty() to use GROUPVARS. The scalar string "none" is
   %  not a GroupSets value and is rejected, so a table variable literally
   %  named "none" cannot be selected this way.
   %
   %  RowSelectVar and RowSelectMembers keep only the rows whose RowSelectVar
   %  value is one of RowSelectMembers, before counting. Give both together:
   %  either one alone is an error, the same two errors
   %  groupstats.prepareTableGroups raises. Row selection applies to a raw
   %  table only. A table that already carries GroupCount is used as given,
   %  so naming RowSelectVar with one is an error.
   %
   % Errors
   %  groupstats:grouppercent:rowSelectVarWithoutMembers - RowSelectVar
   %  without RowSelectMembers.
   %  groupstats:grouppercent:membersWithoutGroupVar - RowSelectMembers
   %  without RowSelectVar.
   %  groupstats:grouppercent:rowSelectOnSummarizedTable - row selection
   %  named for a table that already carries GroupCount.
   %  groupstats:grouppercent:multipleGroupSets - a raw table with more
   %  than one GroupSets variable outside GROUPVARS. The counts for a set
   %  variable outside GROUPVARS are made one set at a time, and one such
   %  variable is all that path takes. Set variables that are in GROUPVARS,
   %  and every set variable of a table that already carries GroupCount,
   %  each get their Percent_ column.
   %  groupstats:grouppercent:reservedName - a GROUPVARS or GroupSets
   %  variable is named GroupCount or Percent.
   %
   %  Percent, which groupcounts produces, is a different quantity. It is each
   %  row's share of every observation in the table, so the whole column sums
   %  to 100.
   %
   %  When grouppercent computes the counts from a raw table, a binned group
   %  variable keeps its original name in G: the disc_ prefix, or the named
   %  bin prefix such as month_, that groupcounts adds is removed. A table
   %  that already carries GroupCount is used as given, so a disc_ name in
   %  it stays.
   %
   %  A missing value of a group variable forms one group, as in groupcounts.
   %  For Percent_<groupvar> it is one more member, so its rows sum to 100.
   %  A missing value of a GroupSets variable outside GROUPVARS forms one
   %  set the same way, counted after the other sets.
   %
   %  IncludedEdge, "left" (default) or "right", is the bin edge a value on
   %  an edge belongs to, passed to groupcounts for every binned group
   %  variable. "left" puts a value on an edge in the bin that starts
   %  there; "right" puts it in the bin that ends there. It is the option
   %  groupstats.groupsummary passes down.
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
      opts.GroupSets (1,:) string = string.empty()
      opts.RowSelectVar (1,:) string = string.empty()
      opts.RowSelectMembers (:,1) string = string.empty()
      % The bin edge a value on an edge belongs to, passed to groupcounts
      % for every binned groupvar, as groupstats.groupsummary passes it.
      opts.IncludedEdge (1,1) string ...
         {mustBeMember(opts.IncludedEdge, ["left", "right"])} = "left"
   end

   % Import the namespace function row selection calls.
   import groupstats.groupselect

   % groupbins has no type constraint in the arguments block: it must accept
   % the string "none" and numeric bin edges. The default "none" applies to
   % every groupvar.

   % string.empty() is the one no-groupsets sentinel across the family. The
   % shared validator rejects a scalar "none" with the rewrite.
   % groupstats.groupsummary validates before its pass-down, so this repeat
   % only guards direct callers. An empty GroupSets means: use groupvars.
   validategroupsets(opts.GroupSets)
   groupsets = opts.GroupSets;
   if isempty(groupsets)
      groupsets = groupvars;
   end

   % G names its count and percent columns GroupCount and Percent, and a
   % GroupCount variable marks a counted table. This function would read a
   % GroupCount grouping variable as the count. A Percent grouping variable
   % would take the place of the Percent share. Reject both, as
   % groupstats.groupsummary does.
   validategroupvarnames([groupvars, groupsets], ...
      ["GroupCount", "Percent"], "grouppercent")

   % Keep only the requested rows. Row selection needs both halves, and the
   % shared check raises the same two errors prepareTableGroups raises,
   % under this function's own identifiers. A summarized table has one row
   % per group, not per observation, so selecting its rows would drop
   % groups from a count already made. Report that rather than count on.
   validaterowselect(opts.RowSelectVar, opts.RowSelectMembers, ...
      "grouppercent", "grouppercent")
   if ~isempty(opts.RowSelectMembers)
      if isvariable('GroupCount', tbl)
         error('groupstats:grouppercent:rowSelectOnSummarizedTable', ...
            ['RowSelectVar was given with a table that already carries ' ...
            'GroupCount. Select the rows before counting, or pass the raw ' ...
            'table.'])
      end
      tbl = groupselect(tbl, opts.RowSelectVar, opts.RowSelectMembers);
   end

   G = tbl;

   % bySet: a groupsets variable is not among groupvars, so count each
   % set's rows separately and stack them, instead of grouping directly.
   % The set variables that are among groupvars need nothing extra: the
   % count already carries them, and the percent loop below reads them.
   extrasets = setdiff(groupsets, groupvars, 'stable');
   bySet = ~isempty(extrasets);

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
         setvar = extrasets(1);
         if ~isscalar(extrasets)
            error('groupstats:grouppercent:multipleGroupSets', ...
               ['grouppercent counts by one groupsets variable outside ' ...
               'groupvars at a time. Received %d: %s.'], ...
               numel(extrasets), strjoin(extrasets, ', '))
         end

         % A missing set value equals no member, so memberrows collects its
         % rows as one more set, sorted last, as groupcounts treats a
         % missing group.
         [sets, setrows] = memberrows(G.(setvar));
         tmpG = cell(numel(sets), 1);
         for n = 1:numel(sets)
            Gn = groupcounts(G(setrows{n}, :), groupvars, groupbins, ...
               "IncludedEdge", opts.IncludedEdge);
            Gn.(setvar) = repmat(sets(n), height(Gn), 1);
            tmpG{n} = Gn;
         end
         G = stacktables(tmpG{:});

      else

         G = groupcounts(G, groupvars, groupbins, ...
            "IncludedEdge", opts.IncludedEdge);
      end

      % Restore each binned group variable's original name, so a caller reads
      % the same name whether or not groupbins was used.
      G = restoregroupvarnames(G, groupvars);
   end

   % If multiple groupvars, calculate the GroupPercent for each groupvar
   for m = 1:numel(groupsets)
      groupvar = groupsets(m);

      % The count makes every missing value one group, but a missing value
      % equals no member. memberrows gives those rows one member of their
      % own, so they get the percents of one more member. It also reads a
      % cellstr column, and a zero-row column gives no member.
      [~, grprows] = memberrows(G.(groupvar));

      % Compute the within group percentages. Every member's rows sum to 100,
      % including a member holding one row, which is then 100 percent of
      % itself. Normalizing over the whole table instead would produce
      % Percent, which is a different quantity groupcounts already returns.
      G.("Percent_" + groupvar) = nan(height(G), 1);
      for n = 1:numel(grprows)
         idx = grprows{n};
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
