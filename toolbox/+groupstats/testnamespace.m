function varargout = testnamespace(whichtest)
   %TESTNAMESPACE Test namespace access.

   arguments
      whichtest (1,1) string {mustBeMember(whichtest, ["internal", "private"])}
   end

   switch whichtest

      case 'internal'

         % test +internal folder
         [varargout{1:max(1, nargout)}] = groupstats.internal.getversion();
         % [varargout{1:max(1, nargout)}] = getversion(); % does not work

      case 'private'
         % test +gs/private folder
         [varargout{1:max(1, nargout)}] = isvariable('test', table());
   end
end