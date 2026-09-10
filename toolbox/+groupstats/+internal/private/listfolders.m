function folderlist = listfolders(toppath, numlevels, option, currentlevel)
   %LISTFOLDERS Return a list of folders under a top-level directory.
   %
   %  FLIST = LISTFOLDERS(TOPPATH) Returns a cell array of folder names under
   %  the top-level directory specified by TOPPATH. It does not include
   %  subdirectories.
   %
   %  FLIST = LISTFOLDERS(TOPPATH, NUMLEVELS) Specifies the depth of folder
   %  hierarchy to explore. NUMLEVELS=0 (default) only returns the folders under
   %  TOPPATH. NUMLEVELS=1 returns those folders plus their subfolders, and so
   %  on.
   %
   %  FLIST = LISTFOLDERS(TOPPATH, NUMLEVELS, OPTION) Specifies the format of
   %  the output list. Options: 'foldernames' (default) returns only the folder
   %  names, 'relativepaths' returns the relative path from TOPPATH, 'fullpaths'
   %  returns the full path of the folders.
   %
   % Example
   %   Suppose we have a folder structure as follows:
   %       myfolder/
   %           - subfolder1/
   %           - subfolder2/
   %               - subsubfolder1/
   %           - subfolder3/
   %   listfolders('myfolder', 1, 'relativepaths') will return
   %   {'subfolder1', 'subfolder2', 'subfolder2/subsubfolder1', 'subfolder3'}.
   %
   % See also: dir

   % PARSE INPUTS
   narginchk(0,4)

   if nargin < 2 || isempty(numlevels), numlevels = 0; end
   if nargin < 3 || isempty(option), option = 'foldernames'; end
   if nargin < 4 || isempty(currentlevel), currentlevel = 0; end

   % MAIN CODE
   d = rmdotfolders(dir(toppath));
   isub = [d(:).isdir];
   toplist = {d(isub).name}';

   if strcmp(option, 'fullpaths')
      folderlist = cellfun(@(x) fullfile(toppath, x), toplist, 'UniformOutput', false);
   elseif strcmp(option, 'relativepaths') || strcmp(option, 'foldernames')
      folderlist = toplist;
   end

   % Recursion. One cell per folder holds the list below it, and the
   % cells are joined once, so no list grows inside the loop.
   if numlevels == -1 || currentlevel < numlevels

      nextlists = cell(numel(toplist), 1);
      for n = 1:numel(toplist)
         nextpath = fullfile(toppath, toplist{n});
         nextlist = listfolders(nextpath, numlevels, option, currentlevel+1);

         if strcmp(option, 'relativepaths')
            nextlist = strcat(toplist{n}, '/', nextlist);
         end

         nextlists{n} = nextlist;
      end
      folderlist = [folderlist; vertcat(nextlists{:})];
   end
end
