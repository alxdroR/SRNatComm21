function [sacIndex2Remove] = findSaccadesLongerThanTFromExpStart(eyeobj,maxRecordingTimeAfter,varargin)
% findSaccadesLongerThanTFromExpStart
%    Helps determine which saccades were recorded late in an experiment. 
% 
%   Computes a lower bound on the time each saccade occurred RELATIVE TO THE BEGINNING OF THE EXPERIMENT 
%  (assuming plane 1 is recorded first and then subsequent
%   planes are recorded later in time). Returns boolean variable of all the saccades that occured after 
%   a user input time, `maxRecordingTimeAfter'. The length of the boolean
%   is equal to the total number of saccades recorded for the (default)
%   left eye. 
%      
options = struct('eyeInd','left');
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


% combine saccades into a matrix
saccadeTimesCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeTimes,'UniformOutput',false);
saccadeTimes = cell2mat(saccadeTimesCell);
if ~isempty(saccadeTimes)
    saccadeTimes = saccadeTimes(:,1);
end

% compute a lower bound on the amount of time elapsed since the beginning
% of recording.
totalTimeInPlane = cellfun(@(z) z(end,eyeInd),eyeobj.time);
cumAmountOfTime = cumsum(totalTimeInPlane);

% used to compute an index for saccade number relative to all saccades in the
% experiment
numberOfSamples = cellfun(@(z) size(z,1),saccadeTimesCell);
cumNumberOfSamples = cumsum(numberOfSamples);

for planeIndex = 1 : length(cumNumberOfSamples)-1
    % index for saccade number relative to all saccades in the experiment
    indicesForThisPlane = cumNumberOfSamples(planeIndex)+1:cumNumberOfSamples(planeIndex+1);
    % lower bound on the amount of time elapsed since the beginning
    saccadeTimes(indicesForThisPlane) =  saccadeTimes(indicesForThisPlane) + cumAmountOfTime(planeIndex);
end
% which saccades to remove
sacIndex2Remove = saccadeTimes(:,1)>maxRecordingTimeAfter;
end
