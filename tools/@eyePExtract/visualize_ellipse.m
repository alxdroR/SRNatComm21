function [x,y,ph,phMA] = visualize_ellipse(s,fig,varargin)
% s -- region_props output
% fig is figure displaying image
% visualizing regionprops ellipse measurments
% http://blogs.mathworks.com/steve/2010/07/30/visualizing-regionprops-ellipse-measurements/
%
%  [x,y] = visualize_ellipse(s,fig,Leye)
% when plotting eye movements, we would like to tell if the algorithm is
% correctly telling left from right.

createPlotHandle = true;
if ~isempty(varargin)
    Leye = varargin{1};
    if length(varargin)>1
        ph = varargin{2};
        phMA = varargin{3};
        createPlotHandle = false;
    end
end
figure(fig); hold on;
elipObj = ellipseImgRgns('majorAxis',[],'minorAxis',[],'orientation',[],'spacing',7);
x = cell(length(s),1);
y = cell(length(s),1);
for k = 1:length(s)
    elipObj.center = s(k).Centroid;
    elipObj.majorAxis = s(k).MajorAxisLength/2;
    elipObj.minorAxis = s(k).MinorAxisLength/2;
    elipObj.orientation = s(k).Orientation;
    [x{k},y{k}] = elipObj.makeShape;
    % get points along major axis so we can plot direction of eyes
    [lineThroughEllipseX,lineThroughEllipseY] = elipObj.getPointsOnMajorAxis('stretch',1.3);
    if ~isempty(varargin)
        if k==Leye
            clr = 'b';
        else
            clr  = 'r';
        end
    else
        clr = 'r';
    end
    if createPlotHandle
        ph(k) = plot(x{k},y{k},clr,'LineWidth',2);
        phMA(k) = plot(lineThroughEllipseX,lineThroughEllipseY,clr); % function added 5/21/2019-ad
    else
        hold off
        set(ph(k),'XData',x{k},'YData',y{k});
        set(phMA(k),'XData',lineThroughEllipseX,'YData',lineThroughEllipseY);
    end
end
end