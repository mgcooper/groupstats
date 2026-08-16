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
   %  groupbayes and groupmap demos print tables rather than draw.
   %
   %  Run one demo by name to look at it on its own, e.g. demo_barchartcats.
   %
   % See also: groupstats.barchartcats, groupstats.boxchartcats,
   % groupstats.scatter, groupstats.histogram

   arguments (Repeating)
      varargin
   end

   % Closing between demos keeps the figure count manageable when the point is
   % to confirm every demo runs rather than to look at the output.
   doclose = any(strcmp(string(varargin), "-close"));

   % The chart demos come first, because they are the ones to look at.
   demos = [ ...
      "demo_barchartcats", ...
      "demo_boxchartcats", ...
      "demo_scatter", ...
      "demo_histogram", ...
      "demo_groupmap", ...
      "demo_groupbayes", ...
      "demo_bayes", ...
      "demo_pairwise_bayes", ...
      "demo_groupbayes_counts"];

   % Run each demo in the base workspace. They are scripts, so calling one
   % from here would share this function's workspace, and demo_pairwise_bayes
   % opens with clearvars, which would wipe the loop state.
   for n = 1:numel(demos)
      fprintf('\n=== %s ===\n', demos(n));
      evalin('base', demos(n));

      if doclose
         close all force
      end
   end

   fprintf('\nRan %d demos.\n', numel(demos));
end
