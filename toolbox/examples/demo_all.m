function demo_all(varargin)
   %DEMO_ALL Run every groupstats demo, for a visual check of the toolbox.
   %
   %  demo_all()          Run every demo and leave the figures open.
   %  demo_all("-close")  Run every demo and close the figures after each one.
   %                      Use this to check that every demo runs clean.
   %
   % Description
   %  The chart demos are the ones worth looking at. demo_barchartcats,
   %  demo_boxchartcats, demo_scatter, and demo_histogram each open one figure
   %  per option, so the effect of every option is visible side by side. The
   %  groupsummary, groupcompare, groupmap, and groupbayes demos print tables
   %  rather than draw figures (demo_groupcompare draws one histogram.
   %
   % See also: groupstats.barchartcats, groupstats.boxchartcats,
   % groupstats.scatter, groupstats.histogram

   arguments (Repeating)
      varargin
   end

   % Closing between demos keeps the figure count manageable when the point is
   % to confirm every demo runs rather than to look at the output.
   doclose = any(strcmp(string(varargin), "-close"));

   % The chart demos come first, because they produce figures.
   demos = [ ...
      "demo_barchartcats", ...
      "demo_boxchartcats", ...
      "demo_scatter", ...
      "demo_histogram", ...
      "demo_groupsummary", ...
      "demo_groupcompare", ...
      "demo_groupmap", ...
      "demo_groupbayes", ...
      "demo_bayes", ...
      "demo_pairwise_bayes"];

   % Run each demo in the base workspace. The demos are scripts, so calling
   % one from this function would run it in the function's workspace,
   % where its variables could overwrite the loop's own (n, demos, doclose).
   for n = 1:numel(demos)
      fprintf('\n=== %s ===\n', demos(n));
      evalin('base', demos(n));

      if doclose
         close all force
      end
   end

   fprintf('\nRan %d demos.\n', numel(demos));
end
