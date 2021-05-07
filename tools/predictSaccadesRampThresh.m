function [predictions,actual,varargout] = predictSaccadesRampThresh(varargin)
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

options = struct('allData',[],'binTimes',-30:1/3:0,'ISImin',2,'ISImax',20,'fdDis',[],'numTests',10,...
    'F',[],'TF',[],'onDirection',[],'IDsFromCellsOfInterest',[],'riseThreshold',0.04);
options = parseNameValueoptions(options,varargin{:});

ISImax = options.ISImax; ISImin =options.ISImin; % values of ISI we will test
numTests = options.numTests;

binTimes = options.binTimes;
if isempty(options.allData)
    F = options.F;
    TF = options.TF;
    onDirection = options.onDirection;
    IDsFromCellsOfInterest = options.IDsFromCellsOfInterest;
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


predictions = cell(numTests,1);
actual = cell(numTests,1);
for ti = 1:numTests
    % grab a random fixation duration sample
    goodSample = false;
    while ~goodSample
        % randomly sample a fixation duration
        sampledTime = randsample(fdDis,1);
        if sampledTime<=ISImax && sampledTime>=ISImin
            ISIFix = round(sampledTime)-ISImin+1;
            goodSample = true;
        end
    end
    
    [yTrain,yTest] = trainTestSplit(allData{ISIFix},0.6);
    % compute population averages
    popAvgTrain = compPopAverage(yTrain);
    popAvgTest = compPopAverage(yTest);
    
   
    % train to get the slope parameter
    D = computePopAvgSlopeRT(popAvgTrain,binTimes,'riseThreshold',options.riseThreshold);
    
    % predict activity based on known time of rise and threshold ----
    
    % extract index of binTimes when activity begins to rise,RTIndex
    [~,~,~,~,RTIndex] = computePopAvgSlopeRT(popAvgTest,binTimes,'riseThreshold',options.riseThreshold);
    %  and threshold, th
    th = popAvgTest(end);
    % predict activity
    predictions{ti} = D*binTimes(RTIndex:end)+th;
    actual{ti} = [binTimes(RTIndex:end)' popAvgTest(RTIndex:end)'];
end
varargout{1}=allData;
end

function [yTrain,yTest] = trainTestSplit(y,trainPercent)
% train / test split
numCells = size(y,1);
numCellsTrain = round(numCells*trainPercent);
if numCells > 2
    trainIndex = randperm(numCells,numCellsTrain);
    testIndex = setdiff(1:numCells,trainIndex);
    yTrain = y(trainIndex,:);
    yTest = y(testIndex,:);
else
    yTrain = y;
    yTest = y;
end
end

function popAvg = compPopAverage(y)
popAvg = nanmean(y);
%popAvg =ymean-ymean(find(~isnan(ymean),1));
end
