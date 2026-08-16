function config(varargin)
   %CONFIG Project configuration hook.
   %
   % setupfile.m runs every m-file in userhooks/ when the project opens.
   %
   % Note, use setenv here, setpref in Setup

   % Set environment variables
   % setenv(...)

   % Report the functions groupstats calls but does not ship. The inventory
   % lives in checkdependencies, so read it from there rather than keeping a
   % second copy that drifts.
   groupstats.internal.checkdependencies();

   % withwarnoff is not on that inventory, because a function in
   % +groupstats/private is reachable from +internal. This file cannot reach
   % it, and the call below needs it, so check it separately.
   groupstats.internal.checkdependencies("withwarnoff");

   % Temporarily turn off warnings about paths not already being on the path.
   % The semicolon keeps the returned cleanup object from printing when the
   % project opens.
   withwarnoff('MATLAB:rmpath:DirNotFound');

   % Detect if this file is being called by menv/mproject
   if ismember(mcallername(), {'workon', 'configureproject', 'setupfile'})

   end

   % This is true if running in desktop. Use it to suppress interactions with
   % editor such as opening or closing project files
   if usejava('desktop')

   end
end
