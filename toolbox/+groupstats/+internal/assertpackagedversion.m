function assertpackagedversion(mltbx, expected)
   %ASSERTPACKAGEDVERSION Error unless a packaged toolbox carries the version.
   %
   %  groupstats.internal.assertpackagedversion(mltbx, expected)
   %
   % Description
   %  Reads the version the .mltbx at MLTBX reports and errors,
   %  groupstats:release:versionMismatch, unless it equals EXPECTED, the
   %  version toolbox/version.txt carries without its leading "v". The
   %  release task runs it after packaging, so a stale project field or a
   %  wrong output file cannot ship a package that reports another version.
   %
   % See also: groupstats.internal.releaseoptions, groupstats.internal.version,
   % matlab.addons.toolbox.toolboxVersion

   arguments
      mltbx (1, 1) string {mustBeFile}
      expected (1, 1) string
   end

   packaged = string(matlab.addons.toolbox.toolboxVersion(mltbx));
   if packaged ~= expected
      error('groupstats:release:versionMismatch', ...
         ['The packaged toolbox %s reports version %s, but version.txt ' ...
         'says %s.'], mltbx, packaged, expected)
   end
end
