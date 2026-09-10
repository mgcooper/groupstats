function S = groupsamples(tbl, groupvar, datavar, opts)
   %GROUPSAMPLES Collect the data of each group member, reference first.
   %
   %  S = GROUPSAMPLES(TBL, GROUPVAR, DATAVAR)
   %  S = GROUPSAMPLES(_, ReferenceGroup=MEMBER)
   %  S = GROUPSAMPLES(_, ConditionVar=NAME)
   %  S = GROUPSAMPLES(_, Pooled=TRUE)
   %
   % Description
   %  S = GROUPSAMPLES(TBL, GROUPVAR, DATAVAR) returns one row per member of
   %  GROUPVAR. S.Group names the member and S.Data holds a cell with that
   %  member's DATAVAR values as one column vector, missing values left
   %  out. The reference member comes first: the first member in category
   %  order, or the one ReferenceGroup names.
   %
   %  ConditionVar names a second grouping variable. S then holds the rows
   %  of every member once per member of that variable, with S.Set naming
   %  it. The reference row comes first within each set. A member with no rows in a
   %  set gets no row there. A row whose group or condition value is
   %  missing belongs to no member and is left out. A table with no usable
   %  row gives S with no rows.
   %
   %  Pooled=true keeps the reference row and pools every other member into
   %  one row, whose Group joins the pooled names with ", ". Pooling happens
   %  within each set, not across sets. A set holding only the reference
   %  has nothing to pool and keeps its one row.
   %
   %  The table goes through groupstats.prepareTableGroups first, the step
   %  every chart in the toolbox runs. That step checks the variable
   %  names, rejects a matrix group variable, and converts the groupings
   %  to categorical. It also drops the rows whose group or condition
   %  value is missing.
   %
   %  This is the reshape groupcompare runs before its tests, and the
   %  table-facing way to hand two samples to a test of your own:
   %
   %   S = groupstats.groupsamples(tbl, "Group", "Value");
   %   p = ranksum(S.Data{1}, S.Data{2});
   %
   %  The vendored permutest is private to the package, so from outside it
   %  is reached through groupcompare(..., Test="permutation").
   %
   % Errors
   %  groupstats:prepareTableGroups:unknownVariable - GROUPVAR, DATAVAR, or
   %  ConditionVar is not a variable of the table.
   %  groupstats:prepareTableGroups:multiColumnGroupVar - GROUPVAR or
   %  ConditionVar names a matrix variable.
   %  groupstats:groupsamples:multiColumnDataVar - DATAVAR names a matrix
   %  variable; a sample is one column.
   %  groupstats:groupsamples:badReferenceGroup - ReferenceGroup is not a
   %  member of GROUPVAR.
   %  groupstats:groupsamples:emptyReferenceGroup - the reference member
   %  has no values in one of the ConditionVar sets, or, without
   %  ConditionVar, every one of its DATAVAR values is missing.
   %
   % Example
   %  tbl = table(categorical(["a"; "b"; "a"; "b"]), [1; 5; 2; 6], ...
   %     'VariableNames', {'Group', 'Value'});
   %  S = groupstats.groupsamples(tbl, "Group", "Value", ReferenceGroup="b");
   %  S.Group      % ["b"; "a"]
   %  S.Data{1}    % [5; 6]
   %
   % See also: groupstats.groupcompare, groupstats.prepareTableGroups

   arguments
      tbl tabular
      groupvar (1, 1) string {mustBeNonempty}
      datavar (1, 1) string {mustBeNonempty}
      opts.ReferenceGroup string {mustBeScalarOrEmpty} = string.empty()
      % One condition variable or none. A vector would name two sets of
      % comparisons, and the per-set loop reads one.
      opts.ConditionVar string {mustBeScalarOrEmpty} = string.empty()
      opts.Pooled (1, 1) logical = false
   end

   import groupstats.prepareTableGroups

   % The shared preprocessing: name checks, the matrix-variable guard, the
   % categorical conversion, and the drop of rows whose group or condition
   % value is missing. After it, the categories are the present members in
   % category order.
   tbl = prepareTableGroups(tbl, datavar, XGroupVar = groupvar, ...
      CGroupVar = opts.ConditionVar);

   % A sample is one column. A matrix data variable would give matrix
   % samples, which a test cannot read.
   if ~iscolumn(tbl.(datavar))
      error('groupstats:groupsamples:multiColumnDataVar', ...
         'datavar "%s" has %d columns. A sample is one column.', ...
         datavar, size(tbl.(datavar), 2))
   end

   % With no usable row there is no member and no set, so return the
   % schema with no rows, whatever ReferenceGroup names.
   S = table(strings(0, 1), cell(0, 1), 'VariableNames', {'Group', 'Data'});
   if ~isempty(opts.ConditionVar)
      S = addvars(S, strings(0, 1), 'NewVariableNames', 'Set', 'Before', 1);
   end
   if height(tbl) == 0
      return
   end

   % The categories are the present members in category order, with the
   % reference moved to the front. The rows are compared against them as
   % the categorical they are.
   members = string(categories(tbl.(groupvar)));
   members = orderReferenceFirst(members, opts.ReferenceGroup);
   groupvalues = tbl.(groupvar);

   % One set of rows per ConditionVar member, or one set of every row.
   if isempty(opts.ConditionVar)
      sets = "";
      inset = {true(height(tbl), 1)};
   else
      setvalues = tbl.(opts.ConditionVar);
      sets = string(categories(setvalues));
      inset = arrayfun(@(s) setvalues == s, sets, 'UniformOutput', false);
   end

   rows = cell(numel(sets), 1);
   for m = 1:numel(sets)
      % A missing value is not an observation: ranksum would skip it, but
      % a median, a t-statistic, or a bootstrap draw would turn NaN.
      data = arrayfun(@(member) presentValues(tbl{groupvalues == member ...
         & inset{m}, datavar}), members, 'UniformOutput', false);

      % Every comparison is against the reference, so it needs data. The
      % members come from the rows, so a set can lack the reference. A
      % member whose every value is missing has rows but no data.
      if isempty(data{1})
         if isempty(opts.ConditionVar)
            where = "";
         else
            where = sprintf(' in set "%s" of %s', sets(m), opts.ConditionVar);
         end
         error('groupstats:groupsamples:emptyReferenceGroup', ...
            ['The reference group "%s" has no values%s. Every ' ...
            'comparison needs reference data.'], members(1), where)
      end

      % A member with no rows in this set has nothing to compare or pool,
      % so it gets no row here. The reference was checked above.
      present = ~cellfun(@isempty, data);
      data = data(present);
      names = members(present);

      % Pooling changes the number of rows, so the labels change with it.
      % A set holding only the reference has nothing to pool.
      if opts.Pooled && numel(names) > 1
         data = [data(1); {vertcat(data{2:end})}];
         names = [names(1); strjoin(names(2:end), ", ")];
      end

      rows{m} = table(names, data, 'VariableNames', {'Group', 'Data'});
      if ~isempty(opts.ConditionVar)
         rows{m} = addvars(rows{m}, repmat(sets(m), height(rows{m}), 1), ...
            'NewVariableNames', 'Set', 'Before', 1);
      end
   end

   S = vertcat(S, rows{:});
end

function values = presentValues(values)
   %PRESENTVALUES The values of one sample with the missing ones left out.

   values = values(~ismissing(values));
end

function members = orderReferenceFirst(members, ReferenceGroup)
   %ORDERREFERENCEFIRST Put the reference member first in the member list.
   %
   % Every comparison is against members(1). Without a named reference that
   % is whichever member comes first, which is rarely the control group.

   if isempty(ReferenceGroup)
      return
   end
   isreference = members == ReferenceGroup;
   if ~any(isreference)
      error('groupstats:groupsamples:badReferenceGroup', ...
         ['ReferenceGroup "%s" is not a member of the group variable. ' ...
         'Members: %s.'], ReferenceGroup, strjoin(members, ', '))
   end
   members = [members(isreference); members(~isreference)];
end
