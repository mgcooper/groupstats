function droprepeatedimages(htmlfile)
   %DROPREPEATEDIMAGES Keep the first of equal published PNG images.
   %
   %  droprepeatedimages(htmlfile)
   %
   % publish captures a figure when it changes after a cell begins. In the
   % reported R2025b headless case, each figure updates about half a second
   % after rendering, without a visible change. A later cell can capture it
   % again. The tested publish options did not prevent that repeat. This pass
   % keeps the first equal image and removes each later tag and unused PNG.
   %
   % Note: an intentionally repeated identical image also appears only once.
   % Compare published image counts with the figures the source draws.
   % Only PNG files beside the page can be removed; other references remain.
   %
   % See also: makedocs, publish

   arguments
      htmlfile (1, 1) string {mustBeFile}
   end

   % Scientific pages contain non-ASCII text, so both streams use UTF-8.
   folder = fileparts(htmlfile);
   page = fileread(htmlfile, 'Encoding', 'UTF-8');
   [first, last, srcs] = regexp(page, ...
      '<img\s+(?:[^>]*\s)?src\s*=\s*["'']([^"'']+\.png)["''][^>]*>', ...
      'start', 'end', 'tokens', 'ignorecase');

   % Read every local image before changing files, and retain all color data.
   kept = cell(1, numel(first));
   files = strings(1, numel(first));
   drop = false(1, numel(first));
   nkept = 0;
   for n = 1:numel(first)
      name = srcs{n}{1};
      if ~isempty(fileparts(name))
         continue
      end
      files(n) = fullfile(folder, name);
      [pixels, map, alpha] = imread(files(n));
      image = {pixels, map, alpha};
      if any(cellfun(@(k) isequal(k, image), kept(1:nkept)))
         drop(n) = true;
      else
         nkept = nkept + 1;
         kept{nkept} = image;
      end
   end
   if ~any(drop)
      return
   end

   % Remove only later tag positions, even when two tags have identical text.
   keep = true(size(page));
   for n = find(drop)
      keep(first(n):last(n)) = false;
   end
   fid = fopen(htmlfile, 'w', 'n', 'UTF-8');
   if fid < 0
      error('droprepeatedimages:writeFailed', 'Cannot write %s.', htmlfile)
   end
   closefile = onCleanup(@() fclose(fid));
   fprintf(fid, '%s', page(keep));
   [message, status] = ferror(fid);
   if status ~= 0
      error('droprepeatedimages:writeFailed', '%s', message)
   end
   delete(closefile)

   % A file still used by any retained tag must survive the cleanup.
   repeats = setdiff(files(drop), files(~drop));
   for file = repeats
      delete(file)
   end
end
