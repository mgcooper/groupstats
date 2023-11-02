function varargout = groupstats(T, groupvars, methods, datavar, ...
      groupbins, groupsets, varargin)
   %GROUPSTATS Compute group-wise statistics 
   % 
   %  Stats = groupstats(T, groupvars, methods, datavar, groupbins, groupsets)
   %  Calls groupsummary with custom function methods. 
   %
   % Note, right now this only supports the following calling syntax:
   %
   % G = groupstats(T,groupvars,methods,datavar,varargin) where T is a table,
   % groupvars, methods, and datavar are charlike, and varargin is a set of
   % Name-Value arguments accepted by groupsummary
   %
   % [G,GR,GC] = groupstats(A,groupvars,methods,datavar,varargin) where A
   % is an array, otherwise same as above
   %
   % groupsets specifies which groupvars define distinct sets, also known as
   % "ingroups". For all groupvars in groupsets, G.(Percent_<varname>) will sum to
   % 100%.
   %
   % Eventually it should conform to the following groupsummary calling syntax:
   %
   % G = groupstats(T,groupvars)
   % G = groupstats(T,groupvars,method)
   % G = groupstats(T,groupvars,method,datavars)
   % G = groupstats(T,groupvars,groupbins)
   % G = groupstats(T,groupvars,groupbins,method)
   % G = groupstats(T,groupvars,groupbins,method,datavars)
   %
   % This function provides three conveniences:
   %
   % 1. If methods contains anonymous function handles, the variable names in the
   % output table are renamed using the function handle name i.e., instead of
   % "fun1_<datavar>" the variable will be the function handle name returned by
   % fnc2str
   %
   % 2. The output of groupcounts is joined with the output of groupsummary
   %
   % 3. Group percents are computed for ingroups using the groupsets optional
   % input. This contrasts with the Percent variable returned by groupcounts, which
   % is the frequency of each group relative to all observations in all groups.
   %
   % See also: groupbayes, grouppercent

   % Note, i changed GroupPercent back to Percent for consistency with matlab

   % groupsummary by default returns counts, but not percents.
   % groupcounts returns the counts and the percents.
   % neither return them for "ingroups" (groupsets).
   % the toolbox function grouppercent is like groupcounts but supports groupsets
   % this function combines the ability to compute additional stats using
   % groupsummary with the default frequencies returned by grouppercent.

   % TODO: add 'usegroups' concept, to subset which rows in T to use. Need a
   % general prepareGroups function that works for this and boxchartcats,
   % barchartcats, etc.

   % methods = {@circ_mean,@circ_std,@circ_median,@iqr};

   % Updats
   % 22 Aug 2023, change narginchk from 3,Inf to 2,Inf, add default method 'mean'
   % 22 Aug 2023, comment out call to parseinputs b/c it only had the simple if
   % numargs < X, set default syntax which means it failed when all arguments were
   % not passed in. TODO: Add parser.

   % Parse inputs
   narginchk(2, Inf);

   % [T, groupvars, methods, datavar, groupbins, groupsets, selectvars, tableFlag] = ...
   %    parseinputs(T, groupvars, methods, datavar, groupbins, groupsets, mfilename, ...
   %    nargin, varargin{:});

   validateattributes(T, "tabular", "nonempty", mfilename, "T", 1);
   
   function arg = setarg(arg, numargs, argpos, default)
      if numargs < argpos || isempty(arg); arg = default; end
   end
   methods = setarg(methods, nargin, 3, {'mean'});
   datavar = setarg(datavar, nargin, 4, vartype("numeric"));
   groupbins = setarg(groupbins, nargin, 5, repmat("none", numel(groupvars), 1));
   groupsets = setarg(groupsets, nargin, 6, "none");

   % This is to sub-select rows. Not sure its worth the trouble
   if nargin == 7
      selectvars = string(varargin{:});
   else
      selectvars = "none";
   end

   % Compute matrix/table switch flag
   tableFlag = istabular(T);


   % Downselect rows in T matching selectvars
   T = downselectvars(T, groupvars, selectvars);

   % Parse group bins
   groupbins = parseGroupBins(groupbins, groupvars);


   if tableFlag
      % Error if asking for more than 1 output for table
      nargoutchk(0,1);

      % Try to convert YData to double if it is categorical
      try
         T.(datavar) = double(T.(datavar));
      catch
         % let the built-in error catching do the work.
         % error('Failed to convert categorical datavar to numeric. Please ensure the categories can be represented as numeric values.');
      end

      % Convert groupvars to cellstr to simplify the variable renaming
      try
         groupvars = cellstr(groupvars);
      catch
      end

   else
      % convert the datavar to double in case of categorical
      try
         T = double(T);
      catch
         % let the built-in error catching do the work.
      end
   end


   % Next was replaced by more robust method in if tableFlag section. This was for
   % the first case where I just wanted to replace the function handles, before
   % bringing in the groupsummary/grouppercent join, I think.
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
      % G = groupsummary(T,groupvars,groupbins,methods,datavar);

      G = join( ...
         groupsummary(T, groupvars, groupbins, methods, datavar), ...
         groupstats.grouppercent(T, groupvars, groupbins, groupsets) );

      % Reset the variable names to match custom function names in methods. The
      % first variables will be groupvars followed by GroupCount from groupsummary,
      % and then the groupvar_method columns, then 'Percent' and any
      % 'Percent_<groupset>' variables from grouppercent. Moving GroupCounts to the
      % end, before Percent, avoids dealing with the groupsets variable names.

      G = movevars(G,"GroupCount","Before","Percent");
      V = G.Properties.VariableNames;

      % this replaces the V2 part below but also negates the need for V1
      keep = cellfun(@(m) ~isa(m,'function_handle'), methods);
      drop = cellfun(@(v) strncmp("fun",v,3), V);
      newvars = arrayfun(@(v) cellfun(@(m) strcat(func2str(m),'_', v), ...
         methods(~keep),'un',0), datavar, 'un',0);
      V(drop) = cellstr(horzcat(newvars{:}));

      % V(notok) = cellfun(@(x) strcat(func2str(x),'_',datavar), methods(~ok),'un',0);

      G = settablevarnames(G,V);

      varargout{1} = G;

   else
      [G,GR,GC] = groupsummary(T,groupvars,methods);

      [varargout{1:nargout}] = deal(G,GR,GC);
   end
end


function T = downselectvars(T, groupvars, groupvarselect)

   if groupvarselect ~= "none"

      % Find which groupvar contains the groupvarselect
      tf = arrayfun(@(n) all(ismember(groupvarselect, string(unique(T.(groupvars(n)))))), ...
         1:numel(groupvars));

      % enforce one groupvar for downselection
      assert(sum(tf) <= 1, "only one groupvar can be downselected using groupvarselect")

      % Keep members of groupvars that are in "groupvarselect", if any found
      if any(tf)
         T = T(ismember(string(T.(groupvars(tf))),groupvarselect), :);
      end
   end
end

% function [T, groupvars, methods, datavar, groupbins, groupsets, ...
%       selectvars, flag] = parseinputs(T, groupvars, methods, datavar, ...
%       groupbins, groupsets, funcname, numargs, varargin);
%    
%    % commented this out, it only did the default nargin checking
% end

function groupbins = parseGroupBins(groupbins, groupvars)
   % NOTE: groupbins needs to have one binning method per groupvar, but its
   % complicated b/c groupbins can be a vector e.g. bin edges or a cell array, so
   % for groupvars = {'var1','var2'}, groupbins could be [1,2,3], and [1,2,3] would
   % apply to both var1 and var2, but this probably isn't what we want, and
   % groupsummary error message is hard to interpret in this case, so I need to
   % require groiupbins to be a cell array I tink

   if ~iscell(groupbins)
      if ~isstring(groupbins) && groupbins == "none"
         error('groupbins must be a cell array with one binning scheme per variable in groupvars or a scalar string "none"')
      end

   elseif numel(groupbins) ~= numel(groupvars)
      % this tries to apply groupbins to each variable, or assume its for the first
      % one and set the rest "none" ...
      groupbins = [groupbins, {repmat("none", numel(groupvars)-1,1)}];

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
   %    [G,GR,GC] = groupsummary(T,groupvars,methods,datavar);
   % catch
   %    G = groupsummary(T,groupvars,methods,datavar);
   % end

   % Replace discretized (binned) groupvars. Note - might have worked to just
   % search for varnames containing datavar, but oh well. Update - I think this
   % just rebuilds the disc_<datavar> column names, so I commented it out when I
   % creatd the method below that searches for fun_ anmes
   % V1 = groupvars;
   % ok = false(size(groupbins));
   % ii = cellfun(@ischarlike, groupbins);
   % ok(ii) = cellfun(@(groupvar) ismember(groupvar, "none"), groupbins(ii));
   % V1(~ok) = cellfun(@(groupvar) strcat('disc_', groupvar), groupvars(~ok),'un',0);

   % Replace custom function handles

   % This works if datavar is a scalar
   % ok = cellfun(@(m) ~isa(m,'function_handle'), methods);
   % V2 = methods;
   % V2(ok) = strcat(methods(ok),'_', char(datavar));
   % V2(~ok) = cellfun(@(x) strcat(func2str(x),'_',char(datavar)), methods(~ok),'un',0);

   %    this could work when datavar is not a scalar, but not sure
   %    vv = arrayfun(@(y) cellfun(@(x) strcat(x,'_', y), methods(ok),'un',0), datavar, 'un',0);
   %    V2(ok) = cellstr(horzcat(vv{:}))

   % Put them all together
   % V = horzcat(V1{:}, V2{:}, V(numel(groupvars)+numel(methods)+1:end));