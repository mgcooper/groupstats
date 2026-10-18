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
   %  The fixture also holds the root defaultAxesColorOrder value that the
   %  session has at setup. defaultcolors reads its first seven rows from
   %  that value, and from R2025a the graphics theme changes it. An R2025b
   %  batch session can apply a dark theme about one second after graphics
   %  start. With the value held, a palette read in a test and a chart's own
   %  read give the same colors. Teardown puts back the earlier value, or
   %  removes the setting when the test found none.
   %
   %  Read the open figure from the Figure property when a test needs the
   %  handle.
   %
   % See also: matlab.unittest.fixtures.Fixture, figure, defaultcolors

   properties (SetAccess = private)
      % The figure this fixture opened.
      Figure
   end

   methods

      function setup(fixture)
         % Register the restore first, so it runs last, after the figure
         % closes. get(groot, 'default') lists only the defaults that code
         % set, so a missing field means the setting was unset.
         defaults = get(groot, 'default');
         if isfield(defaults, 'defaultAxesColorOrder')
            fixture.addTeardown(@() set(groot, 'defaultAxesColorOrder', ...
               defaults.defaultAxesColorOrder));
         else
            fixture.addTeardown(@() set(groot, 'defaultAxesColorOrder', ...
               'remove'));
         end

         % Setting the order to its own value fixes it, so a later theme
         % change leaves it as it is.
         set(groot, 'defaultAxesColorOrder', ...
            get(groot, 'defaultAxesColorOrder'));

         % Open the invisible figure that the test draws into.
         fixture.Figure = figure('Visible', 'off');
         fixture.addTeardown(@() close(fixture.Figure));
      end
   end
end
