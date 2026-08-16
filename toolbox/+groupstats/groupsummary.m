function G = groupsummary(tbl, groupvars, methods, datavar, ...
      groupbins, groupsets, opts)
   %GROUPSUMMARY Compute group-wise statistics
   %
   % Syntax:
   %
   % G = groupstats.groupsummary(tbl,groupvars)
   % G = groupstats.groupsummary(tbl,groupvars,methods)
   % G = groupstats.groupsummary(tbl,groupvars,methods,datavar)
   % G = groupstats.groupsummary(tbl,groupvars,methods,datavar,groupbins)
   % G = groupstats.groupsummary(_,groupsets)
   % G = groupstats.groupsummary(_,RowSelectVar=NAME,RowSelectMembers=M)
   %
   % Description:
   %
   % G = groupsummary(tbl, groupvars, methods, datavar, groupbins, groupsets)
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
   %             scalar string "none" to bin nothing.
   % groupsets - char or string scalar indicating a variable name in tbl which
   %             specifies which groupvars define distinct sets, also known as
   %             "ingroups". For all groupvars in groupsets,
   %             G.(Percent_<varname>) will sum to 100%.
   %
   % RowSelectVar, RowSelectMembers - keep only the rows whose RowSelectVar
   %             value is one of RowSelectMembers, before summarizing.
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
   % 3. Group percents are computed for ingroups using the groupsets optional
   % input. This contrasts with the Percent variable returned by groupcounts,
   % which is the frequency of each group relative to all observations in all
   % groups.
   %
   % See also: groupbayes, grouppercent

   % Note, i changed GroupPercent back to Percent for consistency with matlab

   % groupsummary by default returns counts, but not percents.
   % groupcounts returns the counts and the percents.
   % Neither return them for "ingroups" (groupsets).
   % The toolbox function grouppercent is like groupcounts but supports
   % groupsets. This function combines the ability to compute additional
   % statistics using groupsummary with the default frequencies returned by
   % grouppercent.

   % TODO:
   % - integrate groupsummary functionsignatures

   % methods = {@circ_mean,@circ_std,@circ_median,@iqr};

   arguments
      tbl tabular {mustBeNonempty}
      groupvars (1, :) string
      methods = {'mean'}
      datavar = vartype("numeric")
      groupbins (1, :) = "none"
      groupsets (1, :) string = string.empty()
      opts.RowSelectVar (1, :) string = string.empty()
      opts.RowSelectMembers (:, 1) string = string.empty()
   end

   % import groupstats package
   import groupstats.groupselect

   % "none" is the sentinel this family uses for "no groupsets". Convert it to
   % the empty sentinel, so the code below never treats it as a variable name.
   if isscalar(groupsets) && groupsets == "none"
      groupsets = string.empty();
   end

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

   if ~iscell(methods)
      methods = {methods};
   end

   % Group by groupsets too, so each set gets its own rows. Add it only when
   % groupvars does not already name it, because naming a variable twice
   % makes MATLAB's groupsummary group by it twice. reshape because setdiff
   % returns a column for an empty input, which will not concatenate with
   % the row groupvars holds, so reshape it to a row.
   extrasets = setdiff(string(groupsets), string(groupvars), 'stable');
   summaryvars = [groupvars, reshape(extrasets, 1, [])];

   % Resolve datavar to variable names. The default is a vartype subscript,
   % which selects columns but cannot be indexed by arrayfun or used to build
   % an output variable name, both of which happen below. Exclude every
   % variable the summary groups by, so a numeric groupsets variable is not
   % also summarized as data.
   datavar = resolveDataVars(tbl, datavar, summaryvars);

   % Keep only the requested rows. groupselect reports which variable it
   % searched and what it looked for when nothing matches.
   %
   % Row selection is the only preparation this function shares with the
   % chart family. prepareTableGroups also coerces group variables to
   % categorical, drops unused categories and missing-group rows, and converts
   % the data variable to double. A summary must report the groups and rows
   % the caller's table holds, so it does not route through it.
   if ~isempty(opts.RowSelectMembers)
      selectvars = opts.RowSelectVar;
      if isempty(selectvars)
         selectvars = groupvars;
      end
      tbl = groupselect(tbl, selectvars, opts.RowSelectMembers);
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
         % error( ...
         %    ['Failed to convert categorical datavar to numeric. Please ' ...
         %    'ensure the categories can be represented as numeric values.']);
      end
   end

   % Next was replaced by more robust method in if tableFlag section. This was
   % for the first case where I just wanted to replace the function handles,
   % before bringing in the groupsummary/grouppercent join, I think.
   %
   % Create a cellstr array of method names converting function handles to names
   % names = methods;
   % for n = 1:numel(methods)
   %    if isa(methods{n},"function_handle")
   %       names{n} = func2str(methods{n});
   %    end
   % end
   % % make valid unique varnames
   % names = matlab.lang.makeValidName(names, 'ReplacementStyle', 'delete');
   % names = matlab.lang.makeUniqueStrings(names,1:numel(names),namelengthmax);
   % % names = makevalidvarnames(names);


   % Original, need to test the join with non-none bins
   % G = groupsummary(tbl,groupvars,groupbins,methods,datavar);

   % G = join( ...
   %    groupsummary(tbl, groupvars, groupbins, methods, datavar), ...
   %    groupstats.grouppercent(tbl, groupvars, groupbins, groupsets) );

   % 19 Nov 2023 UPDATE:
   % I think groupsets must be also included in groupvars, and maybe up to
   % now that never came up but I called this function with "months" for
   % groupvar and "scenario" for groupsets expecting it to compute
   % groupsummary for all months by scenario, but groupsets is only used in
   % the call to grouppercent. So I added the [groupvars, groupsets].
   G = groupsummary(tbl, cellstr(summaryvars), groupbins, methods, datavar);

   G = dropDiscPrefix(G, cellstr(summaryvars));

   % If groupbins are used and there is <undefined> e.g. if the groupbins did
   % not include enough edges to define all bins, join will fail with error
   % "The key variables cannot contain any missing values". So, try to
   % replace with NaN. BUT this gets complicated if any values are ordinal or
   % categorical (I think the <undefined> issue is due to categorical)
   %
   % This was a start to fix this, idea was to replace missing with nan, but
   % then I realized its due to categorical, so its complicated whether that
   % should be done or not, and insead, probably better to use a join
   % approach similar to stacktables. But for now my solution was to properly
   % efine the FCS bins outside this function
   % vars = G.Properties.VariableNames;
   % for n = 1:numel(vars)
   %    idx = ismissing(G{:, vars{n}});
   % end

   % Group the percents by summaryvars too, so the join has one key per
   % group and every row finds its match.
   G = join(G, ...
      groupstats.grouppercent(tbl, summaryvars, groupbins, groupsets));

   % Reset the variable names to match custom function names in methods. The
   % first variables will be groupvars followed by GroupCount from
   % groupsummary, and then the groupvar_method columns, then 'Percent' and
   % any 'Percent_<groupset>' variables from grouppercent. Moving GroupCounts
   % to the end, before Percent, avoids dealing with the groupsets variable
   % names.

   G = movevars(G, "GroupCount", "Before", "Percent");
   V = G.Properties.VariableNames;

   % NOTE: Apr 2024 - if methods is function handle like @(x) mean(x) then
   % the stuff below literally makes the variable name "@(x)mean(x)_varname"

   % this replaces the V2 part below but also negates the need for V1
   V = renameFunctionHandleVars(V, methods, datavar);

   % V(notok) = cellfun(@(x) ...
   %    strcat(func2str(x),'_',datavar), methods(~ok),'un',0);

   G = settablevarnames(G, V);
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
   % NOTE: groupbins needs to have one binning method per groupvar, but its
   % complicated b/c groupbins can be a vector e.g. bin edges or a cell array,
   % so for groupvars = {'var1','var2'}, groupbins could be [1,2,3], and [1,2,3]
   % would apply to both var1 and var2, but this probably isn't what we want,
   % and groupsummary error message is hard to interpret in this case, so I need
   % to require groiupbins to be a cell array I tink

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

% % TEST
%    % This shows how I cannot get something like the change between groups
%    without addding new functinaliyt like "ReferenceGroup" which is probably
%    better for a standalone function
%
%    % If there was a "ReferenceGroup" option, I could make it work:
%    ReferenceGroupVar = "basin";
%    ReferenceGroup = "Outlet";
%    Tref = tbl(tbl.(ReferenceGroupVar) == ReferenceGroup, :);
%
%
%    Fcount = @(s, b, m) sum(tbl{tbl.rcp == s & tbl.month == m, b});
%    Fcount("Historical", "Outlet", "Jan")
%    months = unique(tbl.month);
%    for n = 1:numel(months)
%       idxInfo = tbl.month==months(n);
%       idxStats = G.month==months(n);
%       [Percents, Counts] = pfa.percentDeltaFCS(tbl(idxInfo, :), "rcp");
%
%       % to assign them,
%       basinStats.Counts(idxStats) = Counts(:);
%       basinStats.percentDeltaFCS(idxStats) = Percents(:);
%    end
%    % TEST

% try
%    [G,GR,GC] = groupsummary(tbl,groupvars,methods,datavar);
% catch
%    G = groupsummary(tbl,groupvars,methods,datavar);
% end

% Replace discretized (binned) groupvars. Note - might have worked to just
% search for varnames containing datavar, but oh well. Update - I think this
% just rebuilds the disc_<datavar> column names, so I commented it out when I
% creatd the method below that searches for fun_ anmes
% V1 = groupvars;
% ok = false(size(groupbins));
% ii = cellfun(@ischarlike, groupbins);
% ok(ii) = cellfun(@(groupvar) ismember(groupvar, "none"), groupbins(ii));
% V1(~ok) = cellfun(@(groupvar) ...
%    strcat('disc_', groupvar), groupvars(~ok),'un',0);

% % Replace custom function handles

% % This works if datavar is a scalar
% ok = cellfun(@(m) ~isa(m,'function_handle'), methods);
% V2 = methods;
% V2(ok) = strcat(methods(ok),'_', char(datavar));
% V2(~ok) = cellfun(@(x) ...
%    strcat(func2str(x),'_',char(datavar)), methods(~ok),'un',0);

% % this could work when datavar is not a scalar, but not sure
% vv = arrayfun(@(y) cellfun(@(x) ...
%    strcat(x,'_', y), methods(ok),'un',0), datavar, 'un',0);
% V2(ok) = cellstr(horzcat(vv{:}))

% % Put them all together
% V = horzcat(V1{:}, V2{:}, V(numel(groupvars)+numel(methods)+1:end));
