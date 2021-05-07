function [saccadeTimes,saccadeDirection,varargout] = combineSaccadeTimesAcrossEyes(eyeobj,planeIndex,varargin)
options = struct('useOldSaccadeTimeBug',false,'removeSaccadeTimesWNoImaging',false,'returnVelocity',false);
options = parseNameValueoptions(options,varargin{:});

saccadeTimes = [eyeobj.saccadeTimes{planeIndex}{1};eyeobj.saccadeTimes{planeIndex}{2}];
saccadeDirection = [eyeobj.saccadeDirection{planeIndex}{1};eyeobj.saccadeDirection{planeIndex}{2}];
if ~isempty(saccadeTimes)
[~,sI] = unique(saccadeTimes(:,1));
saccadeTimesUnique     = saccadeTimes(sI,:);
saccadeDirection = saccadeDirection(sI);

if options.returnVelocity
    % user wants velocity returned using the same criteria chosen to return
    % the saccade times
    saccadeVelocity = [eyeobj.saccadeVelocity{planeIndex}{1};eyeobj.saccadeVelocity{planeIndex}{2}];
    
    combinedVelocity = NaN(length(sI),2); numLeftSaccades = length(eyeobj.saccadeTimes{planeIndex}{1});
    for conjugateSortedTimeIndex = 1 : length(sI)
        % find the indices of the left and right eyes that have the first
        % uniuqe saccade time value
        leftRightConjugateIndex = saccadeTimes(:,1)  == saccadeTimesUnique(conjugateSortedTimeIndex,1);
        % since the indices are sorted and since we combined saccade times from
        % the right eye AFTER saccade times from teh left eye, we know that
        % column 1 will be left eye and column 2 will be right eye
        combinedVelocity(conjugateSortedTimeIndex,:)  = saccadeVelocity(leftRightConjugateIndex); % this cut removes velocity from an arbitrarily chosen eye
        if sum(leftRightConjugateIndex)==1
            % this index was considered unique and belongs to a single eye. Now
            % we figure out if it was the left eye or right eye
            if leftRightConjugateIndex <= numLeftSaccades
                % left eye
                combinedVelocity(conjugateSortedTimeIndex,2) = NaN; % the right eye velocity was below threshold and not saved
            else
                combinedVelocity(conjugateSortedTimeIndex,1) = NaN; % " left ""
            end
        end
    end
end

% we used unique to remove exact duplicates from left/right eye. Now remove
% close in time (<1s) duplicates
removeSlightDifferenceStartTime = diff(saccadeTimesUnique(:,1))>1;

if options.useOldSaccadeTimeBug
    % This is a bug that I only noticed 3/21/2018
    saccadeTimes = saccadeTimesUnique(removeSlightDifferenceStartTime,:);
    saccadeDirection = saccadeDirection(removeSlightDifferenceStartTime);
else
    % this is the proper code
    st22end = saccadeTimesUnique(2:end,:);sd22end = saccadeDirection(2:end);
    saccadeTimes = [saccadeTimesUnique(1,:);st22end(removeSlightDifferenceStartTime,:)];
    saccadeDirection = [saccadeDirection(1);sd22end(removeSlightDifferenceStartTime)];
    if options.returnVelocity
        v22end = combinedVelocity(2:end,:); combinedVelocityUniqueMinus1 = v22end(removeSlightDifferenceStartTime,:);
        combinedVelocityUniqueNeedsCorrection = [combinedVelocity(1,:);combinedVelocityUniqueMinus1];
        
        % now we have to correct for the fact that combinedVelocityUniqueMinus1
        % only has 1 velocity at points where the two eyes moved, nearly
        % conjugately.
        for indices2correct = find(~removeSlightDifferenceStartTime)
            % this index was left out. We can use it to make sure combinedVelocityUnique
            % contains movements from both eyes that saccade nearly conjugately
            % Ex 1:
            % saccadeTimesUnique(:,1) = [ 1 2 2.01];
            % combinedVelocity = [(30,10) (50,NaN) (NaN,70.1)]
            % v22end = [ (50,NaN) (NaN,70.1)]
            % removeSlightDifferenceStartTime = [1 0];
            % find(~removeSlightDifferenceStartTime) = 2
            % We need to pair v22end(2,:) with combinedVelocity(2,:)
            %
            % Ex 2:
            % saccadeTimesUnique(:,1) = [ 2 2.01 5];
            % removeSlightDifferenceStartTime = [0 1];
            % find(~removeSlightDifferenceStartTime) = 1
            % combinedVelocity = [ (50,NaN) (NaN,70.1) (30,10)]
            % v22end = [ (NaN,70.1) (30,10)]
            % We need to pair v22end(1,:) with
            % combinedVelocity(1,:)
            
            % first determine if one direction has a NaN. We expect this
            % unless there happen to be either two conjugate saccades less than 1
            % second apart or a conjugate saccade occurred and then 1 eye moved again
            % shortly
            missingEye = isnan(combinedVelocity(indices2correct,:));
            if any(missingEye)
                missingEye2 = isnan(v22end(indices2correct,:));
                if any(missingEye2)
                    % only one eye cross threshold for both indices
                    if missingEye ~= missingEye2
                        % this is the scenario we expect for nearly conjugate movements
                        combinedVelocity(indices2correct,missingEye) = v22end(indices2correct,~missingEye2);
                    else
                        % the same eye must have crossed threshold within a
                        % short period of time. Probably a twitch. Do not
                        % combine.
                    end
                    
                else
                    % the previous nearby saccade had 1 eye cross trhreshold
                    % and this saccade had both eyes cross threshold. This
                    % should be impossible the way the code is structured
                    error('logic error in the understanding of what combineSaccadeVelocityAcrossEyes is doing');
                end
            else
                % a conjugate saccade occurred follwed by either another
                % conjugate saccade or followed by one eye only moving. Either
                % way Nothing to combine in this case
            end
        end
        v22end = combinedVelocity(2:end,:); combinedVelocityUniqueMinus1 = v22end(removeSlightDifferenceStartTime,:);
        combinedVelocityUnique = [combinedVelocity(1,:);combinedVelocityUniqueMinus1];
    end
end
end
    if options.removeSaccadeTimesWNoImaging
        cutBecauseImagingEnded = saccadeTimes(:,1) > (eyeobj.time{1}(end,1) - 512*0.002);
        saccadeTimes = saccadeTimes(~cutBecauseImagingEnded,:);
        saccadeDirection = saccadeDirection(~cutBecauseImagingEnded);
        
        cutBecauseImagingHasntStarted = saccadeTimes(:,1) < 512*0.002;
        saccadeTimes = saccadeTimes(~cutBecauseImagingHasntStarted,:);
        saccadeDirection = saccadeDirection(~cutBecauseImagingHasntStarted);
        if options.returnVelocity
            combinedVelocityUnique = combinedVelocityUnique(~cutBecauseImagingEnded,:);
            combinedVelocityUnique = combinedVelocityUnique(~cutBecauseImagingHasntStarted,:);
        end
    end

if options.returnVelocity
    varargout{1} = combinedVelocityUnique;
end

end

