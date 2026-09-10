function G = groupsummary(tbl, groupvars, methods, datavar, ...
      groupbins, opts)
   %GROUPSUMMARY Compute group-wise statistics
   %
   % Syntax:
   %
   % G = groupstats.groupsummary(tbl,groupvars)
   % G = groupstats.groupsummary(tbl,groupvars,methods)
   % G = groupstats.groupsummary(tbl,groupvars,methods,datavar)
   % G = groupstats.groupsummary(tbl,groupvars,methods,datavar,groupbins)
   % G = groupstats.groupsummary(_,GroupSets=NAME)
   % G = groupstats.groupsummary(_,RowSelectVar=NAME,RowSelectMembers=M)
   %
   % The positional order differs from the builtin, which takes
   % groupsummary(T, groupvars, groupbins, method, datavars). The builtin
   % puts groupbins third and tells it from method by inspecting the value,
   % which an arguments block cannot do. Here the everyday inputs come in
   % the order a caller most often needs them: methods, then datavar, then
   % groupbins. A caller who bins almost always names the method and the
   % data variable too. The groupstats-only control GroupSets is a
   % name-value option, so no caller spells out every earlier default to
   % reach it.
   %
   % MATLAB reads an optional positional text value as an option name when
   % it matches one (GroupSets, RowSelectVar, RowSelectMembers,
   % IncludedEdge, or a prefix of one) and another positional follows it.
   % A data variable named "GroupSets", "Group", or "Included" in the
   % five-positional form is therefore read as the option. Pass such a
   % name as a cellstr, {'Group'}, which MATLAB never reads as a name.
   %
   % Description:
   %
   % G = groupsummary(tbl, groupvars, methods, datavar, groupbins)
   % Calls groupsummary with custom function methods.
   %
   % Inputs:
   %
   % tbl       - tabular object (table or timetable)
   % groupvars - char, cellstr, or string of variable names in tbl
   % methods   - char, cellstr, string, function handle, or combination thereof
   % datavar   - char, cellstr, or string of variable names in tbl. Omit it to
   %             summarize every numeric variable that is not a groupvar.
   % groupbins - one binning scheme per groupvar, in a cell array, or the
   %             scalar string "none" to bin nothing. Explicit edges must
   %             span the data; see Errors below.
   %
   % IncludedEdge - "left" (default) or "right", the bin edge a value on an
   %             edge belongs to, passed to the builtin for every binned
   %             groupvar. "left" puts a value on an edge in the bin that
   %             starts there; "right" puts it in the bin that ends there.
   %
   % GroupSets - one or more variable names in tbl, as a string vector or
   %             cellstr, naming the variables whose members define distinct
   %             sets, also known as "ingroups". For every variable in
   %             GroupSets, G.(Percent_<varname>) sums to 100 within each of
   %             its members. Omit the option or pass string.empty() to
   %             request no groupsets. The scalar string "none" is not a
   %             GroupSets value and is rejected, so a table variable
   %             literally named "none" cannot be selected this way.
   %
   % RowSelectVar, RowSelectMembers - keep only the rows whose RowSelectVar
   %             value is one of RowSelectMembers, before summarizing. Give
   %             both together: either one alone is an error, the same two
   %             errors groupstats.prepareTableGroups raises.
   %
   %
   % This function provides three conveniences:
   %
   % 1. If methods contains anonymous function handles, the variable names in
   % the output table are renamed using the function handle name i.e., instead
   % of "fun1_<datavar>" the variable will be the function handle name returned
   % by fnc2str
   %
   % 2. The output of groupcounts is joined with the output of groupsummary
   %
   % 3. Group percents are computed for ingroups using the GroupSets
   % option. This contrasts with the Percent variable returned by groupcounts,
   % which is the frequency of each group relative to all observations in all
   % groups.
   %
   % Errors:
   %
   % groupstats:groupsummary:binsDoNotSpanData - a bin scheme leaves rows
   % outside its edges, so they would form an <undefined> group and the
   % internal percent join would fail on a missing key. The message names
   % the group variable, the scheme, and the row count. Widen the edges or
   % select the rows first.
   %
   % groupstats:groupsummary:noDataVariables - datavar resolved to no
   % variable. Every numeric variable of the table is a group variable, so
   % none is left to summarize. Name datavar explicitly.
   %
   % groupstats:groupsummary:badGroupBins - groupbins is not a scalar string
   % "none" and does not hold one scheme per variable in groupvars, one
   % scheme in total, or a valid non-cell scheme.
   %
   % groupstats:groupsummary:rowSelectVarWithoutMembers and
   % groupstats:groupsummary:membersWithoutGroupVar - RowSelectVar or
   % RowSelectMembers was given without the other.
   %
   % Example
   %
   % Summarize peak by scenario and month, with the percent of each
   % scenario's rows that fall in each month:
   %
   %  data = groupstats.test.generateTestData('info');
   %  G = groupstats.groupsummary(data.Info, ["scenario", "month"], ...
   %     ["mean", "max"], "peak", GroupSets = "scenario");
   %  head(G, 5)
   %
   % See also: groupbayes, grouppercent

   % groupsummary by default returns counts, but not percents.
   % groupcounts returns the counts and the percents.
   % Neither return them for "ingroups" (groupsets).
   % The toolbox function grouppercent is like groupcounts but supports
   % groupsets. This function combines the ability to compute additional
   % statistics using groupsummary with the default frequencies returned by
   % grouppercent.

   arguments
      tbl tabular {mustBeNonempty}
      groupvars (1, :) string
      methods = {'mean'}
      datavar = vartype("numeric")
      groupbins (1, :) = "none"
      opts.GroupSets (1, :) string = string.empty()
      opts.RowSelectVar (1, :) string = string.empty()
      opts.RowSelectMembers (:, 1) string = string.empty()
      opts.IncludedEdge (1, 1) string ...
         {mustBeMember(opts.IncludedEdge, ["left", "right"])} = "left"
   end

   % import groupstats package
   import groupstats.groupselect

   % string.empty() is the one no-groupsets sentinel across the family. The
   % shared validator rejects a scalar "none" with the rewrite, so the code
   % below never treats it as a variable name.
   validategroupsets(opts.GroupSets)

   % An empty positional argument means "use the default", so a caller can
   % skip one and still reach the argument after it.
   if isempty(methods)
      methods = {'mean'};
   end
   if isempty(datavar)
      datavar = vartype("numeric");
   end
   if isempty(groupbins)
      groupbins = "none";
   end

   % The builtin takes the methods as a cell. A string array is a list of
   % names, one method per element; a char, a scalar string, or a function
   % handle is one method.
   if isstring(methods)
      methods = cellstr(methods);
   elseif ~iscell(methods)
      methods = {methods};
   end

   % Group by groupsets too, so each set gets its own rows. Add it only when
   % groupvars does not already name it, because naming a variable twice
   % makes MATLAB's groupsummary group by it twice. reshape because setdiff
   % returns a column for an empty input, which will not concatenate with
   % the row groupvars holds, so reshape it to a row.
   extrasets = setdiff(string(opts.GroupSets), string(groupvars), 'stable');
   summaryvars = [groupvars, reshape(extrasets, 1, [])];

   % Resolve datavar to variable names. The default is a vartype subscript,
   % which selects columns but cannot be indexed by arrayfun or used to build
   % an output variable name, both of which happen below. Exclude every
   % variable the summary groups by, so a numeric groupsets variable is not
   % also summarized as data.
   datavar = resolveDataVars(tbl, datavar, summaryvars);

   % Keep only the requested rows. Row selection needs both halves, and the
   % shared check raises the same two errors prepareTableGroups raises,
   % under this function's own identifiers. groupselect reports which
   % variable it searched and what it looked for when nothing matches.
   %
   % Row selection is the only preparation this function shares with the
   % chart family. prepareTableGroups also coerces group variables to
   % categorical, drops unused categories and missing-group rows, and converts
   % the data variable to double. A summary must report the groups and rows
   % the caller's table holds, so it does not route through it.
   validaterowselect(opts.RowSelectVar, opts.RowSelectMembers, ...
      "groupsummary", "groupsummary")
   if ~isempty(opts.RowSelectMembers)
      tbl = groupselect(tbl, opts.RowSelectVar, opts.RowSelectMembers);
   end

   % Parse the bins against groupvars, the list the caller sized them for.
   % The added set variable was never given a scheme, so bin it with "none".
   groupbins = parseGroupBins(groupbins, groupvars);
   groupbins = [groupbins, repmat({"none"}, 1, numel(extrasets))];

   % Try to convert each data variable to double if it is categorical
   for n = 1:numel(datavar)
      try
         tbl.(datavar(n)) = double(tbl.(datavar(n)));
      catch
         % let the built-in error catching do the work.
      end
   end

   % Summarize with the built-in groupsummary, grouped by every summary
   % variable, so each groupsets member gets its own rows.
   G = groupsummary(tbl, cellstr(summaryvars), groupbins, methods, datavar, ...
      "IncludedEdge", opts.IncludedEdge);

   requireSpanningBins(G, summaryvars, groupbins)

   G = dropDiscPrefix(G, cellstr(summaryvars));

   % Group the percents by summaryvars too, so the join has one key per
   % group and every row finds its match.
   G = join(G, ...
      groupstats.grouppercent(tbl, summaryvars, groupbins, ...
      GroupSets = opts.GroupSets, IncludedEdge = opts.IncludedEdge));

   % Reset the variable names to match custom function names in methods. The
   % first variables will be groupvars followed by GroupCount from
   % groupsummary, and then the groupvar_method columns, then 'Percent' and
   % any 'Percent_<groupset>' variables from grouppercent. Moving GroupCounts
   % to the end, before Percent, avoids dealing with the groupsets variable
   % names.

   G = movevars(G, "GroupCount", "Before", "Percent");
   V = G.Properties.VariableNames;

   % Rename the generated fun<n>_<var> columns after the anonymous methods.
   V = renameFunctionHandleVars(V, methods, datavar);

   G = settablevarnames(G, V);
end

function requireSpanningBins(G, groupvars, groupbins)
   %REQUIRESPANNINGBINS Error when a bin scheme left rows outside its edges.
   %
   % The builtin puts those rows in an <undefined> group of the binned
   % variable, and the percent join fails on that missing key with a
   % message that names no cause. Report the scheme instead.

   for n = 1:numel(groupbins)
      scheme = groupbins{n};
      if (ischar(scheme) || isstring(scheme)) && all(string(scheme) == "none")
         continue
      end
      binned = "disc_" + string(groupvars(n));
      if ~ismember(binned, string(G.Properties.VariableNames))
         continue
      end
      outside = ismissing(G.(binned));
      if any(outside)
         if isnumeric(scheme)
            schemetext = mat2str(scheme);
         else
            schemetext = strjoin(string(scheme), ", ");
         end
         error('groupstats:groupsummary:binsDoNotSpanData', ...
            ['The groupbins scheme %s for %s leaves %d rows outside its ' ...
            'bins. Widen the edges to span the data, or select the rows ' ...
            'first.'], schemetext, groupvars(n), sum(G.GroupCount(outside)))
      end
   end
end

function tbl = dropDiscPrefix(tbl, groupvars)
   %DROPDISCPREFIX Restore a binned group variable's original name.
   %
   % groupcounts and groupsummary name a binned group variable disc_<name>.
   % Strip that prefix so a caller reads the same name whether or not
   % groupbins was used.
   %
   % Only a name built from one of groupvars is renamed. A blanket substring
   % replace would also rewrite a variable the caller named disc_something.

   names = string(tbl.Properties.VariableNames);
   binned = "disc_" + string(groupvars);

   [isbinned, loc] = ismember(names, binned);
   names(isbinned) = string(groupvars(loc(isbinned)));

   tbl.Properties.VariableNames = names;
end

function datavar = resolveDataVars(tbl, datavar, groupvars)
   %RESOLVEDATAVARS Return the data variable names as a string array.
   %
   % datavar may arrive as a vartype subscript, which is the default. A
   % subscript selects columns but cannot be indexed or pasted into an output
   % variable name, so resolve it to names here. A group variable is never a
   % data variable, matching what the built-in groupsummary does.

   if isstring(datavar) || ischar(datavar) || iscellstr(datavar)
      datavar = string(datavar);
      return
   end

   datavar = string(tbl(:, datavar).Properties.VariableNames);
   datavar = datavar(~ismember(datavar, string(groupvars)));

   if isempty(datavar)
      error('groupstats:groupsummary:noDataVariables', ...
         ['No variable is left to summarize. Every numeric variable of the ' ...
         'table is a group variable. Name the data variable explicitly.'])
   end
end

function V = renameFunctionHandleVars(V, methods, datavar)
   %RENAMEFUNCTIONHANDLEVARS Give each anonymous method its own column name.
   %
   % The built-in groupsummary names an anonymous method's output fun1_<var>,
   % fun2_<var>, and so on. Replace those with the function's own text.
   % func2str returns an anonymous function's full text, so the column for
   % the method @(x)mean(x) is named @(x)mean(x)_<datavar>.
   %
   % Match the generated names by their fun<digits>_ shape, anchored to the
   % end. Matching a bare "fun" prefix would also rename a variable the caller
   % happened to name funding or function_id.

   handles = cellfun(@(m) isa(m, 'function_handle'), methods);
   if ~any(handles)
      return
   end

   generated = ~cellfun(@isempty, regexp(V, '^fun\d+_', 'once'));

   newvars = arrayfun(@(v) cellfun(@(m) strcat(func2str(m), '_', v), ...
      methods(handles), 'un', 0), datavar, 'un', 0);
   newvars = cellstr(horzcat(newvars{:}));

   if nnz(generated) ~= numel(newvars)
      % groupsummary named a different number of columns than the anonymous
      % methods and data variables account for, so a rename would misalign
      % them. Leave the generated names alone.
      return
   end

   V(generated) = newvars;
end

function groupbins = parseGroupBins(groupbins, groupvars)
   %PARSEGROUPBINS Return one binning scheme per group variable.
   %
   % A scalar "none" or a single scheme broadcasts to every groupvar. Any
   % other count mismatch errors here, because the message the built-in
   % groupsummary raises for that case is hard to interpret.

   if ~iscell(groupbins)
      if isstring(groupbins) || ischar(groupbins)
         if ~all(string(groupbins) == "none")
            error('groupstats:groupsummary:badGroupBins', ...
               ['groupbins must be a cell array with one binning scheme ' ...
               'per variable in groupvars or a scalar string "none"'])
         end

         % A scalar "none" bins nothing, whatever the number of groupvars.
         groupbins = repmat({"none"}, 1, numel(groupvars));
      else
         % A bare scheme, such as bin edges or a bin count. It is one scheme,
         % so wrap it and let the count check below broadcast it.
         groupbins = {groupbins};
      end
   end

   if numel(groupbins) == numel(groupvars)
      return
   end

   if isscalar(groupbins)
      % One scheme applies to every group variable, which is what the built-in
      % groupsummary does with a single scheme.
      groupbins = repmat(groupbins, 1, numel(groupvars));
      return
   end

   error('groupstats:groupsummary:badGroupBins', ...
      ['groupbins holds %d binning schemes for %d group variables. ' ...
      'Provide one per variable, one in total, or the scalar string ' ...
      '"none".'], numel(groupbins), numel(groupvars))
end
