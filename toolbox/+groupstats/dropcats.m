function tbl = dropcats(tbl, varnames)
   %DROPCATS Remove categories that are not present in a table variable.
   %
   %  TBL = DROPCATS(TBL, VARNAME) takes a table TBL and the name of a
   %  categorical variable VARNAME. It removes any categories in VARNAME that
   %  are not present in the actual data, and returns the modified table.
   %
   % Example:
   %
   %  tbl = table(categorical({'a'; 'b'; 'c'}));
   %  tbl.Var1 = addcats(tbl.Var1, 'd');
   %  oldcats = categories(tbl.Variables)
   %  tbl = groupstats.dropcats(tbl, 'Var1');
   %  % Confirm the category 'd' has been removed from the categorical variable:
   %  newcats = categories(tbl.Variables)
   %
   % Copyright (c) 2023, Matt Cooper, BSD 3-Clause License, github.com/mgcooper
   %
   % See also: removecats, ismember, categories

   % PARSE ARGUMENTS
   arguments
      tbl tabular % Ensure tbl is a table or other tabular data structure
      varnames (1, :) string = tbl(:, vartype('categorical')).Properties.VariableNames;
   end

   % The default varnames names every categorical variable. The two
   % checks in the else branch then cannot fire. A table with no
   % categorical variable stops at the first check instead. With a
   % caller's list, the else branch catches a name that is not in the
   % table and a variable that is not categorical.
   if isempty(varnames)
      msg = 'No categorical variables found in the table.';
      eid = 'groupstats:dropcats:nonCategoricalVar';
      error(eid, msg);
   else
      % Confirm the requested variables exist in the table and are categorical
      for var = varnames(:)'
         if ~any(strcmp(var, tbl.Properties.VariableNames))
            msg = 'Variable name "%s" not found in the table.';
            eid = 'groupstats:dropcats:badVariableName';
            error(eid, msg, var);
         end
         if ~iscategorical(tbl.(var))
            msg = 'Variable "%s" must be categorical.';
            eid = 'groupstats:dropcats:nonCategoricalVar';
            error(eid, msg, var);
         end
      end
   end

   % removecats with no category list removes every category no row
   % uses, one variable at a time.
   for var = varnames(:)'
      tbl.(var) = removecats(tbl.(var));
   end
end

%% LICENSE

% BSD 3-Clause License
%
% Copyright (c) 2023, Matt Cooper (mgcooper)
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
