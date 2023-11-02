function varargout = generateTestData(whichfunction)
   %GENERATETESTDATA Generate test data.

   switch whichfunction

      case 'groupbayes'


         % Create a table T representing events
         groupvar = 'Group';
         groupA = {'A1', 'A2'};
         groupB = {'B1', 'B2'};
         T = table({'A1'; 'A2'; 'B1'; 'B2'; 'A1'; 'B2'; 'A1'; 'B1'; 'A2'; 'B2'}, ...
            [true; false; true; true; true; false; true; false; true; true], ...
            [false; true; true; false; true; true; false; true; false; false], ...
            [true; true; false; false; true; true; false; false; true; true], ...
            [false; false; true; true; false; true; true; false; false; true], ...
            'VariableNames', {groupvar, 'A1', 'A2', 'B1', 'B2'});

         % Use the function groupbayes to calculate conditional probabilities
         % P = groupbayes(T, groupA, groupB, groupvar);

         TestData.T = T;
         TestData.groupvar = groupvar;
         TestData.groupA = groupA;
         TestData.groupB = groupB;
         ExpectedResult.P_A = [0.3 0.3 0.2 0.2];
         ExpectedResult.P_B = [0.2 0.3 0.2 0.3];

         switch nargout
            case 1
               varargout{1} = TestData;
            case 2
               varargout{1} = TestData;
               varargout{2} = ExpectedResult;
         end

         % Expected Result:
         % GroupA    GroupB     P_A       P_B       P_A_AND_B    P_B_GIVEN_A    P_A_GIVEN_B
         % 'A1'      'B1'       0.3       0.2       0.2          0.6667         1.0000
         % 'A1'      'B2'       0.3       0.3       0.1          0.3333         0.3333
         % 'A2'      'B1'       0.2       0.2       0.2          1.0000         1.0000
         % 'A2'      'B2'       0.2       0.3       0            0.0000         0.0000
   end
end