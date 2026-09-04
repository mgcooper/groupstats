classdef InvisibleFigure < matlab.unittest.fixtures.Fixture
   %INVISIBLEFIGURE Open an invisible figure for the duration of a test.
   %
   %  testCase.applyFixture(groupstats.test.fixtures.InvisibleFigure)
   %
   % Description
   %  Chart tests need an axes to plot into but must not open a window, so the
   %  suite runs headless. This fixture opens a figure with Visible off, makes
   %  it current, and closes it on teardown.
   %
   %  Read the open figure from the Figure property when a test needs the
   %  handle.
   %
   % See also: matlab.unittest.fixtures.Fixture, figure

   properties (SetAccess = private)
      % The figure this fixture opened.
      Figure
   end

   methods

      function setup(fixture)
         fixture.Figure = figure('Visible', 'off');
         fixture.addTeardown(@() close(fixture.Figure));
      end
   end
end
