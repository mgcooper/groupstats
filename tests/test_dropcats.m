%TEST_DROPCATS Test dropcats function

import groupstats.dropcats

% Define test data
T = table(categorical({'a'; 'b'; 'c'}), categorical({'x'; 'y'; 'z'}));
T.Var1 = addcats(T.Var1, 'd');
T.Var2 = addcats(T.Var2, 'w');

% Expected result after dropping unused categories 'd' and 'w'
expected = T;
expected.Var1 = removecats(expected.Var1, 'd');
expected.Var2 = removecats(expected.Var2, 'w');

% Note: the verify success and verify failure are redundant with the tests that
% follow them, but keep them for reference for using the custom function-based
% testing in a script-based test framework.

%% Test function accuracy with one variable name
returned = dropcats(T, 'Var1');
assert(isequal(returned.Var1, expected.Var1), 'Unexpected result from dropcats function for one variable name');

%% verify success
testdiag = "Unexpected result from dropcats function";
eid = 'groupstats:dropcats';
assertSuccess(@() dropcats(T, 'Var1'), eid, testdiag)

%% Test function accuracy with multiple variable names
returned = dropcats(T, ["Var1", "Var2"]);
assert(isequal(returned, expected), 'Unexpected result from dropcats function for multiple variable names');

%% Test function accuracy with default variable names
% the default variable names are all categorical vars
returned = dropcats(T);
assert(isequal(returned, expected), 'Unexpected result from dropcats function without specifying variable names');

%% Test error handling

% Test with incorrect variable name
try
   dropcats(T, 'Var3');
   error('Expected an error for incorrect variable name, but none was thrown');
catch ME
   assert(strcmp(ME.identifier, 'groupstats:dropcats:badVariableName'), 'Unexpected error identifier for incorrect variable name');
   %assert(strcmp(ME.identifier, 'MATLAB:table:UnrecognizedVarName'), 'Unexpected error identifier for incorrect variable name');
end

%% Verify Failure with incorrect variable name
testdiag = "Expected an error for incorrect variable name, but none was thrown";
eid = 'groupstats:dropcats:badVariableName';
assertError(@() dropcats(T, 'Var3'), eid, testdiag)

%% Test with non-categorical variable name
T_noncat = table(1, 2, 3);
try
   dropcats(T_noncat, 'Var1');
   error('Expected an error for non-categorical variable, but none was thrown');
catch ME
   assert(strcmp(ME.identifier, 'groupstats:dropcats:nonCategoricalVar'), 'Unexpected error identifier for non-categorical variable');
end

%% Test invalid inputs

% Test with non-table input
try
   dropcats('invalid', 'Var1');
   error('Expected an error for non-table input, but none was thrown');
catch ME
   assert(strcmp(ME.identifier, 'MATLAB:validation:UnableToConvert'), 'Unexpected error identifier for non-table input');
end

% Test with non-categorical variable name
try
   dropcats(T, 123);
   error('Expected an error for non-string variable name, but none was thrown');
catch ME
   assert(strcmp(ME.identifier, 'groupstats:dropcats:badVariableName'), 'Unexpected error identifier for incorrect variable name');
   %assert(strcmp(ME.identifier, 'MATLAB:table:UnrecognizedVarName'), 'Unexpected error identifier for non-string variable name');
end

%% Test too many input arguments

try
   dropcats(T, 'Var1', 123);
   error('Expected an error for too many inputs, but none was thrown');
catch ME
   assert(strcmp(ME.identifier, 'MATLAB:TooManyInputs'), 'Unexpected error identifier for too many inputs');
end

%% Test empty inputs

try
   dropcats();
   error('Expected an error for empty inputs, but none was thrown');
catch ME
   assert(strcmp(ME.identifier, 'MATLAB:minrhs'), 'Unexpected error identifier for empty inputs');
end

% -------------------------------------
% LOCAL FUNCTIONS
% -------------------------------------
function assertError(fh, eid, varargin)
   %ASSERTERROR assert error using function handle and error id

   import matlab.unittest.diagnostics.Diagnostic;
   import matlab.unittest.constraints.Throws;

   throws = Throws(eid);
   passed = throws.satisfiedBy(fh);
   diagText = ""; % set empty string for passed == true
   if ~passed
      diag = Diagnostic.join(varargin{:}, throws.getDiagnosticFor(fh));
      arrayfun(@diagnose, diag);
      diagText = strjoin({diag.DiagnosticText},[newline newline]);
   end
   assert(passed, diagText);
end

function assertSuccess(fnc, eid, varargin)
   %ASSERTSUCCESS assert success using function handle and error id

   import matlab.unittest.diagnostics.Diagnostic;
   import matlab.unittest.constraints.Throws;

   throws = Throws(eid);
   passed = throws.satisfiedBy(fnc);
   diagText = ""; % set empty string for passed == true
   if passed
      diag = Diagnostic.join(varargin{:}, throws.getDiagnosticFor(fnc));
      arrayfun(@diagnose, diag);
      diagText = strjoin({diag.DiagnosticText},[newline newline]);
   end
   assert(~passed, diagText);
end
