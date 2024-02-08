function varargout = groupsummary(tbl, groupvars, methods, datavar, ...
      groupbins, groupsets, varargin)
   %GROUPSUMMARY Compute group-wise statistics 
   % 
   % Syntax:
   % 
   % G = groupstats.groupsummary(tbl,groupvars)
   % G = groupstats.groupsummary(tbl,groupvars,method)
   % G = groupstats.groupsummary(tbl,groupvars,method,datavars)
   % G = groupstats.groupsummary(tbl,groupvars,groupbins)
   % G = groupstats.groupsummary(tbl,groupvars,groupbins,method)
   % G = groupstats.groupsummary(tbl,groupvars,groupbins,method,datavars) 
   % 
   % Description:
   % 
   % G = groupsummary(tbl, groupvars, methods, datavar, groupbins, groupsets)
   % Calls groupsummary with custom function methods. 
   %
   % G = groupsummary(_, varargin) where 
   % 
   % Inputs:
   % 
   % tbl       - tabular object (table or timetable)
   % groupvars - char, cellstr, or string of variable names in T
   % methods   - char, cellstr, string, function handle, or combination thereof
   % datavar   - char, cellstr, or string of variable names in T
   % groupsets - char or string scalar indicating a variable name in T which
   %             specifies which groupvars define distinct sets, also known as
   %             "ingroups". For all groupvars in groupsets,
   %             G.(Percent_<varname>) will sum to 100%.
   % 
   % varargin - a set of Name-Value arguments accepted by groupsummary
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
   % - argument block
   % - call prepareTableGroups
   % - replace rowselectmembers with rowselectvar + rowselectmembers
   % - integrate groupsummary functionsignatures

   % methods = {@circ_mean,@circ_std,@circ_median,@iqr};

   % Todo: use arguments block
   % arguments
   %    T tabular
   %    groupvars
   %    methods = {'mean'}
   %    datavar = vartype("numeric")
   %    groupbins (1,:) = "none"
   %    groupsets = "none"
   % end
   
   % Parse inputs
   narginchk(2, Inf);

   validateattributes(tbl, "tabular", "nonempty", mfilename, "tbl", 1);

   % Set matrix/table switch flag
   tableFlag = istabular(tbl);
   
   if nargin < 3 || isempty(methods)
      methods = {'mean'};
   end
   if nargin < 4 || isempty(datavar)
      datavar = vartype("numeric");
   end
   if nargin < 5 || isempty(groupbins)
      groupbins = repmat("none", numel(groupvars), 1);
   end
   if nargin < 6 || isempty(groupsets)
      groupsets = "none";
   end

   % This is to sub-select rows. Not sure its worth the trouble
   if nargin == 7
      selectvars = string(varargin{:});
   else
      selectvars = "none";
   end

   % Downselect rows in T matching selectvars
   tbl = downselectvars(tbl, groupvars, selectvars);

   % Parse group bins
   groupbins = parseGroupBins(groupbins, groupvars);

   if tableFlag
      % Error if asking for more than 1 output for table
      nargoutchk(0,1);

      % Try to convert YData to double if it is categorical
      try
         tbl.(datavar) = double(tbl.(datavar));
      catch
         % let the built-in error catching do the work.
         % error( ...
         %    ['Failed to convert categorical datavar to numeric. Please ' ...
         %    'ensure the categories can be represented as numeric values.']);
      end

      % Convert groupvars to cellstr to simplify the variable renaming
      try
         groupvars = cellstr(groupvars);
      catch
      end

   else
      % convert the datavar to double in case of categorical
      try
         tbl = double(tbl);
      catch
         % let the built-in error catching do the work.
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


   if tableFlag

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
      if groupsets == "none"
         G = groupsummary(tbl, groupvars, groupbins, methods, datavar);
      else
         G = groupsummary(tbl, [groupvars, groupsets], groupbins, methods, datavar);
      end
      G.Properties.VariableNames = replace( ...
            G.Properties.VariableNames, "disc_", "");
      
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
      
      G = join(G, ...
         groupstats.grouppercent(tbl, groupvars, groupbins, groupsets));
      
      % Reset the variable names to match custom function names in methods. The
      % first variables will be groupvars followed by GroupCount from
      % groupsummary, and then the groupvar_method columns, then 'Percent' and
      % any 'Percent_<groupset>' variables from grouppercent. Moving GroupCounts
      % to the end, before Percent, avoids dealing with the groupsets variable
      % names.

      G = movevars(G, "GroupCount", "Before", "Percent");
      V = G.Properties.VariableNames;

      % this replaces the V2 part below but also negates the need for V1
      keep = cellfun(@(m) ~isa(m, 'function_handle'), methods);
      drop = cellfun(@(v) strncmp("fun", v, 3), V);
      newvars = arrayfun(@(v) cellfun(@(m) strcat(func2str(m), '_', v), ...
         methods(~keep), 'un', 0), datavar, 'un', 0);
      V(drop) = cellstr(horzcat(newvars{:}));

      % V(notok) = cellfun(@(x) ...
      %    strcat(func2str(x),'_',datavar), methods(~ok),'un',0);

      G = settablevarnames(G, V);

      varargout{1} = G;

   else
      [G, GR, GC] = groupsummary(tbl, groupvars, methods);

      [varargout{1:nargout}] = deal(G, GR, GC);
   end
end


function tbl = downselectvars(tbl, groupvars, groupvarselect)

   if groupvarselect ~= "none"

      % Find which groupvar contains the groupvarselect
      tf = arrayfun(@(n) all(ismember(groupvarselect, ...
         string(unique(tbl.(groupvars(n)))))), 1:numel(groupvars));

      % enforce one groupvar for downselection
      assert(sum(tf) <= 1, ...
         "only one groupvar can be downselected using groupvarselect")

      % Keep members of groupvars that are in "groupvarselect", if any found
      if any(tf)
         tbl = tbl(ismember(string(tbl.(groupvars(tf))),groupvarselect), :);
      end
   end
end

function groupbins = parseGroupBins(groupbins, groupvars)
   % NOTE: groupbins needs to have one binning method per groupvar, but its
   % complicated b/c groupbins can be a vector e.g. bin edges or a cell array,
   % so for groupvars = {'var1','var2'}, groupbins could be [1,2,3], and [1,2,3]
   % would apply to both var1 and var2, but this probably isn't what we want,
   % and groupsummary error message is hard to interpret in this case, so I need
   % to require groiupbins to be a cell array I tink

   if ~iscell(groupbins)
      if isstring(groupbins) && ~all(groupbins == "none")
         error( ...
            ['groupbins must be a cell array with one binning scheme per ' ...
            'variable in groupvars or a scalar string "none"'])
      end
   end

   if numel(groupbins) ~= numel(groupvars)
      % this tries to apply groupbins to each variable, or assume its for the
      % first one and set the rest "none" ...
      groupbins = [groupbins, {repmat("none", numel(groupvars)-1, 1)}];

      % if one binning scheme was provided, apply it to each variable
      % if numel(groupbins) == 1
      %    groupbins = repmat(groupbins, 1, numel(groupvars));
      % else
      %    groupbins = {groupbins, repmat("none", numel(groupvars)-1,1)};
      % end
   end
end

   % % TEST
   %    % This shows how I cannot get something like the change between groups
   %    without addding new functinaliyt like "ReferenceGroup" which is probably
   %    better for a standalone function
   %
   %    % If there was a "ReferenceGroup" option, I could make it work:
   %    ReferenceGroupVar = "basin";
   %    ReferenceGroup = "Outlet";
   %    Tref = T(T.(ReferenceGroupVar) == ReferenceGroup, :);
   %
   %
   %    Fcount = @(s, b, m) sum(T{T.rcp == s & T.month == m, b});
   %    Fcount("Historical", "Outlet", "Jan")
   %    months = unique(T.month);
   %    for n = 1:numel(months)
   %       idxInfo = T.month==months(n);
   %       idxStats = G.month==months(n);
   %       [Percents, Counts] = pfa.percentDeltaFCS(T(idxInfo, :), "rcp");
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
