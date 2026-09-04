function opts = releaseoptions(root)
   %RELEASEOPTIONS Build the packaging options a release uses.
   %
   %  opts = groupstats.internal.releaseoptions(root)
   %
   % Description
   %  Returns the matlab.addons.toolbox.ToolboxOptions that buildfile's
   %  release task packages. ROOT is the repository root, the folder holding
   %  GroupStats.prj.
   %
   %  The MATLAB Project holds a Package Toolbox task, added in R2025a, which
   %  carries the identifier, the author fields, the file list, and the
   %  exclusions in toolbox/toolbox.ignore. Reading it keeps one definition of
   %  the release rather than a second copy in a packaging prj.
   %
   %  The version is the one field this overrides. version.txt is the single
   %  place the version is written down, so a release cannot ship a version
   %  that disagrees with the source.
   %
   %  This is separate from the release task so that a test can read the
   %  options without packaging a toolbox.
   %
   % Errors
   %  MATLAB:toolbox_packaging:packaging:NotValidToolboxPRJ - raised before
   %  R2025a, where the Package Toolbox task does not exist.
   %
   % See also: buildfile, matlab.addons.toolbox.packageToolbox

   arguments
      root (1,1) string
   end

   opts = matlab.addons.toolbox.ToolboxOptions( ...
      fullfile(root, "GroupStats.prj"));

   % version.txt carries a leading "v", which a toolbox version must not have.
   addpath(fullfile(root, "toolbox"))
   opts.ToolboxVersion = erase(groupstats.internal.version(), "v");
end
