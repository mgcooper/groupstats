function [members, rows] = memberrows(values)
   %MEMBERROWS Return each member of a group column and the rows it holds.
   %
   %  [MEMBERS, ROWS] = MEMBERROWS(VALUES)
   %
   % Description
   %  MEMBERS holds each distinct value of the column VALUES, sorted as
   %  unique sorts it. When VALUES holds a missing value, one missing value
   %  follows the others as one more member. ROWS{n} is the logical row
   %  index of MEMBERS(n).
   %
   %  A missing value (NaN, <missing>, <undefined>, NaT, or '') equals no
   %  value. unique lists each NaN or <missing> apart, and ismember matches
   %  none of them, so a split by unique and ismember loses those rows.
   %  groupcounts follows the rule used here: every missing value forms one
   %  group, sorted last.
   %
   % Example
   %  [m, r] = memberrows(["b"; missing; "a"; "b"; missing])
   %  % m = ["a"; "b"; <missing>], r = {[0;0;1;0;0]; [1;0;0;1;0]; [0;1;0;0;1]}
   %
   % See also: unique, ismember, ismissing, groupcounts

   arguments
      values (:, 1)
   end

   % unique gets only the present values, so each present member appears
   % once and keeps the order unique gives it.
   ismiss = ismissing(values);
   members = unique(values(~ismiss));
   rows = cell(numel(members), 1);
   for n = 1:numel(members)
      rows{n} = ismember(values, members(n));
   end

   % The missing rows form the last member. Its label is the first missing
   % value itself, so the member keeps the column's type.
   if any(ismiss)
      members = [members; values(find(ismiss, 1))];
      rows = [rows; {ismiss}];
   end
end
