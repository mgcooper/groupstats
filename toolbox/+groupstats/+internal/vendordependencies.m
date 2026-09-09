function [installed, sources] = vendordependencies(toolboxfolder, source, opts)
   %VENDORDEPENDENCIES Copy the files a toolbox calls from a local checkout.
   %
   %  [installed, sources] = groupstats.internal.vendordependencies(toolboxfolder)
   %  [installed, sources] = groupstats.internal.vendordependencies(toolboxfolder, source)
   %  [___] = groupstats.internal.vendordependencies(_, Explicit=names)
   %
   % Description
   %  Copies each file the toolbox under TOOLBOXFOLDER calls, and does not
   %  ship, from the checkout SOURCE into the private folder its callers
   %  reach, with no network:
   %
   %   - what the namespace functions in <namespace> call, into
   %     <namespace>/private/;
   %   - each name in Explicit, into <namespace>/+internal/, for a file a
   %     static scan cannot see, such as the tablecompletions that
   %     functionSignatures.json calls from the base workspace;
   %   - what the maintainer tools in <namespace>/+internal call, including
   %     what the Explicit files need, into <namespace>/+internal/private/.
   %
   %  A third-party file under SOURCE sits in a folder of its own with its
   %  license.txt beside it (the File Exchange layout). That license is
   %  copied too, as <name>_LICENSE.txt next to the copy, and listed, so the
   %  package ships every license it must. A license.txt in the root of
   %  SOURCE is the checkout's own and is not copied.
   %
   %  <namespace> is the one +folder under TOOLBOXFOLDER. Then the function
   %  writes TOOLBOXFOLDER/vendored.txt, the list groupstats.internal.vendoredfiles
   %  reads and the check task excludes from lint. A copy that appears twice
   %  is listed twice. Each line records the copy's source relative to
   %  SOURCE, so the list reads the same on every machine.
   %
   %  A private folder is reachable from the functions in its parent
   %  folder only. A file in examples/ or in a sub-package such as
   %  +namelists or +test cannot reach either private folder. Neither can
   %  a file anywhere else outside the namespace functions and +internal.
   %  A call from there into SOURCE is therefore an error,
   %  groupstats:vendordependencies:unreachableCaller. The fix is to inline
   %  the call or move the caller.
   %
   %  The run is one transaction. It first moves every copy the existing
   %  list names out of the toolbox, so a copy a change stopped needing
   %  goes. Every copy is then refreshed from SOURCE. If any step fails,
   %  including a copy that did not land, the copies this run made go and
   %  the moved copies come back. The list stays as it was, so a failed run
   %  leaves the toolbox as it found it. The folders under SOURCE are on
   %  the path during the scan. The scan therefore resolves the names
   %  whether or not the checkout is on the caller's path. The path is
   %  restored afterwards.
   %
   %  SOURCE defaults to the MATLAB_FUNCTION_PATH environment variable, and
   %  without it to the folder two levels above dealout.m, which every
   %  matfunclib checkout holds at functools/dealout.m.
   %
   %  INSTALLED holds each copy's path under TOOLBOXFOLDER; SOURCES the
   %  absolute path of the file it was copied from.
   %
   % Errors
   %  groupstats:vendordependencies:unresolved - a required file, or a
   %  name in Explicit, has no one copy under SOURCE, so it cannot be
   %  vendored.
   %  groupstats:vendordependencies:collision - a destination already
   %  holds a file of a required name that the list does not name.
   %  groupstats:vendordependencies:installFailed - a required copy did
   %  not land, so the run rolled back.
   %  groupstats:vendordependencies:unreachableCaller - a file outside the
   %  namespace functions and +internal calls a file under SOURCE.
   %  groupstats:vendordependencies:noSource - no SOURCE was given,
   %  MATLAB_FUNCTION_PATH is unset, and dealout.m is not on the path.
   %  groupstats:vendordependencies:oneNamespace - TOOLBOXFOLDER does not
   %  hold exactly one +folder.
   %
   % See also: groupstats.internal.installRequiredFiles,
   % groupstats.internal.vendoredfiles, buildfile

   arguments
      toolboxfolder (1, 1) string {mustBeFolder}
      source (1, 1) string {mustBeFolder} = defaultsource()
      opts.Explicit (1, :) string = "tablecompletions.m"
   end

   % The scan returns absolute paths, and the folder-boundary tests below
   % compare them with source, so a relative source such as ../matfunclib
   % must be absolute first. cd resolves it the way MATLAB does, and the
   % cleanup object puts the working folder back.
   job = withcd(source);
   source = string(pwd);
   delete(job)
   job = withcd(toolboxfolder);
   toolboxfolder = string(pwd);
   delete(job)

   % The namespace folder is the one +folder under the toolbox folder.
   found = dir(fullfile(toolboxfolder, "+*"));
   found = found([found.isdir]);
   if ~isscalar(found)
      error('groupstats:vendordependencies:oneNamespace', ...
         'Expected one +folder under %s, found %d.', toolboxfolder, ...
         numel(found))
   end
   namespace = fullfile(toolboxfolder, found.name);
   internal = fullfile(namespace, "+internal");

   % Put the checkout on the path for the scan, which resolves names
   % through the path, and put the caller's path back afterwards. Folders
   % under .git are not code.
   saved = path();
   restore = onCleanup(@() path(saved));
   folders = split(string(genpath(source)), pathsep);
   folders = folders(strlength(folders) > 0 & ~contains(folders, ".git"));
   addpath(folders{:})

   % Everything from here to the list write is one transaction. The
   % previous copies move to a staging folder, so the scan sees every
   % requirement as missing. A copy nothing calls any more is then not
   % left behind. On any failure the copies this run made go, the staged
   % copies come back, and the list stays as it was.
   previous = groupstats.internal.vendoredfiles(toolboxfolder);
   previous = previous(isfile(previous));
   stage = string(tempname());
   staged = fullfile(stage, extractAfter(previous, toolboxfolder + filesep));
   moved = false(size(previous));
   created = strings(0, 1);
   cleanup = onCleanup(@() removeFolder(stage));

   try
      for n = 1:numel(previous)
         makeFolder(fileparts(staged(n)))
         movefile(previous(n), staged(n))
         moved(n) = true;
      end

      % With the previous copies gone, a call from a folder that reaches
      % no private folder resolves under source. It is caught here, before
      % any copy would hide it behind the whole-toolbox reference.
      rejectUnreachableCallers(toolboxfolder, namespace, source)

      % The namespace functions reach <namespace>/private. The scan covers
      % the whole toolbox minus +internal; the callers outside the
      % namespace functions were rejected above, so what it finds is
      % theirs.
      [names1, from1] = vendorInto(fullfile(namespace, "private"), ...
         projectPath = toolboxfolder, ...
         ignoreFolder = fullfile(found.name, "+internal"), ...
         localSourcePath = source);
      created = [created; fullfile(namespace, "private", names1(:))];

      % A live script directly in the namespace reaches the same private
      % folder, and the .m scan does not read it. What it reaches under
      % the source is therefore vendored by name.
      [names1b, from1b] = vendorInto(fullfile(namespace, "private"), ...
         livescriptRequirements(namespace, source, names1), ...
         projectPath = toolboxfolder, localSourcePath = source);
      names1 = [names1; names1b];
      from1 = [from1; from1b];
      created = [created; fullfile(namespace, "private", names1b(:))];

      % The explicit names are package functions, not private ones,
      % because what calls them cannot reach a private folder.
      names2 = strings(0, 1);
      from2 = strings(0, 1);
      if ~isempty(opts.Explicit)
         [names2, from2] = vendorInto(internal, opts.Explicit, ...
            projectPath = toolboxfolder, localSourcePath = source);
         created = [created; fullfile(internal, names2(:))];
      end

      % +internal reaches its own private folder only. The rest of the
      % toolbox counts as present, so a package function is never copied.
      [names3, from3] = vendorInto(fullfile(internal, "private"), ...
         projectPath = internal, referenceList = toolboxfolder, ...
         ignoreFolder = "private", localSourcePath = source);
      created = [created; fullfile(internal, "private", names3(:))];

      % The same for a live script directly in +internal.
      [names3b, from3b] = vendorInto(fullfile(internal, "private"), ...
         livescriptRequirements(internal, source, names3), ...
         projectPath = toolboxfolder, localSourcePath = source);
      names3 = [names3; names3b];
      from3 = [from3; from3b];
      created = [created; fullfile(internal, "private", names3b(:))];

      installed = [
         fullfile(found.name, "private", names1(:))
         fullfile(found.name, "+internal", names2(:))
         fullfile(found.name, "+internal", "private", names3(:))
         ];
      sources = [from1(:); from2(:); from3(:)];

      % A third-party file ships with its license. A license.txt beside a
      % copied file, in a folder of its own under the source, is copied
      % as <name>_LICENSE.txt next to the copy. It is listed like the
      % copy too.
      [licenses, licensesources] = vendorLicenses(toolboxfolder, ...
         installed, sources, source);
      created = [created; fullfile(toolboxfolder, licenses)];
      installed = [installed; licenses];
      sources = [sources; licensesources];

      % The list records where each copy came from relative to the
      % checkout, so it reads the same on every machine.
      writeVendoredList(toolboxfolder, installed, ...
         extractAfter(sources, source + filesep))
   catch failure
      % Undo this run: remove what it copied, then put back what it
      % moved. A staged copy that did not move is still in place.
      created = cellstr(created(isfile(created)));
      if ~isempty(created)
         delete(created{:})
      end
      for n = find(moved(:))'
         makeFolder(fileparts(previous(n)))
         movefile(staged(n), previous(n))
      end
      rethrow(failure)
   end
end

function names = livescriptRequirements(folder, source, already)
   %LIVESCRIPTREQUIREMENTS Names under SOURCE the live scripts in FOLDER reach.
   %
   % getRequiredFiles reads .m files only. requiredFilesAndProducts reads
   % a live script. This finds the files under SOURCE that the .mlx files
   % directly in FOLDER reach. Names ALREADY vendored for that folder are
   % excluded, and the rest are returned as full paths for an explicit
   % install. A full path needs no lookup by name, so a name that exists
   % twice under SOURCE still resolves. No live script means no names.

   arguments
      folder (1, 1) string
      source (1, 1) string
      already (:, 1) string
   end

   names = strings(0, 1);
   scripts = dir(fullfile(folder, "*.mlx"));
   if isempty(scripts)
      return
   end

   scripts = fullfile(string({scripts.folder}), string({scripts.name}));
   reached = string(matlab.codetools.requiredFilesAndProducts( ...
      cellstr(scripts)))';
   reached = unique(reached(undersource(fileparts(reached), source)));
   [~, base, ext] = fileparts(reached);
   names = reached(~ismember(base + ext, already));
end

function [names, from] = vendorInto(installPath, varargin)
   %VENDORINTO Copy the requirements one scan finds into one folder.
   %
   % A dry run first names the files the scan will copy, and the names it
   % could not resolve under the source, which are fatal. The previous
   % copies are staged away. A destination that already holds a file of a
   % planned name therefore holds a file the list does not name. That is a
   % collision: overwriting it would lose a file nothing could restore. A
   % scan never plans a name a reachable private copy already satisfies.
   % The case arises for an explicit name, or for a copy its caller cannot
   % reach. Then the copy runs. A copy that did not land is fatal:
   % installRequiredFiles warns and continues, but a missing copy leaves
   % the package incomplete. So the transaction rolls back.

   arguments
      installPath (1, 1) string
   end
   arguments (Repeating)
      varargin
   end

   % An explicit list that is empty means nothing to do; the scan form
   % has no first positional argument.
   if ~isempty(varargin) && isstring(varargin{1}) && isempty(varargin{1})
      names = strings(0, 1);
      from = strings(0, 1);
      return
   end

   [planned, ~, ~, skipped] = groupstats.internal.installRequiredFiles( ...
      varargin{:}, installPath = installPath, Source = "local", ...
      dryrun = true);

   % A required file with no one copy under the source cannot be
   % vendored. A list written without it would describe an incomplete
   % package, so the run stops here, before any write.
   if ~isempty(skipped)
      error('groupstats:vendordependencies:unresolved', ...
         ['No one copy of %s under the source. Every required file ' ...
         'must resolve there before the list is written.'], ...
         strjoin(skipped, ', '))
   end

   collide = planned(isfile(fullfile(installPath, planned)));
   if ~isempty(collide)
      error('groupstats:vendordependencies:collision', ...
         ['%s already holds %s, and vendored.txt does not name it. ' ...
         'Rename or remove that file before vendoring.'], installPath, ...
         strjoin(collide, ', '))
   end

   [names, from, failed] = groupstats.internal.installRequiredFiles( ...
      varargin{:}, installPath = installPath, Source = "local");
   if ~isempty(failed)
      % This phase removes what it wrote before it reports, so the
      % caller's rollback has nothing of this phase left to find.
      landed = cellstr(fullfile(installPath, names));
      if ~isempty(landed)
         delete(landed{:})
      end
      error('groupstats:vendordependencies:installFailed', ...
         'These files did not land in %s: %s.', installPath, ...
         strjoin(failed, ', '))
   end
end

function makeFolder(folder)
   %MAKEFOLDER Create a folder unless it exists.

   arguments
      folder (1, 1) string
   end

   if ~isfolder(folder)
      mkdir(folder)
   end
end

function removeFolder(folder)
   %REMOVEFOLDER Remove a staging folder and everything in it, if present.

   arguments
      folder (1, 1) string
   end

   if isfolder(folder)
      rmdir(folder, 's')
   end
end

function rejectUnreachableCallers(toolboxfolder, namespace, source)
   %REJECTUNREACHABLECALLERS Error when an unreachable folder calls source.
   %
   % The match is on folder boundaries, so a folder whose name merely
   % starts with the source folder's name does not count as the source.
   %
   % The files scanned are the files directly under the toolbox folder,
   % plus every folder under it except the namespace folder itself. They
   % also include every folder under the namespace other than +internal
   % and private. A sub-package and an ordinary folder both count. Only
   % the direct calls
   % of each file count (the toponly flag). A demo that calls a namespace
   % function reaches, through it, every private helper that function
   % calls, and those are not the demo's own calls.

   arguments
      toolboxfolder (1, 1) string
      namespace (1, 1) string
      source (1, 1) string
   end

   folders = dir(toolboxfolder);
   folders = folders([folders.isdir] & ~startsWith({folders.name}, "."));
   folders = fullfile(toolboxfolder, string({folders.name}));
   folders = folders(folders ~= namespace);

   subpackages = dir(namespace);
   subpackages = subpackages([subpackages.isdir] ...
      & ~startsWith({subpackages.name}, ".") ...
      & ~ismember({subpackages.name}, ["+internal", "private"]));
   subpackages = fullfile(namespace, string({subpackages.name}));

   % The toolbox root holds files too, such as gettingStarted.m, and no
   % folder loop reaches them, so they form the first set.
   sets = [{[dir(fullfile(toolboxfolder, "*.m")); ...
      dir(fullfile(toolboxfolder, "*.mlx"))]}, ...
      arrayfun(@(f) [dir(fullfile(f, "**", "*.m")); ...
      dir(fullfile(f, "**", "*.mlx"))], [folders, subpackages], ...
      'UniformOutput', false)];
   labels = [toolboxfolder, folders, subpackages];

   for n = 1:numel(sets)
      files = sets{n};
      folder = labels(n);
      if isempty(files)
         continue
      end
      files = fullfile(string({files.folder}), string({files.name}));
      called = string(matlab.codetools.requiredFilesAndProducts( ...
         cellstr(files), "toponly"));
      missing = called(undersource(fileparts(called), source));
      if ~isempty(missing)
         error('groupstats:vendordependencies:unreachableCaller', ...
            ['%s calls %s, and a file there cannot reach a private ' ...
            'folder. Inline the call, or move the caller into the ' ...
            'namespace functions.'], folder, strjoin(missing, ', '))
      end
   end
end

function source = defaultsource()
   %DEFAULTSOURCE Return the matfunclib checkout to copy from.

   source = string(getenv("MATLAB_FUNCTION_PATH"));
   if strlength(source) > 0
      return
   end

   dealoutfile = which("dealout");
   if isempty(dealoutfile)
      error('groupstats:vendordependencies:noSource', ...
         ['matfunclib is not on the path. Set MATLAB_FUNCTION_PATH to ' ...
         'the checkout, add it to the path, or pass the source folder.'])
   end
   source = string(fileparts(fileparts(dealoutfile)));
end

function [licenses, from] = vendorLicenses(toolboxfolder, installed, ...
      sources, source)
   %VENDORLICENSES Copy the license beside each third-party file.
   %
   % A File Exchange function lives in a folder of its own with a
   % license.txt beside it. That file is the license the package must ship
   % with the copy. The checkout's own license.txt, in the root of SOURCE,
   % covers the author's files and is not copied. Two copies from one
   % folder each get the license under their own name, so a reader finds
   % it beside either.

   % Find the copies that have a license first, so the outputs are sized
   % once.
   folders = arrayfun(@(s) string(fileparts(s)), sources);
   licensefiles = fullfile(folders, "license.txt");
   keep = find(arrayfun(@isfile, licensefiles) & folders ~= string(source));

   from = licensefiles(keep);
   licenses = strings(numel(keep), 1);
   for k = 1:numel(keep)
      [installfolder, name] = fileparts(installed(keep(k)));
      licenses(k) = fullfile(installfolder, name + "_LICENSE.txt");
      copyfile(from(k), fullfile(toolboxfolder, licenses(k)))
   end
end

function writeVendoredList(toolboxfolder, installed, sources)
   %WRITEVENDOREDLIST Write vendored.txt: one copy per line, with its source.
   %
   % vendoredfiles reads the first token of each line. The path after the
   % arrow is relative to the source checkout. It records where the copy
   % came from, for a reader who wants to compare it with the checkout.

   arguments
      toolboxfolder (1, 1) string
      installed (:, 1) string
      sources (:, 1) string
   end

   lines = [
      "# Files copied from matfunclib by buildtool dependencies."
      "# Do not edit them here: change matfunclib, then rerun the task."
      "# Format: <path under toolbox/> <- <path under the matfunclib checkout>"
      strrep(installed, filesep, "/") + " <- " + strrep(sources, filesep, "/")
      ];

   % Write beside the list and move over it once the write is complete.
   % A write that fails part way then leaves the previous list in place,
   % and the part file never outlives the failure.
   listfile = fullfile(toolboxfolder, "vendored.txt");
   partial = listfile + ".part";
   try
      writelines(lines, partial)
      movefile(partial, listfile, 'f')
   catch failure
      if isfile(partial)
         delete(partial)
      end
      rethrow(failure)
   end
end
