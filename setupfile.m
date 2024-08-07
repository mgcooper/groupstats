function setupfile(varargin)
   %SETUPFILE project setup file to add paths, run userhooks, etc.
   %
   %  setupfile()
   %  setupfile(SETVARS)
   %  setupfile(PROJECTNAME, PROJECTPATH)
   %  setupfile(PROJECTNAME, PROJECTPATH, SETVARS)
   %
   %  setupfile() adds the path from which this file is run and all
   %  subdirectories to the userpath, ignoring ones that start with '.'
   %  (including .git, .svn, etc.), runs files in the userhooks/ directory if
   %  one exists, and sets default environment variables.
   %
   %  setupfile(SETVARS) does not add environment variables if SETVARS is false.
   %  This is useful if the user prefers to define them in a script saved in the
   %  PROJECTPATH/userhooks/ directory, e.g., config.m.
   %
   %  setupfile(PROJECTNAME, PROJECTPATH) adds the specified PROJECTPATH instead
   %  of the one from which this file is run to the user path.
   %
   %  The following default environment variables are set:
   %
   %  MATLAB_ACTIVE_PROJECT set to PROJECTNAME
   %  MATLAB_ACTIVE_PROJECT_PATH set to PROJECTPATH
   %  MATLAB_ACTIVE_PROJECT_DATA_PATH set to PROJECTPATH/data
   %  MATLAB_ACTIVE_PROJECT_TESTS_PATH set to PROJECTPATH/tests
   %  MATLAB_ACTIVE_PROJECT_TOOLBOX_PATH set to PROJECTPATH/toolbox
   %
   %  To set these variables, PROJECTNAME is inferred from the path to the
   %  directory in which this file is saved. For example, if this file is saved
   %  in: /Users/truelegend/projects/super/setupfile.m then PROJECTNAME='super'
   %  and PROJECTPATH='/Users/truelegend/projects/super'
   %
   %  To use a different value for PROJECTNAME and PROJECTPATH, pass them in:
   %  setupfile('projectname', '/full/path/to/project/root/folder')
   %
   % Copyright (c) 2023, Matt Cooper, BSD 3-Clause License,
   % www.github.com/mgcooper
   %
   % See also: userhooks, config, buildfile, makeproject

   % Notes - toolboxdir returns the full path to mathworks toolboxes, needed for
   % compiler - tbxprefix returns the root folder for mathworks toolboxes (its a
   % builtin func) - tempname, tempdir create temp folders and temp files

   % At most one input, the project name
   narginchk(0, 1)

   % Store the initial warning state
   initialWarningState = warning;

   % Create onCleanup object to restore warning state when function terminates
   cleanupObj = onCleanup(@() warning(initialWarningState));

   % Turn off warnings. Default behavior turns off warning about paths not
   % already being on the path when removed.
   warning('off', 'MATLAB:rmpath:DirNotFound')

   % Get the path to this file, which is the project root path, and the project
   % name, which is the project folder name.
   projectpath = fileparts(mfilename("fullpath"));
   [~, projectname] = fileparts(projectpath);

   % Override the inferred projectname/path if the user provided them
   if nargin == 1
      projectname = varargin{1};
   elseif nargin == 2
      projectname = varargin{1};
      projectpath = varargin{2};
   end

   % Safely add all paths to the userpath
   pathadd(projectpath)

   % Set default environment variables
   setenv('MATLAB_ACTIVE_PROJECT', projectname);
   setenv('MATLAB_ACTIVE_PROJECT_PATH', projectpath);
   setenv('MATLAB_ACTIVE_PROJECT_DATA_PATH', fullfile(projectpath, 'data'));
   setenv('MATLAB_ACTIVE_PROJECT_TESTS_PATH', fullfile(projectpath, 'tests'));
   setenv('MATLAB_ACTIVE_PROJECT_TOOLBOX_PATH', fullfile(projectpath, 'toolbox'));

   % Run user hooks (e.g., Config.m, read .env, etc). The dot folder removal
   % should not ever be necessary, but it doesn't hurt to check.
   hookslist = dir(fullfile(projectpath, 'userhooks/*.m'));
   userhooks = fullfile(projectpath, {hookslist.name}.');
   userhooks = userhooks(cellfun(@(p) ~endsWith(p, '.'), userhooks));
   for n = 1:numel(userhooks)
      try
         run(userhooks{n});
         %run(fullfile(projectpath, 'userhooks', 'config'));
      catch
      end
   end

   % This is true if running in desktop. Use it to suppress interactions with
   % the editor or any other feature that requires the Matlab desktop
   % application.
   if usejava('desktop')
      % user hooks related to the editor go here, such as opening or closing
      % files
   end

   % Set preferences setpref('mytoolbox', 'version', toolboxversion)
   % addpref('mytoolbox', 'toolboxdir', thispath);

   % This detects if menv/mproject is being used to manage projects
   if strcmp(mcallername(), 'workon') || strcmp(mcallername(), 'configurepackage')

   end
end

%% function to safely add paths
function pathadd(pathstring)

   % Generate a list of sub-folders. genpath ignores folders named private,
   % folders that begin with the @ character (class folders), folders that begin
   % with the + character (package folders), folders named resources, or
   % subfolders within any of these.
   subpaths = strsplit(genpath(pathstring), pathsep);

   % Specify additional ignore folders.
   ignorepaths = {'.git', '.svn', 'CVS', '.', '..'};

   % Remove ignored folders.
   keep = @(folders, ignore) cellfun('isempty', (strfind(folders, ignore)));
   for n = 1:numel(ignorepaths)
      subpaths = subpaths(keep(subpaths, ignorepaths(n)));
   end

   % Rebuild the path string
   pathstring = strcat(subpaths, pathsep);
   pathstring = horzcat(pathstring{:});

   % Add the paths to the end of the path
   addpath(pathstring, '-end');

   % Save the path (not enabled, generally do not want this)
   % savepath(fullfile(thispath,'pathdef.m'));
end
