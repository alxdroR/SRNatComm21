function [anticipatoryCC] = anticipatoryCorrelationComputation(Y,saccadeTimes,saccadeDirection,timeF,varargin)
options = struct('timeAfterSaccade2Remove',2);
options = parseNameValueoptions(options,varargin{:});


% create saccade-triggered responses
[STRInPlane,timeForSeg,dirInPlane,absTime] = STresponses(Y,saccadeTimes,saccadeDirection,timeF,'startpoint', ...
    0,'endpoint','all','removeInvalids',false,'useSaccadeDuration',false);

% construct time relative to upcoming saccade index
if length(absTime{1})<length(saccadeTimes)
    timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(1:end-1,1));
else
    timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(:,1));
end

NCells = size(Y,2);
anticipatoryCC = zeros(NCells,6);
for cellIndex = 1: NCells
    yL = []; xL=[];
    yR = []; xR = [];
    for nIndex = 2 : length(STRInPlane{cellIndex})
        % do not use options.timeAfterSaccade2Remove seconds after previous
        % saccade 
         acceptableRegion = timeForSeg{cellIndex}{nIndex-1} > options.timeAfterSaccade2Remove;
        % do not use time before previous saccade AND do not use more than
        % 20 seconds before upcomign saccade 
        %acceptableRegion = timeForSeg{cellIndex}{nIndex-1} > options.timeAfterSaccade2Remove & abs(timeRevSeg{cellIndex}{nIndex-1})<10;
        xx = timeRevSeg{cellIndex}{nIndex-1}(acceptableRegion);
        yy = STRInPlane{cellIndex}{nIndex-1}(acceptableRegion);
        xx = xx(~isnan(yy));
        yy = yy(~isnan(yy));
        
        if ~isempty(xx)
            fAntic = yy;
            tAntic = xx;
        else
            fAntic = [];
            tAntic = [];
        end
        if dirInPlane{cellIndex}(nIndex)
            yL = [yL;fAntic];
            xL = [xL;tAntic];
        else
            yR = [yR;fAntic];
            xR = [xR;tAntic];
        end
        
    end
    if ~isempty(xL(~isnan(yL)))
        [CC,PVAL]=corr(xL(~isnan(yL)),yL(~isnan(yL)),'type','Spearman','tail','right');
        anticipatoryCC(cellIndex,1) = CC;
        anticipatoryCC(cellIndex,3) = PVAL;
        
    else
        anticipatoryCC(cellIndex,1) = NaN;
    end
    if ~isempty(xR(~isnan(yR)))
        [CC,PVAL] = corr(xR(~isnan(yR)),yR(~isnan(yR)),'type','Spearman','tail','right');
        anticipatoryCC(cellIndex,2) = CC;
        anticipatoryCC(cellIndex,4) = PVAL;
    else
        anticipatoryCC(cellIndex,2) = NaN;
    end
    anticipatoryCC(cellIndex,5) = sum(~isnan(yL));
    anticipatoryCC(cellIndex,6) = sum(~isnan(yR));
end
end

