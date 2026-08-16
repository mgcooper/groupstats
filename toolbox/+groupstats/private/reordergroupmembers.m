function idx = reordergroupmembers(order, members, caller, optionname)
   %REORDERGROUPMEMBERS Index a member list by a caller's partial order.
   %
   %  idx = reordergroupmembers(order, members, caller, optionname)
   %
   % Description
   %  Returns the indices that put MEMBERS in the sequence ORDER names. ORDER
   %  may name a subset: the named members come first, and the rest keep
   %  their existing sequence behind them. Naming one group therefore does
   %  not drop the others.
   %
   %  CALLER and OPTIONNAME appear in the error, so the message names the
   %  function and the option the caller actually typed.
   %
   % Errors
   %  groupstats:<caller>:bad<optionname> - ORDER names a value that is not a
   %  member.
   %  groupstats:<caller>:repeated<optionname> - ORDER names a value more
   %  than once.
   %
   % See also: reordercats

   arguments
      order (:, 1) string
      members (:, 1) string
      caller (1, 1) string
      optionname (1, 1) string
   end

   % A repeated name would index the same member twice, which reordercats
   % rejects further down with a message that names neither the option nor
   % the value.
   [counts, values] = groupcounts(order);
   if any(counts > 1)
      error("groupstats:" + caller + ":repeated" + optionname, ...
         '%s names %s more than once.', optionname, ...
         strjoin(values(counts > 1), ', '))
   end

   [found, idx] = ismember(order, members);

   if ~all(found)
      error("groupstats:" + caller + ":bad" + optionname, ...
         ['%s names %s, which is not a member of the group variable. ' ...
         'Members: %s.'], optionname, ...
         strjoin(order(~found), ', '), strjoin(members, ', '))
   end

   % A partial order puts the named members first, and keeps the rest in the
   % sequence they already had.
   idx = [idx(:); setdiff((1:numel(members))', idx(:), 'stable')];
end
