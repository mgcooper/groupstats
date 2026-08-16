classdef test_privatehelpers < matlab.unittest.TestCase
   %TEST_PRIVATEHELPERS Test the helpers in +groupstats/private.
   %
   % MATLAB shows a private folder only to code in its parent folder, so these
   % helpers are not callable by name from this package.
   % groupstats.internal.privatefunction returns a handle to each one.
   %
   % See also: groupstats.internal.privatefunction

   properties
      % Handles to the private helpers under test.
      groupmembers
      validatemember
      isvariable
      settablevarnames
   end

   methods (TestClassSetup)

      function resolvePrivateHandles(testCase)
         % Resolve every handle once. Building a handle changes directory, so
         % doing it per test would slow the suite for no gain.
         testCase.groupmembers = ...
            groupstats.internal.privatefunction('groupmembers');
         testCase.validatemember = ...
            groupstats.internal.privatefunction('validatemember');
         testCase.isvariable = ...
            groupstats.internal.privatefunction('isvariable');
         testCase.settablevarnames = ...
            groupstats.internal.privatefunction('settablevarnames');
      end
   end

   methods (Test)

      % ---- groupmembers

      function testGroupmembersReturnsUniqueValues(testCase)
         % The members are the unique values of the named variable.

         tbl = table(categorical(["a"; "b"; "a"]), 'VariableNames', {'Group'});

         returned = testCase.groupmembers(tbl, "Group");

         expected = categorical(["a"; "b"]);
         testCase.verifyEqual(returned, expected);
      end

      function testGroupmembersEmptyVarReturnsEmptyString(testCase)
         % An empty group variable returns string.empty by default. The chart
         % functions read that as "no grouping requested".

         tbl = table(categorical(["a"; "b"]), 'VariableNames', {'Group'});

         returned = testCase.groupmembers(tbl, string.empty());

         expected = string.empty();
         testCase.verifyEqual(returned, expected);
      end

      function testGroupmembersPreferredEmptyValue(testCase)
         % PreferredEmptyValue fixes the return type when the group variable
         % is empty. Without it the return type depends on which branch runs,
         % which breaks an arguments-block default that validates a class.

         tbl = table(categorical(["a"; "b"]), 'VariableNames', {'Group'});

         returned = testCase.groupmembers(tbl, string.empty(), ...
            categorical.empty());

         expected = categorical.empty();
         testCase.verifyEqual(returned, expected);
      end

      function testGroupmembersPreferredEmptyValueIgnoredWhenVarGiven(testCase)
         % PreferredEmptyValue applies only to the empty branch.

         tbl = table(categorical(["a"; "b"; "a"]), 'VariableNames', {'Group'});

         returned = testCase.groupmembers(tbl, "Group", categorical.empty());

         expected = categorical(["a"; "b"]);
         testCase.verifyEqual(returned, expected);
      end

      % ---- validatemember

      function testValidatememberAcceptsExactMembers(testCase)
         % Every named member is present, so the call raises nothing.

         testCase.verifyWarningFree(@() testCase.validatemember( ...
            ["Jan", "Feb"], ["Jan", "Feb", "Mar"], 'CALLER', 'Members'));
      end

      function testValidatememberRejectsPrefix(testCase)
         % "Jan" is not "January". validatestring's partial matching accepted
         % this, and the caller's exact ismember then selected no rows and
         % returned an empty result with no error.

         testCase.verifyError(@() testCase.validatemember( ...
            "Jan", ["January", "February"], 'CALLER', 'Members'), ...
            'groupstats:validatemember:notAMember');
      end

      function testValidatememberRejectsUnknownMember(testCase)
         % A member absent from the valid list is an error.

         testCase.verifyError(@() testCase.validatemember( ...
            ["Jan", "Xyz"], ["Jan", "Feb"], 'CALLER', 'Members'), ...
            'groupstats:validatemember:notAMember');
      end

      function testValidatememberAllowsExtraValidMembers(testCase)
         % The check is one-way. The valid list may hold members the caller
         % did not name.

         testCase.verifyWarningFree(@() testCase.validatemember( ...
            "Jan", ["Jan", "Feb", "Mar"], 'CALLER', 'Members'));
      end

      % ---- isvariable

      function testIsvariableScalarName(testCase)
         % A name the table carries returns true and its column index.

         tbl = table(1, 2, 'VariableNames', {'a', 'b'});

         [returned, vi] = testCase.isvariable("b", tbl);

         testCase.verifyTrue(returned);
         testCase.verifyEqual(vi, 2);
      end

      function testIsvariableAbsentName(testCase)
         % A name the table does not carry returns false and no index.

         tbl = table(1, 2, 'VariableNames', {'a', 'b'});

         [returned, vi] = testCase.isvariable("z", tbl);

         testCase.verifyFalse(returned);
         testCase.verifyEmpty(vi);
      end

      function testIsvariableVectorOfNames(testCase)
         % The arguments block accepts a vector of names, so the result must
         % report one logical per name. strcmp could not do this.

         tbl = table(1, 2, 'VariableNames', {'a', 'b'});

         [returned, vi] = testCase.isvariable(["a"; "z"; "b"], tbl);

         expected = [true; false; true];
         testCase.verifyEqual(returned, expected);
         testCase.verifyEqual(vi, [1; 2]);
      end

      % ---- privatefunction, the mechanism these tests depend on

      function testPrivatefunctionUnknownNameErrors(testCase)
         % An unknown name reports which function was not found. The template
         % copy left the search result unset on this path, so the check that
         % raises this error itself failed with an undefined-variable error.

         testCase.verifyError( ...
            @() groupstats.internal.privatefunction('nosuchhelper'), ...
            'groupstats:privatefunction:functionNotFound');
      end

      function testPrivatefunctionRestoresWorkingDirectory(testCase)
         % Building a handle changes directory into the private folder. The
         % cleanup object must put the caller back.

         expected = pwd();
         groupstats.internal.privatefunction('groupmembers');

         returned = pwd();
         testCase.verifyEqual(returned, expected);
      end

      function testPrivatefunctionWithNoInputReturnsEveryFolder(testCase)
         % The no-input syntax returns a struct of handle structs, one field
         % per private folder in the toolbox.
         %
         % Check the whole field set, not just that the two expected names
         % appear. The folder search matched any path holding the word
         % private, and on macOS the real paths /private/tmp and /private/var
         % exist, so a toolbox under one of them took every folder in that
         % tree and cell2struct raised DuplicateFieldName. Membership passes
         % while extra folders leak in; an exact set does not.

         returned = groupstats.internal.privatefunction();

         testCase.verifyClass(returned, 'struct');

         returned = sort(string(fieldnames(returned)))';
         expected = ["groupstats", "internal"];
         testCase.verifyEqual(returned, expected);
      end

      function testPrivatefunctionIgnoresAPrivateAncestorFolder(testCase)
         % The folder search matched any path holding the word private. On
         % macOS tempdir sits under /private/var, so a toolbox copied there
         % matched every folder in that tree and cell2struct raised
         % DuplicateFieldName. Run a copy from such a path, because a checkout
         % whose ancestors are not named private cannot show the defect.

         scratch = tempname();
         testCase.assumeTrue(contains(scratch, [filesep 'private' filesep]), ...
            'This check needs a temporary path under a folder named private.');

         mkdir(scratch);
         testCase.addTeardown(@() rmdir(scratch, 's'));

         % projectpath derives the root from its own location, so a copy of
         % the toolbox tree makes the copy report the scratch path as root.
         copyfile(groupstats.internal.buildpath(), ...
            fullfile(scratch, 'toolbox'));

         % addpath prepends, so the copy shadows the checkout for this call.
         testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
            fullfile(scratch, 'toolbox')));

         returned = sort(string(fieldnames( ...
            groupstats.internal.privatefunction())))';
         expected = ["groupstats", "internal"];
         testCase.verifyEqual(returned, expected);
      end

      function testPrivatefunctionWithNoInputHoldsCallableHandles(testCase)
         % Each field holds handles that can be called.

         all = groupstats.internal.privatefunction();

         returned = all.internal.isoctave();
         testCase.verifyFalse(returned);
      end

      % ---- settablevarnames

      function testSettablevarnamesFullList(testCase)
         % One name per column renames every column.

         tbl = table(1, 2, 'VariableNames', {'a', 'b'});

         returned = testCase.settablevarnames(tbl, ["x", "y"]);

         expected = {'x', 'y'};
         testCase.verifyEqual(returned.Properties.VariableNames, expected);
      end

      function testSettablevarnamesConsecutiveUsesUnderscore(testCase)
         % The docstring promises VARNAME_1, VARNAME_2. The code produced
         % VARNAME1 with no separator.

         tbl = table(1, 2, 3, 'VariableNames', {'a', 'b', 'c'});

         returned = testCase.settablevarnames(tbl, "col", 'consecutive');

         expected = {'col_1', 'col_2', 'col_3'};
         testCase.verifyEqual(returned.Properties.VariableNames, expected);
      end
   end
end
