clean

% Generate random events for 8 components
N = 10000;

% Sample data for 8 components
data = randi(100, [8 N]);

% Threshold for each component's event
thresholds = repmat(40, 8, 1);

% Boolean matrix indicating if event happened for each component
events = data > thresholds;

% This directly generates the event occurence states
% events = randi([0, 1], [8, N]);

%% Probabilities

% Compute N_A_AND_B as symmetric
N_A_AND_B = events * events';

% Member-wise sample sizes
N_A_B = sum(events, 2);

% Pair-wise sample sizes
N_A_PLUS_N_B = N_A_B + N_A_B';

% Diagonal set to member-wise sample sizes
N_A_PLUS_N_B = setdiag(N_A_PLUS_N_B, N_A_B);

% Marginal probabilities
P_A_B = N_A_B ./ N_A_PLUS_N_B;

% Probability that both conditions are met, given all possible states
P_A_AND_B = N_A_AND_B ./ N_A_PLUS_N_B;

% Conditional probabilities
P_Cond = P_A_AND_B ./ P_A_B;

% This is equivalent:
% P_Cond = N_A_AND_B ./ (N_A_PLUS_N_B .* P_A_B);

%% Use groupbayes to confirm

% This shows that P_Cond is P(A|B), and since all pairwise combos are computed,
% it also contains P(B|A) since P(A|B) = P(B|A) for the case where A and B are
% reversed i.e., if we have GroupA = A1, GroupB = B1, then P(A1|B1) is the value
% of P_A_GIVEN_B for that pairwise probability, which is equivalent to the
% P_B_GIVEN_A value for the pair GroupA = B1, GroupB = A1. 

v = {'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8'};
T = array2table(events', 'VariableNames', v);
P = groupstats.groupbayes(T, v, v);

% Reshape the P_Cond matrix for comparison with P from groupbayes
P.P2 = reshape(P_Cond, [], 1);

numel(unique(round(P_Cond, 10)))
numel(unique(round(P.P_B_GIVEN_A, 10)))
numel(unique(round(P.P_A_GIVEN_B, 10)))
numel(unique([round(P.P_B_GIVEN_A, 10); round(P.P_A_GIVEN_B, 10)]))

%%

% Given your existing code till P_A_AND_B
N_A = sum(events, 2);
N_B = N_A;  % Since the events are symmetric

P_A_given_B = zeros(size(events, 1));
P_B_given_A = zeros(size(events, 1));

for i = 1:size(events, 1)
   for j = 1:size(events, 1)
      if i ~= j
         P_A_given_B(i, j) = N_A_AND_B(i, j) / N_B(j);
         P_B_given_A(i, j) = N_A_AND_B(i, j) / N_A(i);
      end
   end
end

numel(unique(P_A_given_B))
numel(unique(P_B_given_A))
numel(unique( [P_A_given_B(:); P_B_given_A(:)] ))

isequaltol(P_A_given_B, P_B_given_A')
%% Asymmetric counts

% Now imagine for some reason N_A_AND_B ~= N_B_AND_A, then proceed as above
% but after obtainig the asymmetric N_A_AND_B, replace the lower tri with the
% transposed upper, which assumes the "correct" N_A_AND_B is the lower portion,
% which was the case in the floods study b/c we want rows to be the unique
% events (state B) and we ask, given B, is A true (the variable columns)

% To adjust for the asymmetry:
N_A_AND_B = setdiag(triu(N_A_AND_B) + triu(N_A_AND_B)', diag(N_A_AND_B));

%%

% Take the lower triangular (including the diagonal) for P(A|B)
P_A_given_B = tril(P_Cond);

% Take the upper triangular (excluding the diagonal) for P(B|A)
P_B_given_A = triu(P_Cond, 1);

% Fill in the missing entries in P_B_given_A using P_A_given_B
for i = 1:8
   for j = 1:8
      if i > j
         P_B_given_A(i, j) = P_A_given_B(j, i);
      end
   end
end

%%
% Separate out the matrices
P_A_given_B = P_Cond;
P_B_given_A = P_Cond;

% Fill in P_A_given_B using the upper triangle of P_Cond
for i = 1:8
   for j = 1:8
      if i < j
         P_A_given_B(i, j) = P_Cond(j, i);
      end
   end
end

% Fill in P_B_given_A using the lower triangle of P_Cond
for i = 1:8
   for j = 1:8
      if i > j
         P_B_given_A(j, i) = P_Cond(i, j);
      end
   end
end

%%

% % Didn't finish this, was trying to generate a table for the "system" -
% % "components" example
% events = sort(randi(3, [1 10])).';
% component = ["System", "c1", "c2", "c3"];
% 
% T = table(component, events);
% 
% T = table();
% for n = 1:numel(component)
%    failures = randi([0 1], [1 10])';
%    T{:, component(n)} = failures;
% end

%% prep for gpt system-component example

components = basins;
T.Component = T.basin;
T.Component(T.basin == "Outlet") = "System";
T.system = T.Outlet;
T.Event = T.tpeaks;

%% Compute system-compoenet example using my methods

% components = ["c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "System"];
N_A = sum(T.Component == "System");
N_B_AND_A = arrayfun(@(b) sum(T{T.Component == "System", b}), components);
P_B_GIVEN_A = N_B_AND_A ./ N_A;

% To compute P_A_GIVEN_B, need P(A) and P(B). However, the math can be
% simplified to use just the counts: 
N_B = arrayfun(@(b) sum(T.Component == b), components);
P_A_GIVEN_B = N_B_AND_A ./ N_B;
[P_A_GIVEN_B, P_B_GIVEN_A .* P_A ./ P_B]

% Repeat, this time compute the individual probabilities
N = N_A + sum(N_B)
P_A = N_A / N
P_B = N_B / N
sum(P_B)+P_A
[P_A_GIVEN_B, P_B_GIVEN_A .* P_A ./ P_B]

%% This is the final outcome of gpt where it finally got bayes right

% This verifies my methods, but i had to coach it so much it somewhat defeated
% the purpose

% Number of unique failure events where the system failed
NA = sum(T.Component == "System");

% Total number of unique failure events
N = height(T);

% Probability that the system fails
PA = NA / N;

% Probability that each component i fails
PB = arrayfun(@(b) sum(T.Component == b), components) / N;

% Conditional probabilities
P_A_GIVEN_Bi = arrayfun(@(b) sum(T.Component == "System" & T{:, b}) / ...
   sum(T.Component == b), components);

P_Bi_GIVEN_A = arrayfun(@(b) sum(T.Component == "System" & T{:, b}) / ...
   sum(T.Component == "System"), components);

assert(isequaltol(PA, P_A))
assert(isequaltol(PB, P_B))
assert(isequaltol(sum(PB) + PA, 1))

assert(isequaltol(P_A_GIVEN_Bi, P_A_GIVEN_B))
assert(isequaltol(P_Bi_GIVEN_A, P_B_GIVEN_A))


%%

% Below here is where I was going to try to summarize the different methods in
% PeakFlows.mlx and present them to gpt but now I have to move on.

% The goal of this was to collate the differet ways and see if gpt can identify
% whats wrong /right with them 

N_A = sum(T.basin == "Outlet");
N_B_AND_A = arrayfun(@(b) sum(T{T.basin == "Outlet", b}), basins);
P_B_GIVEN_A = N_B_AND_A ./ N_A;
N_B = arrayfun(@(b) sum(T.basin == b), basins);
P_A_GIVEN_B = N_B_AND_A ./ N_B;

% Confirm it using this method:
N = N_A + sum(N_B);
P_A = N_A / N;
P_B = N_B / N;
sum(P_B)+P_A
[P_A_GIVEN_B, P_B_GIVEN_A .* P_A ./ P_B]

%% Use column sums 

% these provide the total number of times each subbasin has a peak within the
% window of another peak, not the unique events. BUT, check if they yield
% similar and/or identical probabilities.  
N_A = sum(T_unique.Outlet)
N_B = arrayfun(@(b) sum(T_unique{:, b}), basins)
N = N_A + sum(N_B)
P_A = N_A / N
P_B = N_B / N
sum(P_B)+P_A
[basins P_A_GIVEN_B, P_B_GIVEN_A .* P_A ./ P_B]

