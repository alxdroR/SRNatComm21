function [STR,timeSegments,direction,absTimeSegments] = STresponses(data,saccadeTimes,saccadeDirection,calciumTime,varargin)
%STresponses return saccade triggered responses
%   [STR,timeSegments,direction] = STresponses(fid,lind,expCond)
%   saccade triggered response (STR)
%   
% 
%   
%  OUTPUT
%  STR{plne}{n}{j} gives the saccade triggered response for neuron n in
%                   imaging plane plne at the jth saccade (conditioned on the interval 
%                   between response start and stop not being interupted by a saccade that 
%                  we are not triggering on).  The number of responses that pass may be
%                  variable across neurons since the difference in recording time between 
%                  two neurons can vary up to a second.
%
% timeSegments{plne}{n}{j} gives the sampling times for the STR of neuron n 
%                           in plane plne at the jth segment
%
% direction{plne}{n}(j)   tells whether the eye movement for the response at the jth segment 
%                          in plane, plne, was to the left or to the right.
%                         This depends on neuron, n, since the segments in
%                         question are not equal for all neurons (see
%                         explanation in description of STR variable for why all neurons do not
%                         have the same number of responses)



% parameters for cut
options = struct('startpoint',-7,'endpoint',7,'removeInvalids',true,'useSaccadeDuration',true);
options = parseNameValueoptions(options,varargin{:});

startPoint = options.startpoint; % time before saccade
endPoint = options.endpoint; % time after (in seconds)

% cut calcium responses
[STR,timeSegments,~,~,usableInt,absTimeSegments] = saccadeTrigCut(data,saccadeTimes,startPoint,endPoint,calciumTime,false,...
    'removeInvalids',options.removeInvalids,'useSaccadeDuration',options.useSaccadeDuration);
numberCells = size(data,2);
direction = cell(length(STR),1);
for cellNumber = 1 : numberCells
    if options.removeInvalids
        direction{cellNumber}= saccadeDirection(usableInt(:,cellNumber)); % conjugate saccade directions (todo)
    else
        direction{cellNumber}= saccadeDirection; % conjugate saccade directions (todo)
    end
end
end

