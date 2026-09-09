function makecontents(option, opts)
   %MAKECONTENTS Make contents.m for each folder including package folders.
   %
   %  Run this after adding, renaming, or removing a function.
   %
   %  makecontents() Makes a Contents.m file for each folder in the
   %  projectpath/toolbox directory. This usage assumes this file is saved in:
   %  projectpath/toolbox/+groupstats/+internal.
   %
   %  makecontents('-backup') Makes a backup of the current Contents.m file, if
   %  one exists, before updating it. The backup goes to a temporary folder,
   %  with the date appended to the filename, and the path is printed. Backups
   %  are off by default because every Contents.m is tracked by git, so
   %  git diff reviews a change better than a dated copy does. Note: a backup
   %  written beside the original would be a callable member of that package
   %  and would ship inside the .mltbx.
   %
   %  makecontents(_, Folder=PATH) works on the toolbox folder PATH instead
   %  of this file's own, so a test can run it on a scratch copy.
   %
   % See also: updatecontents

   arguments
      option (1, 1) string ...
         {mustBeMember(option, ["-backup", "-nobackup"])} = "-nobackup"
      % "" means this file's own toolbox folder, resolved below.
      opts.Folder (1, 1) string = ""
   end

   % Get the toolbox path and set the backup option
   tbxpath = opts.Folder;
   if strlength(tbxpath) == 0
      tbxpath = toolboxpath(); % call private/toolboxpath function
   end
   dobackup = option == "-backup";

   if ~isfolder(tbxpath)
      error('toolbox folder not found')
   end

   % package and subpackage folders
   pkglist = mpackagefolders(tbxpath, "aspathlist", true, "asstring", true);

   % traverse package folders and generate a contents report in each one
   for thispkg = pkglist(:).'
      processOnePackage(thispkg, dobackup);
   end
end

%% subfunction to handle each package folder individually
function processOnePackage(thispkg, dobackup)

   % With "mfiles", true, this will return an empty list for docs/html folders.
   filelist = listfiles(thispkg, "aslist", true, ...
      "fullpath", true, "asstring", true, "mfiles", true);

   if isempty(filelist)
      return
   end

   % The update below runs only for a folder that already holds a Contents
   % file, so write a placeholder for a folder that does not. updatecontents
   % writes its own header and list, and discards these two lines.
   contentsfile = fullfile(thispkg, 'Contents.m');
   if ~isfile(contentsfile)
      [~, pkgname] = fileparts(thispkg);
      writelines(["% " + upper(pkgname); "% "], contentsfile);
      filelist = [filelist; string(contentsfile)];
   end

   % If an existing Contents file is found, update it.
   if any(strncmp(reverse(filelist), reverse('Contents.m'), 10))
      % Copy the current Contents to a temp file so it is not included as an
      % entry in the new Contents.m file.
      [bkfile, ogfile, tmpfile] = backupContentsFile(filelist);

      % Try to update the Contents file.
      success = true;
      try
         % The cleanup object holds the working folder at thispkg until it
         % is deleted, which happens here on success and at scope exit on
         % an error.
         cdobj = withcd(thispkg);
         updatecontents();
         delete(cdobj)
      catch
         success = false;
         fprintf(2, ...
            ['Error occurred while generating contents for package %s. ' ...
            'Restoring the original Contents.m\n'], thispkg);
      end

      % If successful, copy the tmpfile to the backupfile.
      if success == true
         if dobackup
            cleanupfun(tmpfile, bkfile)

            % The backup is outside the toolbox, so print where it went.
            fprintf('Backed up %s to %s\n', ogfile, bkfile);
         else
            % backupContentsFile moved the original here. Without a backup
            % it has no destination, so delete it rather than leave a copy
            % of the source in the temporary folder on every run.
            delete(tmpfile)
         end
      else
         % If not successful, restore the original file.
         cleanupfun(tmpfile, ogfile)
      end
   else
      % No file found
   end
end
%% local functions
function [bkfile, ogfile, tmpfile] = backupContentsFile(filelist)
   % Move the existing Contents.m file to a tempfile and create a backup
   % filename. If -backup option is passed to the main function, the original
   % file is copied to the backup file name after successful generation of the
   % new Contents.m file. If the generation is not successful, the tempfile is
   % copied back to the original Contents.m file.
   ifile = strncmp(reverse(filelist), reverse('Contents.m'), 10);
   tmpfile = tempfile('fullpath');
   bkfile = backupfile('Contents.m');
   ogfile = filelist(ifile);

   % Keep the backup out of the package folder. A .m file written beside the
   % original is a callable member of that package, which fails the tests that
   % enumerate a package, and the packaging fileset covers the folder, so the
   % backup would ship. Name the package in the backup so several are telling
   % apart.
   [~, pkgname] = fileparts(fileparts(ogfile));
   bkfile = fullfile(tempdir, pkgname + "_" + bkfile);
   movefile(ogfile, tmpfile)
end

function cleanupfun(tmpfile, destinationfile)
   movefile(tmpfile, destinationfile);
end
