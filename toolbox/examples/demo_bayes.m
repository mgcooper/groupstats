
% dataA and dataB are numbers from 1-100, but pretend they represent some
% characteristics like age and number of number of living relatives. In this
% example, each data point is one person, so there are equal numbers of data
% points in dataA and dataB and we might ask, what is the probability that
% someone is older than 40? What is the probability that someone has > 10
% living relatives? What is the probability that someone is older than 40 and
% has > 10 living relatives? What is the probability that someone is older
% than 40, given that they have > 10 living relatives? And finally, what is
% the probability that someone is > 40, given that they have > 10 living
% relatives?

dataA = randi(100, [1 10000]);
dataB = randi(100, [1 10000]);
N = numel(dataA);
N_A = sum(dataA > 40);
N_B = sum(dataB > 10);
N_A_AND_B = sum(dataA > 40 & dataB > 10);

% Probabilities directly from the data
P_A = N_A / N; % Probability that a number from dataA is > 40 (should be ~60%)
P_B = N_B / N; % Probability that a number from dataB is > 10 (should be ~90%)

% Probability that both conditions are met, given all possible states
P_A_AND_B = N_A_AND_B / N; % > 40 AND > 10

% Conditional probabilities directly from the data
P_B_GIVEN_A = P_A_AND_B / P_A; % dataB > 10 given that its pair in dataA is > 40
P_A_GIVEN_B = P_A_AND_B / P_B; % dataA > 40 given that its pair in dataB is > 10

% Use Bayes' rule to verify P_A_GIVEN_B
P_A_GIVEN_B_Bayes = P_B_GIVEN_A * P_A / P_B;

% Print results
fprintf('P(A) = %.3f\n', P_A);
fprintf('P(B) = %.3f\n', P_B);
fprintf('P(A and B) = %.3f\n', P_A_AND_B);
fprintf('P(B|A) directly from data = %.3f\n', P_B_GIVEN_A);
fprintf('P(A|B) directly from data = %.3f\n', P_A_GIVEN_B);
fprintf('P(A|B) using Bayes = %.3f\n', P_A_GIVEN_B_Bayes);

% The difference b/w P_A_AND_B and P_A_GIVEN_B is that the former is normalized
% by all possible states, whereas the latter is normalized by the number of B
% states:

P_B_GIVEN_A = N_A_AND_B / N_A
P_A_GIVEN_B = N_A_AND_B / N_B

% Now imagine we don't have the counts, but we have the probabilities, possibly
% from some prior experiment that did have the counts, or otherwise, then Bayes
% rule becomes useful b/c we can use it directly:
P_A_GIVEN_B_Bayes = P_B_GIVEN_A * P_A / P_B;

% P_A = prior (initial degree of belief prior to observing evidence in B)
% P_B = evidence (marginal likelihood) (total probability of observing evidence)
% P_B_GIVEN_A = likelihood (how probable the evidence is, assuming A is true)
% P_A_GIVEN_B = posterior (updated belief)

%% pairwise



