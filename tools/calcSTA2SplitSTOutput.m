function [STOutputLeft,STOutputRight,STOutputCAT,varargout] = calcSTA2SplitSTOutput(STOutput,varargin)
options = struct('timeAIndex',1,'timeBIndex','all','selectionCriteria',[],'STTime',[]);
options = parseNameValueoptions(options,varargin{:});

[numSTs,numTimeBins,~] = size(STOutput); 

%  does the user want to limit the times 
if ischar(options.timeBIndex)
    timeBIndex = numTimeBins;
else
    timeBIndex = options.timeBIndex;
end
timeIndices = options.timeAIndex:timeBIndex;

% did the user specify a selection criteria 
if isempty(options.selectionCriteria)
    selectionCriteria = 1:numSTs;
else
    selectionCriteria = options.selectionCriteria;
end

STOutputLeft = STOutput(selectionCriteria,timeIndices,1);
STOutputRight = STOutput(selectionCriteria ,timeIndices,2);
STOutputCAT = [STOutputLeft;STOutputRight];

% does the user have a corresponding time vector they want cut in the same way
if ~isempty(options.STTime)
    cutTime = options.STTime(timeIndices);
    varargout{1} = cutTime;
end
end

