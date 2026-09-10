classdef test_groupsummary < matlab.unittest.TestCase
   %TEST_GROUPSUMMARY Test groupstats.groupsummary.
   %
   % These cases pin the defects the audit named:
   %
   %  1. Omitting datavar errored, which broke four of the six documented
   %     syntaxes.
   %  2. Three or more group variables errored in the group-bin parsing.
   %  3. Any output variable whose name started with "fun" was renamed after
   %     an anonymous method, including a variable the caller named.
   %  4. The matrix path could not be reached, because the input validator
   %     rejected a non-table first.
   %
   % See also: groupstats.groupsummary, groupstats.grouppercent

   properties
      Tbl
      GroupVars
      DataVars
   end

   methods (TestMethodSetup)

      function loadTestData(testCase)
         data = groupstats.test.generateTestData('groupsummary');
         testCase.Tbl = data.tbl;
         testCase.GroupVars = data.groupvars;
         testCase.DataVars = data.datavars;
      end
   end

   methods (Test)

      function testGroupsetsAlreadyInGroupvarsIsNotRepeated(testCase)
         % The summary groups by groupsets as well. Naming a variable twice
         % gave MATLAB's groupsummary one binning scheme too few, which it
         % reported from inside parsegroupbins with no mention of groupsets.

         G = groupstats.groupsummary(testCase.Tbl, ["Grp", "Sub"], ...
            {'mean'}, "Value", GroupSets = "Grp");

         returned = string(G.Properties.VariableNames);
         testCase.verifyEqual(sum(returned == "Grp"), 1);
      end

      function testGroupsetsOutsideGroupvarsBecomesAGroupVariable(testCase)
         % A groupsets variable the caller did not list among groupvars must
         % still reach the summary, so each set gets its own rows. Two group
         % variables, because one hid the bin-count mismatch behind the
         % "none" sentinel.

         G = groupstats.groupsummary(testCase.Tbl, ["Grp", "Sub"], ...
            {'mean'}, "Value", GroupSets = "Set");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "Set"));

         % The percent join has to find a match for every row.
         testCase.verifyTrue(any(startsWith(returned, "Percent")));
      end

      function testGroupsetsOutsideGroupvarsIsNotSummarizedAsData(testCase)
         % With datavar omitted, the default is every numeric variable that
         % is not a group variable. A numeric groupsets variable is one the
         % summary groups by, so summarizing it repeats its own group value.

         tbl = testCase.Tbl;
         tbl.SetNum = double(categorical(tbl.Set));

         G = groupstats.groupsummary(tbl, "Grp", "mean", [], ...
            GroupSets = "SetNum");

         returned = string(G.Properties.VariableNames);
         testCase.verifyFalse(any(returned == "mean_SetNum"));
      end

      function testGroupsetsOutsideGroupvarsAcceptsABinScheme(testCase)
         % The caller sizes its bin schemes for groupvars. The groupsets
         % variable it did not list gets no scheme, rather than a copy of
         % one meant for another variable.

         tbl = testCase.Tbl;
         tbl.Amount = repmat([1; 3], height(tbl) / 2, 1);

         G = groupstats.groupsummary(tbl, "Amount", ...
            {'mean'}, "Value", {[0 2 4]}, GroupSets = "Set");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "Set"));
         testCase.verifyTrue(any(contains(returned, "Amount")));
      end

      function testOmittedDataVarSummarizesEveryNumericVariable(testCase)
         % With no datavar the default is a vartype subscript. It has to
         % resolve to names, because the output-name code indexes it.

         G = groupstats.groupsummary(testCase.Tbl, "Grp");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "mean_Value"));
         testCase.verifyTrue(any(returned == "mean_Other"));
      end

      function testOmittedDataVarExcludesGroupVariables(testCase)
         % A group variable is never a data variable, matching the built-in.

         tbl = testCase.Tbl;
         tbl.Grp = double(tbl.Grp);

         G = groupstats.groupsummary(tbl, "Grp");

         returned = string(G.Properties.VariableNames);
         testCase.verifyFalse(any(returned == "mean_Grp"));
      end

      function testOmittedMethodDefaultsToMean(testCase)
         % The documented default method is mean.

         G = groupstats.groupsummary(testCase.Tbl, "Grp", [], "Value");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "mean_Value"));
      end

      function testThreeGroupVariables(testCase)
         % Three group variables errored while the bin parser built a
         % two-element list for them.

         G = groupstats.groupsummary(testCase.Tbl, testCase.GroupVars, ...
            "mean", "Value");

         returned = height(G);
         expected = height(groupcounts(testCase.Tbl, testCase.GroupVars));
         testCase.verifyEqual(returned, expected);
      end

      function testAnonymousMethodNamesItsOwnColumn(testCase)
         % groupsummary names an anonymous method's output fun1_<var>.
         % Replace that with the function's own text.

         G = groupstats.groupsummary(testCase.Tbl, "Grp", {@(x) max(x)}, ...
            "Value");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "@(x)max(x)_Value"));
      end

      function testCallerVariableStartingWithFunSurvives(testCase)
         % A group variable named funding must keep its name. Matching a bare
         % "fun" prefix renamed it after the anonymous method.

         tbl = testCase.Tbl;
         tbl.Properties.VariableNames{1} = 'funding';

         G = groupstats.groupsummary(tbl, "funding", {@(x) max(x)}, "Value");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "funding"));
      end

      function testGroupSetsAddAPercentColumn(testCase)
         % groupsets names the variable whose members define distinct sets.

         G = groupstats.groupsummary(testCase.Tbl, "Sub", "mean", "Value", ...
            GroupSets = "Grp");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "Percent_Grp"));
      end

      function testRowSelectKeepsOnlyTheNamedMembers(testCase)
         % RowSelectVar and RowSelectMembers drop rows before summarizing.

         G = groupstats.groupsummary(testCase.Tbl, "Grp", "mean", "Value", ...
            RowSelectVar = "Sub", RowSelectMembers = "x");

         returned = sum(G.GroupCount);
         expected = sum(testCase.Tbl.Sub == "x");
         testCase.verifyEqual(returned, expected);
      end

      function testRowSelectMembersWithoutVarErrors(testCase)
         % Row selection needs both halves. Members alone have no column to
         % search, the same rule prepareTableGroups applies, under this
         % function's own identifier.

         testCase.verifyError( ...
            @() groupstats.groupsummary(testCase.Tbl, ["Grp", "Sub"], ...
            "mean", "Value", RowSelectMembers = "x"), ...
            'groupstats:groupsummary:membersWithoutGroupVar');
      end

      function testRowSelectVarWithoutMembersErrors(testCase)
         % The other half alone selects no rows and leaves an empty summary,
         % so it is an error too.

         testCase.verifyError( ...
            @() groupstats.groupsummary(testCase.Tbl, "Grp", "mean", ...
            "Value", RowSelectVar = "Sub"), ...
            'groupstats:groupsummary:rowSelectVarWithoutMembers');
      end

      function testGroupCountMatchesTheTable(testCase)
         % Every row of the table lands in exactly one group.

         G = groupstats.groupsummary(testCase.Tbl, "Grp", "mean", "Value");

         returned = sum(G.GroupCount);
         expected = height(testCase.Tbl);
         testCase.verifyEqual(returned, expected);
      end

      function testMethodsOnlySyntax(testCase)
         % The documented three-argument syntax: tbl, groupvars, methods.

         G = groupstats.groupsummary(testCase.Tbl, "Grp", "median");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "median_Value"));
      end

      function testGroupBinsSyntaxWithoutGroupSets(testCase)
         % The documented five-argument syntax: groupbins given, groupsets
         % omitted.

         G = groupstats.groupsummary(testCase.Tbl, "Value", "mean", ...
            "Other", {[0 6 12]});

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "Value"));
         testCase.verifyFalse(any(startsWith(returned, "disc_")));
      end

      function testOneGroupBinSchemeAppliesToEveryGroupVariable(testCase)
         % A single scheme applies to every group variable, which is what the
         % built-in groupsummary does.

         G = groupstats.groupsummary(testCase.Tbl, ["Value", "Other"], ...
            "mean", "Value", {2});

         returned = height(G);
         expected = height(groupsummary(testCase.Tbl, ...
            {'Value', 'Other'}, {2, 2}, "mean", "Value"));
         testCase.verifyEqual(returned, expected);
      end

      function testNoneGroupSetsSentinelErrors(testCase)
         % string.empty() is the one no-groupsets sentinel, so a scalar
         % "none" groupsets is rejected with a rewrite hint. groupbins keeps
         % "none" because there it is a real binning scheme.

         % Catch the exception directly so the message guidance is checked
         % too, not only the identifier.
         exception = MException.empty();
         try
            groupstats.groupsummary(testCase.Tbl, "Grp", "mean", ...
               "Value", "none", GroupSets = "none");
         catch exception
         end
         testCase.assertNotEmpty(exception);
         returned = exception.identifier;
         expected = 'groupstats:validategroupsets:noneIsNotASentinel';
         testCase.verifyEqual(returned, expected);
         testCase.verifySubstring(exception.message, "string.empty()");
      end

      function testEmptyGroupSetsMeansNoGroupSets(testCase)
         % An explicit string.empty() GroupSets must mean the same as
         % omitting the option.

         returned = groupstats.groupsummary(testCase.Tbl, "Grp", "mean", ...
            "Value", "none", GroupSets = string.empty());
         expected = groupstats.groupsummary(testCase.Tbl, "Grp", "mean", ...
            "Value");

         testCase.verifyEqual(returned, expected);
      end

      function testCallerVariableNamedDiscSurvives(testCase)
         % Only a name groupsummary built from a group variable loses its
         % disc_ prefix. A variable the caller named disc_something keeps it.

         tbl = testCase.Tbl;
         tbl.disc_Value = tbl.Value;

         G = groupstats.groupsummary(tbl, "Grp", "mean", "disc_Value");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "mean_disc_Value"));
      end

      function testBareBinSchemeIsAccepted(testCase)
         % A bare binning scheme, such as bin edges, is one scheme. The
         % built-in accepts that shape and so must this.

         G = groupstats.groupsummary(testCase.Tbl, "Value", "mean", ...
            "Other", [0 6 12]);

         returned = height(G);
         expected = 2;
         testCase.verifyEqual(returned, expected);
      end

      function testUnknownGroupBinsTextErrors(testCase)
         % Text other than "none" names no binning scheme.

         testCase.verifyError( ...
            @() groupstats.groupsummary(testCase.Tbl, "Grp", "mean", ...
            "Value", "quarterly"), ...
            'groupstats:groupsummary:badGroupBins');
      end

      function testNoDataVariablesErrors(testCase)
         % Omitting datavar when every numeric variable is a group variable
         % leaves nothing to summarize.

         tbl = table((1:4)', 'VariableNames', {'OnlyVar'});

         testCase.verifyError( ...
            @() groupstats.groupsummary(tbl, "OnlyVar"), ...
            'groupstats:groupsummary:noDataVariables');
      end

      function testAmbiguousGeneratedNamesAreLeftAlone(testCase)
         % A caller variable named like a generated column makes the count of
         % fun<N>_ columns disagree with the count of anonymous methods.
         % Renaming then would misalign them, so no column is renamed.

         tbl = testCase.Tbl;
         tbl.Properties.VariableNames{1} = 'fun1_x';

         G = groupstats.groupsummary(tbl, "fun1_x", {@(x) max(x)}, "Value");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "fun1_x"));
         testCase.verifyTrue(any(returned == "fun1_Value"));
      end

      function testSeveralGroupSetsEachGetAPercentColumn(testCase)
         % GroupSets takes a vector, and both names here are outside
         % groupvars, so the summary groups by all three variables and
         % every named set variable gets its own within-member percent.

         G = groupstats.groupsummary(testCase.Tbl, "Sub", "mean", ...
            "Value", GroupSets = ["Grp", "Set"]);

         % The fixture: Grp a is rows 1 to 4, b 5 to 8, c 9 to 12; Sub
         % alternates x, y; Set p is rows 1 to 6 and q 7 to 12. The eight
         % (Grp, Set, Sub) groups hold 2, 2, 1, 1, 1, 1, 2, 2 rows in that
         % sorted order. Within Grp, a and c split 50/50 and b 25 each.
         % Within Set, each set is 2, 2, 1, 1 of 6 rows.
         G = sortrows(G, ["Grp", "Set", "Sub"]);

         returned = G.GroupCount;
         expected = [2; 2; 1; 1; 1; 1; 2; 2];
         testCase.verifyEqual(returned, expected);

         returned = G.Percent_Grp;
         expected = [50; 50; 25; 25; 25; 25; 50; 50];
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);

         returned = G.Percent_Set;
         expected = 100 * [2; 2; 1; 1; 1; 1; 2; 2] / 6;
         testCase.verifyEqual(returned, expected, 'AbsTol', 1e-10);

         % Rows 1 and 3 are (a, p, x), so that group's mean is 2.
         returned = G.mean_Value(1);
         expected = 2;
         testCase.verifyEqual(returned, expected);
      end

      function testOptionLikeDataVariableNamePassesAsACellstr(testCase)
         % MATLAB reads an optional positional text value that matches an
         % option name, and is followed by another positional, as that
         % option. A cellstr is never read as a name, so it is the
         % documented way to name such a data variable positionally.

         tbl = testCase.Tbl;
         tbl.GroupSets = tbl.Value;

         G = groupstats.groupsummary(tbl, "Grp", "mean", {'GroupSets'}, ...
            "none");

         returned = any(string(G.Properties.VariableNames) == ...
            "mean_GroupSets");
         expected = true;
         testCase.verifyEqual(returned, expected);
      end

      function testAStringArrayOfMethodsIsAList(testCase)
         % A string array names one method per element, the same list a
         % cellstr gives, so both produce the same columns.

         returned = groupstats.groupsummary(testCase.Tbl, "Grp", ...
            ["mean", "max"], "Value");
         expected = groupstats.groupsummary(testCase.Tbl, "Grp", ...
            {'mean', 'max'}, "Value");
         testCase.verifyEqual(returned, expected);
      end

      function testTooManyGroupBinsErrors(testCase)
         % One binning scheme per group variable, one in total, or "none".
         % Anything else would misalign the schemes with the variables.

         testCase.verifyError( ...
            @() groupstats.groupsummary(testCase.Tbl, ["Grp", "Sub"], ...
            "mean", "Value", {"none", "none", "none"}), ...
            'groupstats:groupsummary:badGroupBins');
      end

      function testNonTableInputErrors(testCase)
         % The first argument must be a table or timetable.

         testCase.verifyError( ...
            @() groupstats.groupsummary(magic(4), "Grp"), ...
            'MATLAB:validation:UnableToConvert');
      end

      function testBinsThatDoNotSpanTheDataAreReported(testCase)
         % Rows outside the edges would form an <undefined> group and the
         % percent join would fail on a missing key with a message that
         % names no cause. The error names the scheme and the row count.

         testCase.verifyError(@() groupstats.groupsummary(testCase.Tbl, ...
            "Value", "mean", "Other", {[0 6]}), ...
            'groupstats:groupsummary:binsDoNotSpanData');

         try
            groupstats.groupsummary(testCase.Tbl, "Value", "mean", ...
               "Other", {[0 6]});
         catch e
            returned = [contains(e.message, "[0 6]"); ...
               contains(e.message, "Value"); contains(e.message, "6 rows")];
            expected = [true; true; true];
            testCase.verifyEqual(returned, expected);
         end
      end

      function testIncludedEdgePicksTheBinOfAValueOnAnEdge(testCase)
         % Value runs 1 to 12. With edges [0 6 12], "left" puts 6 in the
         % second bin (5 and 7 rows) and "right" puts it in the first (6
         % and 6).

         G = groupstats.groupsummary(testCase.Tbl, "Value", "mean", ...
            "Other", {[0 6 12]});
         returned = G.GroupCount(:);
         expected = [5; 7];
         testCase.verifyEqual(returned, expected);

         G = groupstats.groupsummary(testCase.Tbl, "Value", "mean", ...
            "Other", {[0 6 12]}, IncludedEdge = "right");
         returned = G.GroupCount(:);
         expected = [6; 6];
         testCase.verifyEqual(returned, expected);
      end

      function testIncludedEdgeRejectsAnUnknownValue(testCase)
         % The option takes the two values the builtin takes.

         testCase.verifyError(@() groupstats.groupsummary(testCase.Tbl, ...
            "Value", "mean", "Other", {[0 6 12]}, IncludedEdge = "middle"), ...
            'MATLAB:validators:mustBeMember');
      end


      function testNonNumericBinsThatDoNotSpanTheDataAreReported(testCase)
         % A duration edge scheme takes the text branch of the message.
         % Twelve one-hour values against edges that stop at six hours
         % leave six rows outside.

         tbl = testCase.Tbl;
         tbl.Elapsed = hours(tbl.Value);
         edges = hours([0 6]);

         try
            groupstats.groupsummary(tbl, "Elapsed", "mean", "Other", {edges});
            testCase.verifyFail("no error was raised");
         catch e
            returned = {e.identifier; contains(e.message, "Elapsed"); ...
               contains(e.message, "6 rows"); ...
               contains(e.message, string(edges(2)))};
            expected = {'groupstats:groupsummary:binsDoNotSpanData'; ...
               true; true; true};
            testCase.verifyEqual(returned, expected);
         end
      end

   end
end
