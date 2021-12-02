% plotAll.m
% Master file to produce results presented in Ramirez, AD, Aksay E, Nature Communications 2021
%
%
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
%% Fig. 1b
fig1b = sampleEyeTraceClass;
fig1b = fig1b.compute;
fig1b.plot; fig1b.printAndSave;clear fig1b
%% Fig. 1c
f1obj = fig1;
fig1c = transitionISIDistributionsClass;
f1obj = f1obj.getPopFD;
fig1c = fig1c.compute('popFD',f1obj.popFD);
fig1c.plot;
fig1c.toCSV;
fig1c.printAndSave;clear fig1c
%% Fig. 1d
f1obj = f1obj.printFixationStats;
f1obj = f1obj.getPowerSamples;
fig1d = powerSpectraCalculationClass;
fig1d = fig1d.compute('powerSamples',f1obj.powerSamples,'ID',f1obj.ID);
fig1d.plot;fig1d.printAndSave;
fig1d.toCSV;
f1obj.printPowerFreqRange('powerData',fig1d.data);
f1obj.printPeakPower('powerData',fig1d.data); clear fig1d
f1obj = f1obj.printTotalRange;
f1obj = f1obj.getPopSacAmp;
f1obj = f1obj.printSacAmpStats;
%% Fig. 1e
fig1e = saccadeAmplitudeClass;
fig1e = fig1e.compute('popSacAmp',f1obj.popSacAmp);
fig1e.plot;fig1e.printAndSave;
fig1e.toCSV;
f1obj.printSacDirAmpStats('sacAmpData',fig1e.data); clear fig1e
clear f1obj
    %% Fig. 2a
showBridgeBrainSample
%% Fig. 2b
demoImage
%% Fig. 2c-e
tonicID = [13,5,51];
burstID = [3,32,9]; % other ideas [3,21,12]; [3,21,11]; [5,10,189];[5,12,127];
SRID = [7,9,34];
fig2obj = fig2('showSTADeconv',true,'deconvOffset',false,'allIDsForFigure',[tonicID;burstID;SRID],'STAFilename','calcSTA2NMFOutput','STADeconvFilename','calcSTA2NMFDeconvOutput',...
    'dFFRange',2.3,'timeWidth',150,'eyeRange',35,'dFFLineWidth',1.5,'dFFLineColor',[0 0 1],...
    'deconvLineWidth',1.5,'deconvLineColor',[0 0 0],'paperPosition',[0 0 4.25 1.333],...
    'STRDFRange',[0 1.5],'rightSTAColor',[60 11 178]./256,'leftSTAColor',[218 84 26]./256,...
    'lineAtZeroWidth',0.5,'spaceBetweenSTRLR',1,'tauLimits',[-8 8],'STRSTAPaperPosition',[0 2 4.25 1.55],...
    'strAXOffset',0.67,'strAXHeight',0.30,'staAXOffset',0.27,'staAXHeight',0.4);

fig2obj = fig2obj.runFig2bi(tonicID,'traceFilename','exemplarTonicTrace','timeOffset2plot',20,'axesOverlap',0.06,'showAxis',false,'showDeconv',true,...
    'strstaFilename','exemplarTonicSTRA');pause(0.1);
fprintf('Tonic: n=%d,%d fixations about saccades to the left/right\n',fig2obj.nTrialsL(1),fig2obj.nTrialsR(1));
fig2obj = fig2obj.runFig2bii(burstID,'traceFilename','exemplarBurstTrace','timeOffset2plot',150,'axesOverlap',0.12,'showAxis',false,'showDeconv',true,...
    'strstaFilename','exemplarBurstSTRA');pause(0.1);
fprintf('Burst: n=%d,%d fixations about saccades to the left/right\n',fig2obj.nTrialsL(2),fig2obj.nTrialsR(2));
fig2obj = fig2obj.runFig2biii(SRID,'traceFilename','exemplarSRFig2Trace','timeOffset2plot',20,'axesOverlap',0.22,'showAxis',false,'showDeconv',true,...
    'strstaFilename','exemplarSRSTRA');pause(0.1);
fprintf('SR: n=%d,%d fixations about saccades to the left/right\n',fig2obj.nTrialsL(3),fig2obj.nTrialsR(3));
fig2obj = fig2obj.runFig2biii(SRID,'traceFilename','exemplarSRFig2Trace','timeOffset2plot',20,'axesOverlap',0.22,'showAxis',false,'showDeconv',true,...
    'strstaFilename','exemplarSRSTRA-scale','addScale',true);pause(0.1);
clear fig2obj
%% S Fig. 1a
demonstrateImgRegistration
%% S Fig. 1c
numSampSag
%% S Fig. 1d
plotActiveNonActiveLabelledCells
showActiveNonActLocationExample
%% S Fig. 1e
suppFig1e
%% stats
close all
[finalActiveCellCriteria,inMBCriteria,Coordinates,maxDFFCriteria,cantComputeSTA,lowLevelDFF] = createFootprintSelector('cutCellsWLowSignal',true,'staDFFFilename','calcSTA2NMFOutput','lowSigPercentile',0.01);
STACriteria = createEyeMovementSelector('filename','calcSTA2NMFOutput','selectionCriteria',finalActiveCellCriteria);
[~,planesV] = totalNumberCells('NMF');
CoordinatesMO = registeredCellLocationsBigWarp('register2Zbrain',true,'caExtractionMethod','MO');
inMBMO = removeCellsRegistered2MB(CoordinatesMO);
imgDataSetStats = dataSetStatistics('numNMFCellsInHB',sum(~inMBCriteria),'numNMFCellsWithSTA',sum(~inMBCriteria & ~cantComputeSTA),...
    'numNMFCellsLowPeakSTA',sum(~cantComputeSTA & ~maxDFFCriteria),'numEyeMUseableActvCells',sum(finalActiveCellCriteria),'lowLevelDFF',lowLevelDFF,...
    'numMorpOpenCellsInHB',sum(~inMBMO),'numPlanesPerAnimal',planesV,'numEyeMovementCells',sum(STACriteria),'numSTAISNAN',sum(cantComputeSTA));
imgDataSetStats.reportPage5;
imgDataSetStats.reportPercentOfHindbrainDedicated2EyeM;
%% Fig. 3a
[coef,score,expl,mu,lon,lat,STACAT,tauPCA,~,~,scoreNormed,~,S] = calcSTA2runPCA('filename','calcSTA2NMFDeconvOutput',...
    'timeBeforeSaccade',-5,'timeAfterSaccade',5,'selectionCriteria',STACriteria,'pc1PostSTAPos',true,'normalizeSTABeforePCA',true);
f3obj = fig3;
f3obj.runFig3ai('cumVar',cumsum(expl),'xlim',[0 8],'ylim',[20 100],'toCSV',true);
%% Fig. 3b
f3obj.runFig3aii('coef',coef,'time',tauPCA,'explainedVar',expl,'toCSV',true);
%% Fig. 3c
f3obj.runFig3bi('scores',score,'explainedVar',expl,'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'zlim',[-1.5 1.5],...
    'markerSize',3,'axisLineWidth',0.4,'axisLim',[-1.2 1.2],'textLocations',[[1.4,-0.1,0];[0,1.23,0];[0,-0.01,1.23]],'toCSV',true);
f3obj.runFig3bii('lon',shiftLongitude(lon,90,'reorder',false),'lat',lat,'lonRange',[0 360] + 90)
%% Fig. 3d
f3obj.runFig3biii('lon',lon,'lat',lat,'bw',3,'BandWidth',[10 3],'toCSV',true)
%% Fig. 3e
scorePhiDensity('lon',shiftLongitude(lon,90,'reorder',false),'OFFCut',90,'YLIM',[0 0.006]);
%% Fig. 3f
ID = getIDFullDataSet('NMF');
popAvgAtPhiModes('lon',shiftLongitude(lon,90,'reorder',false),'OFFCut',90,'STACAT',STACAT,...
    'ID',ID(STACriteria,:),'tauPCA',tauPCA,'binWidth',15,'XLabel',[],'YLabel',[],'paperPosition',[0 1 2*1.5 0.75*1.5]);
%% Fig. 3g
displayPopAvgLeftLongPCSorted('lon',lon,'STACAT',STACAT,'tauPCA',tauPCA,'bw',15,'percent2ShowCut',0.0042,'ID',ID(STACriteria,:));
%% Fig. 3h (run makeMaps and follow instructions for FIJI)
%% S Fig. 2a
[pcaModel,kmeansIndices,kmeansCenters]=kMeansMeanSilhVsK('scoreNormed',scoreNormed);
%% S Fig. 2b
kMeansSilhPlot('pcaModel',pcaModel,'idx',kmeansIndices);
%% S Fig. 2c
kMeansClusterCenterPlots('tauPCA',tauPCA,'mu',mu,'coef',coef,'C',kmeansCenters,'YLIM',[-0.05,0.33]);
kMeansClusterCenterPlots('plotScaleBarOnly',true,'YLIM',[-0.05,0.33]);
kMeansClassificationLongitudeLRPlot('lon',lon,'OFFCut',90);
longitudeLvsR('lon',shiftLongitude(lon,90,'reorder',false),'bestModelClustCenters',kmeansCenters,'S',S)
%% S Fig. 3a
displayPopAvgRightLongPCSorted('lon',lon,'STACAT',STACAT,'tauPCA',tauPCA,'bw',15,'percent2ShowCut',0.0042,'ID',ID(STACriteria,:));
%% Fig. 4a
fig4obj = fig4('timeWidth',150,'dFFLineWidth',1.5,'dFFLineColor',[0 0 1],...
    'deconvLineWidth',1.5,'deconvLineColor',[0 0 0]);

fig4obj = fig4obj.runFig4a([5,8],'cellIndices',[11,15,20,48],'traceFilename','exemplarSimultaneousSRTraces','YAxisRange',9,'eyeRange',50,...
    'timeOffset2plot',120,'axesOverlap',0.17,'eyeAxisShrinkFactor',0.5,'showAxis',false,'showDeconv',true,'paperPosition',[0 0 4.8 4.4]);pause(0.1);
%% Fig. 4b
fig4obj = fig4obj.runFig4b([7,9,34],'traceFilename','exemplarSRFig4bTrace','YAxisRange',2.3,'eyeRange',35,...
    'timeOffset2plot',20,'axesOverlap',0.22,'showAxis',false,'showDeconv',true,'paperPosition',[0 0 7.0 4.5]);pause(0.1);
%% Fig. 4c
[sigLeft,sigRight,Hcc,uniqueIDsFromCOI] = createSRCellSelector('filename','calcAnticCorrAllCellsOutput','selectionCriteria',STACriteria);
IDsFromCellsOfInterest = ID(uniqueIDsFromCOI,:);
% load the firing rates estiamted by non-negative deconvolution
rate = loadNMFRates('cellsOfInterest',IDsFromCellsOfInterest);
% calculate slope of anticipatory rise dF/F traces using non-negative firing rates to
% determine times of rise
firingRateThreshold = 0.1; % we count activity as begining if firing rate is above this value
ignoreRateDrop = 2; % if a cell is firing (above threshold) and the firing goes below threshold for <= `ignoreRateDrop' samples and the
%                   continues to fire, we do not count these drops as part of the start and stop times
[AnticipatoryAnalysisMatrix,ISIMatrix,analysisCell,fixationIDs]=calcSlope3(IDsFromCellsOfInterest,sigLeft(uniqueIDsFromCOI),'tracesForThresholdCalc',rate,'useTwitches',false,...
    'calcRiseTimeWithBaseline',false,'noFireThreshold',firingRateThreshold,'noFireDurationMin',4,'removeInitialNoFireSamples',true,'ignoreRateDropDuration',ignoreRateDrop,'useDeconvF',true,'normFunction','none');
% SRPercent
SRPercent('STACriteria',STACriteria,'Hcc',Hcc,'AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'analysisCell',analysisCell);
% SRnonDSPercent
SRnonDSPercent('Hcc',Hcc);
riseTimeHistos('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'analysisCell',analysisCell,'IDsFromCellsOfInterest',IDsFromCellsOfInterest);
%% Fig. 4D
riseTimeHistosRelToPrevSaccade('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'ISIMatrix',ISIMatrix)
%% Fig.4E
compareRiseTimeDistrPrevvsUpcoming('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'ISIMatrix',ISIMatrix,'SRMatrixIDs',fixationIDs)
%% S Fig. 4a
singleCellRiseTimeVarPrevUpcomRatio('analysisCell',analysisCell);
%% Fig. 4F
ISINormalizedriseTimeHistos('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'ISIMatrix',ISIMatrix,'SRMatrixIDs',fixationIDs)
%% Fig. 4G
riseTimeVISI('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'ISIMatrix',ISIMatrix,'SRMatrixIDs',fixationIDs)
%% S Fig. 4b
singleCellNormRiseVsFDExamples('analysisCell',analysisCell);
%% S Fig. 4c
singleCellNormRiseVsFDCCDist('analysisCell',analysisCell);
%% S Fig. 5d
singleCellNormRiseVsFDPValDist('analysisCell',analysisCell);
%% Fig. 5a
[FDFF,TF] = graphChoiceProbWTime('sigLeft',sigLeft,'uniqueIDsFromCOI',uniqueIDsFromCOI,'IDsFromCellsOfInterest',IDsFromCellsOfInterest);
%% Fig. 5b
fig5obj = fig5('dFFRange',3.0,'eyeRange',45,'dFFLineWidth',1.5,'dFFLineColor',[],...
    'deconvLineWidth',1.5,'deconvLineColor',[0 0 0],'paperPosition',[0 0 5.9 4.5],'showScale',true);
fig5obj = fig5obj.runFig5b([13,5,24],'AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'ISIMatrix',ISIMatrix,'fixationIDs',fixationIDs,...
    'traceFilename','demoSlopeMeasurement','timeWidth',100,'timeOffset2plot',44,'axesOverlap',0.15,'showAxis',false,'showDeconv',true,...
    'slopeColor',[186,124,28]./255,'slopeLineWidth',1.5,'textYLoc',0.2);pause(0.1);
%% Fig. 5c
slopeHistos('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'analysisCell',analysisCell,'IDsFromCellsOfInterest',IDsFromCellsOfInterest,...
    'XLIM',[-100 2000],'xlabel','slope (arb. units)','binEdges',[-100:50:2000],'SRMatrixIDs',fixationIDs);
%% Fig. 5d
rampVRiseTime('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'YLabel','slope (arb.units)','SRMatrixIDs',fixationIDs);
%% Fig. 5e
popAvgConditionedISI('sigLeft',sigLeft,'uniqueIDsFromCOI',uniqueIDsFromCOI,'IDsFromCellsOfInterest',IDsFromCellsOfInterest,'FDFF',FDFF,'TF',TF,'scaleBar',[]);
%% Fig. 5f
[allData,allDataControl,allAnOut]=thresholdVFixationDurFirstConstructPopAvg('sigLeft',sigLeft,'uniqueIDsFromCOI',uniqueIDsFromCOI,'IDsFromCellsOfInterest',IDsFromCellsOfInterest,...
    'FDFF',FDFF,'TF',TF,'allData',[],'allDataControl',[],'allAnOut',[],...
    'YLIM',[-4e4 10e4],'ylabel','activity at time of saccade (arb. units)','YTick',[0],'YTickLabel',{'0'},'SRMatrixIDs',fixationIDs);
%% S Fig. 4e
singleCellSlopeVFDExamples('analysisCell',analysisCell,'YLABEL','slope (arb. units)','YLIM',[0 2000]);
%% S Fig 4f
singleCellSlopeVFDPValDist('analysisCell',analysisCell);
%% S Fig 5a
rebuttalSRONONExamples
%% S Fig 5b
slopeHistosSameDirSaccades('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'XLABEL','slope (arb. units)');
%% S Fig 5c
rampVRiseTimeSameDirSaccades('AnticipatoryAnalysisMatrix',AnticipatoryAnalysisMatrix,'YLABEL','slope (arb. units)','YLIM',[],'showBinMedian',false,'minNumSamples',10,'missingSampVal',[],'SRMatrixIDs',fixationIDs);
%% S Fig 6a
[durations,predictions,actual]=runPredictSaccadesRampThresh_exampleTraces('sigLeft',sigLeft,...
    'uniqueIDsFromCOI',uniqueIDsFromCOI,'IDsFromCellsOfInterest',IDsFromCellsOfInterest,'FDFF',FDFF,'TF',TF,'allData',allData,'riseThreshold',35,...
    'showBinMedian',true,'minNumSamples',10,'missingSampVal',[],'ylabel','activity (a.u)');
%% S Fig 6b
runPredictSaccadesRampThresh('predictions',predictions,'actual',actual,'showBinMedian',true,'minNumSamples',10,...
    'missingSampVal',[],'predictionBinEdges',-300:100:1000,'ylabel','estimated activity (arb. units)','xlabel','actual activity (arb. units)');
%% Fig. 5h
[STEstimate,ST,STEM,binTimes] = saccadeTimePrediction('sigLeft',sigLeft,...
    'uniqueIDsFromCOI',uniqueIDsFromCOI,'IDsFromCellsOfInterest',IDsFromCellsOfInterest,'FDFF',FDFF,'TF',TF,'allData',allData,'riseThreshold',35,...
    'showBinMedian',true,'minNumSamples',10,'missingSampVal',[]);
%% Fig. 5i
saccadeTimePredictionError('STEM',STEM,'binTimes',binTimes,'showBinMedian',true,'minNumSamples',10,'XLIM',[-7.0 0.01]);
predictSaccadesWMean;
%% S Fig. 7 (run makeMaps and follow instructions for FIJI)
%% Fig. 6a
rhDistOfSRCells('sigLeft',sigLeft,'sigRight',sigRight,'Coordinates',Coordinates);
perCellWeight = SRRCLocs1DHistoZBrainBigWarp('sigLeft',sigLeft,'sigRight',sigRight,'Coordinates',Coordinates);
fprintf('%d cells examined over %d fish\n',sum(sigLeft) + sum(sigRight),length(unique(IDsFromCellsOfInterest(:,1))));
%% Fig. 6b
SRLRLocs1DHistoZBrainBigWarp('sigLeft',sigLeft,'sigRight',sigRight,'Coordinates',Coordinates,'perCellWeight',perCellWeight);
%% Fig. 6c
SRDVLocs1DHistoZBrainBigWarp('sigLeft',sigLeft,'sigRight',sigRight,'Coordinates',Coordinates,'perCellWeight',perCellWeight);
%% Fig. 6d-e (run makeMaps and follow instructions for FIJI)
fprintf('%d cells examined over %d fish\n',sum(STACriteria & ~(sigLeft|sigRight)),length(unique(ID(STACriteria & ~(sigLeft|sigRight),1))));
%% Fig. 7b (made in FIJI with figure7B.ijm)
%% Fig. 7c
singleFishExampleOfAblEffectOnISI;
%% Fig. 7d 
AblationSizeInPercentHindbrain
CoorBridgeBrain = SRHorzLROverlap('sigLeft',sigLeft,'sigRight',sigRight);
data=fracAntCoarseAblVsFD('sigLeft',sigLeft,'sigRight',sigRight,'STACriteria',STACriteria,'Coordinates',CoorBridgeBrain,'minSacRatePerDirection',5);
plotCoarseAblFracAblVsEffect(data)
%% S Fig. 8a
behaviorStat = ISIDistributionChangesBoxPlotsHbvsSC;
%% S Fig. 8b
invTauDistributionChangesBoxPlots
%% S Fig. 8c
sacVelocityDistributionChangesBoxPlots
%% S Fig. 9d
effectSizeVsLocationAksayBoot(data);
%% Fig. 7e 
[asc,numFixations,iscontrol]=numberSingleSRCellsAblated;
pvalDistMedCombDirAksayBoot
displayComDirChangeBootIncrease
%% S Fig. 9
scAblatedSRvsContLocations