function [durationWhenNextSaccadeIsLeft,durationWhenNextSaccadeIsRight,totalRecTime] = computeSaveWithinPlaneDurations(fishName,expCond,varargin)
options = struct('restrict2TwaitMinAfterAbl',false,'Twait',30,'stackTimes',[],'ablationTimeMeta',[]);
options = parseNameValueoptions(options,varargin{:});

eyeobj = eyeData('fishid',fishName,'expcond',expCond);
eyeobj = eyeobj.saccadeDetection;
eyeInd=1;

if options.restrict2TwaitMinAfterAbl
    [recTimeRelative2Ablation] = eyeTime2AblationRelTime(eyeobj,...
        'stackTimes',options.stackTimes,'ablationTimeMeta',options.ablationTimeMeta,'useFirstAblation',false,'planeIndex','all');
    tstart = cellfun(@(x) x(1,1),recTimeRelative2Ablation); % extract time of recording start relative to last ablation
    usePlaneBool = tstart >= options.Twait;
    
    [durationWhenNextSaccadeIsLeft,durationWhenNextSaccadeIsRight]=calcCombinedDuration(eyeobj,eyeInd,'onlyUseThesePlanes',usePlaneBool);
    totalRecTime = calcTotalRecTime(eyeobj,eyeInd);
else
    [durationWhenNextSaccadeIsLeft,durationWhenNextSaccadeIsRight]=calcCombinedDuration(eyeobj,eyeInd);
    totalRecTime = calcTotalRecTime(eyeobj,eyeInd);
end
end

function [durationWhenNextSaccadeIsLeft,durationWhenNextSaccadeIsRight]=calcCombinedDuration(eyeobj,eyeInd,varargin)
options = struct('onlyUseThesePlanes',[]);
options = parseNameValueoptions(options,varargin{:});

saccadeTimesCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeTimes,'UniformOutput',false);
saccadeDirectionCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeDirection,'UniformOutput',false);
ISIInFigure = cellfun(@(z) nanPadISIVector(z,'useOldBug',false),saccadeTimesCell,'UniformOutput',false);
durationWhenNextSaccadeIsLeft = cellfun(@(x,y) selectUpcomingLeftSaccade(x,y),saccadeDirectionCell,ISIInFigure,'UniformOutput',false);
durationWhenNextSaccadeIsRight = cellfun(@(x,y) selectUpcomingRightSaccade(x,y),saccadeDirectionCell,ISIInFigure,'UniformOutput',false);

if ~isempty(options.onlyUseThesePlanes)
    durationWhenNextSaccadeIsLeft = cell2mat(durationWhenNextSaccadeIsLeft(options.onlyUseThesePlanes));
    durationWhenNextSaccadeIsRight = cell2mat(durationWhenNextSaccadeIsRight(options.onlyUseThesePlanes));
else
    durationWhenNextSaccadeIsLeft = cell2mat(durationWhenNextSaccadeIsLeft);
    durationWhenNextSaccadeIsRight = cell2mat(durationWhenNextSaccadeIsRight);
end

end

function totalRecTime = calcTotalRecTime(eyeobj,eyeInd,varargin)
options = struct('onlyUseThesePlanes',[]);
options = parseNameValueoptions(options,varargin{:});

totalRecTimeV = cellfun(@(z) z(end,eyeInd),eyeobj.time,'UniformOutput',true);
if ~isempty(options.onlyUseThesePlanes)
    totalRecTime = sum(totalRecTimeV(options.onlyUseThesePlanes));
else
    totalRecTime = sum(totalRecTimeV);
    
end
end