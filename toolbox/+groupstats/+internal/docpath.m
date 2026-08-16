function fullpath = docpath(docname)
   %DOCPATH Return the path to a toolbox help page.
   %
   %  fullpath = groupstats.internal.docpath(docname)
   %
   % Description
   %  Returns the full path to toolbox/docs/html/<docname>.html. When an
   %  m2html folder holds the function pages, searches
   %  toolbox/docs/html/m2html/+groupstats/<docname>.html as well.
   %
   %  Returns an empty string when no such file exists, so a caller can
   %  report the name it was given.
   %
   % See also: groupstats.help, groupstats.internal.buildpath

   arguments
      docname (1, 1) string
   end

   docspath = fullfile(groupstats.internal.buildpath(), 'docs', 'html');

   % docs/html holds the hand-written pages. The documentation build writes
   % one page per function under m2html, so search both.
   candidates = [
      fullfile(docspath, docname + ".html")
      fullfile(docspath, 'm2html', '+groupstats', docname + ".html")
      ];

   found = candidates(arrayfun(@isfile, candidates));

   % Prefer the hand-written page when a function shares its name.
   if isempty(found)
      fullpath = "";
   else
      fullpath = found(1);
   end
end
