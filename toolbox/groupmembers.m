function vars = groupmembers(T, XGroupVar)
   if isempty(XGroupVar)
      vars = string.empty();
   else
      vars = unique(T.(XGroupVar));
   end
end