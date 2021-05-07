function varargout=thresholdVFixationDurFirstConstructPopAvg(varargin)
% thresholdVFixationDurFirstConstructPopAvg - plot average SR population dF/F at the time of saccade (on directions)
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
global saveCSV

options = struct('sigLeft',[],'uniqueIDsFromCOI',[],'IDsFromCellsOfInterest',[],'FDFF',[],'TF',[],'allData',[],'allDataControl',[],'allAnOut',[],...
    'YLIM',[],'ylabel',[],'YTick',[],'YTickLabel',[],'SRMatrixIDs',[]);
options = parseNameValueoptions(options,varargin{:});

ISImin = 3; ISImax = 20;
if isempty(options.uniqueIDsFromCOI)  || isempty(options.IDsFromCellsOfInterest)
    loadAnticipatorySelectionCriteria
else
    uniqueIDsFromCOI = options.uniqueIDsFromCOI;
    IDsFromCellsOfInterest = options.IDsFromCellsOfInterest;
    sigLeft = options.sigLeft;
    fixationIDs = options.SRMatrixIDs;
end

onDirection = sigLeft(uniqueIDsFromCOI); % if the cell is leftward coding (1) then the ON direction is left(1) Otherwise the ON direction is 0;
if isempty(options.FDFF) || isempty(options.TF)
    [FDFF,TF] = loadfullData(IDsFromCellsOfInterest,'dff',false,'useDeconvF',true);
else
    FDFF = options.FDFF;
    TF = options.TF;
end

binTimes = -30:1/3:0;
if isempty(options.allData)
    [allData,allAnOut,indices2keep] = gatherPreSaccadeEventTraces(FDFF,TF,onDirection,IDsFromCellsOfInterest,[ISImin ISImax],...
        'binTimes',binTimes,'ISIwidth',0.5,'tau','future saccade','cutTimeGTISI',false,'NaNInvalidPoints',true);
    varargout{1} = allData;
else
    allData = options.allData;
end

rng('default')
[measuredValueBeforeSaccade,SEMMeasurement,~,NFix,Samples] = shiftPopAvgComputeDffAtSaccade(allData,binTimes,'ISImin',ISImin,'ISImax',ISImax);
if isempty(options.allDataControl)
    [allDataControl] = gatherPreSaccadeEventTraces(FDFF,TF,onDirection,IDsFromCellsOfInterest,[ISImin ISImax],...
        'binTimes',-30:1/3:0,'ISIwidth',0.5,'tau','future saccade','cutTimeGTISI',false,'NaNInvalidPoints',true,'randomSaccadeTimes',true);
    varargout{2} = allDataControl;
    varargout{3} = allAnOut;
else
    allDataControl = options.allDataControl;
 end
if ~isempty(options.allAnOut)
       allAnOut = options.allAnOut;
end
[controlActAtSaccade,controlSEM,~,~,controlSamples] = shiftPopAvgComputeDffAtSaccade(allDataControl,binTimes,'ISImin',ISImin,'ISImax',ISImax);
%[controlActAtSaccade,controlSEM,~,~,controlSamples] = shiftPopAvgComputeDffAtSaccade(allData,binTimes,'ISImin',ISImin,'ISImax',ISImax,'randomTimes',true);
varargout{2}=allDataControl;
varargout{3} = allAnOut;
% format data to plot into a sharable format
data.fdBins = ISImin:ISImax;
data.avgDFF = measuredValueBeforeSaccade;
data.SEMDFF = SEMMeasurement;
data.avgDFFShuffled = controlActAtSaccade;
data.SEMDFFShuffled = controlSEM;
data.numFixations = NFix;

% plot
figure;
errorbar(data.fdBins,100*data.avgDFF,100*data.SEMDFF,...
    'Marker','.','MarkerSize',10); hold on;
conEBHandle=errorbar(data.fdBins,100*data.avgDFFShuffled,100*data.SEMDFFShuffled,...
    'Marker','.','MarkerSize',10);
conEBHandle.Color = [1 1 1]*0.8;
set(gca,'XTick',[5:5:20],'XTickLabel',[5:5:20]);
if ~isempty(options.YTick) && ~isempty(options.YTickLabel)
    set(gca,'YTick',options.YTick,'YTickLabel',options.YTickLabel);
end
box off; xlabel({'fixation duration (s)'});ylabel(options.ylabel); setFontProperties(gca)
if ~isempty(options.YLIM)
    ylim(options.YLIM);
end

xlim([2 20.5]);
set(gcf,'PaperPosition',[0 0 2.2 2.2])

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

%allAnOut = options.allAnOut;
[nc,nf,ne,numCellPerDur,numFishPerDur,numEventsPerDur] = getSampleSizeFromLoadSingleTrialResponses(allAnOut);
fprintf('%d fixations from %d cells examined over %d independent fish\n',ne,nc,nf)
fprintf('sample size per bin ranges from %d-%d fixations\n',min(numEventsPerDur),max(numEventsPerDur));

% print stats quoted in the paper
fprintf('The number of fixations in the average varies between %d and %d\n',min(data.numFixations),max(data.numFixations))

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 5f.csv'],'a');
    fprintf(fileID,'Panel\nf\n');
     for k = 1 : length(Samples)
         numSamp = size(allAnOut{k},1);
            fprintf(fileID,'fixation duration(s),%0.3f',data.fdBins(k));
            fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Within-Plane Cell ID,Sample Index,activity at time of saccade(arb. units),activity at time of saccade(arb. units) using random saccade times\n');
            dlmwrite([fileDirs.scDataCSV 'Figure 5f.csv'],[allAnOut{k}(:,1:3) (1:numSamp)' Samples{k} controlSamples{k}],'delimiter',',','-append');
    end
    fclose(fileID);
end