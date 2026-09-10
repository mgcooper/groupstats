function config(varargin)
   %CONFIG Project configuration hook.
   %
   % setupfile.m runs every m-file in userhooks/ when the project opens.
   %
   % Note, use setenv here, setpref in Setup

   % Set environment variables
   % setenv(...)

   % Report any file the package calls but does not ship. The scan reads
   % the toolbox folder, so nothing here can drift from it. This hook calls
   % nothing outside the package, so it runs on a clone with no matfunclib.
   groupstats.internal.checkdependencies();
end
