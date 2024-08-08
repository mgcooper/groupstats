function tbl = groupmap(T, groupvar, fcn, varargin)
   %GROUPMAP Apply a function to groups within a table and recombine results
   %
   %   TBL = GROUPMAP(T, GROUPVAR, FCN, ...) applies the function FCN to subsets
   %   of table T, grouped by the variable GROUPVAR, and combines the results.
   %
   %   Inputs:
   %       T        - Input table
   %       GROUPVAR - Name of the grouping variable in T (string or char)
   %       FCN      - Function handle to apply to each group. Should accept a
   %                  table as its first argument and return a table or array.
   %       ...      - Additional arguments passed to FCN
   %
   %   Outputs:
   %       TBL      - A table containing the combined results of applying FCN
   %                  to each group, with GROUPVAR added as a categorical column
   %
   %   The function performs the following steps:
   %   1. Identifies unique groups in T based on GROUPVAR
   %   2. For each group:
   %      a. Extracts the subset of T corresponding to the group
   %      b. Applies FCN to this subset, passing varargin{:} to FCN
   %      c. Ensures the result is a table
   %      d. Adds GROUPVAR as a categorical column to the result
   %   3. Vertically concatenates all group results into a single table
   %
   %   The function checks if FCN returns a table, and if not, converts the
   %   result to a table. This allows FCN to return either a table or an array.
   %
   %   Example:
   %       % Group by 'Category' and calculate mean of 'Value' for each group
   %       T = table({'A';'B';'A';'C'}, [1;2;3;4], 'VariableNames', {'Category', 'Value'});
   %       fcn = @(t) mean(t.Value);
   %       result = groupmap(T, 'Category', fcn);
   %
   %   See also: GROUPBY, SPLITAPPLY, STACKTABLES

   % if contains(func2str(fcn), 'tbl')
   %    fcn = str2func(strrep(func2str(fcn), 'tbl', 'tt'));
   % end

   members = unique(T.(groupvar));
   tbl = cell(numel(members), 1);

   for n = 1:numel(members)
      t = T(ismember(T.(groupvar), members(n)), :);
      tbl{n} = fcn(t, varargin{:});

      if ~istable(tbl{n})
         tbl{n} = array2table(tbl{n});
      end

      tbl{n}.(groupvar) = categorical(repmat(members(n), height(tbl{n}), 1));
   end

   tbl = stacktables(tbl{:});
end
