function ISI = nanPadISIVector(saccadeTimes,varargin)
% computes inter-saccade intervals for the input vector of saccade times,
% saccadeTimes, and returns a vector equal in length to
% length(saccadeTimes) by
% adding a NaN to the END of the vector of fixation durations

options = struct('useOldBug',false);
options = parseNameValueoptions(options,varargin{:});

if options.useOldBug
    % bug that was in the version prior to 4/23/2018 where this function was placed directly
    % in the script
    ISI = [diff(saccadeTimes,[],1);[NaN NaN]];  % this will be a different size than saccadeTimes if saccadeTimes is empty.
else
    
    if ~isempty(saccadeTimes)
        ISI = [diff(saccadeTimes,[],1);[NaN NaN]];
    else
        ISI = [];
    end
end
end

