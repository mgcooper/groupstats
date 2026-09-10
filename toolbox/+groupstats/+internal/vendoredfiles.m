function files = vendoredfiles(toolboxfolder)
   %VENDOREDFILES Return the vendored copies listed in vendored.txt.
   %
   %  files = groupstats.internal.vendoredfiles(toolboxfolder)
   %
   % Description
   %  Reads TOOLBOXFOLDER/vendored.txt, the list vendordependencies writes,
   %  and returns the absolute path of every copy it names, one per row. An
   %  absent list returns an empty string column: that is how a checkout
   %  looks before the dependencies task ever ran. Lines starting with #
   %  are comments. An entry must be a relative path with no ".."
   %  segment that stays under TOOLBOXFOLDER; any other entry is an error,
   %  because vendordependencies moves and deletes what this list names.
   %
   % Errors
   %  groupstats:vendoredfiles:badEntry - an entry is absolute, holds a
   %  ".." segment, or resolves outside TOOLBOXFOLDER.
   %
   % See also: groupstats.internal.vendordependencies, buildfile

   arguments
      toolboxfolder (1, 1) string {mustBeFolder}
   end

   % A relative folder such as "toolbox" gives relative results, which a
   % caller that changes folders would misread, so make it absolute. cd
   % resolves it the way MATLAB does, and the cleanup object puts the
   % working folder back.
   job = withcd(toolboxfolder);
   toolboxfolder = string(pwd);
   delete(job)

   listfile = fullfile(toolboxfolder, "vendored.txt");
   files = strings(0, 1);
   if ~isfile(listfile)
      return
   end

   % The first token of a line is the path under the toolbox folder; the
   % arrow and the source path after it are for the reader.
   lines = readlines(listfile);
   lines = lines(~startsWith(lines, "#") & strlength(lines) > 0);
   relative = extractBefore(lines + " <- ", " <- ");

   % A list edited by hand or merged badly could name a path outside the
   % toolbox, and the caller moves and deletes what the list names, so
   % only a relative entry with no ".." segment, on either separator,
   % that stays under the toolbox folder is accepted.
   bad = startsWith(relative, ["/", "\\"]) ...
      | contains(relative, ":") ...
      | arrayfun(@(entry) any(regexp(entry, '[/\\]', 'split') == ".."), ...
      relative) ...
      | strlength(relative) == 0;
   files = fullfile(toolboxfolder, strrep(relative, "/", filesep));
   bad = bad | ~undersource(fileparts(files), toolboxfolder);
   if any(bad)
      error('groupstats:vendoredfiles:badEntry', ...
         ['%s holds an entry that is not a relative path under the ' ...
         'toolbox folder: %s. Fix the list before vendoring.'], listfile, ...
         strjoin(relative(bad), ', '))
   end
end
