classdef test_namelists < matlab.unittest.TestCase
   %TEST_NAMELISTS Test the option lists and the validator that reads them.
   %
   % Every list of valid option values is written down once, in
   % +groupstats/+namelists. Two consumers read it: an arguments block,
   % through groupstats.namelists.mustBeMemberOf, and functionSignatures.json,
   % through a choices entry. The last test compares those two consumers,
   % because a value accepted by one and offered by the other is the failure
   % this package exists to prevent.
   %
   % See also: groupstats.namelists.mustBeMemberOf

   properties (TestParameter)
      % Every namelist in the package, so a new one is covered on arrival.
      listname = listNamelists()
   end

   methods (Test, ParameterCombination = "sequential")

      function testEachListIsANonemptyStringColumn(testCase, listname)
         % Each list feeds mustBeMember and a choices entry, and both need a
         % string array.

         returned = feval("groupstats.namelists." + listname);

         testCase.verifyClass(returned, "string");
         testCase.verifyNotEmpty(returned);
         testCase.verifySize(returned, [numel(returned), 1]);
      end

      function testEachListHasNoRepeatedValue(testCase, listname)
         % A repeat means two sources were merged by hand.

         returned = feval("groupstats.namelists." + listname);

         testCase.verifyEqual(numel(unique(returned)), numel(returned));
      end
   end

   methods (Test)

      function testPopulationOptionHoldsTheGroupbayesValues(testCase)
         % groupbayes documents these three values, so name them here. This
         % is the one list whose members this test file states outright.

         returned = groupstats.namelists.populationoption();

         expected = ["union"; "table"; "withingroup"];
         testCase.verifyEqual(returned, expected);
      end

      function testSortorderExtendsSortdirection(testCase)
         % sortorder adds the no-sort value to the sort directions rather
         % than repeating them.

         returned = groupstats.namelists.sortorder();

         expected = [groupstats.namelists.sortdirection(); "none"];
         testCase.verifyEqual(returned, expected);
      end

      function testMustBeMemberOfAcceptsAMember(testCase)
         testCase.verifyWarningFree(@() ...
            groupstats.namelists.mustBeMemberOf("union", "populationoption"));
      end

      function testMustBeMemberOfRejectsANonMember(testCase)
         testCase.verifyError(@() groupstats.namelists.mustBeMemberOf( ...
            "nonsense", "populationoption"), ...
            'MATLAB:validators:mustBeMember');
      end

      function testMustBeMemberOfRejectsAnUnknownList(testCase)
         % A misspelled list name must say so, rather than accept every
         % value because the list came back empty.

         testCase.verifyError(@() groupstats.namelists.mustBeMemberOf( ...
            "union", "nosuchnamelist"), ...
            'groupstats:namelists:unknownList');
      end

      function testSignatureChoicesMatchTheArgumentValidators(testCase)
         % The drift test. For every option whose functionSignatures entry
         % offers a namelist, the function's arguments block must validate
         % that option against the same namelist.

         signatures = readSignatures();

         functions = string(fieldnames(signatures));
         functions = functions(functions ~= "x_schemaVersion");

         checked = 0;
         for f = 1:numel(functions)
            fname = functions(f);
            inputs = signatures.(fname).inputs;

            % A function name reaches the JSON with its dots replaced, and
            % jsondecode returns either a struct array or a cell array.
            validators = readValidators(strrep(fname, "_", "."));

            for k = 1:numel(inputs)
               input = getInput(inputs, k);
               list = signatureNamelist(input);
               if list == ""
                  continue
               end

               optname = string(input.name);
               testCase.assertTrue(isfield(validators, optname), ...
                  sprintf(['%s offers %s for %s, and the arguments block ' ...
                  'does not validate that option.'], fname, list, optname));

               testCase.verifyEqual(validators.(optname), list, ...
                  sprintf('%s option %s.', fname, optname));
               checked = checked + 1;
            end
         end

         % A parsing mistake would pass every case above by checking none.
         testCase.verifyGreaterThan(checked, 0);
      end

      function testEveryOfferedNameValueIsAccepted(testCase)
         % Tab completion offering an option the function rejects is worse
         % than offering nothing. barchartcats and boxchartcats both offered
         % CGroupOrder for months after it was removed from their arguments
         % blocks, and nothing caught it.

         signatures = readSignatures();

         functions = string(fieldnames(signatures));
         functions = functions(functions ~= "x_schemaVersion");

         checked = 0;
         for f = 1:numel(functions)
            fname = strrep(functions(f), "_", ".");
            declared = readNameValueOptions(fname);

            % A function with no arguments block declares nothing to compare.
            if isempty(declared)
               continue
            end

            inputs = signatures.(functions(f)).inputs;
            for k = 1:numel(inputs)
               input = getInput(inputs, k);
               if ~isfield(input, 'kind') || input.kind ~= "namevalue"
                  continue
               end

               optname = string(input.name);
               testCase.verifyTrue(ismember(optname, declared), sprintf( ...
                  ['%s offers name-value %s, and its arguments block does ' ...
                  'not declare it.'], fname, optname));
               checked = checked + 1;
            end
         end

         % A parsing mistake would pass every case above by checking none.
         testCase.verifyGreaterThan(checked, 0);
      end

      function testEveryValidatedOptionIsOfferedInTheSignatures(testCase)
         % The other direction. An option validated against a namelist, in a
         % function the signature file describes, must offer that same list.
         % Without this, an option accepts three values and completes none.

         signatures = readSignatures();

         functions = string(fieldnames(signatures));
         functions = functions(functions ~= "x_schemaVersion");

         checked = 0;
         for f = 1:numel(functions)
            fname = functions(f);
            validators = readValidators(strrep(fname, "_", "."));
            offered = signatureNamelists(signatures.(fname).inputs);

            options = string(fieldnames(validators));
            for k = 1:numel(options)
               optname = options(k);
               checked = checked + 1;

               testCase.assertTrue(isfield(offered, optname), sprintf( ...
                  ['%s validates %s against %s, and functionSignatures ' ...
                  'offers no choices for that option.'], ...
                  fname, optname, validators.(optname)));

               testCase.verifyEqual(offered.(optname), ...
                  validators.(optname), ...
                  sprintf('%s option %s.', fname, optname));
            end
         end

         % A parsing mistake would pass every case above by checking none.
         testCase.verifyGreaterThan(checked, 0);
      end
   end
end

function offered = signatureNamelists(inputs)
   %SIGNATURENAMELISTS Return the namelist each input offers, by input name.

   offered = struct();
   for k = 1:numel(inputs)
      input = getInput(inputs, k);
      list = signatureNamelist(input);
      if list ~= ""
         offered.(string(input.name)) = list;
      end
   end
end

function names = listNamelists()
   %LISTNAMELISTS Return every namelist function name, as a cell array.
   %
   % Two files in the package are not lists: mustBeMemberOf takes arguments
   % and returns nothing, and Contents.m is the generated file listing.

   folder = fullfile(groupstats.internal.buildpath(), '+groupstats', ...
      '+namelists');
   found = dir(fullfile(folder, '*.m'));

   names = string({found.name});
   names = erase(names, ".m");
   names = names(~ismember(names, ["mustBeMemberOf", "Contents"]));

   names = cellstr(names);
end

function signatures = readSignatures()
   %READSIGNATURES Read functionSignatures.json into a struct.
   %
   % The file allows // comments, which jsondecode rejects.

   jsonfile = fullfile(groupstats.internal.buildpath(), ...
      'functionSignatures.json');

   text = string(fileread(jsonfile));
   text = regexprep(text, '^\s*//.*$', '', 'lineanchors');

   signatures = jsondecode(text);
end

function input = getInput(inputs, k)
   %GETINPUT Return one input entry from a struct array or a cell array.
   %
   % jsondecode returns a cell array when the entries have different fields,
   % and a struct array when they match.

   if iscell(inputs)
      input = inputs{k};
   else
      input = inputs(k);
   end
end

function list = signatureNamelist(input)
   %SIGNATURENAMELIST Return the namelist an input's choices entry names.
   %
   % Returns an empty string when the entry offers no namelist. The type
   % field holds a string, a cell array of strings, or nested cell arrays.

   list = "";
   if ~isfield(input, 'type')
      return
   end

   % The type field nests to no fixed depth, so read it as text.
   text = string(jsonencode(input.type));

   found = regexp(text, 'groupstats\\?\.namelists\\?\.(\w+)\(\)', ...
      'tokens', 'once');
   if ~isempty(found)
      list = string(found{1});
   end
end

function options = readNameValueOptions(functionname)
   %READNAMEVALUEOPTIONS Return the name-value options a function declares.
   %
   % Reads the arguments block for entries of the form opts.Name or
   % Opts.Name, which is how this toolbox declares a name-value option.
   % Returns an empty string array when the file declares none.

   located = which(functionname);
   if isempty(located)
      options = string.empty();
      return
   end

   lines = readlines(located);

   % Read the arguments block alone, so a name-value pair passed in a call
   % further down does not read as a declaration.
   first = find(strcmp(strtrim(lines), "arguments"), 1);
   if isempty(first)
      options = string.empty();
      return
   end
   last = first + find(strcmp(strtrim(lines(first + 1:end)), "end"), 1) - 1;

   found = regexp(lines(first:last), '^\s*[Oo]pts\.(\w+)', 'tokens', 'once');
   found = found(~cellfun(@isempty, found));
   options = string(cellfun(@(t) t{1}, found, 'UniformOutput', false));
end

function validators = readValidators(functionname)
   %READVALIDATORS Return the namelist each option is validated against.
   %
   % Returns a struct whose fields are option names and whose values are
   % namelist names, read from the mustBeMemberOf calls in the arguments
   % block of the named function.

   code = string(fileread(which(functionname)));

   % Join continuation lines so one call reads as one line.
   code = regexprep(code, '\.\.\.\s*\r?\n\s*', '');

   pattern = 'mustBeMemberOf\(\s*\w+\.(\w+)\s*,\s*"(\w+)"\s*\)';
   found = regexp(code, pattern, 'tokens');

   validators = struct();
   for k = 1:numel(found)
      validators.(found{k}{1}) = string(found{k}{2});
   end
end
