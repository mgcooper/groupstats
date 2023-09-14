function fullpath = projectpath(varargin)
   %PROJECTPATH Return the full path to the top-level project directory.
   %
   %
   %
   % See also
   fullpath = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));

   if nargin == 1
      fullpath = fullfile(fullpath, varargin{:});
   end
end
