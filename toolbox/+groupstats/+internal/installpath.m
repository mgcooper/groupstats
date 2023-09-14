function fullpath = installpath(toolboxname)
   %INSTALLPATH Get toolbox installation path from user preferences group.
   fullpath = getpref(toolboxname, 'install_path');
end