function varargout = help(docname)
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
   %  fullpath = groupstats.help(_) returns the page's full path and opens
   %  nothing, so a script or a test can check a page without a browser.
   %
   %  docs/ holds the hand-written pages (groupstats_welcome and others).
   %  The documentation build writes one page per function under
   %  docs/html/m2html/+groupstats/, and groupstats.internal.docpath
   %  searches both locations, so DOCNAME also accepts a function name.
   %
   % Errors
   %  groupstats:help:docNotFound - no html file of that name is in docs/.
   %
   % Example
   %  page = groupstats.help("groupsummary")   % the page path, nothing opens
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

   % With an output requested, the caller wants the path, not a browser.
   if nargout > 0
      varargout{1} = fullpath;
      return
   end

   % web, not doc: these are toolbox pages, not MATLAB reference pages.
   web(fullpath)
end
