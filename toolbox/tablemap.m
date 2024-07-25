function tbl = tablemap(T, groupvar, fcn, varargin)

   % if contains(func2str(fcn), 'tbl')
   %    fcn = str2func(strrep(func2str(fcn), 'tbl', 'tt'));
   % end
   members = unique(T.(groupvar));
   tbl = cell(numel(members), 1);
   for n = 1:numel(members)
      t = T(T.(groupvar) == members(n), :);
      tbl{n} = fcn(t, varargin{:});
      if ~istable(tbl{n})
         tbl{n} = array2table(tbl{n});
      end
      tbl{n}.(groupvar) = categorical(repmat(members(n), height(tbl{n}), 1));
   end
   tbl = stacktables(tbl{:});
end
