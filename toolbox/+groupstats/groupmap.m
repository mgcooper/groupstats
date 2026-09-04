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
   %                  to each group, with GROUPVAR as the first column,
   %                  converted to categorical
   %
   %   The function performs the following steps:
   %   1. Identifies unique groups in TBL based on GROUPVAR
   %   2. For each group:
   %      a. Extracts the subset of TBL corresponding to the group
   %      b. Applies FCN to this subset, passing varargin{:} to FCN
   %      c. Ensures the result is a table
   %      d. Inserts GROUPVAR as the first column of the result, as categorical
   %   3. Vertically concatenates all group results into a single table
   %
   %   GROUPVAR comes first to match MATLAB's groupsummary and groupcounts.
   %   It is categorical in OUT whatever its type in TBL. The conversion keeps
   %   a numeric group variable out of a downstream vartype("numeric") sweep.
   %   A GROUPVAR that is already categorical passes through unconverted. An
   %   ordinal one keeps its Ordinal flag and its category list, so a
   %   relational comparison on the returned column still works.
   %
   %   The function checks if FCN returns a table, and if not, converts the
   %   result to a table. This allows FCN to return either a table or an array.
   %
   %   Errors:
   %       groupstats:groupmap:groupVariableNameConflict - FCN returned a
   %       variable whose name matches GROUPVAR. Inserting the group column
   %       would drop that variable's data.
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

      % Refuse to insert over a variable the applied function returned.
      % Assigning onto that name would drop the variable's data.
      if ismember(string(groupvar), string(out{n}.Properties.VariableNames))
         error('groupstats:groupmap:groupVariableNameConflict', ...
            ['The applied function returned a variable named "%s", which ' ...
            'is the group variable name. Rename that variable in the ' ...
            'function, or group by a different variable.'], groupvar)
      end

      % Build the group column. Convert only a group variable that is not
      % already categorical. Rewrapping a categorical in categorical() resets
      % its Ordinal flag and drops the categories no row uses. That costs the
      % ordinal sorting this conversion exists to enable.
      groupcolumn = repmat(members(n), height(out{n}), 1);
      if ~iscategorical(groupcolumn)
         groupcolumn = categorical(groupcolumn);
      end

      % Insert the group column first, matching groupsummary and groupcounts.
      out{n} = addvars(out{n}, groupcolumn, ...
         'NewVariableNames', groupvar, 'Before', 1);
   end

   out = stacktables(out{:});
end
