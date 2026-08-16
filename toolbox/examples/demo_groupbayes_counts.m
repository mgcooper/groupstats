%% Why groupbayes subsets rows by groupA and counts groupB columns
%
% N_A_AND_B should equal N_B_AND_A, and it does not. This demo holds the work
% that established why, and the measures that were tried against it.
%
% It is also where the scratch work lives. groupbayes itself stays clean.
% The subfunctions below are kept as they were written, so nothing is lost
% before it is decided what to keep.
%
% See also: groupstats.groupbayes, groupstats.test.generateTestData

data = groupstats.test.generateTestData('info');

Info = data.Info;
groupvar = "basin";

% The outlet, and the subbasins that drain to it.
groupA = string(data.basins(:));
groupB = "Outlet";

%% The two count forms
%
% The count changes depending on which set picks the rows. Subsetting rows
% where tbl.(groupvar) == groupA(n) and then counting the tbl.(groupB)
% columns gives a different answer than subsetting by groupB and counting the
% groupA columns. It may be specific to the flood data and how non-unique
% events were removed from it.
%
% The two forms, for reference:
%
%   N_A_AND_B = arrayfun(@(A) sum(tbl{tbl.(groupvar) == A, groupB}), groupA);
%   N_B_AND_A = arrayfun(@(A) sum(tbl{tbl.(groupvar) == groupB, A}), groupA);
%
% N_B_AND_A is the form used to compute each sub-basin's contribution to the
% outlet dFCS. groupbayes uses N_A_AND_B.

comparecountmethods(Info, groupvar, groupA, groupB);

%% Where the asymmetry comes from
%
% The answer is in the peak pairing, not in groupbayes. pfa.getFloodPeaks,
% subfunction getUniqueOutletPeaks, says it directly:
%
%   "If more than one peak is within the window of this outlet peak, count
%   the larger one, but if the smaller one is retained in the subbasin list,
%   then two floods will be tagged as "coherent" with the one outlet peak
%   here, leading to asymmetry in the joint probability. However, the smaller
%   peak could be uniquely associated with another outlet peak, so it cannot
%   be removed without first checking that. This is done in
%   removeDuplicatePeaks."
%
% So the pairing is many-to-one: two subbasin peaks can be coherent with one
% outlet peak. Counting from the subbasin rows finds both. Counting from the
% outlet rows finds one. The asymmetry is a property of the event table, not
% an error in either count.
%
% generateTestData builds co-occurrence symmetrically, so both forms agree on
% the fixture. The hand table below reproduces the asymmetry without the peak
% data.

%% The smallest table that shows the asymmetry
%
% From the timeline in the groupbayes docs. Three events at member a and two
% at member b, all inside one 2-t co-occurrence window:
%
%     a_1       a_2       a_3 ... group member A(n) = a, events 1,2,3
% o----o----o----o----o----o
%          b_1            b_2 ... group member B(m) = b, events 1,2
% o----o----o----o----o----o
%
% Every event co-occurs with every other, so every column is true:
%
% | Event | tbl.(groupvar) | a | b |
% | -------------------------------
% |   1   |       a        | 1 | 1 |  ... event a1
% |   2   |       a        | 1 | 1 |  ... event a2
% |   3   |       a        | 1 | 1 |  ... event a3
% |   4   |       b        | 1 | 1 |  ... event b1
% |   5   |       b        | 1 | 1 |  ... event b2

handvar = "basin";
handtbl = table( ...
   categorical(["a"; "a"; "a"; "b"; "b"]), ...
   true(5, 1), ...
   true(5, 1), ...
   'VariableNames', {char(handvar), 'a', 'b'});

% Subsetting by a-rows counts three. Subsetting by b-rows counts two. This is
% the many-to-one pairing in the small: the three a events are all coherent
% with the two b events, but there are only two b events to be coherent with.
N_a_AND_b = sum(handtbl{handtbl.(handvar) == "a", "b"});
N_b_AND_a = sum(handtbl{handtbl.(handvar) == "b", "a"});

fprintf('N_a_AND_b = %d, N_b_AND_a = %d\n', N_a_AND_b, N_b_AND_a);

%% What the asymmetry costs
%
% groupbayes counts N_A_AND_B from the a-rows and divides by N_B, so the two
% come from different pairings. P_A_GIVEN_B leaves the unit interval.

disp(groupstats.groupbayes(handtbl, "a", "b", handvar));

% Reading the row: N_A_AND_B is 3 and N_B is 2, so P_A_GIVEN_B is 3/2. A
% probability above one is the signature of this defect. Note: groupbayes
% does not guard against it, and no caller checks for it.

%% One fix, from the peakflows notes
%
% Let O1 be associated with both M1 and M2, so the outlet event is listed
% once per subbasin event it pairs with:
%
%      O   M
% M M1 1   1
% M M2 1   1
% M M3 1   1
% O O1 1   1  represents M1
% O O1 1   1  represents M2
% O O2 1   1
%
% The duplicated row makes the two counts agree.

fixtbl = table( ...
   categorical(["M"; "M"; "M"; "O"; "O"; "O"]), ...
   true(6, 1), ...
   true(6, 1), ...
   'VariableNames', {char(handvar), 'M', 'O'});

fprintf('after the fix: N_M_AND_O = %d, N_O_AND_M = %d\n', ...
   sum(fixtbl{fixtbl.(handvar) == "M", "O"}), ...
   sum(fixtbl{fixtbl.(handvar) == "O", "M"}));

% This changes what an event means: an outlet event stops being one row.
% It was not adopted. Whether it should be is still open.

%% Symmetric measures, tried against the asymmetry
%
% A Jaccard index and a phi coefficient can be computed from the same three
% counts. Both were written to test whether a symmetric measure sidesteps the
% problem. Neither has a caller.
%
% Run them on the fixture. They print, as they were written to, because they
% were evaluated at a debug prompt inside groupbayes.

J = groupjaccard(Info, groupvar, groupA, groupB);

% The phi coefficient needs the three counts, so compute them the way the
% main function does, then hand them over.
N_A = arrayfun(@(A) sum(Info.(groupvar) == A), groupA);
N_B = arrayfun(@(B) sum(Info.(groupvar) == B), groupB);
N_A_AND_B = arrayfun(@(A) sum(Info{Info.(groupvar) == A, groupB}), groupA);

phi = groupphicoeff(Info, groupvar, groupA, groupB, N_A, N_B, N_A_AND_B);

fprintf('phi ranges %.3f to %.3f\n', min(phi(:)), max(phi(:)));

%% Why there are two syntaxes, from sandbox/groupbayes_doc.m
%
% groupbayes(tbl, groupA, groupB). Each member of groupA and groupB is a
% variable (aka column) in tbl. If groupA is ["tacos", "sandwich"] and groupB
% is ["salad", "pho"], then tbl must contain tbl.tacos, tbl.sandwich,
% tbl.salad, and tbl.pho, holding logical true/false for whether the event
% occurred. Multiple events can be true for the same row, e.g. if the row
% represents one week of observations, all group members might be TRUE if all
% were on the menu that week, or all FALSE if none were, or one TRUE.
%
% groupbayes(tbl, groupA, groupB, groupvar). The column tbl.(groupvar) holds
% the group member labels that define unique events. If groupvar is "lunch"
% and the members are "tacos", "sandwich", "salad", and "pho", then each
% element of tbl.lunch is one of those four. The same group columns must also
% be present. The difference is that each row represents the event "tacos",
% or "sandwich", or "salad", or "pho", rather than one week of observations.
%
% Why support both: imagine there is additional metadata about each event,
% like price, but you still want to know how the members co-occur on a weekly
% schedule. One row per week makes the per-lunch metadata hard to hold.
% Instead define one row per lunch type per week, plus a column for the week
% number. tbl.lunch(1) = "tacos" with tbl.week(1) = 1 says the event "tacos"
% occurred during week 1, and the four member columns are true or false:
%
% lunch     week  tacos sandwich salad pho
% "tacos"   1     true  false    true  false
% "salad"   1     true  false    true  false
% "tacos"   2     true  true     false true
% "sandwich"2     true  true     false true
% "pho"     2     true  true     false true
% "salad"   3     false false    true  false
% ... and so forth
%
% The column tbl.pho is true for each row if pho was had during that week.
% This is a sort of binning. It accommodates the case where multiple trials
% each generate a table of results which are then joined into one table.

%% What the table must contain, from sandbox/groupbayes_doc_peakflows.m
%
% Each row is one unique event for one member of either groupA or groupB. For
% each row representing an event for a member of groupA, we must know whether
% the event also occurred for each member of groupB. The groupB columns carry
% that, true or false per row. All events in BOTH groupA and groupB must be
% represented by rows, but there only needs to be columns for each member of
% groupB.
%
% tbl must contain tbl.(groupvar), each element of which is a member of either
% groupA or groupB, and one row for each unique event over all possible
% events. unique(tbl.(groupvar)) yields all member labels for both sets. So
% tbl.(groupvar) == groupA(n) yields all rows where an event occurred at
% member n of groupA, and the same for each member of groupB.
%
% The group labels in groupB must be column names: tbl.(groupB(m)) must exist.
% This is not required for groupA, though groupA columns are fine. Each
% element of tbl.(groupB(m)) is true or false indicating whether the event in
% row i is also true for that member.
%
% The KEY THING is that the rows contain the unique events for all groupA
% members, and the columns indicate whether there was an event in each of the
% groupB members. Rows for the groupB events are needed too, but only to get
% the number of unique events in groupB.
%
% Stated the other way: for a set of rows representing all events for member i
% of groupA, the columns contain BOTH true AND false for all members of
% groupB. If there is a column for member i itself, it must be ONLY true for
% those rows. Depending on how the data is generated, N_A_AND_B can differ
% depending on whether rows or columns subset the groups. That is the
% asymmetry reproduced above.

%% Why rows subset by groupA and not by groupB
%
% A possible source of confusion is whether to subset rows for each member of
% groupA and then sum down columns where each member of groupB is true, or the
% opposite. If the members of groupA are sub-members of groupB, it must be the
% former, which is how it is coded.
%
% Say you have flood events in a river basin, and also in smaller sub-basins
% within it, and you want the conditional probability of a river basin flood
% given a subbasin flood and vice versa. The rows must represent all floods in
% all subbasins and the river basin. The subbasins are groupA and the river
% basin is groupB. The function goes over all members of groupA, subsets the
% rows, then sums down the column for groupB. Subsetting rows where groupB is
% true instead would eliminate all events where groupB was not true.
%
% Say the rows contained all events in groupA, and the columns were only
% groupB. We could find N_A_AND_B, but since groupB could be true for multiple
% members of groupA, we would not know which events in groupB were unique.
% This is why the rows must contain all events, in both groupA and groupB. The
% columns only need groupB.

%% The worked example carried in both doc files
%
% Note: both files write the call as groupbayes(T, groupvar, groupA, groupB).
% The shipped signature takes groupvar last, so the call below reorders it.
% The expected result is reproduced verbatim from the doc files.

docgroupvar = 'Group';
docgroupA = {'A1', 'A2'};
docgroupB = {'B1', 'B2'};
docT = table({'A1'; 'A2'; 'B1'; 'B2'; 'A1'; 'B2'; 'A1'; 'B1'; 'A2'; 'B2'}, ...
      [true; false; true; true; true; false; true; false; true; true], ...
      [false; true; true; false; true; true; false; true; false; false], ...
      [true; true; false; false; true; true; false; false; true; true], ...
      [false; false; true; true; false; true; true; false; false; true], ...
      'VariableNames', {docgroupvar, 'A1', 'A2', 'B1', 'B2'});

disp(groupstats.groupbayes(docT, docgroupA, docgroupB, docgroupvar));

% Expected Result, as recorded in the doc files:
% GroupA    GroupB     P_A       P_B       P_A_AND_B    P_B_GIVEN_A    P_A_GIVEN_B
% 'A1'      'B1'       0.3       0.2       0.2          0.6667         1.0000
% 'A1'      'B2'       0.3       0.3       0.1          0.3333         0.3333
% 'A2'      'B1'       0.2       0.2       0.2          1.0000         1.0000
% 'A2'      'B2'       0.2       0.3       0            0.0000         0.0000

%% Bayes reference, carried from both doc files
%
% Bayes' theorem is:
%
%                 P(B|A)P(A)
%       P(A|B) = ------------
%                    P(B)
%
%
% The total probabilities schema is:
%
%                    A                     ~A
%          ----------------------------------------------
%      B  |  P(A∩B)= P(B|A)P(A)     P(~AB)= P(B|~X)p(~A) | P(B)
%         |                                              |
%     ~B  |  B(A~B)= P(~B|A)P(A)   P(~A~B)= P(~B|~A)P(~A)| P(~B)
%          ----------------------------------------------
%                   P(A)                  P(~A)
%
%
% Reading from left to right, | means 'given'. Reading from right to left, |
% means 'implies' or 'leads to'. Thus A|B reads 'A given B' or 'the
% probability that an element is A, given that the element is B'. From right
% to left, A|B reads 'B implies A or 'the probability that an element
% containing B is A'. - attributed to Eliezer S. Yudkowsky
%
% P_A = prior (initial degree of belief prior to observing evidence in B)
% P_B = evidence (marginal likelihood) (total probability of observing evidence)
% P_B_GIVEN_A = likelihood (how probable the evidence is, assuming A is true)
% P_A_GIVEN_B = posterior (updated belief)

%% The investigation note at the head of sandbox/groupbayes_doc.m
%
% "This is the version I was dbstopping to figure out why N(A and B) differs
% depending on the subsetting method and also the threshold."
%
% "NOTE: Although the results suggest subsetting by subbasin rows is 'correct'
% for the threshold cases, I think that's only because the number of outlet
% events that get eliminated by the thresholding step is much smaller than the
% number of subbasin events so the N_A_AND_B doesn't end up being bigger than
% N(subbasins) but the numbers are not right ... so basically the table needs
% to be built from scratch using the threshold"
%
% The threshold case is still open. The hand table above shows the pairing
% defect on its own, with no threshold involved.

%% The identities worth remembering
%
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


%    sum(tbl.basin == "Outlet") % 205
%    sum(tbl.basin == "Outlet" & tbl.UpperDelaware) % 105
%    sum(tbl.basin == "Outlet" & ~tbl.UpperDelaware) % 100
%
%    sum(tbl.basin == "UpperDelaware") % 198
%    sum(tbl.basin == "UpperDelaware" & tbl.Outlet) % 106
%    sum(tbl.basin == "UpperDelaware" & ~tbl.Outlet) % 92
%
%    sum(tbl.basin ~= "Outlet" & tbl.basin ~= "UpperDelaware") % 1372
%
%    % These are the wrong ones
%    sum(tbl.basin ~= "Outlet" & tbl.UpperDelaware) % 941
%    sum(tbl.basin ~= "UpperDelaware" & tbl.Outlet) % 1117

%% Inputs, as originally documented

% Inputs:
% tbl - table, each row represents an event
% groupvar - string, cellstr, or char, indicating the column (variable) name in
% tbl containing the group names for each event
% groupA - string, cellstr, or char, indicating the members of all unique values
% in tbl.(groupvar) for which the conditional probability of A given B should be
% computed
% groupB - string, cellstr, or char, indicating the members of all unique values
% in tbl.(groupvar) for which the conditional probability of A given B should be
% computed
% datavar - the
%
% tbl must contain the column tbl.(groupvar), each element of which is a member of
% either groupA or groupB, and one column for each member of groupA and groupB
% e.g. tbl.(groupA(i)) must exist, where i goes from 1:numel(groupA), same for
% tbl.(groupB(j)), with j from 1:numel(groupB). Each element of tbl.(groupA(i)) and
% tbl.(groupB(j)) columns must be true or false indicating if the event
% Assumptions:
% 1. groupA and groupB are both cell arrays containing column names in tbl.
% 2. tbl.(groupA{i}) and tbl.(groupB{j}) contain boolean (true/false) data.

% % % % % % % % % %
% for testing with floodFrequency variables:
% tbl = Info;
% groupvar = "basin";
% allBasins = unique(Info.basin); % including the outlet
% groupA = allBasins(1:3);
% groupB = allBasins(4:end);

%% Column sums, kept for reference

% % Keep these for now b/c they show how to get the sum of all the columns
% % Counts of each groupA and groupB
% countA = sum(tbl{:, groupA}, 1);
% countB = sum(tbl{:, groupB}, 1);
%
% % Counts of each groupA and groupB happening together
% count_B_AND_A = cell2mat(arrayfun(@(A) arrayfun(@(B) ...
%    sum(tbl{:, A} & tbl{:, B}), groupB), groupA, 'UniformOutput', false));

% To confirm count_A_AND_B
% test_A_AND_B = nan(numel(groupA)*numel(groupB),1);
% i = 0;
% for n = 1:numel(groupA)
%    A = groupA(n);
%    for m = 1:numel(groupB)
%       i = i+1;
%       B = groupB(m);
%       test_A_AND_B(i) = sum(tbl.(groupvar) == A & tbl.(B));
%    end
% end

% count_B_AND_A = nan(numel(groupA),1);
% for n = 1:numel(groupA)
%    count_B_AND_A(n) = sum(tbl.(groupvar) == groupA{n} & tbl.(groupB));
% end

%% The explicit-loop version, kept for reference

%%
% % Keep this b/c it is more explicit w/ the loop
% function P = groupbayes2(tbl,groupvar,groupA,groupB)
%
% % Initialize cell arrays to store probabilities for each group pair
% P_A = cell(numel(groupB), numel(groupA));
% P_B = cell(numel(groupB), numel(groupA));
% P_A_AND_B = cell(numel(groupB), numel(groupA));
% P_B_GIVEN_A = cell(numel(groupB), numel(groupA));
% P_A_GIVEN_B = cell(numel(groupB), numel(groupA));
%
% % Total counts
% countTotal = height(tbl);
%
% % Iterate over all pairs of groups
% for n = 1:numel(groupB)
%    for m = 1:numel(groupA)
%       % Counts of each groupA and groupB
%       countA = sum(tbl.(groupvar) == groupA{m});
%       countB = sum(tbl.(groupvar) == groupB{n});
%
%       % Counts of each groupA and groupB happening together
%       count_B_AND_A = sum(tbl.(groupvar) == groupA{m} & tbl{:, groupB{n}});
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

%% Subfunctions, kept as written
%
% comparecountmethods was named dummy. It is not a function to call for a
% result; it is the crib sheet that compares every count form against the
% others, which is what a debug stop inside groupbayes was for.
%
% The author's own note on where these came from:

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Between here was in peakflows but not here
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

function test = comparecountmethods(tbl, groupvar, groupA, groupB)

   % N_A_AND_B should equal N_B_AND_A, but it does not. The test below demonstrates
   % why, and clarified why we need to subset rows by groupA (subbasins) not groupB
   % (outlet) (when computing bayes? Or when diagnosing FCS? I think bayes)

   % This shows that it changes when groupA sets are chosen based on rows where
   % tbl.(groupvar) == groupA(n) and then N_A_AND_B is computed using the columns
   % tbl.(groupB) == true, versus the other way around. It might be specific to my
   % flood data and how I removed non-unique events.

   % Counts of each groupA and groupB happening together. This is how it's done in
   % the main function above.
   N_A_AND_B = cell2mat( ...
      arrayfun(@(A) arrayfun(@(B) ...
      sum(tbl.(groupvar) == A & tbl{:, B}), groupB), groupA, ...
      'UniformOutput', false));

   % This replicates N_A_AND_B above for clarity. It uses groupA rows and then sums
   % down groupB columns for those rows.
   N_A_AND_B = nan(numel(groupA), 1);
   for n = 1:numel(groupA)
      N_A_AND_B(n) = sum(tbl.(groupvar) == groupA(n) & tbl{:, groupB});
   end

   % This uses events where groupB is true, to test if it provides the same result
   % as the percentOfdFCS
   N_B_AND_A = cell2mat(arrayfun(@(B) arrayfun(@(A) ...
      sum(tbl{tbl.(groupvar) == B, A}), groupA), groupB, 'UniformOutput', false));

   % This replicates N_B_AND_A above for clarity. It uses the groupB rows and then
   % sums down groupA columns for those rows.
   N_B_AND_A = nan(numel(groupA), 1);
   for n = 1:numel(groupA)
      N_B_AND_A(n) = sum(tbl.(groupvar) == groupB & tbl{:, groupA(n)});
   end

   % These are equivalent to above, but only work b/c groupB is scalar. They were
   % helpful for clarifying how the methods used in precentDeltaFCS relate to the
   % methods used in groupbayes.
   N_B_AND_A = arrayfun(@(A) sum(tbl.(groupvar) == groupB & tbl{:, A}), groupA);
   N_A_AND_B = arrayfun(@(A) sum(tbl{tbl.(groupvar) == A, groupB}), groupA);

   % This is how I compute the contribution of each sub-basin to outlet dFCS,
   % Counts == N_B_AND_A
   Fcount = @(a) sum(tbl{tbl.(groupvar) == groupB, a});
   Counts_B_AND_A = arrayfun(@(a) Fcount(a), groupA);

   % This replicates N_A_AND_B:
   Fcount = @(a) sum(tbl{tbl.(groupvar) == a, groupB});
   Counts_A_AND_B = arrayfun(@(a) Fcount(a), groupA)

   % Compare them:
   test = [N_A_AND_B N_B_AND_A Counts_A_AND_B Counts_B_AND_A];
end

function J = groupjaccard(tbl, groupvar, groupA, groupB)

   % Counts of each groupA and groupB
   N_A = cellfun(@(group) sum(tbl.(groupvar) == group), groupA);
   N_B = cellfun(@(group) sum(tbl.(groupvar) == group), groupB);

   % Counts of each groupA and groupB happening together
   N_A_AND_B = cell2mat(arrayfun(@(A) arrayfun(@(B) sum(tbl.(groupvar) == A & ...
      tbl{:, B}), groupB), groupA, 'UniformOutput', false));

   % To compute Jaccard similarity
   N_B_AND_A = cell2mat(arrayfun(@(B) arrayfun(@(A) ...
      sum(tbl{tbl.(groupvar) == B, A}), groupA), groupB, 'UniformOutput', false));

   % These should be symmetric
   J_A_AND_B = N_A_AND_B ./ (N_A + N_B - N_A_AND_B)
   J_B_AND_A = N_B_AND_A ./ (N_A + N_B - N_B_AND_A)

   % Check if it is symmetric (they're not)
   [J_A_AND_B J_B_AND_A]

   % try this way
   J_A_AND_B = N_A_AND_B ./ (N_A + N_B - N_B_AND_A);
   J_B_AND_A = N_B_AND_A ./ (N_A + N_B - N_A_AND_B);
   J = [J_A_AND_B J_B_AND_A] % not
end

function phi = groupphicoeff(tbl, groupvar, groupA, groupB, ...
      N_A, N_B, N_A_AND_B)

   % Counts of each group not A and not B
   N_NOT_A = cellfun(@(A) sum(tbl.(groupvar) ~= A), groupA);
   N_NOT_B = cellfun(@(B) sum(tbl.(groupvar) ~= B), groupB);

   % Counts of A and not B, and not A and B
   N_A_AND_NOT_B = cell2mat( ...
      arrayfun(@(A) ...
      arrayfun(@(B) sum(tbl.(groupvar) == A & tbl{:, B}==false), groupB), groupA, ...
      'UniformOutput', false));

   N_NOT_A_AND_B = cell2mat( ...
      arrayfun(@(A) ...
      arrayfun(@(B) sum(tbl.(groupvar) == B & tbl{:, A}), groupA), groupB, ...
      'UniformOutput', false));

   % N_NOT_A_AND_B = cell2mat( ...
   %    arrayfun(@(A) ...
   %    arrayfun(@(B) sum(tbl.(groupvar) ~= A & tbl{:, B}), groupB), groupA, ...
   %    'UniformOutput', false));

   % Counts of each group not A and not B happening together
   N_NOT_A_AND_NOT_B = cell2mat( ...
      arrayfun(@(A) arrayfun(@(B) ...
      sum(tbl.(groupvar) ~= A & tbl{:, B}==false), groupB), groupA, ...
      'UniformOutput', false));

   % phi coeff
   phi = (N_A_AND_B .* N_NOT_A_AND_NOT_B - N_A_AND_NOT_B .* N_NOT_A_AND_B) ...
      ./ sqrt(N_A .* N_NOT_A .* N_B .* N_NOT_B);

end
