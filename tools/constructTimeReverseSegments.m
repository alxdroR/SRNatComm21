function timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes)
%timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes)
%  Create an array of cell arrays that gives the time segments were
%  recorded with respect to the upcoming saccade. The value is NaN if 
%  we don't have the upcoming saccade. 


nCells = length(absTime);

% check length of absTime{i} is the same for all elements
uniqueLengths = unique(cellfun('size',absTime,1));
if length(uniqueLengths)~= 1
    error('All elements absTime{i} need to have the same length');
else
    numTrials = uniqueLengths;
end

if numTrials ~= length(saccadeTimes)
    error('All elements absTime{i} should equal length(saccadeTimes)')
end

timeRevSeg = cell(size(absTime));
for cellIndex = 1:nCells
    timeRevSeg{cellIndex} = cell(numTrials,1);
    for trialIndex=1:numTrials-1
        timeReversal = absTime{cellIndex}{trialIndex}-saccadeTimes(trialIndex+1);
        timeRevSeg{cellIndex}{trialIndex} = timeReversal;
    end
    timeRevSeg{cellIndex}{numTrials}= NaN;
end

end

