function makedocs(opts)
   %MAKEDOCS Publish the toolbox documentation as html files.
   %
   %  groupstats.internal.makedocs()
   %  groupstats.internal.makedocs(Parts=["docpages", "demos"])
   %  groupstats.internal.makedocs(M2htmlPath=FOLDER, Template=NAME)
   %  groupstats.internal.makedocs(OutputFolder=FOLDER)
   %  groupstats.internal.makedocs(Parts="demos", Demos=NAMES)
   %
   % Description
   %  Builds the pages the Help browser shows for this toolbox. Run it after
   %  a docstring, a demo, or a docs source changes; the docs task in
   %  buildfile.m calls it, and release depends on that task.
   %
   %  Parts names what to build, any of these, default all four:
   %
   %   "docpages"  publishes every groupstats_*.m file in toolbox/docs/ with
   %               publish, into the output folder. These are the welcome,
   %               getting-started, and examples-contents pages.
   %   "demos"     publishes every examples/demo_*.m file other than
   %               demo_all with publish, so each demo page shows its code,
   %               its printed tables, and its figures. It also runs and
   %               exports the two plain-text live scripts, gettingStarted.m
   %               and examples/usingGroupStats.m.
   %   "functions" runs m2html over the +groupstats folder, one page per
   %               public function, into m2html/+groupstats/ under the
   %               output folder; m2html mirrors the source folder.
   %               m2html/function_index.html is the index. docpath
   %               searches that folder.
   %   "docsearch" runs builddocsearchdb on the output folder, so the Help
   %               browser search finds the pages. builddocsearchdb indexes
   %               only a folder that the help_location of an info.xml on
   %               the path names, which toolbox/docs/html is.
   %
   %  Demos names the demos the "demos" part publishes, default every
   %  examples/demo_*.m file other than demo_all. A test publishes one demo
   %  with it, because publishing every demo with its figures takes minutes.
   %  The "demos" part exports the two plain-text live scripts, which needs
   %  R2025a; an older release errors (groupstats:makedocs:needsR2025a)
   %  before any demo page is written.
   %
   %  M2htmlPath is the folder holding m2html.m. The default is the
   %  GROUPSTATS_M2HTML environment variable, then the folder of m2html on
   %  the path. With neither, the "functions" part errors
   %  (groupstats:makedocs:m2htmlNotFound) and says so.
   %
   %  Template is the m2html template name, default "blue2_groupstats".
   %  m2html reads a template from the templates/ folder of its own
   %  installation by name only, so this function copies
   %  toolbox/docs/templates/m2html/<Template>/ there before the run. That
   %  copy is the one write outside the repository this function makes. A
   %  name with no matching folder under toolbox/docs/templates/m2html/
   %  errors (groupstats:makedocs:templateNotFound).
   %
   %  OutputFolder is where the pages go, default toolbox/docs/html, the
   %  help_location that toolbox/info.xml names. A test builds into a
   %  scratch folder with it.
   %
   % Dependencies
   %  m2html (https://github.com/gllmflndn/m2html) for the "functions" part;
   %  graphviz dot is not needed, the dependency graph is off.
   %
   % See also: groupstats.help, groupstats.internal.docpath, publish,
   % builddocsearchdb

   arguments
      opts.Parts (1, :) string {mustBeMember(opts.Parts, ...
         ["docpages", "demos", "functions", "docsearch"])} = ...
         ["docpages", "demos", "functions", "docsearch"]
      % "" means: resolve from the environment, then from the path.
      opts.M2htmlPath (1, 1) string = ""
      opts.Template (1, 1) string {mustBeNonzeroLengthText} = ...
         "blue2_groupstats"
      % "" means the shipped help location, toolbox/docs/html.
      opts.OutputFolder (1, 1) string = ""
      % Empty means every demo.
      opts.Demos (1, :) string = string.empty()
   end

   % The toolbox folder holds the sources; the output folder holds the
   % pages. An output folder given relative is made absolute here, because
   % publish and m2html change folder while they run.
   tbxpath = toolboxpath();
   docspath = fullfile(tbxpath, 'docs');
   examplespath = fullfile(tbxpath, 'examples');
   if strlength(opts.OutputFolder) == 0
      htmlpath = fullfile(docspath, 'html');
   else
      htmlpath = absolutePath(opts.OutputFolder);
   end
   if ~isfolder(htmlpath)
      mkdir(htmlpath)
   end

   % publish options shared by the docs pages and the demos. useNewFigure
   % off keeps a demo's figures in the page in the order they are drawn.
   % figureSnapMethod 'print' is set explicitly, not left at publish's
   % default 'entireGUIWindow'. That default screenshots a real GUI
   % window, which a `-nodisplay` batch session does not have. It happens
   % to fall back to a print-equivalent capture there (measured identical
   % output to 'print' at the default figure size), but that fallback is
   % undocumented. 'print' is the capture path this function also relies
   % on below to sharpen the output, so it is named here rather than
   % depended on implicitly.
   pubopts = struct('format', 'html', 'outputDir', char(htmlpath), ...
      'useNewFigure', false, 'figureSnapMethod', 'print');

   % publish runs a file only from the path. The sources, the examples, and
   % m2html join the path for this run and leave it after. A session that
   % built the docs then looks like one that did not.
   oldpath = path;
   restorepath = onCleanup(@() path(oldpath));
   addpath(docspath, examplespath)

   % publish and export capture a figure as a PNG through the hardcopy
   % renderer. That renderer resolves the matlab.appearance.figure.GraphicsTheme
   % setting on its own, separate from the figure's own Color and Theme.
   % Measured in a headless batch session with that setting at its default
   % "auto": a drawn figure's Color and Theme.BackgroundColor both read
   % [1 1 1] (white). Yet the PNG publish writes has a black corner pixel.
   % Forcing GraphicsTheme to "light" for the run, and only that, turns the
   % same PNG white. Restore the setting on cleanup, whether or not a
   % temporary value was already set. A build must never change it for the
   % rest of the session.
   graphicstheme = settings().matlab.appearance.figure.GraphicsTheme;
   hadtemporarytheme = graphicstheme.hasTemporaryValue;
   oldtheme = "";
   if hadtemporarytheme
      oldtheme = graphicstheme.TemporaryValue;
   end
   restoretheme = onCleanup(@() restoreGraphicsTheme( ...
      graphicstheme, hadtemporarytheme, oldtheme));
   graphicstheme.TemporaryValue = "light";

   % A `-nodisplay` batch session has no real screen. groot's
   % ScreenPixelsPerInch then reads a fixed, low virtual value (measured:
   % 60). Unlike a normal session, that value cannot be changed: the
   % property has been read-only since R2015b.
   %
   % publish's figureSnapMethod 'print' rasterizes at that fixed dpi.
   % pubopts.maxWidth/maxHeight only ever shrink an oversized capture, and
   % never sharpen or enlarge one (measured: setting maxWidth above the
   % native 704 px width changed nothing). So no combination of publish
   % options alone raises a demo figure's captured detail.
   %
   % A glyph's or a line's pixel size is its point-based FontSize or
   % LineWidth times dpi/72. Scaling those point sizes and the figure's
   % pixel Position together, at that same fixed dpi, genuinely raises the
   % rendered detail. Measured: a tick-label glyph band went from 64 px to
   % 124 px tall at FIGURESCALE below.
   %
   % The trade-off is size: the published PNG, and its width on the docs
   % page, grow by the same factor. There is no CSS max-width on the
   % page's <img> elements. FIGURESCALE = 2 was chosen so the widest
   % current demo image (704 px) becomes about 1400 px. That is a
   % reasonable width for a modern docs page, not so large the pages
   % become unwieldy. Restore every
   % scaled default on cleanup, so a build never changes them for the
   % rest of the session.
   figurescale = 2;
   oldfiguredefaults = struct( ...
      'FigurePosition', get(groot, 'defaultFigurePosition'), ...
      'AxesFontSize', get(groot, 'defaultAxesFontSize'), ...
      'TextFontSize', get(groot, 'defaultTextFontSize'), ...
      'LineLineWidth', get(groot, 'defaultLineLineWidth'), ...
      'AxesLineWidth', get(groot, 'defaultAxesLineWidth'), ...
      'PatchLineWidth', get(groot, 'defaultPatchLineWidth'));
   restorefiguredefaults = onCleanup( ...
      @() restoreFigureDefaults(oldfiguredefaults));
   scaledposition = oldfiguredefaults.FigurePosition;
   scaledposition(3:4) = scaledposition(3:4) * figurescale;
   set(groot, ...
      'defaultFigurePosition', scaledposition, ...
      'defaultAxesFontSize', oldfiguredefaults.AxesFontSize * figurescale, ...
      'defaultTextFontSize', oldfiguredefaults.TextFontSize * figurescale, ...
      'defaultLineLineWidth', oldfiguredefaults.LineLineWidth * figurescale, ...
      'defaultAxesLineWidth', oldfiguredefaults.AxesLineWidth * figurescale, ...
      'defaultPatchLineWidth', ...
      oldfiguredefaults.PatchLineWidth * figurescale);

   % The docs pages: every groupstats_*.m source in docs/. The template's
   % version of this branch read a list that nothing defined; the list is
   % the folder's contents.
   if any(opts.Parts == "docpages")
      sources = dir(fullfile(docspath, 'groupstats_*.m'));
      stems = string(erase({sources.name}, ".m"));
      % A source that was renamed or removed leaves its page behind, and
      % the search database and the package would keep it.
      removeOrphans(htmlpath, 'groupstats_*', stems)
      for n = 1:numel(sources)
         removeOutputs(htmlpath, stems(n))
         publish(fullfile(sources(n).folder, sources(n).name), pubopts);
      end
   end

   % The demos: every demo but the runner, then the two live scripts. A
   % published demo runs, so the toolbox and the examples must be on the
   % path; publish runs the script in the base workspace.
   if any(opts.Parts == "demos")
      demos = groupstats.internal.demolist(opts.Demos);
      % The two live scripts are plain-text live scripts, which export
      % reads from R2025a. The release that packages needs R2025a too, so
      % the docs build runs there. An older release stops here, before any
      % demo page is written, with the reason.
      if isMATLABReleaseOlderThan("R2025a")
         error('groupstats:makedocs:needsR2025a', ...
            ['The demos part exports the plain-text live scripts, which ' ...
            'export reads from R2025a. This is %s.'], version('-release'))
      end
      figuresbefore = findall(groot, 'Type', 'figure');
      % The outputs of a demo file that no longer exists go, whatever the
      % selection: a page with no source is stale. Then each selected
      % demo's page and figures go before it runs, so a demo that now
      % draws fewer figures leaves no extra numbered ones.
      [~, roster] = fileparts(groupstats.internal.demolist());
      removeOrphans(htmlpath, 'demo_*', string(roster))
      for n = 1:numel(demos)
         [~, stem] = fileparts(demos(n));
         removeOutputs(htmlpath, stem)
         publish(demos(n), pubopts);
      end
      % publish leaves the figures a demo opened. Close those, and no
      % figure the caller had open before.
      close(setdiff(findall(groot, 'Type', 'figure'), figuresbefore))
      livescripts = [
         fullfile(string(tbxpath), "gettingStarted.m")
         fullfile(string(examplespath), "usingGroupStats.m")
         ];
      for n = 1:numel(livescripts)
         [~, name] = fileparts(livescripts(n));
         removeOutputs(htmlpath, name)
         export(livescripts(n), fullfile(htmlpath, name + ".html"), ...
            'Run', true);
      end
   end

   % The function pages: m2html over the namespace folder, not recursive,
   % so private/, +internal/, +namelists/, and +test/ get no page. m2html
   % builds its paths from the current folder, so run it from the toolbox
   % folder with the namespace folder as a relative name.
   if any(opts.Parts == "functions")
      m2htmlfolder = resolveM2html(opts.M2htmlPath);
      installTemplate(docspath, m2htmlfolder, opts.Template)
      addpath(m2htmlfolder)  % restored with the rest by restorepath
      m2htmlpath = fullfile(htmlpath, 'm2html');
      if ~isfolder(m2htmlpath)
         mkdir(m2htmlpath)
      end
      % m2html rewrites the page of every file it finds and leaves the
      % page of a file that is gone, so the previous pages go first.
      stale = dir(fullfile(m2htmlpath, '+groupstats', '*.html'));
      for n = 1:numel(stale)
         delete(fullfile(stale(n).folder, stale(n).name))
      end
      cdobj = withcd(tbxpath);
      m2html( ...
         'mfiles', '+groupstats', ...
         'htmldir', char(m2htmlpath), ...
         'recursive', 'off', ...
         'source', 'on', ...
         'download', 'off', ...
         'syntaxHighlighting', 'on', ...
         'globalHypertextLinks', 'off', ...
         'graph', 'off', ...
         'indexFile', 'function_index', ...
         'template', char(opts.Template), ...
         'verbose', 'off');
      delete(cdobj)
   end

   % The search database, last, so it indexes every page built above.
   if any(opts.Parts == "docsearch")
      builddocsearchdb(char(htmlpath))
   end
end

function removeOutputs(htmlpath, stem)
   %REMOVEOUTPUTS Delete the page and figures one source wrote.
   %
   % publish writes <stem>.html, <stem>.png, and <stem>_NN.png, and a
   % live-script export writes <stem>.html. Every output of the stem goes
   % before the rebuild, so a source that now draws fewer figures leaves
   % no extra numbered ones.

   old = [
      dir(fullfile(htmlpath, stem + ".html"))
      dir(fullfile(htmlpath, stem + ".png"))
      dir(fullfile(htmlpath, stem + "_*.png"))
      ];
   for n = 1:numel(old)
      delete(fullfile(old(n).folder, old(n).name))
   end
end

function removeOrphans(htmlpath, pattern, stems)
   %REMOVEORPHANS Delete the outputs whose source no longer exists.
   %
   % PATTERN names the output files one part owns, and STEMS the sources
   % that exist. An output whose stem, with any figure number removed, is
   % not among them has no source, so it goes.

   old = dir(fullfile(htmlpath, pattern));
   old = old(~[old.isdir]);
   for n = 1:numel(old)
      stem = regexprep(old(n).name, '(_\d+)?\.(html|png)$', '');
      if ~ismember(stem, stems)
         delete(fullfile(old(n).folder, old(n).name))
      end
   end
end

function restoreGraphicsTheme(graphicstheme, hadtemporaryvalue, oldvalue)
   %RESTOREGRAPHICSTHEME Put the GraphicsTheme temporary value back.
   %
   % makedocs forces the setting to "light" for the run so publish and
   % export write white PNGs. This puts back whatever the caller's session
   % had, a temporary value if one was set, or none at all.

   if hadtemporaryvalue
      graphicstheme.TemporaryValue = oldvalue;
   else
      graphicstheme.clearTemporaryValue();
   end
end

function restoreFigureDefaults(olddefaults)
   %RESTOREFIGUREDEFAULTS Put the pre-scale groot figure defaults back.
   %
   % makedocs scales the figure Position and the point-based font and line
   % size defaults for the run, so publish captures sharper demo PNGs.
   % This puts back whatever the caller's session had for each one.

   fields = fieldnames(olddefaults);
   for n = 1:numel(fields)
      set(groot, ['default' fields{n}], olddefaults.(fields{n}));
   end
end

function folder = resolveM2html(given)
   %RESOLVEM2HTML The folder holding m2html.m: given, environment, or path.

   folder = given;
   if strlength(folder) == 0
      folder = string(getenv("GROUPSTATS_M2HTML"));
   end
   if strlength(folder) == 0
      found = which('m2html');
      if ~isempty(found)
         folder = string(fileparts(found));
      end
   end
   if strlength(folder) == 0 || ~isfile(fullfile(folder, 'm2html.m'))
      error('groupstats:makedocs:m2htmlNotFound', ...
         ['m2html.m was not found. Pass M2htmlPath, set the ' ...
         'GROUPSTATS_M2HTML environment variable, or add m2html to the ' ...
         'path. Given: "%s".'], folder)
   end
   folder = absolutePath(folder);
end

function installTemplate(docspath, m2htmlfolder, name)
   %INSTALLTEMPLATE Copy the shipped m2html template into m2html's folder.
   %
   % m2html resolves a template by name under its own templates/ folder,
   % and strips any path from the name. The copy is therefore the only way
   % to use a template the repository holds.

   source = fullfile(docspath, 'templates', 'm2html', name);
   if ~isfolder(source)
      error('groupstats:makedocs:templateNotFound', ...
         'No m2html template folder at %s.', source)
   end
   target = fullfile(m2htmlfolder, 'templates', name);
   copyfile(source, target, 'f')
end

function folder = absolutePath(folder)
   %ABSOLUTEPATH Make a folder path absolute, creating nothing.
   %
   % A relative path is read against the current folder. The folder need
   % not exist yet, so this resolves the parent that does.

   folder = char(folder);
   if isfolder(folder)
      cdobj = withcd(folder);
      folder = pwd;
      delete(cdobj)
   else
      [parent, name, ext] = fileparts(folder);
      if isempty(parent)
         parent = pwd;
      end
      cdobj = withcd(parent);
      folder = fullfile(pwd, [name ext]);
      delete(cdobj)
   end
   folder = string(folder);
end
