function P = groupbayes(T, groupA, groupB, groupvar)
   %GROUPBAYES Compute group-wise conditional (Bayesian) probabilities.
   %
   % Syntax:
   % P = groupbayes(T, groupA, groupB)
   % P = groupbayes(T, groupA, groupB, groupvar)
   %
   % Description:
   % This function calculates group-wise Bayesian probabilities based on the
   % information provided in a table. This is useful in cases where you are
   % working with multiple categories and want to understand the conditional
   % probabilities between them.
   %
   % Input Arguments:
   % T - A MATLAB table containing the information about the events.
   %
   % groupA - An array containing the group labels for which you want to
   % calculate the Bayesian probabilities in relation to groupB. Can be a cell,
   % string, categorical, or char array.
   %
   % groupB - An array (like groupA) containing the group labels for which you
   % want to calculate the Bayesian probabilities in relation to groupA.
   %
   % groupvar - (Optional) The column (i.e., variable) name in table T which
   % contains the group labels. Can be a string, cellstr, or char. If provided,
   % rows of the table define the event "A" and columns define "and B". If not
   % provided, columns belonging to groupA and groupB define the events "A" and
   % "B".
   %
   % Output Arguments:
   % P - A MATLAB table that contains the calculated probabilities, including
   %     marginal probabilities, joint probabilities, and conditional
   %     probabilities.
   %
   % See also:

   narginchk(3, 4)
   
   % Set the persistent assert flag
   assertF off
   
   % Cast any table variable of type char or cellstr to string
   T = convertvars(T, @ischar, "string");
   T = convertvars(T, @iscellstr, "string");

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
   if nargin == 3
      % Events are defined by variable (column) names
      N_A = cellfun(@(A) sum(T{:, A}), groupA);
      N_B = cellfun(@(B) sum(T{:, B}), groupB);
      N_A_AND_B = cell2mat(arrayfun(@(A) ...
         cellfun(@(B) sum(T{:, A} & T{:, B}), groupB), groupA, 'Un', 0));

      assertF(@() all(N_A_AND_B <= N_A))
      assertF(@() all(N_A_AND_B <= N_B))
      
      % Need to consider if N should be:
      % N = N_A + N_B - N_A_AND_B;

   else
      % Events are defined by rows of column T.(groupvar)
      if ~iscategorical(T.(groupvar))
         try
            % Cast T.(groupvar) to categorical
            T.(groupvar) = categorical(T.(groupvar));
         catch e
            warning("T.(groupvar) must be convertible to categorical")
            rethrow(e)
         end
      end
      
      N_A = cellfun(@(A) sum(T.(groupvar) == A), groupA); % N(A,C), or N(A)
      N_B = cellfun(@(B) sum(T.(groupvar) == B), groupB); % N(B), or N(B,D)

      % Subset groupB rows, count groupA columns
      N_B_AND_A = cell2mat(arrayfun(@(A) ...
         arrayfun(@(B) sum(T.(groupvar) == B & T{:, A}), groupB), ...
         groupA, 'Uniform', 0)); % N(A and B)

      % Subset groupA rows, count groupB columns
      N_A_AND_B = cell2mat(arrayfun(@(A) ...
         arrayfun(@(B) sum(T.(groupvar) == A & T{:, B}), groupB), ...
         groupA, 'Uniform', 0)); % N(A,C and B) or N(A and B,D)

      if ~isequal(N_A_AND_B, N_B_AND_A)
         % warning('N(A and B) ~= N(B and A)')
      end

      % Use N_A_AND_B, as described in the documentation (rows define the event
      % "A", columns define the event "and B")
      assertF(@() all(N_A_AND_B <= N_A))
      assertF(@() all(N_A_AND_B <= N_B))
   end
   % Quantities computed below here depend only on N_A, N_B, and N_A_AND_B.

   % Total counts
   N = sum(N_A) + sum(N_B); % N(A,C) + N(B) = N(A,C or B)

   % Compute marginal probabilities of A and B
   P_A = N_A ./ N; % N(A,C) / N(A,C or B)
   P_B = N_B ./ N; % N(B) / N(A,C or B)

   % Compute joint probability of A and B
   P_A_AND_B = N_A_AND_B ./ N; % P(A ∩ B) = P(B ∩ A) % N(A,C and B) / N(A,C or B)

   assert(abs(sum(P_B) + sum(P_A) - 1) < 1e-3)
   assert(all(0 < P_A_AND_B ) & all(P_A_AND_B < 1))

   % Repeat counts and marginal probabilities for each pair
   N_B = repmat(N_B, numel(groupA), 1);
   P_B = repmat(P_B, numel(groupA), 1);
   N_A = repelem(N_A, numel(groupB), 1);
   P_A = repelem(P_A, numel(groupB), 1);

   epsilon = 1e-10; % A small number to avoid division by zero

   % Compute conditional probabilities.
   P_B_GIVEN_A = P_A_AND_B ./ (P_A + epsilon); % P(B|A)
   P_A_GIVEN_B = P_A_AND_B ./ (P_B + epsilon); % P(A|B) = P(B|A)P(A)/P(B)

   % Compute the relative joint frequencies - note: not equal to P(B)
   F_A = N_A / sum(N_A_AND_B);
   F_B = N_B ./ sum(N_A_AND_B);
   F_A_AND_B = N_A_AND_B ./ sum(N_A_AND_B);

   % Organize into a table
   P = table(N_A, N_B, N_A_AND_B, P_A, P_B, P_A_AND_B, F_A, F_B, F_A_AND_B, ...
      P_B_GIVEN_A, P_A_GIVEN_B, 'VariableNames', ...
      ["N_A", "N_B", "N_A_AND_B", "P_A", "P_B", "P_A_AND_B", "F_A", "F_B", ...
      "F_A_AND_B", "P_B_GIVEN_A", "P_A_GIVEN_B"]);

   % Adding group names to the table
   [a, b] = meshgrid(groupA, groupB);
   P.GroupA = categorical(reshape(a, [], 1));
   P.GroupB = categorical(reshape(b, [], 1));

   % Organize the columns
   P = movevars(P,"GroupA","Before","N_A");
   P = movevars(P,"GroupB","After","GroupA");
end

% It is helpful to remember:
% P_B_GIVEN_A = N_A_AND_B ./ N_A
% P_A_GIVEN_B = N_A_AND_B ./ N_B

% P_B_GIVEN_A = P_A_AND_B / P_A
% P_B_GIVEN_A = Fcs * F_A_AND_B
% P_B_GIVEN_A = N_A_AND_B / N_A
% F_A_AND_B = N_A_AND_B / sum(N_A_AND_B)
% Fcs = sum(N_A_AND_B) / N_A

% P_A_GIVEN_B = P_B_GIVEN_A * P(A)/P(B)
% P_A_GIVEN_B = N_A_AND_B / N_A * N_A)/P(B)

% P(B|A) = P(B ∩ A) / P(A) - The conditional probability of an outlet flood
% given a subbasin flood i.e., when a flood occurs in a specific subbasin,
% how likely is it that a flood is also occurring at the outlet? Can be
% interpreted as the likelihood of a subbasin flood "contributing" to a
% basin-scale flood, given that a flood has occurred in that sub-basin.

% Should be able to construct a table:
% ========================================|
%  A   \ Basin |  Yes   |   No   |  Total |
% Inlet \  B   |        |        |        |
% ========================================|
%  Yes         |  105   |  100   |  205   | <- Total # of inlet floods
% -------------------------------|--------|
%  No          |   92   | 1372   | 1464   | <- Total # of non-inlet floods
% ========================================|
%  Total       |  198   | 1472   | 1669   |
%------------------------------------------
%                  ^
%                Total
%                # of
%                basin
%                floods
%
%
% P_A = P_Inlet = (105+100) / 1669 = 0.1228
% P_B = P_Basin = (105+92) / 1669 = 0.1180
% P_A_GIVEN_B = P_Inlet_Given_Basin = N_A_AND_B / N_B = 105/198 = 0.5303
% P_B_GIVEN_A = P_Basin_Given_Inlet = N_A_AND_B / N_A = 105/205 = 0.5122

% Should be


%    sum(T.basin == "Outlet") % 205
%    sum(T.basin == "Outlet" & T.UpperDelaware) % 105
%    sum(T.basin == "Outlet" & ~T.UpperDelaware) % 100
%
%    sum(T.basin == "UpperDelaware") % 198
%    sum(T.basin == "UpperDelaware" & T.Outlet) % 106
%    sum(T.basin == "UpperDelaware" & ~T.Outlet) % 92
%
%    sum(T.basin ~= "Outlet" & T.basin ~= "UpperDelaware") % 1372
%
%    % These are the wrong ones
%    sum(T.basin ~= "Outlet" & T.UpperDelaware) % 941
%    sum(T.basin ~= "UpperDelaware" & T.Outlet) % 1117

% % Keep these for now b/c they show how to get the sum of all the columns
% % Counts of each groupA and groupB
% countA = sum(T{:, groupA}, 1);
% countB = sum(T{:, groupB}, 1);
%
% % Counts of each groupA and groupB happening together
% count_B_AND_A = cell2mat(arrayfun(@(A) arrayfun(@(B) ...
%    sum(T{:, A} & T{:, B}), groupB), groupA, 'UniformOutput', false));

% To confirm count_A_AND_B
% test_A_AND_B = nan(numel(groupA)*numel(groupB),1);
% i = 0;
% for n = 1:numel(groupA)
%    A = groupA(n);
%    for m = 1:numel(groupB)
%       i = i+1;
%       B = groupB(m);
%       test_A_AND_B(i) = sum(T.(groupvar) == A & T.(B));
%    end
% end

% count_B_AND_A = nan(numel(groupA),1);
% for n = 1:numel(groupA)
%    count_B_AND_A(n) = sum(T.(groupvar) == groupA{n} & T.(groupB));
% end

%
% Inputs:
% T - table, each row represents an event
% groupvar - string, cellstr, or char, indicating the column (variable) name in
% T containing the group names for each event
% groupA - string, cellstr, or char, indicating the members of all unique values
% in T.(groupvar) for which the conditional probability of A given B should be
% computed
% groupB - string, cellstr, or char, indicating the members of all unique values
% in T.(groupvar) for which the conditional probability of A given B should be
% computed
% datavar - the
%
% T must contain the column T.(groupvar), each element of which is a member of
% either groupA or groupB, and one column for each member of groupA and groupB
% e.g. T.(groupA(i)) must exist, where i goes from 1:numel(groupA), same for
% T.(groupB(j)), with j from 1:numel(groupB). Each element of T.(groupA(i)) and
% T.(groupB(j)) columns must be true or false indicating if the event
% Assumptions:
% 1. groupA and groupB are both cell arrays containing column names in T.
% 2. T.(groupA{i}) and T.(groupB{j}) contain boolean (true/false) data.

% % % % % % % % % %
% for testing with floodFrequency variables:
% T = Info;
% groupvar = "basin";
% allBasins = unique(Info.basin); % including the outlet
% groupA = allBasins(1:3);
% groupB = allBasins(4:end);
% % % % % % % % % %


% % Keep this b/c it is more explicit w/ the loop
% function P = groupbayes2(T,groupvar,groupA,groupB)
%
% % Initialize cell arrays to store probabilities for each group pair
% P_A = cell(numel(groupB), numel(groupA));
% P_B = cell(numel(groupB), numel(groupA));
% P_A_AND_B = cell(numel(groupB), numel(groupA));
% P_B_GIVEN_A = cell(numel(groupB), numel(groupA));
% P_A_GIVEN_B = cell(numel(groupB), numel(groupA));
%
% % Total counts
% countTotal = height(T);
%
% % Iterate over all pairs of groups
% for n = 1:numel(groupB)
%    for m = 1:numel(groupA)
%       % Counts of each groupA and groupB
%       countA = sum(T.(groupvar) == groupA{m});
%       countB = sum(T.(groupvar) == groupB{n});
%
%       % Counts of each groupA and groupB happening together
%       count_B_AND_A = sum(T.(groupvar) == groupA{m} & T{:, groupB{n}});
%
%       % Compute marginal probabilities of A and B
%       P_A{n, m} = countA / countTotal;
%       P_B{n, m} = countB / countTotal;
%
%       % Compute joint probability of A and B
%       P_A_AND_B{n, m} = count_B_AND_A / countTotal;
%
%       % Compute conditional probabilities.
%       P_B_GIVEN_A{n, m} = P_A_AND_B{n, m} / P_A{n, m}; % P(B|A)
%       P_A_GIVEN_B{n, m} = P_A_AND_B{n, m} / P_B{n, m}; % P(A|B)
%    end
% end
%
% % Organize into a table
% P = table(reshape(cell2mat(P_A), [], 1), reshape(cell2mat(P_B), [], 1), ...
%    reshape(cell2mat(P_A_AND_B), [], 1), reshape(cell2mat(P_B_GIVEN_A), [], 1), ...
%    reshape(cell2mat(P_A_GIVEN_B), [], 1), ...
%    'VariableNames', ["P_A", "P_B", "P_A_AND_B", "P_B_GIVEN_A", "P_A_GIVEN_B"]);
%
% % Adding group names to the table
% [a, b] = meshgrid(groupA, groupB);
% P.GroupA = reshape(a, [], 1);
% P.GroupB = reshape(b, [], 1);
%
% % Organize the columns
% P = movevars(P,"GroupA","Before","P_A");
% P = movevars(P,"GroupB","Before","P_B");
%
% end

