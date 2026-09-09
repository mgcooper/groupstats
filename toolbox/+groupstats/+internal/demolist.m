function files = demolist(names)
   %DEMOLIST The demo files makedocs publishes.
   %
   %  files = groupstats.internal.demolist()
   %  files = groupstats.internal.demolist(names)
   %
   % Description
   %  Returns the full path of every examples/demo_*.m file other than
   %  demo_all, the runner, as a string column. With NAMES, returns the
   %  files those names select, in folder order; a name that matches no
   %  file selects nothing.
   %
   % See also: groupstats.internal.makedocs, demo_all

   arguments
      names (1, :) string = string.empty()
   end

   % The runner is not a demo page; it runs the others.
   demos = dir(fullfile(toolboxpath(), 'examples', 'demo_*.m'));
   demos = demos(~strcmp({demos.name}, 'demo_all.m'));

   % An empty list means every demo, the docs task's case.
   if ~isempty(names)
      demos = demos(ismember(string(erase({demos.name}, ".m")), names));
   end

   files = string(fullfile({demos.folder}, {demos.name}));
   files = files(:);
end
