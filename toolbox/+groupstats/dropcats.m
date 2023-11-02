function tbl = dropcats(tbl, varnames)
   % DROPCATS Remove categories that are not present in a table variable.
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
   
   % I might just return rather than error on the first if, and in the else,
   % only error if ALL categorical ... actually I think I should keep the else
   % errors because if varnames is default, they are guaranteed not to trigger,
   % so they are useful for understanding how the function is designed to work,
   % if a user wants all cats dropped, just call dropcats(tbl), also it will
   % provide an error if the user thinks a var is categorical but it isnt', but
   % need to confirm what happens when a table is constructed with a categorical
   % variable then that variable is converted to a string and/or cats are
   % removed, are the cats still a property of the table? 
   
   % If varnames is not provided, find all categorical variables
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
   
   % I realized I can just call removecats with no oldcats input, since
   % removecats removes unused cats by default. But I kept the loop because I
   % could add an 'oldcats' input option to mimic removecats
   
   % Iterate through the categorical variables and remove unused categories
   for var = varnames(:)'
      tbl.(var) = removecats(tbl.(var));
   end
   
%    % Iterate through the categorical variables and remove unused categories
%    for var = varnames(:)'
%       % Retrieve the categories in the given variable
%       allcats = categories(tbl.(var));
%    
%       % Find categories that are not present in the actual data
%       oldcats = allcats(~ismember(allcats, tbl.(var)));
%    
%       % Remove the unused categories
%       tbl.(var) = removecats(tbl.(var), oldcats);
%    end
end

%% TESTS

%!test

% ## add octave tests here

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