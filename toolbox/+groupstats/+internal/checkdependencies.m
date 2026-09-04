function missing = checkdependencies(required)
   %CHECKDEPENDENCIES Report functions groupstats needs but does not ship.
   %
   %  missing = groupstats.internal.checkdependencies()
   %  missing = groupstats.internal.checkdependencies(required)
   %
   % Description
   %  Returns the names in REQUIRED that no file on the MATLAB path defines,
   %  and warns when that list is not empty. With no argument, checks the
   %  functions the toolbox calls but does not ship. Those live in matfunclib
   %  and libplot.
   %
   %  tablecompletions is what functionSignatures.json calls to offer table
   %  variable names, so tab completion stops working without it.
   %  bootdiff is the statistical engine groupdifference calls.
   %
   %  withwarnoff is not on this list. A function sits in
   %  +groupstats/private/ because only +internal calls it, so the toolbox
   %  template ships it there by default. Code that cannot reach a private
   %  function, such as userhooks/config.m, treats it as a vendored
   %  dependency and names it in REQUIRED, and installRequiredFiles resolves
   %  it.
   %
   % Errors
   %  groupstats:checkdependencies:missingDependencies - a warning, not an
   %  error. Listing what is missing at project open beats a chart failing
   %  later with an unrecognized-function error.
   %
   % See also: groupstats.internal.installRequiredFiles

   arguments
      required (:, 1) string = [
         "stacktables"
         "dealout"
         "mcallername"
         "defaultcolors"
         "defaultmarkers"
         "distinguishable_colors"
         "tablecompletions"
         "bootdiff"
         "cat2double"
         "makevalidvarnames"
         "naninterp1"
         ]
   end

   % which returns an empty char for a name no file on the path defines.
   missing = required(arrayfun(@(fn) isempty(which(fn)), required));

   % Warn rather than error. A missing name stops one function, not the
   % whole toolbox, and the project still has to open.
   if ~isempty(missing)
      warning('groupstats:checkdependencies:missingDependencies', ...
         ['These functions are not on the path: %s. ' ...
         'Add matfunclib and libplot to the path, or run ' ...
         'groupstats.internal.installRequiredFiles.'], ...
         strjoin(missing, ', '))
   end
end
