function fullpath = installpath(toolboxname)
   %INSTALLPATH Return toolbox installation path from user preferences group.
   %
   % FULLPATH = INSTALLPATH() Returns the install path stored in the preferences
   % group named for this package.
   %
   % FULLPATH = INSTALLPATH(TOOLBOXNAME) Returns the install path stored in the
   % preferences group TOOLBOXNAME.
   %
   % This errors until something writes the 'install_path' preference.
   %
   % See also: mpackagename, getpref
   if nargin < 1
      toolboxname = mpackagename();
   end
   fullpath = getpref(toolboxname, 'install_path');
end
