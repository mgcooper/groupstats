function tf = undersource(folder, root)
   %UNDERSOURCE True when FOLDER is ROOT or lies below it.
   %
   %  tf = undersource(folder, root)
   %
   % Description
   %  Compares on folder boundaries, so "/tmp/src-copy" is not under
   %  "/tmp/src", which a substring test would accept. Both paths are
   %  normalized first: either separator counts, "." segments go, and a
   %  ".." segment removes the segment before it, so "/tmp/src/../x" is
   %  not under "/tmp/src" either. A trailing separator on ROOT is
   %  ignored. FOLDER may be a string array, and TF has the same size.
   %
   % See also: groupstats.internal.installRequiredFiles,
   % groupstats.internal.vendordependencies

   arguments
      folder string
      root (1, 1) string
   end

   % arrayfun over an empty string array returns an empty double, which
   % the comparison below rejects, so an empty input answers itself.
   tf = false(size(folder));
   if isempty(folder)
      return
   end

   root = normalize(root);
   folder = arrayfun(@normalize, folder);
   tf = folder == root | startsWith(folder, root + "/");
end

function path = normalize(path)
   %NORMALIZE Resolve "." and ".." segments and use one separator.

   arguments
      path (1, 1) string
   end

   % A path that starts with a separator is absolute; keep that mark.
   absolute = startsWith(path, ["/", "\\"]);
   % kept holds the resolved segments in its first n slots. It is sized
   % for every segment, since a resolved path is never longer.
   segments = regexp(path, '[/\\]+', 'split');
   kept = strings(numel(segments), 1);
   n = 0;
   for segment = segments
      if segment == "" || segment == "."
         continue
      elseif segment == ".."
         n = max(n - 1, 0);
      else
         n = n + 1;
         kept(n) = segment;
      end
   end
   path = strjoin(kept(1:n), "/");
   if absolute
      path = "/" + path;
   end
end
