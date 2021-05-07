function [AM,indexLookUp] = raggedArray2Matrix(timeSegments,A,binTimes,varargin)
% raggedArray2Matrix(timeSegments,A,binTimes)
% convet ragged array into a matrix using interpolation. Use 
% NaNs to fill in missing values. A is assumed to be of the form
% A{i}{j} holds a vector whose size can vary with i and j.
% The length of A{i} is assumed to be fixed 

options = struct('endInterpAtNeighboringSaccade',false,'neighborTimes',[]);
options = parseNameValueoptions(options,varargin{:});


% determine the matrix size
T = length(binTimes);
nCells = length(A);

% check length of A{i} is the same for all elements
uniqueLengths = unique(cellfun('size',A,1));
if length(uniqueLengths)~= 1
    error('All elements A{i} need to have the same length');
else
    numTrials = uniqueLengths;
end

% check proper input for interpolation
if options.endInterpAtNeighboringSaccade
    if isempty(options.neighborTimes)
        error('User must enter the points where interpolation cannot go past in field `neighborTimes`. `neighborTimes must be numTrials -1`');
    end
end
AM = zeros(numTrials*nCells,T);
indexLookUp = zeros(numTrials*nCells,2);
for cellIndex = 1:nCells
    for trialIndex=1:numTrials
        tCoarse = timeSegments{cellIndex}{trialIndex};
        yCoarse = A{cellIndex}{trialIndex};
        if length(tCoarse)>=2
            STRq=interp1(tCoarse,yCoarse,binTimes);
            if options.endInterpAtNeighboringSaccade && trialIndex < numTrials
                % cut off the interpolated times that went too far
                tooFar = abs(binTimes)>abs(options.neighborTimes(trialIndex));
                STRq(tooFar)=NaN;
            end
            AM(trialIndex + (cellIndex-1)*numTrials,:)=STRq;
        else
            AM(trialIndex + (cellIndex-1)*numTrials,:) = NaN;
        end
        indexLookUp(trialIndex + (cellIndex-1)*numTrials,:) = [cellIndex,trialIndex];
    end
end
end

