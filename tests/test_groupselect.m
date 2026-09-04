classdef test_groupselect < matlab.unittest.TestCase
   %TEST_GROUPSELECT Test groupstats.groupselect.
   %
   % groupselect finds the one variable that holds every requested member and
   % keeps the rows matching them. These cases cover the search, the no-match
   % guard, and the one-variable rule.
   %
   % See also: groupstats.groupselect

   properties
      % Two variables that could match a member list, and one that cannot.
      Tbl
   end

   methods (TestMethodSetup)

      function buildTable(testCase)
         testCase.Tbl = table( ...
            ["a"; "b"; "c"; "a"], ...
            ["north"; "south"; "north"; "south"], ...
            (1:4)', ...
            'VariableNames', {'Letter', 'Region', 'Value'});
      end
   end

   methods (Test)
      function testSelectsFromATimetable(testCase)
         % prepareTableGroups accepts a timetable and calls this function,
         % so declaring the input table here made row selection on a
         % timetable fail.

         tt = table2timetable(testCase.Tbl, ...
            'RowTimes', datetime(2020, 1, 1) + days(0:3)');

         returned = groupstats.groupselect(tt, "Letter", "a");

         testCase.verifyClass(returned, 'timetable');
         testCase.verifyEqual(height(returned), 2);
      end


      function testEmptyMemberListIsRejected(testCase)
         % Requesting no members matches every variable, because all([]) is
         % true. Reporting that as an ambiguous variable would name two
         % variables that hold nothing in common.

         testCase.verifyError(@() groupstats.groupselect(testCase.Tbl, ...
            ["Letter", "Region"], string.empty(0, 1)), ...
            'groupstats:groupselect:noMembersRequested');
      end

      function testSelectsMatchingRows(testCase)
         % Only the rows whose value is a requested member survive.

         returned = groupstats.groupselect(testCase.Tbl, "Letter", ["a", "b"]);

         expected = [1; 2; 4];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testFindsTheVariableAmongSeveral(testCase)
         % The caller may name several variables without knowing which one
         % carries the members.

         returned = groupstats.groupselect(testCase.Tbl, ...
            ["Letter", "Region"], "south");

         expected = [2; 4];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testNoMatchingVariableErrors(testCase)
         % No variable holds the requested member. The error names the members
         % and the variables searched. It raised an opaque table error about
         % an empty variable name.

         testCase.verifyError( ...
            @() groupstats.groupselect(testCase.Tbl, "Letter", "zzz"), ...
            'groupstats:groupselect:noMatchingVariable');
      end

      function testPartialMemberSetErrors(testCase)
         % One variable must hold every requested member, not some of them.

         tbl = testCase.Tbl;

         testCase.verifyError( ...
            @() groupstats.groupselect(tbl, "Letter", ["a", "zzz"]), ...
            'groupstats:groupselect:noMatchingVariable');
      end

      function testTwoMatchingVariablesErrors(testCase)
         % Two variables holding the same member set is ambiguous.

         tbl = table(["a"; "b"], ["a"; "b"], (1:2)', ...
            'VariableNames', {'One', 'Two', 'Value'});

         testCase.verifyError( ...
            @() groupstats.groupselect(tbl, ["One", "Two"], ["a", "b"]), ...
            'groupstats:groupselect:ambiguousVariable');
      end
   end
end
