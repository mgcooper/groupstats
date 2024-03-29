function tf = isoctave()
   %ISOCTAVE Determine if the environment is Octave.
   %
   % See also: 

   persistent cacheval;  % speeds up repeated calls

   if isempty (cacheval)
      cacheval = (exist ("OCTAVE_VERSION", "builtin") > 0);
   end

   tf = cacheval;
end
