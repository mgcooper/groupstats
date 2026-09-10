function results = bootmediandiff(data, opts)
   %BOOTMEDIANDIFF Bootstrap the signed median difference against a reference.
   %
   %  RESULTS = BOOTMEDIANDIFF(DATA)
   %  RESULTS = BOOTMEDIANDIFF(DATA, NumBootstrap=N, Alpha=A, NumDraws=D)
   %
   % Description
   %  DATA is a cell array of numeric vectors. The first is the reference.
   %  For every other vector the function draws NumBootstrap resamples of it
   %  and of the reference and takes the median of each resample. It then
   %  quantiles the signed difference, other minus reference. The sign is kept: a
   %  positive MedianDiff means the other sample's median is larger. An
   %  absolute difference here would make CILower positive for identical
   %  samples, so H would be true every time.
   %
   %  NumDraws sets how many values each resample draws: one scalar for
   %  every sample, or one value per sample. The default is each sample's
   %  own length.
   %
   % Outputs
   %  RESULTS is a struct with one column per comparison in every field but
   %  the first:
   %   BootMedians  NumBootstrap-by-numel(DATA) bootstrap medians, the
   %                reference in column 1.
   %   Differences  NumBootstrap-by-(numel(DATA) - 1) signed differences.
   %   MedianDiff   the median of each column of Differences.
   %   CILower      the Alpha/2 quantile of each column.
   %   CIUpper      the 1 - Alpha/2 quantile of each column.
   %   H            true when the interval excludes zero.
   %
   % Errors
   %  groupstats:bootmediandiff:emptySample - a sample holds no values.
   %  groupstats:bootmediandiff:numDrawsMismatch - NumDraws is neither a
   %  scalar nor one value per sample.
   %
   % Dependencies
   %  quantile, from the Statistics and Machine Learning Toolbox.
   %
   % See also: groupstats.groupcompare, bootci

   arguments
      data (1, :) cell {mustBeNonempty}
      opts.NumBootstrap (1, 1) double {mustBeInteger, mustBePositive} = 10000
      opts.Alpha (1, 1) double ...
         {mustBeInRange(opts.Alpha, 0, 1, "exclusive")} = 0.05
      opts.NumDraws (1, :) double {mustBeInteger, mustBePositive} = ...
         double.empty()
   end

   % A resample of nothing has no median, so say which sample is empty.
   nsamples = cellfun(@numel, data);
   if any(nsamples == 0)
      error('groupstats:bootmediandiff:emptySample', ...
         'Sample %d holds no values. Every sample needs data to resample.', ...
         find(nsamples == 0, 1))
   end

   % One draw count per sample: the sample's own length, one scalar for
   % all, or one value each.
   if isempty(opts.NumDraws)
      ndraws = nsamples;
   elseif isscalar(opts.NumDraws)
      ndraws = repmat(opts.NumDraws, size(nsamples));
   elseif numel(opts.NumDraws) == numel(data)
      ndraws = opts.NumDraws;
   else
      error('groupstats:bootmediandiff:numDrawsMismatch', ...
         'NumDraws holds %d values for %d samples. Give one, or one each.', ...
         numel(opts.NumDraws), numel(data))
   end

   % One index matrix per sample, NumBootstrap rows of ndraws columns, so
   % the medians come from one call rather than one call per resample.
   nboot = opts.NumBootstrap;
   bootmedians = zeros(nboot, numel(data));
   for m = 1:numel(data)
      sample = data{m}(:);
      idx = randi(nsamples(m), nboot, ndraws(m));
      bootmedians(:, m) = median(sample(idx), 2);
   end

   % Signed differences, other minus reference, quantiled as they are.
   differences = bootmedians(:, 2:end) - bootmedians(:, 1);
   results.BootMedians = bootmedians;
   results.Differences = differences;
   results.MedianDiff = median(differences, 1);
   results.CILower = quantile(differences, opts.Alpha / 2, 1);
   results.CIUpper = quantile(differences, 1 - opts.Alpha / 2, 1);
   results.H = results.CILower > 0 | results.CIUpper < 0;
end
