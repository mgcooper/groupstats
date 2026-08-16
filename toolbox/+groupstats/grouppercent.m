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
   %  variable, the rows belonging to that member sum to 100.
   %
   %  Percent, which groupcounts produces, is a different quantity. It is each
   %  row's share of every observation in the table, so the whole column sums
   %  to 100.
   %
   % Example
   %  tbl = table(["a";"a";"b"], [1;2;3], 'VariableNames', {'Group', 'Value'});
   %  G = groupstats.grouppercent(tbl, "Group");
   %
   % See also: groupsummary, groupcounts, groupstats.groupsummary

   % Update: I did this see the else block below
   % It might be helpful to remove "disc_" from binned variables, since the
   % table returned by this function won't ever have the original variable there
   % won't be any conflict i.e. if we send in a table with variable FCS, we get
   % back a table with variable disc_FCS, so calling functions need if-else
   % statements to use FCS if groupbins is "none", or disc_FCS otherwise

   arguments
      tbl (:,:) tabular
      groupvars (1,:) string
      groupbins (1,:) = "none"
      groupsets (1,:) string = string.empty()
   end

   % "none" is the sentinel groupstats.groupsummary passes down. Accept it and
   % convert to the empty sentinel the rest of the family uses.
   if isscalar(groupsets) && groupsets == "none"
      groupsets = string.empty();
   end
   if isempty(groupsets)
      groupsets = groupvars;
   end

   G = tbl;

   % I do not specify type for groupbins b/c ot needs to support various types e.g.
   % "none" as well as numeric bin edges, but default is "none" which will be
   % applied to all groupvars when passed to groupsummary.

   bySet = false;

   % not sure about this yet, but if it isn't true, then the groupsets variable
   % wont be in the groupsummary table produced by a call to groupsummary then
   % here, and it might not even be possible to do the withingroup percents
   if ~any(ismember(groupsets, groupvars))
      % UPDATE: what this really means, I think, is that the input table G
      % should be considered separate tables, one for each member of groupsets,
      % so below I added a method that relies on stacktables, use that instead
      % of error. After some testing, it appears to work, and there might not be
      % any need for this check at all, just use it by default, maybe what was
      % missing was stacktables.
      bySet = true;
      % error('groupsets must be contained in groupvars')
   end


   % Normalization and percent refers more to the method applied to the vars than
   % the intrinsic property that the vars represent wholegroups
   % NormalizationVars
   % percentvars
   % wholevars
   % completevars
   % wholesets
   % integralvars
   % wholegroups

   % NOTE, I changed "Percent" to "GroupPercent" in groupstats so now I definitely
   % need to append wholegroups variable names to group percent here. But, if this
   % is called after a groupcounts call then it wont have that, it will have
   % Percent, so to generalize it I can either check for Percent here and not
   % GroupPercent and change to GroupPercent meaning this function transforms to a
   % new naming protocol, or go back to Percent and append group names here. For
   % now do the latter for consistency with matlab.

   % Check if G contains 'GroupCount' variable
   if ~isvariable('GroupCount', G)

      % Assume input G is a data table and call groupcounts
      %G1 = groupcounts(G, groupsets, groupbins);

      % NOTE: After adding this, it actually does what the main function does
      % below. I think the distinction is this works when there is no
      % GroupCounts variable, meaning no prior call to groupsummary, which I
      % think could only work if I passed an already-summarized table with one
      % value per groupset member, so this generalizes it to the case where I
      % pass in a non-summarized table, and somehow I overlooked this simple
      % solution to simply loop over the groupsets members. But note that the
      % main part below loops over groupsets, so maybe this won't work when
      % multiple groupsets are provided, but that seems like something I wont
      % support
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

      % warning(['Input 1, G, does not contain GroupCount variable. ' ...
      %    'This function assumes G is a groupsummary or groupcounts table.'])
   end

   % If multiple groupvars, calculate the GroupPercent for each groupvar
   for m = 1:numel(groupsets)
      groupvar = groupsets(m);
      grps = unique(G.(groupvar));

      % For now, require conversion of cell to string, otherwise grps(n) fails
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

% To confirm each Percent_<groupset> sums to 100 within its own group:
%
%   varfun(@sum, G, "InputVariables", "Percent_" + groupset, ...
%      "GroupingVariables", groupset)
%
% Grouping that sum by a different variable does not check anything: it sums
% across the sets rather than within them.
%
%   % This shows how it doesn't work b/c we get the sum across scenarios
%   varfun(@sum, G, "InputVariables", "Percent_scenario", ...
%      "GroupingVariables", 'basin')


% This shows why groupsummary nomenclature is confusing ... "GroupCount" is
% correct nomenclature, but "Percent" is misleading, maybe that's why they don't
% call it "GroupPercent", but imagine groupvars = ["scenario","basin"], then
% each row where scenario=="1980-2020-WRF-DIST" and basin=="CrosswicksNeshaminy"
% is a member of the group defined by that scenario and that basin, and in the
% summary Stats table, there will be one row for those two, and the GroupCount
% value is indeed the Count (number of) all members of that group in Info, but
% Percent is the GroupCount divided by the total number of values in Info, NOT
% the GroupCount divided by the total number of values in the group defined by
% groupvars ... because there could be (are) two distinct groups - scenario and
% basin, so which would it pick? That's what wholegroups is for. Then Percent
% should be "GroupPercent", and the percent of wholegroups could be
% "WithinGroupPercent" or "InGroupPercent". But back to why the nomenclature is
% confusing ... the other stats returned by groupsummary ARE within-group stats,
% compare these to the rows in Stats for this combo:
% mean(Info.FCS(Info.scenario=="1980-2020-WRF-DIST" & Info.basin=="CrosswicksNeshaminy"))
% mean(Info.FCS(Info.scenario=="1980-2020-WRF-DIST" & Info.basin=="EastBranchDelaware"))
% If Percent was the same, then this would match the Percent value for the group
% defined by the scenario and basin above:
% numel(Info.FCS(Info.scenario=="SSP545-COOL-FAR" & ...
%    Info.basin=="EastBranchDelaware"))/numel(Info.FCS(Info.scenario=="SSP545-COOL-FAR"))
% The GOOD NEWS is, this means we can compute stats here correctly, it's just
% the WITHIN GROUP percents, i.e., FREQUENCIES that require special attention
% with grouppercent



% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% If we did not have groupcounts function, then this would get us the
% within-group percents i.e. G.("Percent_" ) above
% ingroups = unique(Info.(wholegroups));
% outgroups = unique(Info.(groupvars(~ismember(groupvars,wholegroups))));
% for n = 1:numel(outgroups)
%    outgroupavgs(n) = arrayfun(@(g) numel(Info.FCS(Info.scenario==g & Info.basin==outgroups(n))) / ...
%       numel(Info.FCS(Info.scenario==g)), ingroups)
% end
%
% for n = 1:numel(ingroups)
%    ingroupavgs(n) = arrayfun(@(g) numel(Info.FCS(Info.scenario==ingroups(n) & Info.basin==g)) / ...
%       numel(Info.FCS(Info.scenario==ingroups(n))), outgroups);
% end
% % avgs = arrayfun(@(g,b) numel(Info.FCS(Info.scenario==g & Info.basin==b)) / ...
% %    numel(Info.FCS(Info.scenario==g)), ingroups, outgroups)

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % This was where I wanted to not append the groupvar name if there was only
% one groupvar for a cleaner table, but its better to be explicit. If i went
% back to this I think it could be broken into subfunctions
% % If only one groupvar, calculate the GroupPercent directly
% if numel(groupvars) == 1
%    groupvar = groupvars;
%    grps = unique(G.(groupvar));
%    if numel(grps) == height(G)
%       G.GroupPercent = 100.*G.GroupCount./sum(G.GroupCount);
%    else
%       G.GroupPercent = nan(height(G),1);
%       for n = 1:numel(grps)
%          idx = G.(groupvar) == grps(n);
%          G.GroupPercent(idx) = 100.*G.GroupCount(idx)./sum(G.GroupCount(idx));
%       end
%    end
% else
%    % If multiple groupvars, calculate the GroupPercent for each groupvar
%    for m = 1:numel(groupvars)
%       groupvar = groupvars(m);
%       grps = unique(G.(groupvar));
%       if numel(grps) == height(G)
%          G.("GroupPercent_" + groupvar) = 100.*G.GroupCount./sum(G.GroupCount);
%       else
%          G.("GroupPercent_" + groupvar) = nan(height(G),1);
%          for n = 1:numel(grps)
%             idx = G.(groupvar) == grps(n);
%             G.("GroupPercent_" + groupvar)(idx) = 100.*G.GroupCount(idx)./sum(G.GroupCount(idx));
%          end
%       end
%    end
% end
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% function G = grouppercent(G,groupvars)
%
% % for now only one groupvar, if >1, its complicated to determine which one to
% % use for group percent calculation e.g. in the floods case, I group by FCS and
% % scenario, but I also bin by FCS, in which case scenario is the one that needs
% % to be used for the group percent
%
% arguments
%    G (:,:) table
%    groupvars (1,1) string
% end
%
% if ~isvariable('GroupCount',G)
%    warning(['Input 1, G, does not contain GroupCount variable. ' ...
%       'This function assumes G is a groupsummary or groupcounts table.'])
% end
%
% grps = unique(G.(groupvars));
%
% if numel(grps) == height(G)
%    G.GroupPercent = 100.*G.GroupCount./sum(G.GroupCount);
% else
%
%    G.GroupPercent = nan(height(G),1);
%    for n = 1:numel(grps)
%       idx = G.(groupvars) == grps(n);
%       G.GroupPercent(idx) = 100.*G.GroupCount(idx)./sum(G.GroupCount(idx));
%    end
%
% end
