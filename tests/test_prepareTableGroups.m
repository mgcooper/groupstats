classdef test_prepareTableGroups < matlab.unittest.TestCase
   %TEST_PREPARETABLEGROUPS Test groupstats.prepareTableGroups.
   %
   % prepareTableGroups is the one place the chart functions validate group
   % members and select rows. These cases cover the name-value arguments, the
   % data changes the docstring promises, and every documented error.
   %
   % See also: groupstats.prepareTableGroups

   properties
      % A table with an x-axis group, a color group, a row-select variable,
      % and one numeric data variable.
      Tbl
   end

   methods (TestMethodSetup)

      function buildTable(testCase)
         % Six rows across two x-groups, two color groups, and two regions.
         testCase.Tbl = table( ...
            categorical(["a"; "a"; "b"; "b"; "c"; "c"]), ...
            categorical(["red"; "blue"; "red"; "blue"; "red"; "blue"]), ...
            ["north"; "north"; "south"; "south"; "north"; "south"], ...
            (1:6)', ...
            'VariableNames', {'XGroup', 'CGroup', 'Region', 'Value'});
      end
   end

   methods (Test)

      function testNoOptionsKeepsEveryRow(testCase)
         % With only the data variable named, no row is dropped.

         returned = groupstats.prepareTableGroups(testCase.Tbl, "Value");

         expected = height(testCase.Tbl);
         testCase.verifyEqual(height(returned), expected);
      end

      function testXGroupMembersSelectRows(testCase)
         % Naming x-group members keeps only their rows.

         returned = groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            XGroupVar = "XGroup", XGroupMembers = "a");

         expected = [1; 2];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testCGroupMembersSelectRows(testCase)
         % Naming color group members keeps only their rows.

         returned = groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            CGroupVar = "CGroup", CGroupMembers = "red");

         expected = [1; 3; 5];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testBothGroupsIntersect(testCase)
         % Both member lists apply, so the surviving rows are the ones in both.

         returned = groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            XGroupVar = "XGroup", XGroupMembers = ["a", "b"], ...
            CGroupVar = "CGroup", CGroupMembers = "blue");

         expected = [2; 4];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testRowSelectMembersSelectRows(testCase)
         % RowSelectVar selects rows without becoming a group variable.

         returned = groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            RowSelectVar = "Region", RowSelectMembers = "south");

         expected = [3; 4; 6];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testEmptyMembersKeepEveryGroup(testCase)
         % Naming a group variable without members keeps every row of it.
         % Resolving the members to the full member list would select the same
         % rows, which is why this function does not call groupmembers.

         returned = groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            XGroupVar = "XGroup");

         expected = height(testCase.Tbl);
         testCase.verifyEqual(height(returned), expected);
      end

      function testGroupVarBecomesCategorical(testCase)
         % A text group variable is converted, because the chart functions
         % group and order by category.

         tbl = testCase.Tbl;
         tbl.XGroup = string(tbl.XGroup);

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "XGroup");

         testCase.verifyClass(returned.XGroup, 'categorical');
      end

      function testUnusedCategoriesAreDropped(testCase)
         % Selecting members drops the categories no surviving row uses, so a
         % legend lists only the groups that are plotted.

         returned = groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            XGroupVar = "XGroup", XGroupMembers = "a");

         expected = {'a'};
         testCase.verifyEqual(categories(returned.XGroup), expected);
      end

      function testCategoricalDataVarBecomesDouble(testCase)
         % A categorical y-axis variable is converted, because a chart needs
         % numeric axis data.

         tbl = testCase.Tbl;
         tbl.Value = categorical(tbl.Value);

         returned = groupstats.prepareTableGroups(tbl, "Value");

         testCase.verifyClass(returned.Value, 'double');
         testCase.verifyEqual(returned.Value, (1:6)');
      end

      function testTextXDataVarBecomesDouble(testCase)
         % A text x-axis variable is converted the same way.

         tbl = testCase.Tbl;
         tbl.XValue = string((11:16)');

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XDataVar = "XValue");

         testCase.verifyEqual(returned.XValue, (11:16)');
      end

      function testCGroupMembersWithoutCGroupVarErrors(testCase)
         % Members without their group variable is a caller mistake. Reading
         % tbl.() with an empty name raised an opaque table error instead.

         testCase.verifyError( ...
            @() groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            CGroupMembers = "red"), ...
            'groupstats:prepareTableGroups:membersWithoutGroupVar');
      end

      function testXGroupMembersWithoutXGroupVarErrors(testCase)
         % The same rule applies to the x-axis group.

         testCase.verifyError( ...
            @() groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            XGroupMembers = "a"), ...
            'groupstats:prepareTableGroups:membersWithoutGroupVar');
      end

      function testRowSelectMembersWithoutRowSelectVarErrors(testCase)
         % And to the row-select variable.

         testCase.verifyError( ...
            @() groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            RowSelectMembers = "north"), ...
            'groupstats:prepareTableGroups:membersWithoutGroupVar');
      end

      function testUnknownGroupMemberErrors(testCase)
         % A member the group variable does not carry is an error.

         testCase.verifyError( ...
            @() groupstats.prepareTableGroups(testCase.Tbl, "Value", ...
            XGroupVar = "XGroup", XGroupMembers = "zzz"), ...
            'groupstats:validatemember:notAMember');
      end

      function testUnknownDataVarErrors(testCase)
         % The data variable must name a column of the table.
         %
         % validatestring builds its identifier from the calling function's
         % name, which prepareTableGroups reads with mcallername. The whole
         % identifier therefore changes with the caller, so this pins the
         % stable suffix. Beads groupstats-hw0 covers making the family's
         % identifiers consistent.

         try
            groupstats.prepareTableGroups(testCase.Tbl, "NoSuchVar");
            testCase.verifyFail('Expected an error for an unknown variable.')
         catch ME
            testCase.verifyTrue( ...
               endsWith(ME.identifier, ':unrecognizedStringChoice'), ...
               sprintf('Unexpected identifier: %s', ME.identifier));
         end
      end

      function testTimetableIsAccepted(testCase)
         % A timetable passes through with its rows intact. Grouping by its
         % time dimension is a documented limitation: the name passes the
         % variable-name check, and dropcats then rejects it.

         tbl = table2timetable(testCase.Tbl, ...
            'RowTimes', datetime(2020, 1, 1) + days(0:5)');

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "XGroup");

         expected = height(tbl);
         testCase.verifyEqual(height(returned), expected);
      end

      function testTimetableTimeDimensionAsGroupErrors(testCase)
         % Pin the documented limitation, so a later change that supports it
         % has to update this test and the docstring together.

         tbl = table2timetable(testCase.Tbl, ...
            'RowTimes', datetime(2020, 1, 1) + days(0:5)');

         testCase.verifyError( ...
            @() groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "Time"), ...
            'groupstats:dropcats:badVariableName');
      end

      function testOrdinalGroupKeepsItsOrder(testCase)
         % An already-categorical group variable passes through untouched, so
         % an ordinal group keeps its Ordinal flag and its category order.
         % Wrapping it in categorical() again would reset both.

         tbl = testCase.Tbl;
         tbl.XGroup = categorical(string(tbl.XGroup), ["c", "b", "a"], ...
            'Ordinal', true);

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "XGroup");

         testCase.verifyTrue(isordinal(returned.XGroup));
         expected = {'c'; 'b'; 'a'};
         testCase.verifyEqual(categories(returned.XGroup), expected);
      end

      function testMissingGroupValuesAreDropped(testCase)
         % A row whose group value is undefined cannot be placed on a chart,
         % so it goes. The removed groupmembers default did this by accident.

         tbl = testCase.Tbl;
         tbl.XGroup(3) = missing;

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "XGroup");

         expected = [1; 2; 4; 5; 6];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testMissingStringGroupValuesAreDropped(testCase)
         % A missing string is dropped for the same reason as an undefined
         % categorical.

         tbl = testCase.Tbl;
         tbl.XGroup = string(tbl.XGroup);
         tbl.XGroup(3) = missing;

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "XGroup");

         expected = [1; 2; 4; 5; 6];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testEmptyCharGroupValuesAreKept(testCase)
         % An empty char is not a missing value. The removed groupmembers
         % default kept its row, and this reproduces that.

         tbl = testCase.Tbl;
         tbl.XGroup = cellstr(string(tbl.XGroup));
         tbl.XGroup{3} = '';

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "XGroup");

         expected = (1:6)';
         testCase.verifyEqual(returned.Value, expected);
      end

      function testNanGroupValuesAreDropped(testCase)
         % A NaN group value converts to a missing string, so its row goes.
         % The removed groupmembers default dropped it too.

         tbl = testCase.Tbl;
         tbl.XGroup = [1; 1; NaN; 2; 2; 3];

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XGroupVar = "XGroup");

         expected = [1; 2; 4; 5; 6];
         testCase.verifyEqual(returned.Value, expected);
      end

      function testUnconvertibleDataVarIsLeftAlone(testCase)
         % A categorical data variable whose categories are not numeric cannot
         % convert to double. The conversion failure is swallowed and the
         % variable is returned as it is, for the calling function to reject.

         tbl = testCase.Tbl;
         tbl.Value = categorical(["p"; "q"; "p"; "q"; "p"; "q"]);

         returned = groupstats.prepareTableGroups(tbl, "Value");

         expected = tbl.Value;
         testCase.verifyEqual(returned.Value, expected);
      end

      function testUnconvertibleXDataVarIsLeftAlone(testCase)
         % The same rule applies to the x-axis data variable, which tries a
         % categorical conversion and then a text conversion.

         tbl = testCase.Tbl;
         tbl.XValue = ["p"; "q"; "p"; "q"; "p"; "q"];

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            XDataVar = "XValue");

         testCase.verifyTrue(all(isnan(returned.XValue)));
      end

      function testMissingColorGroupValuesAreDropped(testCase)
         % The same rule applies to the color group.

         tbl = testCase.Tbl;
         tbl.CGroup(2) = missing;

         returned = groupstats.prepareTableGroups(tbl, "Value", ...
            CGroupVar = "CGroup");

         expected = [1; 3; 4; 5; 6];
         testCase.verifyEqual(returned.Value, expected);
      end
   end
end
