function T = prepareTableGroups(T, YDataVar, XDataVar, XGroupVar, CGroupVar, ...
      XGroupMembers, CGroupMembers, RowSelectVar, RowSelectMembers)
   %PREPARETABLEGROUPS Prepare group data in table.
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
   % prepareTableGroups empty, but the if-else check sets it true(height(T), 1),
   % which is the desired behavior.
   %
   % The reason CGroupMembers cannot default to all groupmembers is because in
   % this case, CGroupVar does not exist.
   %
   % Case 2 example. If cgroupvar is passed to boxchartcats but CGroupMembers is
   % not, groupmembers returns all group members for CGroupMembers, so
   % CGroupMembers goes to prepareTableGroups as all members, which is the
   % desired behavior.

   arguments
      T tabular
      YDataVar string {mustBeNonempty}
      XDataVar string = string.empty()
      XGroupVar string = string.empty()
      CGroupVar string = string.empty()
      XGroupMembers (:, 1) string = groupmembers(T, XGroupVar)
      CGroupMembers (:, 1) string = groupmembers(T, CGroupVar)
      RowSelectVar string = string.empty()
      RowSelectMembers (:, 1) string = groupmembers(T, RowSelectVar)
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
   %    msg = 'No XGroupVar or CGroupVar provided, try %s(T.(ydatavar))';
   %    error(eid, msg, Caller);
   % end

   % Validate variable names by confirming that they are column names of T.
   VarNames = T.Properties.VariableNames;

   % If a timetable is passed in, append the Time dimension
   if istimetable(T)
      VarNames = [T.Properties.DimensionNames(1) VarNames];
   end

   % other than YDataVar, we need ~isempty, then validatestr, then
   % validateGroupMembers. The groupmembers default assignment eliminates the
   % default assigmnent step, but that's it

   % Validate YDataVar and (if provided) XDataVar and RowSelectVar.
   validatestring(YDataVar, VarNames, Caller, 'YDataVar');

   if ~isempty(XDataVar)
      validatestring(XDataVar, VarNames, Caller, 'XDataVar');
   end

   % Downselect the table by rows if requested
   if ~isempty(RowSelectVar)
      validatestring(RowSelectVar, VarNames, Caller, 'RowSelectVar');
      T = groupstats.groupselect(T, RowSelectVar, RowSelectMembers);
      % Dec 2023 - replaced VarNames with RowSelectVar, otherwise if
      % RowSelectMembers are present in more than one of VarNames, groupselect
      % errors b/c it only allows one variable to select rows by. Not sure why
      % VarNames was ever used.
      % T = groupstats.groupselect(T, VarNames, RowSelectMembers);
   end

   % Confirm each XGroupMember is a member of T.(XGroupVar)
   if ~isempty(XGroupVar)
      validatestring(XGroupVar, VarNames, Caller, 'XGroupVar');
   end
   if ~isempty(XGroupMembers)
      % 18 Nov 2023 - I reversed XGroupMembers and T.(XGroupVar). I think this
      % is the desired behavior - XGroupMembers defines the "ValidMembers"
      % provided by the user, T.(XGroupVar) defines the actual members.
      % UPDATE: reversing them fixes the situation where the data does not
      % contain one of the expected group members e.g. in my application, I sent
      % in all months from Jan-Dec which were previously defined, but the table
      % did not contain any Feb data points. If instead I used
      % unique(T.(XGroupVar)) to define XGroupMembers, it would work. So I
      % commented out the "fix" and re-activated the old behavior, otherwise the
      % expected behavior where a specific group member is designated by
      % XGroupMembers leads to failure in validatemember.
      % validatemember(T.(XGroupVar), XGroupMembers, Caller, 'XGroupMembers')
      validatemember(XGroupMembers, T.(XGroupVar), Caller, 'XGroupMembers')
      inxgroup = ismember(string(T.(XGroupVar)), XGroupMembers);
   else
      inxgroup = true(height(T), 1);
   end

   % Confirm each CGroupMember is a member of T.(CGroupVar)
   if ~isempty(CGroupVar)
      validatestring(CGroupVar, VarNames, Caller, 'CGroupVar');
   end
   if ~isempty(CGroupMembers)
      validatemember(CGroupMembers, T.(CGroupVar), Caller, 'CGroupMembers')
      incgroup = ismember(string(T.(CGroupVar)), CGroupMembers);
   else
      incgroup = true(height(T), 1);
   end

   % I think I can replace everything below regarding badcats with a call to
   % dropcats, and combine the try-catch cast to / from categorical for clarity

   % If xgroupvar/cgroupvar are not categorical, try to convert them
   try T.(XGroupVar) = categorical(T.(XGroupVar)); catch; end
   try T.(CGroupVar) = categorical(T.(CGroupVar)); catch; end

   %--------------------------------------

   % Subset rows that are in both xgroupuse and cgroupuse
   T = T(incgroup & inxgroup, :);

   % Remove cats that are not in xgroupuse
   if ~isempty(XGroupVar)
      T = groupstats.dropcats(T, XGroupVar);
   end

   % Remove cats that are not in cgroupuse
   if ~isempty(CGroupVar)
      T = groupstats.dropcats(T, CGroupVar);
   end

   % Check if YDataVar is categorical, and try to convert it if so
   if iscategorical(T.(YDataVar))
      try
         T.(YDataVar) = cat2double(T.(YDataVar));
      catch
         % let the built-in error catching do the work.
      end
   end

   % Check if xdatavar is categorical, and try to convert it if provided
   if ~isempty(XDataVar) && ~isnumeric(T.(XDataVar))

      % Try to convert categorical to double
      try
         T.(XDataVar) = cat2double(T.(XDataVar));
      catch
         % Try to convert string to double
         try
            T.(XDataVar) = str2double(T.(XDataVar));
         catch
            % let the built-in error catching do the work.
         end
      end
   end
end


% For reference, I thought this would work but it fails if the calling function
% has a non-empty X/CGroupVar and an empty X/CGroupMembers, so the default
% assignment is almost worthless, but it does allow for calling this function
% wihtout those variables at all, so there is still non-zero purpose

% % Confirm each XGroupMember is a member of T.(XGroupVar)
% if isempty(XGroupVar)
%    inxgroup = true(height(T), 1);
% else
%    validatestring(XGroupVar, VarNames, Caller, 'XGroupVar');
%    validatemember(XGroupMembers, T.(XGroupVar), Caller, 'XGroupMembers')
%    inxgroup = ismember(string(T.(XGroupVar)), XGroupMembers);
% end
%
% % Confirm each CGroupMember is a member of T.(CGroupVar)
% if isempty(CGroupVar)
%    incgroup = true(height(T), 1);
% else
%    validatestring(CGroupVar, VarNames, Caller, 'CGroupVar');
%    validatemember(CGroupMembers, T.(CGroupVar), Caller, 'CGroupMembers')
%    incgroup = ismember(string(T.(CGroupVar)), CGroupMembers);
% end

% function T = prepareTableGroups(T, varargin)
%     arguments
%         T tabular
%         opts.YDataVar (1,1) string {mustBeNonempty}
%         opts.XDataVar (1,1) string = "none"
%         opts.XGroupVar (1,1) string = "none"
%         opts.CGroupVar (1,1) string = "none"
%         opts.XGroupMembers (:,1) string = "none"
%         opts.CGroupMembers (:,1) string = "none"
%         opts.SelectVars (:,1) string = "none"
%     end
%
%     ydatavar = opts.YDataVar;
%     xdatavar = opts.XDataVar;
%     xgroupvar = opts.XGroupVar;
%     cgroupvar = opts.CGroupVar;
%     xgroupuse = opts.XGroupMembers;
%     cgroupuse = opts.CGroupMembers;
%     selectvars = opts.SelectVars;
%
%     funcname = mfilename; % Use the current function name for error messages
%
%     % Confirm ydatavar is valid variable of table T
%     validatestring(ydatavar, T.Properties.VariableNames, funcname, 'ydatavar', 2);
%
%     % Check if xdatavar is provided and validate
%     if xdatavar ~= "none"
%         validatestring(xdatavar, T.Properties.VariableNames, funcname, 'xdatavar', 3);
%     end
%
%     % Require at least one grouping variable
%     if cgroupvar == "none" && xgroupvar == "none"
%         eid = 'groupstats:prepareGroups:badGroupingVar';
%         msg = 'No xgroupvar or cgroupvar provided, try %s(T.(ydatavar))';
%         error(eid, msg, funcname);
%     end
%
%     % Rest of the code, including grouping and subsetting, stays the same as in your original code.
%     % ...
%
%     % Check if xdatavar is categorical, and try to convert it if provided
%     if xdatavar ~= "none" && iscategorical(T.(xdatavar))
%         try
%             T.(xdatavar) = cat2double(T.(xdatavar));
%         catch
%             % let the built-in error catching do the work.
%         end
%     end
% end


