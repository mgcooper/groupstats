function dest = copytoolbox(dest)
   %COPYTOOLBOX Copy the toolbox folder without its generated help pages.
   %
   %  dest = groupstats.test.copytoolbox(dest)
   %
   % Description
   %  Copies toolbox/ into DEST for a test that rewrites files under the
   %  toolbox, so the working tree is never written. The generated pages
   %  under docs/html are left out: they are build output, hundreds of
   %  images, and no test reads them, so the copy stays fast. The docs
   %  sources and the templates under docs/ are copied.
   %
   % See also: groupstats.internal.buildpath, groupstats.internal.makecontents

   arguments
      dest (1, 1) string
   end

   source = groupstats.internal.buildpath();
   copyfolder(source, dest, fullfile(source, "docs", "html"))
end

function copyfolder(source, dest, skip)
   %COPYFOLDER Copy a folder tree, leaving out the one folder SKIP.

   if ~isfolder(dest)
      mkdir(dest)
   end
   items = dir(source);
   items = items(~ismember({items.name}, {'.', '..'}));
   for n = 1:numel(items)
      from = fullfile(items(n).folder, items(n).name);
      if strcmp(from, skip)
         continue
      end
      if items(n).isdir
         copyfolder(from, fullfile(dest, items(n).name), skip)
      else
         copyfile(from, fullfile(dest, items(n).name))
      end
   end
end
