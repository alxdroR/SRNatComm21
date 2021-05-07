function [propCorrect,varargout] = predictSaccadesRampThresh(F,TF,onDirection,IDsFromCellsOfInterest,varargin)
%  propCorrect = saccadePredictionAccuracy(F,TF,IDsFromCellsOfInterest)
% Determine how well a threhsold rule can predict upcoming saccades using
% traces saved in cell array F recorded at sample times in cell array TF.
%
% 1) For each ISI, take `trainSetFraction` of the data (randomly chosen) and determine population average at the time of saccade. From these training
%   set averages at different ISIs (from the set ISImin,...,ISImin+k,...,ISImax, where k is an integer)
% , extract either a constant threshold (useConstantThreshold=true) by finding the mean value at the time of saccade or extract
%  a threshold that linearly varies with ISI by fitting a linear function : threshold = a ISI + b.
%
% 2) For the remaining cells, calculate their population average at the time of saccade, m, and use `numBoots` bootstrap
%  samples to determine the standard error, se, of this value. Do this at all ISIs.
%  Record in propCorrect if their average is within the right ballpark ( m +- numSE*se ) of the threshold for this ISI.
%  If it isn't propCorrect = false and we can deduce (given monotonically rising data) that
%  the test set must have never reached threshold or reached it too quickly.
%
%  Repeat steps 1 and 2 numTests times.

options = struct('allData',[],'ISImin',2,'ISImax',20,'fdDis',[],'useShuffleControl',false,'chooseKCellsAtRandom',[]);
options = parseNameValueoptions(options,varargin{:});

ISImax = options.ISImax; ISImin =options.ISImin; % values of ISI we will test
numTests = 10000;

binTimes = -30:1/3:0;
if isempty(options.allData)
    allData = gatherPreSaccadeEventTraces(F,TF,onDirection,IDsFromCellsOfInterest,[ISImin ISImax],...
        'binTimes',-30:1/3:0,'ISIwidth',0.5,'tau','future saccade','cutTimeGTISI',false);
else
    allData = options.allData;
end

if isempty(options.fdDis)
    durations=jointISIDistributionPopAggregatev2;
    fdDis = [durations.left;durations.right];
else
    fdDis = options.fdDis;
end
% determine training set threshold
sumFinalValueVector = cellfun(@(x) nansum(x(:,end)),allData);
numEventsVector = cellfun(@(x) size(x,1),allData);
th = sum(sumFinalValueVector)/sum(numEventsVector);

if isempty(options.chooseKCellsAtRandom)
    RT = NaN(length(ISImin:ISImax),1);D = RT;
    offset = RT;
    count = 1;
    for ISIFix = ISImin:ISImax
        dFFISI = allData{ISIFix-ISImin+1};
        
        ymean = nanmean(dFFISI);
        popAvg =ymean-ymean(find(~isnan(ymean),1));
        [D(count),RT(count),offset(count)] = computePopAvgSlopeRT(popAvg,binTimes,'riseThreshold',0.04);
        
        
        % find time when ramping model will cross threshold
        count = count + 1;
    end
    crossTime = (th-offset)./D + RT;
end
propCorrect = NaN(numTests,1);

for ti = 1:numTests
    if ~isempty(options.chooseKCellsAtRandom)
        % we need to randomly sample cells to find slope, risetime
        % population measurements
        RT = NaN(length(ISImin:ISImax),1);D = RT;
        offset = RT; count = 1;
        
        for ISIFix = ISImin:ISImax
            if size(allData{ISIFix-ISImin+1},1)>options.chooseKCellsAtRandom
                randInd = randperm(size(allData{ISIFix-ISImin+1},1),options.chooseKCellsAtRandom);
                dFFISI = allData{ISIFix-ISImin+1}(randInd,:);
            else
               % not random, use all cells 
               dFFISI = allData{ISIFix-ISImin+1};
            end
            
            
            ymean = nanmean(dFFISI);
            popAvg =ymean-ymean(find(~isnan(ymean),1));
            [D(count),RT(count),offset(count)] = computePopAvgSlopeRT(popAvg,binTimes,'riseThreshold',0.04);
            
            
            % find time when ramping model will cross threshold
            count = count + 1;
        end
        crossTime = (th-offset)./D + RT;
    end
    goodSample = false;
    while ~goodSample
        % randomly sample a fixation duration
        sampledTime = randsample(fdDis,1);
        if sampledTime<=ISImax && sampledTime>=ISImin
            durationIndex = round(sampledTime)-ISImin+1;
            goodSample = true;
        end
    end
    
    if options.useShuffleControl
        % shuffle the RT vs slope relationship
        crossTime = (th-offset)./randsample(D,length(D)) + RT;
    end
    
    % check if the guess would be correct
    correctGuess = abs(crossTime(durationIndex))<=sampledTime*0.2;
    propCorrect(ti) = correctGuess;
end
varargout{1}=allData;
end

