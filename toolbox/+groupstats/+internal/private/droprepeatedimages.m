function droprepeatedimages(htmlfile)
   %DROPREPEATEDIMAGES Remove a published image that repeats an earlier one.
   %
   %  droprepeatedimages(htmlfile)
   %
   % publish snaps a figure after a cell when the figure changed since the
   % cell began. In a -nodisplay session, every figure gets one update about
   % half a second after its first render, with no visible change. When that
   % update arrives after publish has snapped the figure, the next cell
   % snaps it again, and the page shows the figure twice. No publish option
   % stops it. The repeat is pixel-identical to the first snap. This pass
   % keeps the first of equal images, in the section that draws the figure,
   % and removes each later <img> tag and its PNG file.
   %
   % Note: a demo that draws the same figure twice on purpose loses the
   % second image. The docs build count, one image per figure the demo
   % draws, shows that case.
   %
   % See also: groupstats.internal.makedocs, fitimages

   % The pages declare UTF-8 and carry characters outside ASCII, so both the
   % read and the write name that encoding, as fitimages does.
   folder = fileparts(htmlfile);
   page = fileread(htmlfile, 'Encoding', 'UTF-8');
   [tags, srcs] = regexp(page, ...
      '<img\s[^>]*src\s*=\s*["'']([^"'']+\.png)["''][^>]*>', ...
      'match', 'tokens', 'ignorecase');

   % Compare each image with every image kept so far, so a repeat that
   % follows another figure's snap is found too.
   kept = cell(1, numel(tags));
   nkept = 0;
   for n = 1:numel(tags)
      file = fullfile(folder, srcs{n}{1});
      pixels = imread(file);
      if any(cellfun(@(k) isequal(k, pixels), kept(1:nkept)))
         page = strrep(page, tags{n}, '');
         delete(file)
      else
         nkept = nkept + 1;
         kept{nkept} = pixels;
      end
   end

   fid = fopen(htmlfile, 'w', 'n', 'UTF-8');
   closefile = onCleanup(@() fclose(fid));
   fprintf(fid, '%s', page);
end
