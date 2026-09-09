function names = comparetest()
   %COMPARETEST Tests groupcompare can run.
   %
   %  names = groupstats.namelists.comparetest()
   %
   % Description
   %  Returns the values the Test option of groupcompare accepts:
   %
   %    ranksum     - the two-sample rank-sum test against the reference
   %                  data. The default.
   %    signrank    - the one-sample sign-rank test of each group against
   %                  the reference median.
   %    permutation - the cluster-based permutation test permutest runs on
   %                  the two samples.
   %
   % See also: groupstats.groupcompare, ranksum, signrank

   names = [
      "ranksum"
      "signrank"
      "permutation"
      ];
end
