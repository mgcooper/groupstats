classdef test_reordergroupmembers < matlab.unittest.TestCase
   %TEST_REORDERGROUPMEMBERS Test the shared group-order helper.
   %
   % barchartcats and boxchartcats both order their x-groups and their color
   % groups against a caller's list. That list may name a subset. Both charts
   % read the order from here, so a defect here reaches four options.
   %
   % See also: groupstats.barchartcats, groupstats.boxchartcats

   properties
      reorder
   end

   methods (TestClassSetup)

      function resolveHandle(testCase)
         testCase.reorder = groupstats.internal.privatefunction( ...
            'reordergroupmembers');
      end
   end

   methods (Test)

      function testFullOrder(testCase)
         returned = testCase.reorder(["c"; "a"; "b"], ["a"; "b"; "c"], ...
            "barchartcats", "CGroupOrder");

         testCase.verifyEqual(returned, [3; 1; 2]);
      end

      function testPartialOrderKeepsTheRestBehind(testCase)
         % Naming one member must not drop the others.

         returned = testCase.reorder("c", ["a"; "b"; "c"], ...
            "barchartcats", "CGroupOrder");

         testCase.verifyEqual(returned, [3; 1; 2]);
      end

      function testSingleMemberList(testCase)
         returned = testCase.reorder("a", "a", "barchartcats", "XGroupOrder");

         testCase.verifyEqual(returned, 1);
      end

      function testOrderThatChangesNothing(testCase)
         returned = testCase.reorder(["a"; "b"], ["a"; "b"], ...
            "barchartcats", "CGroupOrder");

         testCase.verifyEqual(returned, [1; 2]);
      end

      function testNonMemberIsRejected(testCase)
         % The error names the calling function and the option the caller
         % typed, so the message is about their call.

         testCase.verifyError(@() testCase.reorder("z", ["a"; "b"], ...
            "boxchartcats", "XGroupOrder"), ...
            'groupstats:boxchartcats:badXGroupOrder');
      end

      function testRepeatedNameIsRejected(testCase)
         % A repeat would index one member twice, which reordercats rejects
         % further down with a message naming neither the option nor the
         % value.

         testCase.verifyError(@() testCase.reorder(["a"; "a"], ["a"; "b"], ...
            "barchartcats", "CGroupOrder"), ...
            'groupstats:barchartcats:repeatedCGroupOrder');
      end

      function testEveryIndexAppearsOnce(testCase)
         % The result indexes the member list, so it must be a permutation.

         members = ["a"; "b"; "c"; "d"];

         returned = testCase.reorder(["d"; "b"], members, ...
            "barchartcats", "CGroupOrder");

         testCase.verifyEqual(sort(returned), (1:numel(members))');
      end
   end
end
