function P = groupbayes(tbl, groupA, groupB, groupvar, opts)
   %GROUPBAYES Compute group-wise conditional (Bayesian) probabilities.
   %
   % Syntax:
   % P = groupbayes(tbl, groupA, groupB)
   % P = groupbayes(tbl, groupA, groupB, groupvar)
   % P = groupbayes(_, Population=NAME)
   %
   % Description:
   % This function calculates group-wise Bayesian probabilities based on the
   % information provided in a table. This is useful in cases where you are
   % working with multiple categories and want to understand the conditional
   % probabilities between them.
   %
   % Input Arguments:
   % tbl - A MATLAB table containing the information about the events.
   %
   % groupA - An array containing the group labels for which you want to
   % calculate the Bayesian probabilities in relation to groupB. Can be a cell,
   % string, categorical, or char array.
   %
   % groupB - An array (like groupA) containing the group labels for which you
   % want to calculate the Bayesian probabilities in relation to groupA.
   %
   % groupvar - (Optional) The column (i.e., variable) name in table tbl which
   % contains the group labels. Can be a string, cellstr, or char. If provided,
   % rows of the table define the event "A" and columns define "and B". If not
   % provided, columns belonging to groupA and groupB define the events "A" and
   % "B".
   %
   % Population - (Optional) The denominator N for the marginal and joint
   % probabilities. One of:
   %
   %  "union"       Default. N counts the events that belong to groupA or
   %                groupB. With groupvar, that is the rows whose label is in
   %                either set. Without it, the rows where any of the union's
   %                columns is true. Each event counts once, so a label named
   %                in both sets, or a pairwise call where groupA equals
   %                groupB, does not count twice.
   %  "table"       N is height(tbl). Use this when the table is already
   %                restricted to the population of interest and some rows
   %                belong to neither group.
   %  "withingroup" P_A is renormalized over groupA alone and P_B over groupB
   %                alone, so each marginal set sums to one within its own
   %                group. The joint keeps the "union" denominator. This is
   %                the variant a published table needs when one label, such
   %                as a basin outlet, must stay out of the other group's
   %                marginal. Read the Limitations section before combining
   %                P_A_AND_B with P_A or P_B under this value.
   %
   % Output Arguments:
   % P - A MATLAB table that contains the calculated probabilities, including
   %     marginal probabilities, joint probabilities, and conditional
   %     probabilities.
   %
   % P_B_GIVEN_A and P_A_GIVEN_B do not change with Population. They are ratios
   % of counts, N_A_AND_B ./ N_A and N_A_AND_B ./ N_B, so N cancels. Population
   % changes only P_A, P_B, and P_A_AND_B. A conditional whose denominator
   % count is zero is NaN, because it has no value.
   %
   % Limitations
   % Under Population="withingroup", P_A_AND_B does not agree with P_A and
   % P_B. P_A and P_B carry different denominators, sum(N_A) and sum(N_B), so
   % no single joint is consistent with both. Read the conditionals from the
   % P_B_GIVEN_A and P_A_GIVEN_B columns. Deriving them as
   % P_A_AND_B ./ P_B gives a different, wrong figure. The other two
   % Population values keep one denominator throughout, so this does not
   % apply to them.
   %
   % Assumptions and non-goals
   % This function assumes TBL is a complete, unfiltered event table. Every
   % event that belongs to groupA or groupB must have a row. Filtering the
   % table before the call breaks the conditionals as well as the marginals.
   % The counts then describe the rows that survived the filter, not the
   % population the probabilities are about. Filtering before the call is a
   % non-goal, not a supported mode.
   %
   % Errors and warnings
   % groupstats:groupbayes:marginalsDoNotPartition - a warning. The marginals
   % do not sum to one, so the two label sets overlap or leave events out.
   % groupstats:groupbayes:jointProbabilityOutOfRange - a joint probability
   % fell outside 0 to 1. A probability with no denominator is NaN, and this
   % check passes over those.
   %
   % See also: groupstats.groupmap, groupstats.grouppercent,
   % groupstats.namelists.populationoption

   arguments
      tbl tabular
      groupA
      groupB
      groupvar string = string.empty()
      opts.Population (1, 1) string ...
         {groupstats.namelists.mustBeMemberOf(opts.Population, ...
         "populationoption")} = "union"
   end

   % Events are defined by variable (column) names when no group variable
   % names the column that holds the row labels.
   bycolumn = isempty(groupvar);

   % Cast any table variable of type char or cellstr to string
   tbl = convertvars(tbl, @ischar, "string");
   tbl = convertvars(tbl, @iscellstr, "string");

   % Ensure groupA and groupB are columns of strings
   try
      groupA = reshape(string(groupA), [], 1);
      groupB = reshape(string(groupB), [], 1);
   catch e
      error("Error in converting group labels to strings: %s", e.message);
   end

   % If one of either groupA or groupB has one member and it is present in the
   % other, remove it.
   if isscalar(groupA) && ismember(groupA, groupB)
      groupB = groupB(groupB ~= groupA);
   elseif isscalar(groupB) && ismember(groupB, groupA)
      groupA = groupA(groupA ~= groupB);
   end

   % Counts of each groupA and groupB, and groupA and groupB happening together
   if bycolumn
      % Events are defined by variable (column) names
      N_A = cellfun(@(A) sum(tbl{:, A}), groupA);
      N_B = cellfun(@(B) sum(tbl{:, B}), groupB);
      N_A_AND_B = cell2mat(arrayfun(@(A) ...
         cellfun(@(B) sum(tbl{:, A} & tbl{:, B}), groupB), groupA, 'Un', 0));

      % Count each event once. An event that occurred for more than one
      % member belongs to the population once, not once per member.
      N_union = sum(any(tbl{:, unique([groupA; groupB])}, 2));

   else
      % Events are defined by rows of column tbl.(groupvar)
      if ~iscategorical(tbl.(groupvar))
         try
            % Cast tbl.(groupvar) to categorical
            tbl.(groupvar) = categorical(tbl.(groupvar));
         catch e
            warning("tbl.(groupvar) must be convertible to categorical")
            rethrow(e)
         end
      end

      N_A = cellfun(@(A) sum(tbl.(groupvar) == A), groupA); % N(A,C), or N(A)
      N_B = cellfun(@(B) sum(tbl.(groupvar) == B), groupB); % N(B), or N(B,D)

      % Subset groupB rows, count groupA columns
      N_B_AND_A = cell2mat(arrayfun(@(A) ...
         arrayfun(@(B) sum(tbl.(groupvar) == B & tbl{:, A}), groupB), ...
         groupA, 'Uniform', 0)); % N(A and B)

      % Subset groupA rows, count groupB columns
      N_A_AND_B = cell2mat(arrayfun(@(A) ...
         arrayfun(@(B) sum(tbl.(groupvar) == A & tbl{:, B}), groupB), ...
         groupA, 'Uniform', 0)); % N(A,C and B) or N(A and B,D)

      if ~isequal(N_A_AND_B, N_B_AND_A)
         % warning('N(A and B) ~= N(B and A)')
      end

      % Use N_A_AND_B, as described in the documentation (rows define the event
      % "A", columns define the event "and B")
      % Count each row once. A row whose label appears in both sets belongs
      % to the population once. A pairwise call, where groupA equals groupB,
      % puts every label in both sets.
      N_union = sum(ismember(string(tbl.(groupvar)), [groupA; groupB]));
   end
   % Quantities computed below here depend only on N_A, N_B, and N_A_AND_B.

   % Total counts
   switch opts.Population
      case "table"
         N = height(tbl);
      otherwise
         N = N_union; % N(A or B)
   end

   % Compute marginal probabilities of A and B
   if opts.Population == "withingroup"
      % Renormalize each marginal within its own group, so P_A sums to one
      % over groupA and P_B sums to one over groupB.
      P_A = N_A ./ sum(N_A);
      P_B = N_B ./ sum(N_B);
   else
      P_A = N_A ./ N; % N(A) / N(A or B)
      P_B = N_B ./ N; % N(B) / N(A or B)
   end

   % Compute joint probability of A and B
   P_A_AND_B = N_A_AND_B ./ N; % P(A ∩ B) = P(B ∩ A) % N(A and B) / N(A or B)

   % The marginals partition the population only when the two label sets
   % together account for every event and share no member. A pairwise call
   % with groupA equal to groupB breaks both conditions on purpose, so this
   % reports rather than stops.
   if opts.Population == "union" && abs(sum(P_B) + sum(P_A) - 1) > 1e-3
      warning('groupstats:groupbayes:marginalsDoNotPartition', ...
         ['The marginals sum to %.4f, not 1. groupA and groupB do not ' ...
         'partition the population: they overlap, or some events belong ' ...
         'to neither.'], sum(P_A) + sum(P_B))
   end
   % A population count of zero makes every probability NaN, the documented
   % value for one with no denominator, so check only the defined ones. A
   % joint probability of exactly 1 is valid: every event in the population
   % belongs to both groups.
   defined = ~isnan(P_A_AND_B);
   assert(all(P_A_AND_B(defined) >= 0 & P_A_AND_B(defined) <= 1), ...
      'groupstats:groupbayes:jointProbabilityOutOfRange', ...
      'A joint probability fell outside 0 to 1.')

   % Repeat counts and marginal probabilities for each pair
   N_B = repmat(N_B, numel(groupA), 1);
   P_B = repmat(P_B, numel(groupA), 1);
   N_A = repelem(N_A, numel(groupB), 1);
   P_A = repelem(P_A, numel(groupB), 1);

   % Compute conditional probabilities from the counts. Written as count
   % ratios rather than probability ratios, these do not change with
   % Population, because N cancels.
   P_B_GIVEN_A = N_A_AND_B ./ N_A; % P(B|A)
   P_A_GIVEN_B = N_A_AND_B ./ N_B; % P(A|B) = P(B|A)P(A)/P(B)

   % P(B|A) has no value when no event belongs to A. Report NaN.
   P_B_GIVEN_A(N_A == 0) = NaN;
   P_A_GIVEN_B(N_B == 0) = NaN;

   % Compute the relative joint frequencies - note: not equal to P(B)
   F_A = N_A / sum(N_A_AND_B);
   F_B = N_B ./ sum(N_A_AND_B);
   F_A_AND_B = N_A_AND_B ./ sum(N_A_AND_B);

   % Organize into a table
   P = table(N_A, N_B, N_A_AND_B, P_A, P_B, P_A_AND_B, F_A, F_B, F_A_AND_B, ...
      P_B_GIVEN_A, P_A_GIVEN_B, 'VariableNames', ...
      ["N_A", "N_B", "N_A_AND_B", "P_A", "P_B", "P_A_AND_B", "F_A", "F_B", ...
      "F_A_AND_B", "P_B_GIVEN_A", "P_A_GIVEN_B"]);

   % Adding group names to the table. This repeats each label the same way
   % the counts above were repeated, and returns an empty column when a
   % group set is empty. meshgrid cannot do that, because it calls zeros
   % with the class of its input, and zeros has no string method.
   P.GroupA = categorical(repelem(groupA(:), numel(groupB), 1));
   P.GroupB = categorical(repmat(groupB(:), numel(groupA), 1));

   % Organize the columns
   P = movevars(P,"GroupA","Before","N_A");
   P = movevars(P,"GroupB","After","GroupA");
end

% The scratch work that established why this function subsets rows by
% groupA and counts groupB columns is in
% toolbox/examples/demo_groupbayes_counts.m, with the count comparison,
% the Jaccard and phi attempts, and the explicit-loop version.

% An open question from the column-syntax branch, kept verbatim:

      % Need to consider if N should be:
      % N = N_A + N_B - N_A_AND_B;
