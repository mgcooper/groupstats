function help(docname)
   %HELP Open toolbox html help document in the MATLAB Help browser.
   %
   %  groupstats.help() opens the groupstats toolbox help pages in the MATLAB
   %  help browser.
   %
   %  groupstats.help(DOCNAME) opens the documentation file DOCNAME.HTML in
   %  the MATLAB help browser. DOCNAME can be the name of a function, an
   %  example, or any other file with an .html extension in the docs/ folder
   %  or any subfolder of docs/.
   %
   %  docs/ holds one page, groupstats_welcome. Per-function pages come from
   %  the documentation build, which this toolbox does not ship yet. For one
   %  function's help meanwhile, use help:
   %
   %  help groupstats.groupbayes
   %
   % Errors
   %  groupstats:help:docNotFound - no html file of that name is in docs/.
   %
   % See also: groupstats.internal.docpath, doc, web

   arguments
      docname (1, 1) string = "groupstats_welcome"
   end

   fullpath = groupstats.internal.docpath(docname);

   % Name the missing page. web opens a blank browser for a path that does
   % not exist, which reads as a broken help system.
   if fullpath == ""
      error('groupstats:help:docNotFound', ...
         ['No help page named %s. Run groupstats.help() for the toolbox ' ...
         'landing page.'], docname)
   end

   % web, not doc: these are toolbox pages, not MATLAB reference pages.
   web(fullpath)
end
