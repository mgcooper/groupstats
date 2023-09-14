function version = getversion()
   %GETVERSION Read version.txt in the toolbox root directory.
   %
   %  version = groupstats.internal.getversion()
   %
   % See also:

   try
      version = fileread(groupstats.internal.projectpath(), 'version.txt');
   catch
      version = 'v0.1.0';
   end
end
