classdef test_namelists < matlab.unittest.TestCase
   %TEST_NAMELISTS Test the option lists and the validator that reads them.
   %
   % Every list of valid option values is written down once, in
   % +groupstats/+namelists. Two consumers read it: an arguments block,
   % through groupstats.namelists.mustBeMemberOf, and functionSignatures.json,
   % through a choices entry. The drift tests compare those two consumers,
   % because a value accepted by one and offered by the other is the failure
   % this package exists to prevent. The last test also compares each
   % signature's input kinds, defaults, and properties class with the
   % arguments block.
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
         % groupbayes documents these three values, so name them here.
         % sortorder's test below states its members outright too, because
         % that list is the one SortBy namelist for every chart.

         returned = groupstats.namelists.populationoption();

         expected = ["union"; "table"; "withingroup"];
         testCase.verifyEqual(returned, expected);
      end

      function testSortorderHoldsTheDirectionsAndNone(testCase)
         % sortorder is the one SortBy namelist for every chart: the two
         % sort directions plus the no-sort value.

         returned = groupstats.namelists.sortorder();

         expected = ["ascend"; "descend"; "none"];
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
            declared = readArguments(fname);
            declared = declared.Name(declared.Kind == "namevalue");

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

      function testSignaturesMatchTheArgumentsBlocks(testCase)
         % Tab completion must describe the inputs the function declares.
         % A positional input with a default is optional, a listed default
         % is the declared default, and the properties class is the class
         % the function passes through. For example, a ShadeGroups default
         % of true is wrong for barchartcats, whose code resolves an empty
         % default. Scatter properties are wrong for scatter, which passes
         % Line properties.

         signatures = readSignatures();

         functions = string(fieldnames(signatures));
         functions = functions(functions ~= "x_schemaVersion");

         checked = 0;
         for f = 1:numel(functions)
            fname = strrep(functions(f), "_", ".");
            declared = readArguments(fname);

            % A function with no arguments block declares nothing to compare.
            if isempty(declared)
               continue
            end

            inputs = signatures.(functions(f)).inputs;
            listed = strings(numel(inputs), 1);
            listedkinds = strings(numel(inputs), 1);
            for k = 1:numel(inputs)
               input = getInput(inputs, k);
               message = sprintf('%s input %s.', fname, input.name);

               % Keep each listed name and kind for the reverse check below.
               listed(k) = input.name;
               listedkinds(k) = input.kind;

               % A function declares a repeating input in its own arguments
               % block, which readArguments does not read.
               if isfield(input, 'repeating') && input.repeating
                  continue
               end
               checked = checked + 1;

               % The properties entry names the class the function passes
               % through, and it has no default or positional kind.
               if input.kind == "properties"
                  returned = string(input.type);
                  expected = declared.Class(declared.Kind == "properties");
                  testCase.verifyEqual(returned, expected, message);
                  continue
               end

               % Every other listed input must have one declaration.
               row = declared(declared.Name == input.name, :);
               testCase.assertEqual(height(row), 1, sprintf( ...
                  '%s lists %s, and its arguments block does not declare it.', ...
                  fname, input.name));

               % The signature file lists a name-value option as namevalue
               % and a positional input as another kind.
               returned = input.kind == "namevalue";
               expected = row.Kind == "namevalue";
               testCase.verifyEqual(returned, expected, message);

               % Only a positional input without a default is required.
               if row.Kind == "positional"
                  returned = input.kind == "required";
                  expected = ismissing(row.Default);
                  testCase.verifyEqual(returned, expected, message);
               end

               % A listed default must be the default the code declares.
               % A computed default, such as an empty sentinel the code
               % resolves later, must not be listed as a fixed value.
               if isfield(input, 'default')
                  returned = normalizeDefault(input.default);
                  expected = normalizeDefault(row.Default);
                  testCase.verifyEqual(returned, expected, message);
               end
            end

            % The other direction: tab completion never offers an input
            % the signature file leaves out. The properties row has no
            % listed name, so match it by its kind.
            for k = 1:height(declared)
               if declared.Kind(k) == "properties"
                  returned = any(listedkinds == "properties");
               else
                  returned = any(listed == declared.Name(k));
               end
               testCase.verifyTrue(returned, sprintf(['%s declares %s, ' ...
                  'and functionSignatures.json does not list it.'], ...
                  fname, declared.Name(k)));
               checked = checked + 1;
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

function declared = readArguments(functionname)
   %READARGUMENTS Return each input the first arguments block declares.
   %
   % Returns a table with one row per declaration and these variables:
   %
   %   Name     The input name, or the option name of opts.Name.
   %   Kind     "positional", "namevalue" for opts.Name or Opts.Name, or
   %            "properties" for props.?Class.
   %   Default  The text after the default's =, or a missing string when
   %            the declaration has none.
   %   Class    The class of a properties row, or a missing string.
   %
   % A function with no arguments block returns a table with no rows.
   % readArguments does not read the repeating block of a varargin input.

   % Every return gives the same columns, so a caller can index an empty
   % result.
   declared = table(string.empty(0, 1), string.empty(0, 1), ...
      string.empty(0, 1), string.empty(0, 1), ...
      'VariableNames', {'Name', 'Kind', 'Default', 'Class'});

   % A function MATLAB cannot find declares nothing.
   located = which(functionname);
   if isempty(located)
      return
   end

   % Join continuation lines, so one declaration reads as one line.
   code = string(fileread(located));
   code = regexprep(code, '\.\.\.[^\n]*\r?\n\s*', ' ');
   lines = strtrim(splitlines(code));

   % Read the arguments block alone, so a name-value pair passed in a call
   % further down does not read as a declaration.
   first = find(lines == "arguments", 1);
   if isempty(first)
      return
   end
   last = first + find(lines(first + 1:end) == "end", 1) - 1;
   lines = lines(first + 1:last);

   % Blank lines and comment lines declare nothing.
   lines = lines(lines ~= "" & ~startsWith(lines, "%"));

   % Read each declaration into one row, then stack the rows once.
   rows = cell(numel(lines), 1);
   for k = 1:numel(lines)
      rows{k} = readDeclaration(lines(k));
   end
   declared = vertcat(declared, rows{:});
end

function row = readDeclaration(line)
   %READDECLARATION Return one arguments-block declaration as a table row.
   %
   % LINE is one declaration with its continuations joined. The default
   % is the text after the first lone = outside the validator braces. A
   % validator can hold an = of its own only inside those braces, so the
   % function strips them first.

   % A declaration is positional, with no default, unless its text says
   % otherwise.
   kind = "positional";
   default = string(missing);
   class = string(missing);

   % props.?Class passes graphics properties through and has no default.
   % opts.Name declares a name-value option, and any other name is
   % positional.
   found = regexp(line, '^(\w+)\.\?([\w.]+)', 'tokens', 'once');
   if ~isempty(found)
      name = found(1);
      kind = "properties";
      class = found(2);
   else
      [found, matched] = regexp(line, '^(?:[Oo]pts\.)?(\w+)', ...
         'tokens', 'match', 'once');
      name = found(1);
      if startsWith(line, ["opts.", "Opts."])
         kind = "namevalue";
      end

      % Braces can nest, so strip the innermost pair until none is left.
      rest = extractAfter(line, strlength(matched));
      while contains(rest, "{")
         rest = regexprep(rest, '\{[^{}]*\}', '');
      end

      % The first lone = starts the default. ==, ~=, <=, and >= compare.
      value = regexp(rest, '(?<![=~<>])=(?!=)\s*(.*)$', 'tokens', 'once');
      if ~isempty(value)
         default = strtrim(value(1));
      end
   end

   % One row with the columns readArguments stacks.
   row = table(name, kind, default, class, ...
      'VariableNames', {'Name', 'Kind', 'Default', 'Class'});
end

function text = normalizeDefault(text)
   %NORMALIZEDEFAULT Return default text in one form for comparison.
   %
   % The signature file quotes a text default as 'mean', and an arguments
   % block writes it as "mean". Drop a trailing semicolon and one pair of
   % enclosing quotes, and compare without case.

   text = regexprep(strtrim(string(text)), ';$', '');
   text = lower(regexprep(text, '^([''"])(.*)\1$', '$2'));
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
