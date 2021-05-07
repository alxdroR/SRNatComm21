function [CP,ISIVector,animalOut,varargout] = saccadeChoiceProbability(F,TF,onDirection,IDsFromCellsOfInterest,varargin)
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

options = struct('allData',[],'binTimes',0:1/3:30,'useConstantThreshold',true,'ISImin',2,'ISImax',20,'earliestCrossTol',2,'avgRandwRplcmnt',false,'numSamples',100,'numCellsInAvg',0:3:20);
options = parseNameValueoptions(options,varargin{:});

trainSetFraction = 0.5;
%trainSetFraction = 0.2;
ISImax = options.ISImax; ISImin =options.ISImin; % values of ISI we will test
useConstantThreshold = options.useConstantThreshold;
numBoots = 100;
numSE = 3; % determines range of acceptable passing region
earliestCrossTol = options.earliestCrossTol;
numTests = 50;
numConditions = ISImax - ISImin + 1; % number of ISI values we calculate population average at time of saccade
ISIVector = ISImin:ISImax;
binTimes = options.binTimes;
if isempty(options.allData)
    % Step 1 Gather all the data before breaking it into training and test sets
    allData = cell(numConditions,1);
    allDataOFF = cell(numConditions,1);
    animalOut = struct('ON',cell(numConditions,1),'OFF',cell(numConditions,1));
    for ISIFix = ISImin:ISImax
        % segment the input data according to activity after a saccade
        [dFFISI,binTimes,animalOutON]=loadSingleTrialResponses(F,TF,IDsFromCellsOfInterest,'direction','preceeding ON','ONdirection',onDirection,'cells','all',...
            'interp2gridThenCat',true,'binTimes',binTimes,'tau','past saccade','ISI',ISIFix+0.5,'ISIwidth',1);
        maxTimeIndex = find(binTimes>=ISIFix,1);
        % the only relevant portion for the test is activity at ISI
        allData{ISIFix-ISImin+1} = dFFISI(:,1:maxTimeIndex);
        animalOut(ISIFix-ISImin+1).ON = animalOutON;
        
        % repeat the same procedure for the OFF direction
        [dFFISIOFF,~,animalOutOFF]=loadSingleTrialResponses(F,TF,IDsFromCellsOfInterest,'direction','preceeding OFF','ONdirection',onDirection,'cells','all',...
            'interp2gridThenCat',true,'binTimes',binTimes,'tau','past saccade','ISI',ISIFix+0.5,'ISIwidth',1);
        allDataOFF{ISIFix-ISImin+1} = dFFISIOFF(:,1:maxTimeIndex);
        animalOut(ISIFix-ISImin+1).OFF = animalOutOFF;
    end
else
    
    allData = options.allData;
end

CP = cell(numConditions,1);
for ISIFix = ISImin:ISImax
    if ~options.avgRandwRplcmnt
        maxTimeIndex = find(binTimes>=ISIFix,1);
        CP{ISIFix-ISImin+1} = nan(maxTimeIndex,2);
        CP{ISIFix-ISImin+1}(:,2) = binTimes(1:maxTimeIndex);
    else
        numSamps = 1;
        maxTimeIndex = find(binTimes>=ISIFix,1);
        CP{ISIFix-ISImin+1} = nan(length(options.numCellsInAvg),maxTimeIndex,numSamps);
        % CP{ISIFix-ISImin+1}(:,2) = binTimes(1:maxTimeIndex);
    end
    %figure;
    %plot(binTimes(1:maxTimeIndex),nanmean(allData{ISIFix-ISImin+1})); hold on;
    % plot(binTimes(1:maxTimeIndex),nanmean(allDataOFF{ISIFix-ISImin+1}));
    % xlabel('time since last saccade');ylabel('df/f');legend('preceeding
    % ON','preceeding OFF'); % note that noise distribution is dynamic
    nON = size(allData{ISIFix-ISImin+1},1); nOFF = size(allDataOFF{ISIFix-ISImin+1},1);
    %labels = [ones(nON,1);zeros(nOFF,1)];
    labels = [ones(options.numSamples,1);zeros(options.numSamples,1)];
    if ~options.avgRandwRplcmnt
        for timeIndex = 1:maxTimeIndex
            scores = [allData{ISIFix-ISImin+1}(:,timeIndex);allDataOFF{ISIFix-ISImin+1}(:,timeIndex)];
            [X,Y,T,AUC] = perfcurve(labels,scores,1);
            %figure;plot(X,Y);xlabel('false alarm');ylabel('hit rate')
            CP{ISIFix-ISImin+1}(timeIndex,1) = AUC;
        end
    else
        % average the data -
        for cellIndex = 1: length(options.numCellsInAvg)
            for timeIndex = 1:maxTimeIndex
                for sampIndex = 1 : numSamps
                    dataOnAvg = NaN(options.numSamples,1);
                    dataOffAvg = NaN(options.numSamples,1);
                    if options.numCellsInAvg(cellIndex) ~= 0
                        for avgSampIndex = 1 : options.numSamples
                            sampleIndices = randperm(nON,options.numCellsInAvg(cellIndex));
                            dataOnAvg(avgSampIndex,1) = nanmean(allData{ISIFix-ISImin+1}(sampleIndices,timeIndex));
                        end
                        for avgSampIndex = 1 : options.numSamples
                            sampleIndices = randperm(nOFF,options.numCellsInAvg(cellIndex));
                            dataOffAvg(avgSampIndex,1) = nanmean(allDataOFF{ISIFix-ISImin+1}(sampleIndices,timeIndex));
                        end
                        scores = [dataOnAvg;dataOffAvg];
                    else
                        scores = [allData{ISIFix-ISImin+1}(:,timeIndex);allDataOFF{ISIFix-ISImin+1}(:,timeIndex)];
                    end
                    [X,Y,T,AUC] = perfcurve(labels,scores,1);
                    CP{ISIFix-ISImin+1}(cellIndex,timeIndex,sampIndex) = AUC;
                end
            end
        end
    end
end

varargout{1}=allData;
varargout{2} = options.numCellsInAvg;
varargout{3} = binTimes(1:maxTimeIndex);
end

