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
            {'mean'}, "Value", "none", "Grp");

         returned = string(G.Properties.VariableNames);
         testCase.verifyEqual(sum(returned == "Grp"), 1);
      end

      function testGroupsetsOutsideGroupvarsBecomesAGroupVariable(testCase)
         % A groupsets variable the caller did not list among groupvars must
         % still reach the summary, so each set gets its own rows. Two group
         % variables, because one hid the bin-count mismatch behind the
         % "none" sentinel.

         G = groupstats.groupsummary(testCase.Tbl, ["Grp", "Sub"], ...
            {'mean'}, "Value", "none", "Set");

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

         G = groupstats.groupsummary(tbl, "Grp", "mean", [], "none", ...
            "SetNum");

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
            {'mean'}, "Value", {[0 2 4]}, "Set");

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
            "none", "Grp");

         returned = string(G.Properties.VariableNames);
         testCase.verifyTrue(any(returned == "Percent_Grp"));
      end

      function testRowSelectKeepsOnlyTheNamedMembers(testCase)
         % RowSelectVar and RowSelectMembers drop rows before summarizing.

         G = groupstats.groupsummary(testCase.Tbl, "Grp", "mean", "Value", ...
            "none", string.empty(), ...
            RowSelectVar = "Sub", RowSelectMembers = "x");

         returned = sum(G.GroupCount);
         expected = sum(testCase.Tbl.Sub == "x");
         testCase.verifyEqual(returned, expected);
      end

      function testRowSelectFindsTheVariableWhenNotNamed(testCase)
         % Naming members without the variable searches the group variables.

         G = groupstats.groupsummary(testCase.Tbl, ["Grp", "Sub"], "mean", ...
            "Value", "none", string.empty(), RowSelectMembers = "x");

         returned = sum(G.GroupCount);
         expected = sum(testCase.Tbl.Sub == "x");
         testCase.verifyEqual(returned, expected);
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

      function testNoneGroupSetsSentinelIsAccepted(testCase)
         % "none" is the sentinel this family uses for "no groupsets". It must
         % mean the same as omitting the argument, not name a variable.

         withnone = groupstats.groupsummary(testCase.Tbl, "Grp", "mean", ...
            "Value", "none", "none");
         withempty = groupstats.groupsummary(testCase.Tbl, "Grp", "mean", ...
            "Value");

         testCase.verifyEqual(withnone, withempty);
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
   end
end
