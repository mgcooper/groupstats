%% Pairwise conditional probabilities against a manual computation
%
% This demo checks groupbayes's Pairwise option against a hand-rolled
% pairwise computation. It builds a symmetric event matrix for 8
% components, computes every pairwise conditional probability with plain
% matrix arithmetic, and compares those numbers against groupbayes called
% with the same label set as both groups. The later sections repeat the
% comparison from the asymmetric-count case, where the two triangles of
% the joint-count matrix differ.
%
% See also: groupstats.groupbayes, demo_groupbayes, demo_bayes

% Compare floating point results. The checks below allow for round off in
% probabilities computed two ways.
isequaltol = @(a, b) all(abs(a - b) < 1e-10, 'all');

% Generate random events for 8 components
N = 10000;

% Sample data for 8 components
data = randi(100, [8 N]);

% Threshold for each component's event
thresholds = repmat(40, 8, 1);

% Boolean matrix indicating if event happened for each component
events = data > thresholds;

%% Probabilities

% Compute N_A_AND_B as symmetric
N_A_AND_B = events * events';

% Member-wise sample sizes
N_A_B = sum(events, 2);

% Pair-wise sample sizes
N_A_PLUS_N_B = N_A_B + N_A_B';

% Diagonal set to member-wise sample sizes. The linear index 1:n+1:end
% walks the diagonal of a square matrix.
N_A_PLUS_N_B(1:size(N_A_PLUS_N_B, 1) + 1:end) = N_A_B;

% Marginal probabilities
P_A_B = N_A_B ./ N_A_PLUS_N_B;

% Probability that both conditions are met, given all possible states
P_A_AND_B = N_A_AND_B ./ N_A_PLUS_N_B;

% Conditional probabilities
P_Cond = P_A_AND_B ./ P_A_B;

%% Use groupbayes to confirm

% This shows that P_Cond is P(A|B), and since all pairwise combos are computed,
% it also contains P(B|A) since P(A|B) = P(B|A) for the case where A and B are
% reversed i.e., if we have GroupA = A1, GroupB = B1, then P(A1|B1) is the value
% of P_A_GIVEN_B for that pairwise probability, which is equivalent to the
% P_B_GIVEN_A value for the pair GroupA = B1, GroupB = A1.

v = {'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8'};
tbl = array2table(events', 'VariableNames', v);

% Passing the same label set as both groups is the point of a pairwise
% call, so every event belongs to both sets. Pairwise=true declares that
% intent and keeps the marginals warning quiet.
P = groupstats.groupbayes(tbl, v, v, Pairwise = true);

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

% When the joint count of A and B differs from the count of B and A, the
% two triangles of N_A_AND_B differ. The line below keeps the upper
% triangle as the reference and mirrors it over the lower one, so the
% matrix is symmetric again and the steps above apply. Which triangle is
% the reference depends on which direction counts the unique events; see
% the groupbayes help on the groupvar syntax.

% To adjust for the asymmetry:
N_A_AND_B = triu(N_A_AND_B, 1) + triu(N_A_AND_B, 1)' + diag(diag(N_A_AND_B));

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
