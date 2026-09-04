%% Conditional probabilities between two sets of group labels
%
% groupbayes counts co-occurrences between the members of groupA and the
% members of groupB, and reports the marginal, joint, and conditional
% probabilities for each pair.
%
% See also: groupstats.groupbayes, groupstats.test.generateTestData

% Create a table tbl representing events. The same table backs the groupbayes
% unit tests, so the demo and the tests cannot drift apart.
data = groupstats.test.generateTestData('groupbayes');
tbl = data.tbl;
groupvar = data.groupvar;
groupA = data.groupA;
groupB = data.groupB;

% Use the function groupbayes to calculate conditional probabilities
P = groupstats.groupbayes(tbl, groupA, groupB, groupvar);

% Display the resulting table
disp(P);

% Expected Result:
% GroupA    GroupB     P_A       P_B       P_A_AND_B    P_B_GIVEN_A    P_A_GIVEN_B
% 'A1'      'B1'       0.3       0.2       0.2          0.6667         1.0000
% 'A1'      'B2'       0.3       0.3       0.1          0.3333         0.3333
% 'A2'      'B1'       0.2       0.2       0.2          1.0000         1.0000
% 'A2'      'B2'       0.2       0.3       0            0.0000         0.0000

% Keep a copy of the original tbl
originaltbl = tbl;

%% Rows from one group only
%
% Removing the A rows is the clearer case to reason about. groupB can still
% be B1 and B2. groupbayes counts N_A by rows, so N_A is zero, P_A is zero,
% and every probability conditioned on A is NaN.
%
% Bayesian probabilities need every event present in both groups. Where both
% groups have the same sample size, the rows could be taken as groupB, and
% the columns matching the groupA members summed down to give N_A. That case
% needs an assertion that summing down the groupB members matches the row
% counts.

tbl = originaltbl(contains(originaltbl.Group, {'B1', 'B2'}), :);

P = groupstats.groupbayes(tbl, groupA, groupB, groupvar);
disp(P);

%% Swap the roles of the two groups
%
% The rows are the givens, so groupB names the labels the rows hold.

tbl = originaltbl(contains(originaltbl.Group, {'A1', 'A2'}), :);

P = groupstats.groupbayes(tbl, {'B1', 'B2'}, {'A1', 'A2'}, groupvar);
disp(P);

%% Columns for one group only
%
% Keeping the B columns alone leaves nothing to count the A events with.

tbl = originaltbl(~contains(originaltbl.Group, {'B1', 'B2'}), ...
   {'Group', 'B1', 'B2'});

try
   P = groupstats.groupbayes(tbl, {'B1', 'B2'}, {'A1', 'A2'}, groupvar);
   disp(P);
catch e
   fprintf('Columns for group B alone: %s\n', e.message);
end

% This note was in groupbayes right after the "Counts of each groupA and groupB"
% section:

% Note: above counts assume the group labels in the rows are also column
% names as in the original floods case, but there could be a situation where
% we have all the events for group B in the rows, and columns indicating
% true/false for group B members, which means we can compute P(B|A) but not
% P(A|B). See demo_groupbayes for discussion, and a possible way to
% accomodate that case.
