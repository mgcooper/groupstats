function tbl = prepareTableGroups(tbl, ydatavar, opts)
   %PREPARETABLEGROUPS Select rows and prepare group variables in a table.
   %
   %  TBL = PREPARETABLEGROUPS(TBL, YDATAVAR)
   %  TBL = PREPARETABLEGROUPS(TBL, YDATAVAR, XDataVar=NAME)
   %  TBL = PREPARETABLEGROUPS(TBL, YDATAVAR, XGroupVar=NAME, XGroupMembers=M)
   %  TBL = PREPARETABLEGROUPS(TBL, YDATAVAR, CGroupVar=NAME, CGroupMembers=M)
   %  TBL = PREPARETABLEGROUPS(TBL, YDATAVAR, RowSelectVar=NAME,
   %                           RowSelectMembers=M)
   %
   % Description
   %  TBL = PREPARETABLEGROUPS(TBL, YDATAVAR) validates that YDATAVAR names a
   %  variable of TBL and converts it from categorical to double if it is
   %  categorical. Every other step is opt-in.
   %
   %  The name-value arguments select rows and prepare group variables:
   %
   %   XDataVar         Name of the x-axis data variable. Converted to double
   %                    from categorical, then from text, if it is neither.
   %   XGroupVar        Name of the x-axis group variable.
   %   XGroupMembers    Members of XGroupVar to keep. Rows outside them go.
   %   CGroupVar        Name of the color group variable.
   %   CGroupMembers    Members of CGroupVar to keep. Rows outside them go.
   %   RowSelectVar     Name of a variable used only to select rows.
   %   RowSelectMembers Members of RowSelectVar to keep.
   %   ConvertDataVar   Set false to keep YDATAVAR as it is. A categorical
   %                    histogram needs its data variable to stay
   %                    categorical, where a chart axis needs it numeric.
   %
   %  The chart functions in this toolbox route their group handling here so
   %  they do not each re-implement member validation and row selection.
   %
   % Data changes this function makes
   %  It converts XGroupVar and CGroupVar to categorical when they are not
   %  already, because the chart functions group and order by category. A
   %  variable that is already categorical passes through untouched, so an
   %  ordinal group keeps its order. It drops the categories that no surviving
   %  row uses, so a legend lists only the groups that are plotted. It drops
   %  the rows whose group value is missing or undefined, because a chart
   %  cannot place them. It converts a categorical YDataVar, and a categorical
   %  or text XDataVar, to double, because a chart needs numeric axis data.
   %  Set ConvertDataVar false to keep a categorical YDataVar, which is what
   %  a categorical histogram needs.
   %
   % Limitations
   %  A timetable's time dimension passes the variable-name check but cannot
   %  be a group variable: dropcats rejects a name it cannot find among the
   %  table variables. Group by an ordinary column instead.
   %
   % Example
   %  tbl = table(categorical(["a";"b";"a"]), [1;2;3], ...
   %     'VariableNames', {'Group', 'Value'});
   %  tbl = groupstats.prepareTableGroups(tbl, "Value", ...
   %     XGroupVar="Group", XGroupMembers="a");
   %
   % Errors
   %  groupstats:prepareTableGroups:membersWithoutGroupVar - Members were given
   %  for a group variable that was not named.
   %  groupstats:prepareTableGroups:rowSelectVarWithoutMembers - RowSelectVar
   %  was named without RowSelectMembers.
   %
   % Notes.
   %
   % Two cases where the calling function parsing and this function need to
   % interact carefully: 1) CGroupVar is empty, and CGroupMembers is empty, and
   % 2) CGroupVar is NOT empty, and CGroupMembers is empty.
   %
   % Case 1 example using boxchartcats. If cgroupvar is not passed to the
   % calling function, it is assigned string.empty, which means groupmembers
   % returns string.empty for CGroupMembers, so CGroupMembers goes to
   % prepareTableGroups empty, but the if-else check sets it true(height(tbl), 1),
   % which is the desired behavior.
   %
   % The reason CGroupMembers cannot default to all groupmembers is because in
   % this case, CGroupVar does not exist.
   %
   % Case 2 example. If cgroupvar is passed to boxchartcats but CGroupMembers is
   % not, groupmembers returns all group members for CGroupMembers, so
   % CGroupMembers goes to prepareTableGroups as all members, which is the
   % desired behavior.
   %
   % Both cases reduce to one rule with the name-value arguments: empty members
   % keep every row of that group variable. Resolving the members to the full
   % member list would select the same rows, so this function does not call
   % groupmembers at all. The calling functions still do, to fill their own
   % option defaults.
   %
   % See also: groupstats.groupselect, groupstats.dropcats, groupmembers,
   % validatemember

   arguments
      tbl tabular
      ydatavar (1, 1) string {mustBeNonempty}
      opts.XDataVar string = string.empty()
      opts.XGroupVar string = string.empty()
      opts.CGroupVar string = string.empty()
      opts.XGroupMembers (:, 1) string = string.empty()
      opts.CGroupMembers (:, 1) string = string.empty()
      opts.RowSelectVar string = string.empty()
      opts.RowSelectMembers (:, 1) string = string.empty()
      opts.ConvertDataVar (1, 1) logical = true
   end

   Caller = upper(mcallername());

   % UPDATE: if YDataVar is categorical, and the calling function also accepts a
   % "Member"-of var, then the next check is too restrictive. Also, the next
   % check makes it difficult / impossible to mimic built-in functions for the
   % simple case where no grouping is desired.

   % Before commenting it out, I added isempty(RowSelectVar) as another
   % requirement, but ultimately I think its better to let it pass and then
   % mimic built-in behavior in the calling function.

   % Exit if at least one grouping variable was not provided.
   % if isempty(CGroupVar) && isempty(XGroupVar) && isempty(RowSelectVar)
   %    eid = sprintf('groupstats:%s:noGroupingVarProvided', Caller);
   %    msg = 'No XGroupVar or CGroupVar provided, try %s(tbl.(ydatavar))';
   %    error(eid, msg, Caller);
   % end

   % Members are meaningless without the variable they belong to.
   requireGroupVar(opts.XGroupVar, opts.XGroupMembers, Caller, ...
      'XGroupVar', 'XGroupMembers')
   requireGroupVar(opts.CGroupVar, opts.CGroupMembers, Caller, ...
      'CGroupVar', 'CGroupMembers')
   requireGroupVar(opts.RowSelectVar, opts.RowSelectMembers, Caller, ...
      'RowSelectVar', 'RowSelectMembers')

   % Validate variable names by confirming that they are column names of tbl.
   VarNames = tbl.Properties.VariableNames;

   % If a timetable is passed in, append the Time dimension
   if istimetable(tbl)
      VarNames = [tbl.Properties.DimensionNames(1) VarNames];
   end

   % other than YDataVar, we need ~isempty, then validatestr, then
   % validateGroupMembers. The groupmembers default assignment eliminates the
   % default assigmnent step, but that's it

   % Validate YDataVar and (if provided) XDataVar and RowSelectVar.
   validatestring(ydatavar, VarNames, Caller, 'ydatavar');

   if ~isempty(opts.XDataVar)
      validatestring(opts.XDataVar, VarNames, Caller, 'XDataVar');
   end

   % Downselect the table by rows if requested
   if ~isempty(opts.RowSelectVar)
      validatestring(opts.RowSelectVar, VarNames, Caller, 'RowSelectVar');

      % RowSelectVar with no members selects no rows, leaving an empty table
      % and an empty chart. Report it in the caller's own vocabulary, the way
      % the opposite combination is reported below.
      if isempty(opts.RowSelectMembers)
         error('groupstats:prepareTableGroups:rowSelectVarWithoutMembers', ...
            ['RowSelectVar names %s, and RowSelectMembers is empty. ' ...
            'Name the members to keep, or leave both out.'], ...
            opts.RowSelectVar)
      end

      tbl = groupstats.groupselect(tbl, opts.RowSelectVar, ...
         opts.RowSelectMembers);
      % Dec 2023 - replaced VarNames with RowSelectVar, otherwise if
      % RowSelectMembers are present in more than one of VarNames, groupselect
      % errors b/c it only allows one variable to select rows by. Not sure why
      % VarNames was ever used.
      % tbl = groupstats.groupselect(tbl, VarNames, RowSelectMembers);
   end

   % Confirm each XGroupMember is a member of tbl.(XGroupVar)
   if ~isempty(opts.XGroupVar)
      validatestring(opts.XGroupVar, VarNames, Caller, 'XGroupVar');
   end
   if ~isempty(opts.XGroupMembers)
      % 18 Nov 2023 - I reversed XGroupMembers and tbl.(XGroupVar). I think this
      % is the desired behavior - XGroupMembers defines the "ValidMembers"
      % provided by the user, tbl.(XGroupVar) defines the actual members.
      % UPDATE: reversing them fixes the situation where the data does not
      % contain one of the expected group members e.g. in my application, I sent
      % in all months from Jan-Dec which were previously defined, but the table
      % did not contain any Feb data points. If instead I used
      % unique(tbl.(XGroupVar)) to define XGroupMembers, it would work. So I
      % commented out the "fix" and re-activated the old behavior, otherwise the
      % expected behavior where a specific group member is designated by
      % XGroupMembers leads to failure in validatemember.
      % validatemember(tbl.(XGroupVar), XGroupMembers, Caller, 'XGroupMembers')
      validatemember(opts.XGroupMembers, tbl.(opts.XGroupVar), Caller, ...
         'XGroupMembers')
      inxgroup = ismember(string(tbl.(opts.XGroupVar)), opts.XGroupMembers);
   elseif ~isempty(opts.XGroupVar)
      % Drop rows whose group value is missing or undefined. A chart cannot
      % place them.
      %
      % Test string(), not the raw column, so the rule reads the same for
      % every type. An undefined categorical, a missing string, and a NaN all
      % convert to a missing string. An empty char does not, so its row
      % stays.
      inxgroup = ~ismissing(string(tbl.(opts.XGroupVar)));
   else
      inxgroup = true(height(tbl), 1);
   end

   % Confirm each CGroupMember is a member of tbl.(CGroupVar)
   if ~isempty(opts.CGroupVar)
      validatestring(opts.CGroupVar, VarNames, Caller, 'CGroupVar');
   end
   if ~isempty(opts.CGroupMembers)
      validatemember(opts.CGroupMembers, tbl.(opts.CGroupVar), Caller, ...
         'CGroupMembers')
      incgroup = ismember(string(tbl.(opts.CGroupVar)), opts.CGroupMembers);
   elseif ~isempty(opts.CGroupVar)
      % Same rule as the x-axis group above.
      incgroup = ~ismissing(string(tbl.(opts.CGroupVar)));
   else
      incgroup = true(height(tbl), 1);
   end

   % I think I can replace everything below regarding badcats with a call to
   % dropcats, and combine the try-catch cast to / from categorical for clarity

   % If xgroupvar/cgroupvar are not categorical, try to convert them. The chart
   % functions group and order by category, so a text or numeric group variable
   % must become categorical first. A variable that cannot convert is left
   % alone for the calling function to reject.
   tbl = tryCategorical(tbl, opts.XGroupVar);
   tbl = tryCategorical(tbl, opts.CGroupVar);

   %--------------------------------------

   % Subset rows that are in both xgroupuse and cgroupuse
   tbl = tbl(incgroup & inxgroup, :);

   % Remove cats that are not in xgroupuse
   if ~isempty(opts.XGroupVar)
      tbl = groupstats.dropcats(tbl, opts.XGroupVar);
   end

   % Remove cats that are not in cgroupuse
   if ~isempty(opts.CGroupVar)
      tbl = groupstats.dropcats(tbl, opts.CGroupVar);
   end

   % Check if YDataVar is categorical, and try to convert it if so
   if opts.ConvertDataVar && iscategorical(tbl.(ydatavar))
      try
         tbl.(ydatavar) = cat2double(tbl.(ydatavar));
      catch
         % let the built-in error catching do the work.
      end
   end

   % Check if xdatavar is categorical, and try to convert it if provided
   if ~isempty(opts.XDataVar) && ~isnumeric(tbl.(opts.XDataVar))

      % Try to convert categorical to double
      try
         tbl.(opts.XDataVar) = cat2double(tbl.(opts.XDataVar));
      catch
         % Try to convert string to double
         try
            tbl.(opts.XDataVar) = str2double(tbl.(opts.XDataVar));
         catch
            % let the built-in error catching do the work.
         end
      end
   end
end

function requireGroupVar(GroupVar, GroupMembers, Caller, VarArg, MemberArg)
   %REQUIREGROUPVAR Reject members given without their group variable.
   %
   % Naming members but not the variable they belong to has no sensible
   % reading. Name both arguments in the error so the caller sees the pair.

   if isempty(GroupVar) && ~isempty(GroupMembers)
      error('groupstats:prepareTableGroups:membersWithoutGroupVar', ...
         '%s: %s was given without %s. Name the group variable too.', ...
         Caller, MemberArg, VarArg)
   end
end

function tbl = tryCategorical(tbl, GroupVar)
   %TRYCATEGORICAL Convert a group variable to categorical where possible.
   %
   % A group variable that cannot convert, such as a cell array of mixed
   % types, is left as it is. The calling function reports the problem when it
   % tries to group by it.

   % An already-categorical variable is left as it is. Rewrapping it in
   % categorical() resets its Ordinal flag and drops the categories no row
   % uses, which costs an ordinal group its order and a legend its empty
   % group.
   if isempty(GroupVar) || iscategorical(tbl.(GroupVar))
      return
   end

   try
      tbl.(GroupVar) = categorical(tbl.(GroupVar));
   catch
      % let the built-in error catching do the work.
   end
end


% For reference, I thought this would work but it fails if the calling function
% has a non-empty X/CGroupVar and an empty X/CGroupMembers, so the default
% assignment is almost worthless, but it does allow for calling this function
% wihtout those variables at all, so there is still non-zero purpose

% % Confirm each XGroupMember is a member of tbl.(XGroupVar)
% if isempty(XGroupVar)
%    inxgroup = true(height(tbl), 1);
% else
%    validatestring(XGroupVar, VarNames, Caller, 'XGroupVar');
%    validatemember(XGroupMembers, tbl.(XGroupVar), Caller, 'XGroupMembers')
%    inxgroup = ismember(string(tbl.(XGroupVar)), XGroupMembers);
% end
%
% % Confirm each CGroupMember is a member of tbl.(CGroupVar)
% if isempty(CGroupVar)
%    incgroup = true(height(tbl), 1);
% else
%    validatestring(CGroupVar, VarNames, Caller, 'CGroupVar');
%    validatemember(CGroupMembers, tbl.(CGroupVar), Caller, 'CGroupMembers')
%    incgroup = ismember(string(tbl.(CGroupVar)), CGroupMembers);
% end
