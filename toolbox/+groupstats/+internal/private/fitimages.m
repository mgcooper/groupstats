function fitimages(htmlfile, figurescale)
   %FITIMAGES Show each figure at its unscaled width, and no wider than the page.
   %
   %  fitimages(htmlfile, figurescale)
   %
   % The figures are rendered FIGURESCALE times larger than their default
   % size (see the build). publish writes each <img> with no width, and
   % export writes each with width 100%, so a browser would show the
   % first at FIGURESCALE times its intended size and stretch the second
   % to the page. Each image gets a width of its pixel width divided by
   % FIGURESCALE, and one rule caps every image at the page width, with
   % the height following, for a page narrower than that.

   % Attribute names, and the quote form, are matched without case, so a
   % page from a release that writes them differently still fits.
   % The pages declare UTF-8 and carry characters outside ASCII, so both
   % the read and the write name that encoding; a plain char write would
   % put one byte per character and break them.
   page = fileread(htmlfile, 'Encoding', 'UTF-8');
   [tags, starts, ends] = regexp(page, '<img\s[^>]*>', 'match', 'start', ...
      'end', 'ignorecase');
   for n = numel(tags):-1:1
      width = round(imageWidth(tags{n}, fileparts(htmlfile)) / figurescale);
      tag = regexprep(tags{n}, '\s(style|width)\s*=\s*("[^"]*"|''[^'']*'')', ...
         '', 'ignorecase');
      tag = regexprep(tag, '^<img', sprintf('<img width="%d"', width), ...
         'once', 'ignorecase');
      page = [page(1:starts(n) - 1) tag page(ends(n) + 1:end)];
   end
   page = strrep(page, '</head>', ...
      ['<style>img { max-width: 100%; height: auto; }</style>' newline ...
      '</head>']);
   fid = fopen(htmlfile, 'w', 'n', 'UTF-8');
   closefile = onCleanup(@() fclose(fid));
   fprintf(fid, '%s', page);
end

function width = imageWidth(tag, folder)
   %IMAGEWIDTH The pixel width of the PNG an <img> tag shows.
   %
   % publish links a PNG file beside the page; export embeds the PNG as a
   % base64 data URI. A PNG's width is the big-endian uint32 at bytes 17
   % to 20, so the embedded case decodes only the first 32 bytes.

   src = regexp(tag, 'src\s*=\s*["'']([^"'']*)["'']', 'tokens', 'once', ...
      'ignorecase');
   src = src{1};
   if startsWith(src, 'data:image/png;base64,')
      encoded = extractAfter(src, 'base64,');
      header = matlab.net.base64decode(encoded(1:44));
      width = double(typecast(uint8(header(20:-1:17)), 'uint32'));
   else
      info = imfinfo(fullfile(folder, src));
      width = info.Width;
   end
end
