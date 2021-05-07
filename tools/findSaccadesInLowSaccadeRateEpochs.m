function [passes,varargout] = findSaccadesInLowSaccadeRateEpochs(eyeobj,minSacRatePerDirection,sizeOfEpoch,varargin)

options = struct('eyeInd','left','eventTimes',[],'maxTime',60*60);
options = parseNameValueoptions(options,varargin{:});

if ischar(options.eyeInd)
    switch options.eyeInd
        case 'left'
            eyeIndV = 1 ;
        case 'right'
            eyeIndV = 2;
        case 'both'
            eyeIndV = 1:2;
            error('Not working ')
    end
else
    eyeIndV = options.eyeInd;
end
eyeInd = eyeIndV; % temp while both eyes option is down -- adr - 4/23/2018

conjSacc = false;
% combine saccades into a matrix
if length(eyeobj.saccadeTimes)>1
    if ~conjSacc
        % any one of the two eyes has to pass criteria
        saccadeTimesCell = cellfun(@(z,x) z{eyeInd} + x(end,eyeInd),eyeobj.saccadeTimes(2:end),eyeobj.time(1:end-1),'UniformOutput',false);
        saccadeTimes = [eyeobj.saccadeTimes{1}{eyeInd};cell2mat(saccadeTimesCell)];
    else
        % only exmaine conjugate saccaedes
        saccadeTimes = []; saccadeDirection = [];
        for planeIndex = 1 : length(eyeobj.saccadeTimes)
            [saccadeTimes0,saccadeDirection0] = combineSaccadeTimesAcrossEyes(eyeobj,planeIndex);
            saccadeTimes = [saccadeTimes; saccadeTimes0];
            saccadeDirection = [saccadeDirection;saccadeDirection0];
        end
    end
else
    if ~conjSacc
        saccadeTimes = eyeobj.saccadeTimes{1}{eyeInd};
    else
        [saccadeTimes,saccadeDirection] = combineSaccadeTimesAcrossEyes(eyeobj,1);
    end
end
if ~isempty(saccadeTimes)
    saccadeTimes = saccadeTimes(:,1);
end

if isempty(options.eventTimes)
    eventTimes = saccadeTimes;
else
    eventTimes = options.eventTimes;
end
if ~conjSacc
    % create a matrix of all saccade directions since experiment beginning.
    saccadeDirectionCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeDirection,'UniformOutput',false);
    saccadeDirection = cat(1,saccadeDirectionCell{:});
end
% compute a lower bound on the amount of time elapsed since the beginning
% of recording.
totalTimeInPlane = cellfun(@(z) z(end,eyeInd),eyeobj.time);
cumAmountOfTime = cumsum(totalTimeInPlane);

numSections = ceil(cumAmountOfTime(end)/sizeOfEpoch);
if numSections<2
    fprintf('%s-total time(min)=%0.3f\n',eyeobj.fishID,cumAmountOfTime(end)/60);
end
sacIndex2Remove = false(size(eventTimes));
passesAllSections = false(numSections,1);
sacRate = struct('toLeft',NaN(numSections,1),'toRight',NaN(numSections,1));
for sectionIndex = 1 : numSections
    if sizeOfEpoch*(sectionIndex-1) < options.maxTime
        saccadesInWindow = sizeOfEpoch*(sectionIndex-1) < saccadeTimes & saccadeTimes<= sizeOfEpoch*sectionIndex;
        windowIndicesForRemovalVector = sizeOfEpoch*(sectionIndex-1) < eventTimes & eventTimes<= sizeOfEpoch*sectionIndex;
        
        dirInWindow = saccadeDirection(saccadesInWindow);
        numberL = sum(dirInWindow);
        numberR = sum(~dirInWindow);
        sacRate.toLeft(sectionIndex) = numberL/sizeOfEpoch;
        sacRate.toRight(sectionIndex) = numberR/sizeOfEpoch;
        %if (numberL + numberR) < minSacRatePerDirection
        if ~(numberL >= minSacRatePerDirection && numberR >= minSacRatePerDirection)
            sacIndex2Remove(windowIndicesForRemovalVector) = true;
        else
            passesAllSections(sectionIndex) = true;
        end
    end
end
passes = sum(passesAllSections)>=1;
varargout{1} = sacRate;
end

