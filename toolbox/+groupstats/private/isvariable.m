function [tf, vi] = isvariable(varname, tbl)
   %ISVARIABLE Determine if VARNAME is a variable in table TBL.
   %
   %  [TF, VI] = ISVARIABLE(VARNAME, TBL) returns TF = true if VARNAME is a
   %  variable in table TBL, and the variable (column) index VI.
   %
   %  VARNAME may name several variables. TF then holds one logical per name,
   %  in the order given. VI holds the column index of each name that was
   %  found, so VI is shorter than TF when a name is absent.
   %
   % Example
   %  tbl = table(1, 2, 'VariableNames', {'a', 'b'});
   %  [tf, vi] = isvariable(["a"; "z"; "b"], tbl)   % tf = [1;0;1], vi = [1;2]
   %
   % See also: ismember, table

   % Reconciled 2026 across the icemodel and groupstats vendored copies:
   % groupstats' ismember implementation (correct multi-name semantics) with
   % the tabular class spec so timetables keep working. icemodel keeps its
   % own validateattributes variant for codegen, which is an icemodel-only
   % requirement.
   arguments
      varname (:,1) string
      tbl (:,:) tabular
   end
   [tf, loc] = ismember(varname, string(tbl.Properties.VariableNames));
   vi = loc(tf);

   % tf = any(varname == string(tbl.Properties.VariableNames))
end
