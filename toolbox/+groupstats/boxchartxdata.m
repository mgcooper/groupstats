function [xlocs,xleft,xright] = boxchartxdata(H)
   %BOXCHARTXDATA retrieve x-axis data for boxcharts in handle H
   %
   % Syntax
   %  xlocs = boxchartxdata(H) returns the xtick locations for each boxchart in
   %  H. If H contains groups of boxchart, each element of H is a group of
   %  boxcharts per xtick in the figure.
   %
   % Inputs:
   %  H = BoxChart graphics object (one group per element of H). Every
   %      element must share one Notch setting.
   %
   % Outputs:
   %  xlocs = array of xtick locations for each boxchart group in H
   %
   % More detail:
   % size(xlocs) = numel(cgroupvars) x numel(xgroupvars) = M x N
   % size(H) = numel(cgroupvars) x 1 = M x 1
   %
   % i.e., for a boxchart figure with:
   % N = numel(xgroupvars) (number of xticks), and
   % M = numel(cgroupvars) (number of boxcharts per xtick),
   %
   % size(H) = M x 1 (number of boxcharts per xtick BY 1)
   % size(xlocs) = M x N (number of boxcharts per xtick BY number of xticks)
   %
   %
   % Example
   %
   % Label every box with its median, placed at the box's x coordinate:
   %
   %  data = groupstats.test.generateTestData('info');
   %  [H, ~, ax] = groupstats.boxchartcats(data.Info, "peak", "month", ...
   %     "scenario", XGroupMembers = ["Jan", "Feb", "Mar"]);
   %  xlocs = groupstats.boxchartxdata(H);
   %  text(ax, xlocs(1, :), [12 12 12], "median", ...
   %     HorizontalAlignment = "center")
   %
   % See also boxchartcats, groupstats.boxchartydata

   % Each element of H is one color group's boxes. H(m).NodeChildren(5) is
   % the Quadrilateral primitive that draws the box faces. A notched box
   % has 8 vertices and a plain one 4. One count serves every element, so
   % every chart in H must share one Notch setting; boxchartcats sets
   % Notch once for all of its boxes. A mixed H would read the notched
   % charts with the wrong stride.
   % drawnow makes the primitive's vertex data current before it is read,
   % and the warning it can raise on the way is not the caller's.
   withwarnoff('MATLAB:handle_graphics:exceptions:SceneNode');
   drawnow;

   % Data dimensions
   M = numel(H);

   if all( [H.Notch] == 'on' )
      numVertsPerBox = 8;
   else
      numVertsPerBox = 4;
   end

   % Functions to retrieve box vertices and reshape them to per-box columns
   Fverts = @(m) H(m).NodeChildren(5).VertexData(1,:);
   Fshape = @(m) reshape(Fverts(m), numVertsPerBox, []);

   % Part 1 - Get the x-coordinates of the center of each boxchart. A box's
   % center is the mean of its two x vertices. On boxchart's categorical
   % ruler the ticks sit at the integers, and a group's boxes spread less
   % than half a tick to either side. The rounded center is therefore the
   % tick the box belongs to, and it indexes the box's column.
   xverts = cell(M, 1);
   centers = cell(M, 1);
   for m = 1:M
      xverts{m} = double(Fshape(m));
      centers{m} = mean(xverts{m}(1:2, :), 1);
   end

   % One column per tick up to the highest tick any group reaches. The box
   % count of one group can be smaller than that, so sizing by the count
   % would let a later assignment grow the matrix with zeros. A tick with
   % no box of a group keeps NaN in that column.
   ticks = round([centers{:}]);
   xlocs = nan(M, max([ticks, 0]));
   xleft = nan(1, max([ticks, 0]));
   xright = nan(1, max([ticks, 0]));
   for m = 1:M
      xlocs(m, round(centers{m})) = centers{m};

      % Part 2 - Get the min/max bounds of each boxchart group: the left
      % edge of the first group's boxes and the right edge of the last
      % group's, placed by the same tick index.
      switch m
         case 1
            xleft(round(centers{m})) = xverts{m}(1, :);
         case M
            xright(round(centers{m})) = xverts{m}(2, :);
      end
   end

   % With one color group the first group is also the last, and the switch
   % above took only the first case.
   if M == 1
      xright(round(centers{M})) = xverts{M}(2, :);
   end
end
