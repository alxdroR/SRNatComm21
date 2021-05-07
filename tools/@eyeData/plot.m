function options=plot(eyeobj,varargin)
% function plot(eyeobj,varargin)
% plot eye position versus time
% Name-value pair input options
% struct('plotPlane',1,'axisHandle',[],'figureHandle',[],'drawSaccadeTimes',false,'LineStyle','-',...
%    'Marker','none','color',[[1 1 1]*0;[1 1 1]*0.8],'drawEye','both');

options = struct('plotPlane',1,'axisHandle',[],'figureHandle',[],'drawSaccadeTimes',false,'LineStyle','-',...
    'Marker','none','color',[[1 1 1]*0;[1 1 1]*0.8],'drawEye','both','showNull',false);
options = parseNameValueoptions(options,varargin{:});

grabFigure(options.figureHandle);
if isempty(options.axisHandle)
    for eyeInd =1 : 2
        options.axisHandle{eyeInd} = subplot(2,1,eyeInd);
    end
end
hold on;

if strcmp(options.plotPlane,'all')
    options.plotPlane = 1:length(eyeobj.time);
end
offsetTime = 0;
% determine which eyes to show
switch options.drawEye
    case 'both'
        eyeIndV = 1:2;
    case 'left'
        eyeIndV = 1;
    case 'right'
        eyeIndV = 2;
end
if options.drawSaccadeTimes
    if isempty(eyeobj.saccadeTimes{1})
        eyeobj = eyeobj.saccadeDetection;
    end
end

ymax = 0; ymin = 0;
for plane = reshape(options.plotPlane,[1 length(options.plotPlane)])
    
    % center the position traces
    positionMean = mean(eyeobj.position{plane});
    centeredPosition = bsxfun(@minus,eyeobj.position{plane},positionMean);
    ymax = max(ymax,max(max(centeredPosition)));
    ymin = min(ymin,min(min(centeredPosition)));
    count = 1;
    for eyeInd =eyeIndV
        axes(options.axisHandle{count})
        plot(eyeobj.time{plane}(:,eyeInd) + offsetTime,centeredPosition(:,eyeInd),'color',options.color(count,:) ...
            ,'LineStyle',options.LineStyle,'Marker',options.Marker); hold on;
        
        if options.showNull
            % plot([0 eyeobj.time{plane}(end,eyeInd)] + offsetTime,[1 1]*positionMean(eyeInd),'k--');
            plot([0 eyeobj.time{plane}(end,eyeInd)] + offsetTime,[1 1]*0,'k--');
        end
        
        if options.drawSaccadeTimes
            for segmentInd = 1 : length(eyeobj.saccadeTimes{plane}{eyeInd})
                plot([1 1]*eyeobj.saccadeTimes{plane}{eyeInd}(segmentInd)+offsetTime,[-50 50],'r');
            end
        end
        count = count+1;
        ylim([ymin ymax])
    end
    offsetTime = offsetTime + eyeobj.time{plane}(end,1);
    
end

end