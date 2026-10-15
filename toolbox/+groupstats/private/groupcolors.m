function colors = groupcolors(n)
   %GROUPCOLORS Palette colors for N color groups, one row per group.
   %
   %  COLORS = GROUPCOLORS(N)
   %
   % COLORS is an N-by-3 array of RGB triplets. Row k colors the k-th color
   % group in every chart of the family, so one group has one color across
   % the charts. The rows come from defaultcolors, which holds 21 colors.
   % The 22nd group starts over at the first color.
   %
   % See also: defaultcolors, groupstats.barchartcats,
   % groupstats.boxchartcats, groupstats.histogram, groupstats.scatter

   arguments
      n (1, 1) double {mustBeInteger, mustBeNonnegative}
   end

   % defaultcolors errors for more rows than it holds, so read the whole
   % palette and repeat its rows.
   palette = defaultcolors();
   colors = palette(mod((1:n) - 1, size(palette, 1)) + 1, :);
end
