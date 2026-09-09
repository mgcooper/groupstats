function missing = checkdependencies(required, opts)
   %CHECKDEPENDENCIES Report files groupstats needs but does not ship.
   %
   %  missing = groupstats.internal.checkdependencies()
   %  missing = groupstats.internal.checkdependencies(required)
   %  missing = groupstats.internal.checkdependencies(_, ToolboxFolder=folder)
   %
   % Description
   %  With no argument, scans every .m file under the toolbox folder with
   %  getRequiredFiles, and every .mlx live script there with
   %  requiredFilesAndProducts, and returns the files they call that lie
   %  outside the toolbox folder, as full paths, minus MATLAB's own files
   %  under matlabroot, together with any copy toolbox/vendored.txt names
   %  that is not on disk. An empty result means the package is self-contained:
   %  what it calls, it ships. The check task asserts that, and the
   %  dependencies task vendors what is missing. The scan is static, so it
   %  lists a file only when it resolves on the current path; on a path
   %  with no matfunclib the scan cannot see the names it lacks, and the
   %  clean-path install proof in the release validation covers that case.
   %
   %  With REQUIRED, a list of function names, returns the names no file on
   %  the MATLAB path defines. That form checks names a scan cannot reach,
   %  such as a function userhooks/config.m calls.
   %
   %  Either form warns when the result is not empty. ToolboxFolder names
   %  the toolbox folder to scan; the default is the one this file ships
   %  in, and a test names a scratch tree.
   %
   % Errors
   %  groupstats:checkdependencies:missingDependencies - a warning, not an
   %  error. Listing what is missing at project open beats a chart failing
   %  later with an unrecognized-function error.
   %
   % See also: groupstats.internal.installRequiredFiles, buildfile

   arguments
      required (:, 1) string = string.empty()
      % "" means the toolbox folder this file ships in, resolved below.
      opts.ToolboxFolder (1, 1) string = ""
   end

   if isempty(required)
      % The toolbox folder is the parent of the +groupstats folder, and
      % this file sits in +groupstats/+internal.
      toolboxfolder = opts.ToolboxFolder;
      if strlength(toolboxfolder) == 0
         toolboxfolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
      end
      mustBeFolder(toolboxfolder)

      % The scans return absolute paths, so a relative folder such as
      % "toolbox" must be absolute for the containment tests below. cd
      % resolves it the way MATLAB does, and the cleanup object puts the
      % working folder back.
      job = withcd(toolboxfolder);
      toolboxfolder = string(pwd);
      delete(job)

      % Files under matlabroot are MATLAB's own, such as
      % toolbox/local/userpath.m, which the scan lists because MATLAB
      % counts that folder as user-editable. They are not dependencies.
      found = getRequiredFiles(toolboxfolder, "referenceList", toolboxfolder);
      missing = found.missingFiles(:);

      % getRequiredFiles lists .m files only. The shipped live scripts
      % call the toolbox too, so scan them here and keep what they reach
      % outside the toolbox folder.
      scripts = dir(fullfile(toolboxfolder, "**", "*.mlx"));
      if ~isempty(scripts)
         scripts = fullfile(string({scripts.folder}), string({scripts.name}));
         reached = string(matlab.codetools.requiredFilesAndProducts( ...
            cellstr(scripts)))';
         missing = [missing; reached(~undersource(fileparts(reached), ...
            toolboxfolder))];
      end

      missing = unique(missing(~undersource(fileparts(missing), matlabroot)));

      % A listed copy that was deleted is a missing file the scan cannot
      % see when the source checkout is off the path.
      listed = groupstats.internal.vendoredfiles(toolboxfolder);
      missing = [missing; listed(~isfile(listed))];
      what = "files";
      advice = "Run buildtool dependencies to vendor them.";
   else
      % which returns an empty char for a name no file on the path defines.
      % A name checked this way is one the vendoring task cannot reach,
      % such as a hook's call, so the advice is to add its library.
      missing = required(arrayfun(@(fn) isempty(which(fn)), required));
      what = "functions";
      advice = "Add the library that defines them to the path.";
   end

   % Warn rather than error. A missing name stops one function, not the
   % whole toolbox, and the project still has to open.
   if ~isempty(missing)
      warning('groupstats:checkdependencies:missingDependencies', ...
         'These %s are not shipped or not on the path: %s. %s', what, ...
         strjoin(missing, ', '), advice)
   end
end
