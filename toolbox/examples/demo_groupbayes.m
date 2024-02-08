

% Create a table T representing events
groupvar = 'Group';
groupA = {'A1', 'A2'};
groupB = {'B1', 'B2'};
T = table({'A1'; 'A2'; 'B1'; 'B2'; 'A1'; 'B2'; 'A1'; 'B1'; 'A2'; 'B2'}, ...
   [true; false; true; true; true; false; true; false; true; true], ...
   [false; true; true; false; true; true; false; true; false; false], ...
   [true; true; false; false; true; true; false; false; true; true], ...
   [false; false; true; true; false; true; true; false; false; true], ...
   'VariableNames', {groupvar, 'A1', 'A2', 'B1', 'B2'});

% Use the function groupbayes to calculate conditional probabilities
P = groupstats.groupbayes(T, groupA, groupB, groupvar);

% Display the resulting table
disp(P);

% Expected Result:
% GroupA    GroupB     P_A       P_B       P_A_AND_B    P_B_GIVEN_A    P_A_GIVEN_B
% 'A1'      'B1'       0.3       0.2       0.2          0.6667         1.0000
% 'A1'      'B2'       0.3       0.3       0.1          0.3333         0.3333
% 'A2'      'B1'       0.2       0.2       0.2          1.0000         1.0000
% 'A2'      'B2'       0.2       0.3       0            0.0000         0.0000

% Keep a copy of the original T
Tkeep = T;

% Adjust T so there are no A's in the rows
T = T(contains(T.Group, {'B1', 'B2'}), :);

% Need to return to these, but removing A's from the rows is less confusing b/c
% groupB can still be B1, B2, but the function fails b/c it counts N_A by rows
% ... I think that is necessary though, to get Bayesian probabilities, we have
% to have all the events in both groups, but maybe if both groups have identical
% sample size, then we could assume the rows are groupB, and the columns that
% match groupA members we'd sum down to get N_A, so in that case we'd need to
% assert that summing down the B groupd members matches the row counts, as a
% check 


% Adjust T so there are no B's in the rows
T = Tkeep;
T = T(contains(T.Group, {'A1', 'A2'}), :);

% Now when the function is called, groupB needs to be the A's, since the rows
% are the "givens"
groupA = {'B1', 'B2'};
groupB = {'A1', 'A2'};
P = groupstats.groupbayes(T, groupA, groupB, groupvar);

% Adjust T so there are no B's in the rows
T = T(~contains(T.Group, {'B1', 'B2'}), {'Group', 'B1', 'B2'});

% Now when the function is called, groupA needs to be 
groupA = {'B1', 'B2'};
groupB = {'A1', 'A2'};
P = groupstats.groupbayes(T, groupA, groupB, groupvar);

% Adjust it so there are no B's in the rows
T = T(~contains(T.Group, {'B1', 'B2'}), {'Group', 'B1', 'B2'});

% This note was in groupbayes right after the "Counts of each groupA and groupB"
% section:

% Note: above counts assume the group labels in the rows are also column
% names as in the original floods case, but there could be a situation where
% we have all the events for group B in the rows, and columns indicating
% true/false for group B members, which means we can compute P(B|A) but not
% P(A|B). See demo_groupbayes for discussion, and a possible way to
% accomodate that case.

