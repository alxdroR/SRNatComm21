function varargout = saccadeTimePrediction(varargin)
% saccadeTimePrediction - plot saccade time prediction versus actual
% saccade time
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
global saveCSV

options = struct('sigLeft',[],'uniqueIDsFromCOI',[],'IDsFromCellsOfInterest',[],'FDFF',[],'TF',[],'allData',[],...
    'riseThreshold',0.04,'ST',[],'STEstimate',[],'showBinMedian',false,'minNumSamples',10,'missingSampVal',NaN);
options = parseNameValueoptions(options,varargin{:});

ISImin = 3; ISImax = 20;
if isempty(options.ST) || isempty(options.STEstimate)
    if isempty(options.uniqueIDsFromCOI) || isempty(options.IDsFromCellsOfInterest)
        loadAnticipatorySelectionCriteria
    else
        uniqueIDsFromCOI = options.uniqueIDsFromCOI;
        IDsFromCellsOfInterest = options.IDsFromCellsOfInterest;
        sigLeft = options.sigLeft;
    end
    onDirection = sigLeft(uniqueIDsFromCOI); % if the cell is leftward coding (1) then the ON direction is left(1) Otherwise the ON direction is 0;
    if isempty(options.FDFF) || isempty(options.TF)
        [FDFF,TF] = loadfullData(IDsFromCellsOfInterest,'dff',false,'useDeconvF',true);
    else
        FDFF = options.FDFF;
        TF = options.TF;
    end
    if isempty(options.allData)
        [allData] = gatherPreSaccadeEventTraces(FDFF,TF,onDirection,IDsFromCellsOfInterest,[ISImin ISImax],...
            'binTimes',-30:1/3:0,'ISIwidth',0.5,'tau','future saccade','cutTimeGTISI',false,'NaNInvalidPoints',true);
        varargout{1} = allData;
        voutIndex = 1;
    else
        allData=options.allData;
        voutIndex = 0;
    end
    [STEstimate,ST,STEM,binTimes] = predictTimeUntilUpcomingSaccade(FDFF,TF,onDirection,IDsFromCellsOfInterest,...
        'ISImin',ISImin,'ISImax',ISImax,'allData',allData,'chooseKCellsAtRandom',[],'runLinearModel',false,'riseThreshold',options.riseThreshold);
    
    varargout{voutIndex+1} = STEstimate;
    varargout{voutIndex+2} = ST;
    varargout{voutIndex+3} = STEM;
    varargout{voutIndex+4} = binTimes;
else
    ST=options.ST;
    STEstimate = options.STEstimate;
end
% convert the estimates into a vector

% format data to plot into a sharable format
data.actualTime = ST;
data.predictedTime = STEstimate;
data.fdBins = ISImin:ISImax;

% plot
actualTimeAll = cat(2,data.actualTime{:})';
predictedTimeAll = cat(2,data.predictedTime{:})';

showAvg = true;
if showAvg
    pointColor = [1 1 1]*0.8;
else
    pointColor = 'b';
end
figure;
ph=plot(actualTimeAll,predictedTimeAll,'.');hold on;
defaultBlue = ph.Color;
ph.Color = pointColor;
if showAvg
    binCenters = -10.5:0.5:2;
    pB = plotBinner([actualTimeAll predictedTimeAll],binCenters);
    [binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',options.showBinMedian,'minNumSamples',options.minNumSamples,'missingSampVal',options.missingSampVal);
    eh=errorbar(binCenters,binnedData,sqrt(binVar./numberSamp),'Color',defaultBlue); hold on;
end
eh.LineWidth=1.5;
plot([-20 2],[-20 2],'k--')
xlim([-13 0]);ylim([-22 2])
ylabel('estimated time until saccade (s)');xlabel('actual time until saccade (s)'); box off
setFontProperties(gca)
set(gcf,'PaperPosition',[0 0 2.2 2.2])

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

% print stats quoted in the paper
[cc,pval] = corr(predictedTimeAll,actualTimeAll);
fprintf('The correlation between all predictions and actual data is %0.4f\n (p=%0.5f)\n',cc,pval)
fprintf('total number of predictions = %d\n',size(actualTimeAll,1));
fprintf('sample size per bin ranges from %d-%d predictions\n',max(10,min(numberSamp)),max(numberSamp));

STEstimateVp = [];
STVp = [];
for count = 1 : length(data.actualTime)
    twoSecondAfterRampSelector = data.actualTime{count}-data.actualTime{count}(1)<=2;
    STEstimateVp  = [STEstimateVp;data.predictedTime{count}(twoSecondAfterRampSelector)'];
    STVp = [STVp;data.actualTime{count}(twoSecondAfterRampSelector)'];
end

[ccp,pvalp] = corr(STEstimateVp,STVp);
fprintf('The correlation between predictions and data restricted to 2 seconds after ramping is %0.4f\n (p=%0.5f)\n',ccp,pvalp)
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 5h.csv'],'a');
    fprintf(fileID,'Panel\nh\n');
    indices2bin = binData(pB,'onlyReturnIndicesPerBin',true);
    numSamp = cellfun(@(x) size(x,1),indices2bin);
    for k = 1 : length(indices2bin)
        if numSamp(k) >= 10
            fprintf(fileID,'\nactual time until saccade(s) fixed at,%0.3f',pB.binParameter(k));
            fprintf(fileID,'\nSample Index, actual time(s), predicted time (s)\n');
            dlmwrite([fileDirs.scDataCSV 'Figure 5h.csv'],[(1:numSamp(k))' pB.data(indices2bin{k},1) pB.data(indices2bin{k},2 )],'delimiter',',','-append');
        end
    end
    fclose(fileID);
end
