function varargout = testnamespace(whichtest)
   %TESTNAMESPACE Test namespace access.
   %
   % TESTNAMESPACE("internal") Calls a +groupstats/+internal function.
   % TESTNAMESPACE("private") Calls a +groupstats/private function.
   %
   % Two resolution rules that MATLAB does not report as errors until a call
   % fails:
   %
   %  1. Code in +groupstats reaches +internal only through the qualified name
   %     groupstats.internal.<fn>. The unqualified name does not resolve.
   %  2. Code in +groupstats reaches +groupstats/private unqualified.
   %
   % This file must stay in +groupstats. That is the only folder from which
   % both rules are testable: +groupstats/private is invisible to code in
   % +groupstats/+internal and +groupstats/+test.
   %
   % See also: groupstats.internal.version

   arguments
      whichtest (1,1) string {mustBeMember(whichtest, ["internal", "private"])}
   end

   switch whichtest

      case 'internal'

         % test +internal folder
         [varargout{1:max(1, nargout)}] = groupstats.internal.version();
         % [varargout{1:max(1, nargout)}] = getversion(); % does not work

      case 'private'
         % test +gs/private folder
         [varargout{1:max(1, nargout)}] = isvariable('test', table());
   end
end
