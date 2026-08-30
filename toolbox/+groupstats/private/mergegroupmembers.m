function column = mergegroupmembers(column, mergegroups)
   %MERGEGROUPMEMBERS Pool named members of a categorical group column.
   %
   %  COLUMN = MERGEGROUPMEMBERS(COLUMN, MERGEGROUPS)
   %
   % Description
   %  MERGEGROUPS is a cell array. Each cell names the members of COLUMN to
   %  pool into one group. A bare string vector is one merge group. The
   %  merged group's label joins the member names with " and ", in the
   %  order given. The merged group takes the category position of its
   %  first member in the current category order. All four chart functions
   %  merge through this helper, so the identifiers below stay the same
   %  from every chart.
   %
   % Errors
   %  groupstats:mergegroupmembers:unknownMergeMember - A named member is
   %  not a category of COLUMN.
   %  groupstats:mergegroupmembers:overlappingMergeGroups - A member is
   %  named in two merge groups.
   %  groupstats:mergegroupmembers:mergedLabelConflict - A generated label
   %  already names a category, or two merge groups generate one label.
   %
   % See also: mergecats, groupstats.histogram, groupstats.barchartcats

   arguments
      column categorical
      mergegroups (:, 1)
   end

   % One cell per merge group. A bare member list is one group, so wrap it
   % and treat both shapes the same below.
   if ~iscell(mergegroups)
      mergegroups = {mergegroups};
   end

   % Validate against the full category list, not just the categories with
   % rows, so a member the data lacks is still mergeable by name.
   validnames = string(categories(column));
   allnamed = cellfun(@(members) reshape(string(members), [], 1), ...
      mergegroups, 'UniformOutput', false);
   allnamed = vertcat(allnamed{:});

   unknown = setdiff(allnamed, validnames);
   if ~isempty(unknown)
      error('groupstats:mergegroupmembers:unknownMergeMember', ...
         ['Merge member %s is not a member of the group variable. ' ...
         'Valid members: %s.'], ...
         strjoin(unknown, ', '), strjoin(validnames, ', '))
   end

   % A member in two merge groups has no single destination.
   if numel(allnamed) ~= numel(unique(allnamed))
      [counts, names] = groupcounts(allnamed);
      error('groupstats:mergegroupmembers:overlappingMergeGroups', ...
         'Merge groups overlap. Named more than once: %s.', ...
         strjoin(names(counts > 1), ', '))
   end

   % A generated label that already names a category would make mergecats
   % pool that category's rows too. A label two merge groups both generate
   % would pool the two groups. Reject both before merging. A
   % single-member group whose label is that member is a plain no-op and
   % is fine.
   labels = strings(numel(mergegroups), 1);
   for n = 1:numel(mergegroups)
      members = string(mergegroups{n});
      labels(n) = strjoin(members, " and ");
      if ismember(labels(n), validnames) ...
            && ~(isscalar(members) && labels(n) == members)
         error('groupstats:mergegroupmembers:mergedLabelConflict', ...
            ['Merged label "%s" already names a category. Rename that ' ...
            'category first, or change the merge.'], labels(n))
      end
   end
   if numel(labels) ~= numel(unique(labels))
      error('groupstats:mergegroupmembers:mergedLabelConflict', ...
         'Two merge groups generate the same label. Change the merge.')
   end

   for n = 1:numel(mergegroups)
      members = string(mergegroups{n});

      % The label joins the names in the order given. mergecats places the
      % merged category at the lowest of the old categories' positions,
      % which is the first member in the current category order.
      column = mergecats(column, cellstr(members), char(labels(n)));
   end
end
