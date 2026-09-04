function v = version()
   %VERSION Read version.txt in the toolbox root directory.
   %
   %  v = groupstats.internal.version()
   %
   % Description
   %  Returns the toolbox version as a char row, such as 'v0.2.0'. version.txt
   %  is the one place the version is written down. The packaging file takes
   %  its value from here, so a release cannot ship a version that disagrees
   %  with the source.
   %
   % Errors
   %  groupstats:version:versionFileNotFound - version.txt is missing from the
   %  toolbox folder.
   %
   % See also: groupstats.internal.buildpath

   versionfile = fullfile(toolboxpath(), 'version.txt');

   if ~isfile(versionfile)
      error('groupstats:version:versionFileNotFound', ...
         'version.txt not found at %s', versionfile)
   end

   % fileread takes one argument, the full path. Two arguments make it read
   % the folder. The error above reports that, rather than a catch returning
   % a hard-coded version that drifts from the file.
   v = strtrim(fileread(versionfile));
end
