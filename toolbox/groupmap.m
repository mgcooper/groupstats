function out = groupmap(tbl, groupvar, fcn, varargin)
   %GROUPMAP Apply a function to groups within a table and recombine results
   %
   %   OUT = GROUPMAP(TBL, GROUPVAR, FCN, ...) applies the function FCN to subsets
   %   of table TBL, grouped by the variable GROUPVAR, and combines the results.
   %
   %   Inputs:
   %       TBL      - Input table
   %       GROUPVAR - Name of the grouping variable in TBL (string or char)
   %       FCN      - Function handle to apply to each group. Should accept a
   %                  table as its first argument and return a table or array.
   %       ...      - Additional arguments passed to FCN
   %
   %   Outputs:
   %       OUT      - A table containing the combined results of applying FCN
   %                  to each group, with GROUPVAR added as a categorical column
   %
   %   The function performs the following steps:
   %   1. Identifies unique groups in TBL based on GROUPVAR
   %   2. For each group:
   %      a. Extracts the subset of TBL corresponding to the group
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
   %       tbl = table({'A';'B';'A';'C'}, [1;2;3;4], 'VariableNames', {'Category', 'Value'});
   %       fcn = @(t) mean(t.Value);
   %       result = groupmap(tbl, 'Category', fcn);
   %
   %   See also: GROUPBY, SPLITAPPLY, STACKTABLES

   % if contains(func2str(fcn), 'tbl')
   %    fcn = str2func(strrep(func2str(fcn), 'tbl', 'tt'));
   % end

   members = unique(tbl.(groupvar));
   out = cell(numel(members), 1);

   for n = 1:numel(members)
      t = tbl(ismember(tbl.(groupvar), members(n)), :);
      out{n} = fcn(t, varargin{:});

      if ~istable(out{n})
         out{n} = array2table(out{n});
      end

      out{n}.(groupvar) = categorical(repmat(members(n), height(out{n}), 1));
   end

   out = stacktables(out{:});
end
