function version = getversion()
   %GETVERSION Read version.txt in the toolbox root directory.
   %
   %  version = tbx.util.getversion()
   %
   % See also:

   try
      version = fileread(gs.util.projectpath(), 'version.txt');
   catch
      version = 'v0.1.0';
   end
end
