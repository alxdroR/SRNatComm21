% loadSRSlopes - wrapper for loading SR cells and calculating a matrix of
% their properties before upcoming saccade
% 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 

% load the selection criteria for anticipatory cells 
loadAnticipatorySelectionCriteria

% load the firing rates estiamted by non-negative deconvolution 
%runFOOPSIOnAnticipatoryCells
%load('runFOOPSIOnAnticipatoryCellsFeb272018Output','rate')
%load([smallDataPath 'runFOOPSIOnAnticipatoryCellsMar292018Output.mat'],'rate');
%load([smallDataPath 'runFOOPSIOnAnticipatoryCellsOutput.mat'],'rate');
rate = loadNMFRates('cellsOfInterest',IDsFromCellsOfInterest);

% calculate slope of anticipatory rise dF/F traces using non-negative firing rates to
% determine times of rise
firingRateThreshold = 0.1; % we count activity as begining if firing rate is above this value
ignoreRateDrop = 2; % if a cell is firing (above threshold) and the firing goes below threshold for <= `ignoreRateDrop' samples and the 
%                   continues to fire, we do not count these drops as part of the start and stop times  
[AnticipatoryAnalysisMatrix,ISIMatrix,analysisCell,fixationIDs]=calcSlope3(IDsFromCellsOfInterest,sigLeft(uniqueIDsFromCOI),'tracesForThresholdCalc',rate,'useTwitches',false,...
    'calcRiseTimeWithBaseline',false,'noFireThreshold',firingRateThreshold,'noFireDurationMin',4,'removeInitialNoFireSamples',true,'ignoreRateDropDuration',ignoreRateDrop,'useDeconvF',true,'normFunction','none');
