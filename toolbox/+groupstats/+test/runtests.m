function varargout = runtests(what)
   %RUNTESTS Run unit tests.

   if nargin < 1
      what = 'all';
   end

   import matlab.unittest.TestSuite;

   testfolder = groupstats.internal.projectpath('tests');

   % Found here https://github.com/ragavsathish/mmockito/blob/master/runtests.m

   % add a check that the setupfile has been run and if not, run it

   switch what
      case 'all'
         suite = TestSuite.fromFolder(testfolder, 'IncludingSubfolders', true);
         result = transpose(suite.run());
         % suite = TestSuite.fromPackage("groupstats.test", "IncludingSubpackages", true);
      case 'acceptance'
         suite = TestSuite.fromFolder(fullfile(testfolder, 'acceptance'));
         result = transpose(suite.run());
      case 'unit'
         suite = TestSuite.fromFolder(fullfile(testfolder, 'unit'));
         result = transpose(suite.run());
      otherwise
         try
            result = run(TestSuite.fromFolder('tests', 'IncludingSubfolders', true));
         catch e
            error('No tests found in tests/ folder');
         end
   end

   disp(result.table)

   % print the results to the screen (bit more user friendly than the default)
   % for n = 1:numel(result)
   %    if result(n).Passed == true
   %       disp(['Passed Test ' int2str(n)])
   %    else
   %       disp(['Failed Test ' int2str(n)])
   %    end
   % end


   % disp([num2str(nnz([result.Passed]) / numel(result) * 100), ' % tests passed']);

   switch nargout
      case 1
         varargout{1} = result;
   end
end
