function [naOut,firingLengths,noFiringLengths,firingStartIndices,firingEndIndices] = findNoFiringEpochs(x,varargin)
options = struct('noFireThreshold',0.1,'noFireDurationMin',0,'removeInitialNoFireSamples',false,'ignoreRateDropDuration',0);
options = parseNameValueoptions(options,varargin{:});

% INPUT
% x - T x N matrix of  non-negative, de-convolved, de-noised firing rate
% traces, where T is total number of temporal samples

% OUTPUT
% 
% SAMPLE OUTPUT FOR size(x) = T x 3 
% figure;plot(x(:,3))
% plot when activity starts
% hold on;plot(firingStartIndices{3},x(firingStartIndices{3},3),'ro')
% plot when activity ends 
% plot(firingEndIndices{3},x(firingEndIndices{3},3),'go')
% plot the no-firing periods whose duration is longer than 
% options.noFireDurationMin
% plot(find(na(:,3)),x(na(:,3),3),'k.')
% plot(find(~na(:,3)),x(~na(:,3),3),'r.')

[T,N] = size(x);
if (T==1) || (N==1)
    x = x(:);
    T = length(x);
    N = 1;
end
% non-active regions (regions where firing rate is effectively zero)
na = x<=options.noFireThreshold;
if options.noFireDurationMin == 0
    % there is no minimum duration for how long the no-firing period has to
    % be, so user wants all samples below threshold.
    naOut = na;
elseif options.noFireDurationMin > 0
    % there IS a minimum duration for how long the no-firing period has to
    % be
    naOut = false(size(x));
else
    error('noFireDurationMin must by greater than or equal to zero');
end

% CHARACTERIZE WHEN FIRING STARTS AND STOPS, HOW LONG (IN UNITS OF NUMBER
% OF SAMPLES) NO FIRING BOUTS LAST, HOW LONG (IN UNITS OF NUMBER OF SAMPLES) FIRING LASTS
%----------------------------

firingLengths = cell(N,1);
noFiringLengths = cell(N,1);
firingStartIndices = cell(N,1);
firingEndIndices = cell(N,1);

for cellIndex = 1:N
    
    naIndices = find(na(:,cellIndex));      % naIndices is empty if every time point is active. length (naIndices) equals number of non-active time points
    sequentialFiringList = diff(naIndices); % sequentialFiringList equals 1 if a time point is not active AND the next time point is also 
                                            % not active (e.g. firing rate is elevated for 0 time points). sequentialFiringList equals 2 if a time point is not active AND the next time point 
                                            % is active but the time point
                                            % after that is not (e.g.
                                            % firing rate is elevated for 1
                                            % time point). 
    
    % 1) distribution of firing bout lengths (in units of number of samples)
    firingLengths{cellIndex} = sequentialFiringList(sequentialFiringList~=1) -1 ; 
    
    if naIndices(end)~=T
        % In this case, the last time point is active. It must have become
        % active at the final index in naIndices. We must add this length
        firingLengths{cellIndex} = [firingLengths{cellIndex};length(naIndices(end)+1:T)];
    end
    if naIndices(1)~=1
        % In this case, the firing began before the recording. We will
        % arbitrarily start the firing at index 1 and use a firing length
        % value where we arbitrarily assume firing began at index 0. 
        firingLengths{cellIndex} = [naIndices(1)-1;firingLengths{cellIndex}];
    end
    
    % DURATION OF NO FIRING EPOCHS
    % find sample numbers when firing bouts start
    firingStartIndices{cellIndex} = naIndices(sequentialFiringList~=1);
    if naIndices(end)~=T
        firingStartIndices{cellIndex} = [firingStartIndices{cellIndex};naIndices(end)];
    end
    if naIndices(1)~=1
        firingStartIndices{cellIndex} = [1;firingStartIndices{cellIndex};];
    end
    % find the last sample in the firing bout
    lastFiringSampleIndex = firingStartIndices{cellIndex} + firingLengths{cellIndex};
    % find sample numbers when firing bout ends
    firingEndIndices{cellIndex} = lastFiringSampleIndex+1;
    if firingEndIndices{cellIndex}(end) == T+1
        % This only happens when the last time point is active. Technically
        % we don't know when this bout will end. Doing firingLengths +
        % firingStartIndices will artificically set the bout end to T+1. Since we need
        % these to be valid indices we set the value to T.
        firingEndIndices{cellIndex}(end) = T;
    end
    if naIndices(1)~=1
        % because of the convention of setting firing start to index 1 and
        % using a firing length that assumes firing begins at index 0, we
        % have to change the firing end value. 
        firingEndIndices{cellIndex}(1) = firingEndIndices{cellIndex}(1)-1;
    end
    
    % 2) during of no firing
    noFiringLengths{cellIndex} = [firingStartIndices{cellIndex}(1)-naIndices(1);firingStartIndices{cellIndex}(2:end)-firingEndIndices{cellIndex}(1:end-1)] + 1;
    if naIndices(end)==T
         noFiringLengths{cellIndex} = [noFiringLengths{cellIndex};length(firingEndIndices{cellIndex}(end):T)];
    end
    
    if options.noFireDurationMin > 0
        % there IS a minimum duration for how long the boolean output that marks no-firing periods has to
        % be
        for noFireBoutIndex = 1 : length(noFiringLengths{cellIndex})
            % loop through each of epochs of no Firing.
            if noFiringLengths{cellIndex}(noFireBoutIndex) > options.noFireDurationMin
                % This epoch passes
                if noFireBoutIndex == 1
                    noFireIndices = naIndices(1):firingStartIndices{cellIndex}(1);
                elseif (naIndices(end)==T) && (noFireBoutIndex ==length(noFiringLengths{cellIndex}))
                    noFireIndices = firingEndIndices{cellIndex}(noFireBoutIndex-1)+1:T;
                else
                    noFireIndices = firingEndIndices{cellIndex}(noFireBoutIndex-1):firingStartIndices{cellIndex}(noFireBoutIndex);
                end
                if options.removeInitialNoFireSamples
                    noFireIndices = noFireIndices(options.noFireDurationMin+1:end);
                end
                naOut(noFireIndices,cellIndex) = true;
            end
        end
    end
    if options.ignoreRateDropDuration > 0 
        % revise the start, stop, and durations so that periods of firing
        % followed by no firing of length options.ignoreRateDropDuration
        % followed by firing are NOT included in the start and stop and in
        % the durations
        
        % notice that unless we added a final epoch of no firing,
        % noFiringLengths has the same number of elements as firingStartIndices 
        % and firingEndIndices. This fact provides an easy way for using the noFiringLength 
        % values to remove undesirable start and stop periods 
       
         firingStartIndicesEnding = firingStartIndices{cellIndex}(2:end);
         firingEndIndicesBeg = firingEndIndices{cellIndex}(1:end-1);
         if naIndices(end)~=T
            % region where we have No fire - fire - no fire
            index2keep = noFiringLengths{cellIndex}(2:end) > options.ignoreRateDropDuration; 
             firingStartIndices{cellIndex} = [firingStartIndices{cellIndex}(1); firingStartIndicesEnding(index2keep)];
            firingEndIndices{cellIndex} = [firingEndIndicesBeg(index2keep);firingEndIndices{cellIndex}(end)];
         else
             index2keep = noFiringLengths{cellIndex}(2:end-1) > options.ignoreRateDropDuration; 
             firingStartIndices{cellIndex} = [firingStartIndices{cellIndex}(1); firingStartIndicesEnding(index2keep)];
            firingEndIndices{cellIndex} = [firingEndIndicesBeg(index2keep);firingEndIndices{cellIndex}(end)];
        end
        
    end

end

end

