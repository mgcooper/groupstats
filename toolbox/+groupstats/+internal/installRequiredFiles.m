function [requirementsList, urlList, failedList, skippedList] = ...
      installRequiredFiles(requiredFiles, kwargs)
   %INSTALLREQUIREDFILES Install required files from GitHub or a local checkout.
   %
   %  INSTALLREQUIREDFILES(REQUIREDFILES)
   %  INSTALLREQUIREDFILES(PROJECTPATH=PATHNAME)
   %  INSTALLREQUIREDFILES(REQUIREMENTSFILE=FILENAME)
   %
   %  INSTALLREQUIREDFILES(_, INSTALLPATH=PATHNAME)
   %  INSTALLREQUIREDFILES(_, LOCALSOURCEPATH=PATHNAME)
   %  INSTALLREQUIREDFILES(_, IGNOREFOLDER=FOLDERNAME)
   %  INSTALLREQUIREDFILES(_, REFERENCELIST=PATHNAME)
   %  INSTALLREQUIREDFILES(_, REMOTEREPONAME=REPONAME)
   %  INSTALLREQUIREDFILES(_, REMOTEBRANCH=BRANCHNAME)
   %  INSTALLREQUIREDFILES(_, GITHUBUSERNAME=USERNAME)
   %  INSTALLREQUIREDFILES(_, SOURCE="local")
   %  INSTALLREQUIREDFILES(_, DRYRUN=TRUE)
   %
   % Description
   %
   %  The use case for this function is to install a list of required files
   %  from GitHub, or from a local checkout of the repository that holds
   %  them. The list could be shipped with a toolbox, and third party
   %  users run an install script which reads the requirements list and installs
   %  them from GitHub. Alternatively, the toolbox maintainer can use this
   %  function to package the requirements with the toolbox, copying them
   %  from the checkout beside it with SOURCE="local".
   %
   % Input Arguments
   %
   %  The following arguments control what files get installed: Either a
   %  pre-existing list of requirements (REQUIREDFILES or REQUIREMENTSFILE), or
   %  a list of requirements generated internally by this function for a
   %  specific project folder (PROJECTPATH), optionally ignoring any
   %  requirements for files contained in IGNOREFOLDER.
   %
   %  REQUIREDFILES - (optional, positional) a list of required functions. If
   %  not provided or if empty, the requirements are read from
   %  REQUIREMENTSFILE when one is supplied; otherwise the requirements for
   %  all files in the PROJECTPATH folder are installed.
   %
   %  PROJECTPATH - (optional, name-value) a full path (scalar text) to a
   %  folder. Requirements for all files within this folder are generated and
   %  installed. In this bootstrapped-toolbox copy the default PROJECTPATH is
   %  the project root resolved by projectpath(), and the default install
   %  location is the "dependencies" subfolder of the toolbox folder resolved
   %  by toolboxpath(). Specify the optional INSTALLPATH argument to control
   %  where dependencies are installed.
   %
   %  REQUIREMENTSFILE - (optional, name-value) a full path to a file containing
   %  a list of required files. Two formats are supported: a .mat file
   %  containing a variable named "missingFiles" (preferred) or
   %  "requiredFiles" — the format GETREQUIREDFILES writes when called with
   %  SAVEREQUIREMENTSFILE=TRUE — or a plain-text file with one file name or
   %  path per line (blank lines and lines starting with # are ignored). If
   %  REQUIREDFILES is also supplied (non-empty), it takes precedence and
   %  REQUIREMENTSFILE is ignored.
   %
   %  NOTE: If none of the three arguments above are supplied, the default
   %  behavior installs the requirements of the project root resolved by
   %  projectpath() into the toolbox "dependencies" folder resolved by
   %  toolboxpath().
   %
   %  IGNOREFOLDER - A folder or array of folder names to be ignored when
   %  generating the list of requirements for the PROJECTPATH folder.
   %  IGNOREFOLDER should contain a single folder name or array of folder names
   %  which are subfolders of PROJECTPATH. Use this option to ignore a scratch/
   %  or testbed/ or sandbox/ or examples/ folder which is not under source
   %  control and is not distributed with the toolbox or project.
   %
   %  REFERENCELIST - (optional, name-value) a folder whose files count as
   %  satisfied, so they are never installed. The default is PROJECTPATH.
   %  Name a folder above PROJECTPATH to vendor the requirements of one
   %  subfolder while the rest of the toolbox counts as present.
   %
   %  These arguments control how the requirements are found and/or resolved:
   %
   %  LOCALSOURCEPATH - folder with local versions of the required files.
   %  REMOTEREPONAME - remote (Github) repo for the localSourcePath.
   %  REMOTEBRANCH - branch to use when downloading from the remote Github repo.
   %  GITHUBUSERNAME - GitHub username for the REMOTEREPONAME.
   %
   %  These arguments control if and where files are installed:
   %
   %  INSTALLPATH - full path to location where files are installed. The default
   %  value is a folder named "dependencies" in the toolbox folder.
   %  SOURCE - "remote" (default) downloads each file from the GitHub
   %  repository with websave, which needs GITHUBUSERNAME. "local" copies
   %  each file with copyfile from the working copy under LOCALSOURCEPATH,
   %  with no network and no GITHUBUSERNAME. A maintainer vendors a
   %  toolbox's requirements this way from the checkout beside it.
   %  DRYRUN - logical flag controlling whether files are installed. If true,
   %  nothing is downloaded; the resolved file and url lists are returned,
   %  and printed to the screen when no output is requested. The default
   %  value is false (files are installed).
   %
   % Output Arguments
   %
   %  REQUIREMENTSLIST - the file names installed, one per row. A file
   %  whose install failed is warned about and left out. With DRYRUN, the
   %  files that would be installed.
   %  URLLIST - the source of each file: its GitHub raw URL for
   %  SOURCE="remote", or its path under LOCALSOURCEPATH for SOURCE="local".
   %  FAILEDLIST - the file names whose install failed, one per row, so a
   %  caller can treat an incomplete install as an error.
   %  SKIPPEDLIST - the required file names that resolved nowhere under
   %  LOCALSOURCEPATH, or in several places, one per row. Each was warned
   %  about and left out. A MATLAB file under matlabroot is not listed.
   %
   % Resolving a file under LOCALSOURCEPATH
   %
   %  A required file whose resolved path lies under LOCALSOURCEPATH is used
   %  from there. One resolved elsewhere on the path, such as a copy in
   %  another library that shadows the LOCALSOURCEPATH copy, or one given as
   %  a bare name with no path, is looked up by name under LOCALSOURCEPATH.
   %  One match is used. A name with no match under LOCALSOURCEPATH is
   %  skipped, with a warning unless it is a MATLAB file under matlabroot,
   %  and a name with several matches is skipped with a warning that lists
   %  them.
   %
   % See also: getRequiredFiles

   arguments
      %%% The following arguments control what gets installed:
      requiredFiles (:, :) string {mustBeText} ...
         = []

      kwargs.requirementsFile (1, :) string {mustBeTextScalar} ...
         = ""

      kwargs.projectPath (1, :) string {mustBeFolder} ...
         = projectpath()

      kwargs.ignoreFolder (1, :) string ...
         = "testbed"

      % "" means projectPath; the default is resolved below, after
      % projectPath is known.
      kwargs.referenceList (1, :) string {mustBeTextScalar} ...
         = ""

      %%% The following arguments control how requirements are found:
      kwargs.localSourcePath (1, :) {mustBeFolder} ...
         = getenv('MATLAB_FUNCTION_PATH')

      kwargs.remoteRepoName (1, :) string {mustBeTextScalar} ...
         = "matfunclib"

      kwargs.remoteBranch (1, :) string {mustBeTextScalar} ...
         = "main"

      kwargs.GitHubUserName (1, :) string {mustBeTextScalar} ...
         = getenv('GITHUB_USER_NAME')

      %%% The following arguments control where and if files get installed:

      % installPath default is derived in parseargs (the toolbox
      % "dependencies" folder); the "" sentinel distinguishes "not supplied"
      % from an explicit path.
      kwargs.installPath (1, :) string {mustBeTextScalar} ...
         = ""

      % "remote" keeps the websave download; "local" copies the working
      % copy under localSourcePath.
      kwargs.Source (1, 1) string ...
         {mustBeMember(kwargs.Source, ["remote", "local"])} = "remote"

      kwargs.dryrun (1, 1) logical {mustBeNumericOrLogical} ...
         = false
   end

   [projectPath, ignoreFolder, localSourcePath, remoteSourcePath, ...
      requirementsFile, installPath] = parseargs(kwargs);

   % Remember current folder and go to folder for external dependencies.
   % The job cleanup object restores pwd: explicitly via the delete(job)
   % below on the normal path, or at scope exit if an error is thrown.
   job = withcd(projectPath);

   % Find the required files: an explicit list wins, then a requirements
   % file, then generation from the project folder.
   if all(isempty(requiredFiles))
      if strlength(requirementsFile) > 0
         requiredFiles = readRequirementsFile(requirementsFile);
      else
         % referenceList is the project itself unless the caller named a
         % folder: its files count as satisfied, independent of which
         % manager project is active.
         referenceList = kwargs.referenceList;
         if strlength(referenceList) == 0
            referenceList = projectPath;
         end
         requiredFiles = getRequiredFiles(projectPath, ...
            "ignoreList", ignoreFolder, "referenceList", referenceList);
         requiredFiles = requiredFiles.missingFiles;
      end
   end

   % Build the source list: a url per file for the remote files, and the
   % local path per file under localSourcePath.
   [requirementsList, urlList, localList, skippedList] = ...
      remoteDependencyList(requiredFiles, projectPath, localSourcePath, ...
      remoteSourcePath);

   % The second output names where each file came from, so a local install
   % reports the paths it copied.
   if kwargs.Source == "local"
      urlList = localList;
   end

   % Option to install the missing requirement locally
   fileList = installPath + filesep + requirementsList;
   failedList = strings(0, 1);
   if not(kwargs.dryrun)

      if ~isfolder(installPath)
         mkdir(installPath)
      end
      % A file landed when this call wrote it and a file is there
      % afterwards. A destination that existed before and survived a
      % failed overwrite is not this call's, so the existence test alone
      % would report it.
      landed = false(size(requirementsList));
      for n = 1:numel(requirementsList)
         wrote = false;
         try
            % copyfile and websave write into a folder of the destination
            % name, which would leave a nested copy nothing lists, so a
            % folder in the way is a failure before any write.
            assert(~isfolder(fileList(n)), ...
               'a folder is in the way at %s', fileList(n))

            % A local copy needs no network. copyfile keeps the source
            % file read-only when it is, so clear that on the copy.
            if kwargs.Source == "local"
               copyfile(localList(n), fileList(n), 'f');
               wrote = true;
               fileattrib(fileList(n), '+w');
            else
               websave(fileList(n), urlList(n));
               wrote = true;
            end
            landed(n) = isfile(fileList(n));
            reason = "no file at the destination";
         catch ME
            reason = ME.message;

            % A write that succeeded before a later step failed leaves a
            % file the caller is told did not land, so remove it.
            if wrote && isfile(fileList(n))
               delete(fileList(n))
            end
         end

         % The file test after the call catches a write that raised no
         % error and still left no file.
         if ~landed(n)
            warning('installRequiredFiles:installFailed', ...
               'Failed to install file: %s\nReason: %s', ...
               requirementsList(n), reason);
         end
      end

      % Report what landed, not what was planned: a file that failed was
      % warned about above and must not be listed as installed.
      failedList = reshape(requirementsList(~landed), [], 1);
      requirementsList = reshape(requirementsList(landed), [], 1);
      urlList = reshape(urlList(landed), [], 1);
   elseif nargout == 0
      % A dry run with no output requested is a report for the screen. A
      % caller that takes the lists reads them instead.
      fprintf(1, "\n Files will be installed to: \n %s \n", installPath)
      fprintf(1, "\n The following files will be installed: \n")
      disp(urlList)
   end

   % Restore the original working directory.
   delete(job)
end

%% Local Functions
function [projectPath, ignoreFolder, localSourcePath, ...
      remoteSourcePath, requirementsFile, installPath] = parseargs(kwargs)

   % Retrieve the Github user name. A local install never reads it, so
   % it is required for a remote install only.
   if isempty(kwargs.GitHubUserName) && kwargs.Source == "remote"
      error('Set "GitHubUserName" or environment variable "GITHUB_USER_NAME"')
   else
      GITHUB_USER_NAME = kwargs.GitHubUserName;
   end

   % Without a local source path, the user path stands in: it is where a
   % user's own functions live when no library checkout is named.
   if isempty(kwargs.localSourcePath)
      localSourcePath = userpath();
   else
      localSourcePath = kwargs.localSourcePath;
   end

   % The scan returns absolute paths, and the working folder changes to
   % projectPath before any of them is compared with localSourcePath, so a
   % relative localSourcePath must be absolute here. cd resolves it the
   % way MATLAB does, and the cleanup object puts the working folder back.
   % A trailing separator would survive into the relative paths erased
   % from each file's folder below, so it goes too.
   job = withcd(localSourcePath);
   localSourcePath = string(pwd);
   delete(job)
   localSourcePath = regexprep(localSourcePath, '[/\\]+$', '');

   if isempty(kwargs.remoteRepoName)
      error(['Set "remoteRepoName" to the GitHub repository ' ...
         'which hosts the required files'])
   else
      GITHUB_URL = 'https://raw.githubusercontent.com/';
      remoteSourcePath = strcat(GITHUB_URL, GITHUB_USER_NAME, '/', ...
         kwargs.remoteRepoName, '/', kwargs.remoteBranch);
   end

   % Pull out required args and remaining optional args
   projectPath = kwargs.projectPath;
   requirementsFile = kwargs.requirementsFile;

   % Derive the documented installPath default (the toolbox "dependencies"
   % folder) when the caller did not supply one. This bootstrapped-copy
   % default intentionally differs from the matfunclib canonical, which
   % derives it from PROJECTPATH.
   if strlength(kwargs.installPath) == 0
      installPath = fullfile(toolboxpath(), "dependencies");
   else
      installPath = kwargs.installPath;
   end

   % Full path to ignore folder
   ignoreFolder = fullfile(projectPath, kwargs.ignoreFolder);
end

function requiredFiles = readRequirementsFile(requirementsFile)
   %READREQUIREMENTSFILE Read a required-files list from a requirements file.
   %
   % Supports the .mat format written by getRequiredFiles
   % (saveRequirementsFile=true), preferring its "missingFiles" variable and
   % falling back to "requiredFiles", and plain text with one entry per line
   % (blank lines and #-comment lines ignored).

   if ~isfile(requirementsFile)
      error('installRequiredFiles:requirementsFileNotFound', ...
         'requirementsFile not found: %s', requirementsFile)
   end

   [~, ~, ext] = fileparts(requirementsFile);
   if strcmpi(ext, '.mat')
      vars = load(requirementsFile);
      if isfield(vars, 'missingFiles')
         requiredFiles = string(vars.missingFiles);
      elseif isfield(vars, 'requiredFiles')
         requiredFiles = string(vars.requiredFiles);
      else
         error('installRequiredFiles:badRequirementsFile', ...
            ['requirementsFile %s must contain a variable named ' ...
            '"missingFiles" or "requiredFiles"'], requirementsFile)
      end
   else
      % Plain text: one file per line; ignore blanks and # comments.
      requiredFiles = strtrim(readlines(requirementsFile));
      requiredFiles(requiredFiles == "") = [];
      requiredFiles(startsWith(requiredFiles, "#")) = [];
   end
   requiredFiles = reshape(requiredFiles, 1, []);
end

function [requirementsList, urlList, localList, skippedList] = ...
      remoteDependencyList(requiredFiles, projectPath, localsource, ...
      remotesource)
   %REMOTEDEPENDENCYLIST Get a list of remote url's to function dependencies.
   %
   % LOCALLIST holds each file's path under LOCALSOURCE, which is the
   % source of a local install and the basis of each url. SKIPPEDLIST
   % holds the names that resolved nowhere under LOCALSOURCE, or in
   % several places, other than MATLAB's own files.

   % This operates on one file at a time

   [requirementsList, urlList, localList, skippedList] = ...
      deal(strings(length(requiredFiles), 1));

   % For each dependency
   for ifile = 1:length(requiredFiles)

      % Get the file name with extension
      [requiredFilePath, requiredFileName, ext] = fileparts(requiredFiles{ifile});
      requiredFileName = strcat(requiredFileName, ext);

      if skipfile(requiredFileName, requiredFilePath, ...
            requirementsList, projectPath)
         continue
      end

      % If the required file exists in the local source repo, add it to the
      % requirementsList and build a full path to the remote file.
      %
      % Limitation: one source repository per call. A project whose
      % requirements live in several repositories needs one call per
      % repository, because the lookup below searches one localSourcePath.

      % A file resolved outside localsource, or given as a bare name, is
      % looked up by name under localsource, so a shadowing copy elsewhere
      % on the path does not hide the source repo's copy.
      originalPath = string(requiredFilePath);
      if ~undersource(requiredFilePath, localsource)
         requiredFilePath = findUnderSource(requiredFileName, ...
            requiredFilePath, localsource);
      end

      if ~undersource(requiredFilePath, localsource)
         % Not resolved under the source, and not MATLAB's own: the lookup
         % above warned, and the caller can read the name here.
         if ~undersource(originalPath, matlabroot)
            skippedList(ifile) = requiredFileName;
         end
      else

         % Add file names to list of external depencies
         requirementsList(ifile) = requiredFileName;
         localList(ifile) = fullfile(requiredFilePath, requiredFileName);

         % Get the subfolder path relative to the top-level source repo.
         % A file at the repo root has no subfolder, so its url has no
         % middle segment.
         relativePath = erase(requiredFilePath, localsource);
         relativePath = strrep(relativePath, filesep , '/');
         relativePath = regexprep(relativePath, '^/', '');

         % Use '/' not fullfile b/c fullfile is platform specific
         if strlength(relativePath) == 0
            urlList(ifile) = remotesource + '/' + requirementsList(ifile);
         else
            urlList(ifile) = remotesource + '/' + relativePath + '/' ...
               + requirementsList(ifile);
         end
      end
   end
   % Keep the outputs columns, including the empty ones: deleting every
   % element of a column leaves a 1-by-0 otherwise.
   requirementsList = reshape(requirementsList(requirementsList ~= ""), [], 1);
   urlList = reshape(urlList(urlList ~= ""), [], 1);
   localList = reshape(localList(localList ~= ""), [], 1);
   skippedList = reshape(skippedList(skippedList ~= ""), [], 1);
   assert(all(endsWith(urlList, requirementsList)))
end

function folder = findUnderSource(requiredFileName, resolvedPath, localsource)
   %FINDUNDERSOURCE Find one file by name under the local source folder.
   %
   % Returns the folder holding the one match, or "" when there is no match
   % or more than one. A MATLAB file under matlabroot, such as userpath.m,
   % is skipped with no warning: it is not a dependency to vendor.

   arguments
      requiredFileName (1, 1) string
      resolvedPath (1, 1) string
      localsource (1, 1) string
   end

   folder = "";
   if undersource(resolvedPath, matlabroot)
      return
   end

   found = dir(fullfile(localsource, '**', requiredFileName));
   found = found(~[found.isdir]);

   if isscalar(found)
      folder = string(found.folder);
   elseif isempty(found)
      warning('installRequiredFiles:notUnderLocalSource', ...
         '%s is not under localSourcePath %s, so it is skipped.', ...
         requiredFileName, localsource)
   else
      warning('installRequiredFiles:severalUnderLocalSource', ...
         ['%s has %d copies under localSourcePath, so it is skipped: ' ...
         '%s'], requiredFileName, numel(found), ...
         strjoin(fullfile(string({found.folder}), requiredFileName), ', '))
   end
end

function tf = skipfile(requiredFileName, requiredFilePath, ...
      requirementsList, projectPath)

   [~, ~, ext] = fileparts(requiredFileName);

   % skip this file if it is the target function, a mex file, already found,
   % or already satisfied b/c it exists in the projectPath. The last test
   % is on folder boundaries, so a source folder whose name starts with
   % the project folder's name does not count as inside it.
   tf = ...
      strcmp(ext, '.mex') | ...
      any(strcmpi(requiredFileName, requirementsList)) | ...
      undersource(requiredFilePath, projectPath);
end
