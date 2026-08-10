function [tf,vi] = isvariable(varname,tbl)
   %ISVARIABLE determine if VARNAME is a variable in table tbl
   %
   %  [TF, VI] = isvariable(VARNAME,tbl) returns TF = true if VARNAME is a variable
   %  in table tbl, and the variable (column) index VI.
   %
   % See also

   arguments
      varname (:,1) string
      tbl (:,:) table
   end
   tf = any(strcmp(varname,tbl.Properties.VariableNames));
   vi = find(strcmp(varname,tbl.Properties.VariableNames));

   % tf = any(varname == string(tbl.Properties.VariableNames))
end
