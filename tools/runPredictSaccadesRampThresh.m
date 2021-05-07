function varargout = runPredictSaccadesRampThresh(varargin)
% runPredictSaccadesRampThresh
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202x
global saveCSV
options = struct('sigLeft',[],'uniqueIDsFromCOI',[],'IDsFromCellsOfInterest',[],'FDFF',[],'TF',[],'allData',[],...
    'riseThreshold',0.04,'predictions',[],'actual',[],'showBinMedian',false,'minNumSamples',10,'missingSampVal',NaN,...
    'predictionBinEdges',[],'ylabel','estimated','xlabel','actual');
options = parseNameValueoptions(options,varargin{:});

ISImin = 3; ISImax = 20;
if isempty(options.predictions) || isempty(options.actual)
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
    else
        allData=options.allData;
    end
    if isempty(options.durations)
        durations=jointISIDistributionPopAggregatev2;
        voutIndex = 1;
        varargout{voutIndex} = durations;
    else
        durations = options.durations;
        voutIndex = 0;
    end
    samplesBoth = [durations.left;durations.right];
    % using known times of rise and thresholds predict activity
    rng('default')
    tic
    ntests = 10000;
    [predictions,actual]= predictSaccadesRampThresh('ISImin',ISImin,'ISImax',ISImax,'allData',allData,'fdDis',samplesBoth,'numTests',ntests,'riseThreshold',options.riseThreshold);
    timeTest = toc;
    fprintf('Total time to run %d = %0.4f\n',ntests,timeTest)
    varargout{voutIndex+1} = predictions;
    varargout{voutIndex+2} = actual;
else
    predictions=options.predictions;
    actual = options.actual;
end

% view all predictions and all actual values
predictionsV = cat(2,predictions{:});
actualV = cat(1,actual{:});

% format data to plot into a sharable format
data.predictedAll = predictionsV';
data.actualAll = actualV(:,2);
data.predicted = predictions;
data.actual = actual;

figure;
nPoints = length(data.predictedAll);
showAvg = true;
if showAvg
     pointColor = [1 1 1]*0.6;
else
    pointColor = 'b';
end
if nPoints > 1000
    % show a random selection
    indices2display = randperm(nPoints,1000);
    plot(data.actualAll(indices2display),data.predictedAll(indices2display),'.','Color',pointColor)
else
    plot(data.actualAll,data.predictedAll,'.','Color',pointColor)
end
%xlim([-0.2 0.6]);ylim([-0.6 0.7])
hold on;
% plot binned and averaged data
if showAvg
     if isempty(options.predictionBinEdges)
        rg = max(data.actualAll)-min(data.actualAll);
        pB = plotBinner([data.actualAll data.predictedAll],rg/10);
    else
        pB = plotBinner([data.actualAll data.predictedAll],options.predictionBinEdges);
     end
    [binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',options.showBinMedian,'minNumSamples',options.minNumSamples,'missingSampVal',options.missingSampVal);
    %eh=errorbar(binCenters,binnedData,sqrt(binVar./numberSamp),'Color',[0 0.4470 0.7410]); hold on;
    eh=plot(binCenters,binnedData,'Color',[0 0.4470 0.7410]); hold on;
    pointColor = [1 1 1]*0.6;
else
    pointColor = 'b';
end
eh.LineWidth=1;
hold on;plot([0 1400],[0 1400],'k--')
xlim([0 1400]);ylim([-1000 1500]);
ylabel(options.ylabel);xlabel(options.xlabel); box off
setFontProperties(gca)
%xlabel('');ylabel('');set(gca,'XTickLabel',[],'YTickLabel',[]);
set(gcf,'PaperPosition',[0 0 2.2 2.2])

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

fprintf('num test/train splits at fixed duration=%d\n',length(data.predicted));
fprintf('each test/train split leads to series of predictions\ntotal num predications=%d\n',length(data.predictedAll));
fprintf('SEM = %0.3f(arb. units)\n',std(data.predictedAll)/sqrt(length(data.predictedAll)))

% print stats quoted in the paper 
fprintf('... using the entire period when SR activity increases(cc between model and data equaled %0.4f\n',corr(data.predictedAll,data.actualAll));
%fprintf('The correlation between predicted and actual values is %0.4f\n',corr(data.predictedAll,data.actualAll));
mse = mean( (data.actualAll-data.predictedAll).^2);
r2 = 1-mse/var(data.actualAll,1);
fprintf('R2 = %0.4f\n',r2);
if saveCSV
[~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 6.csv'],'a');
    fprintf(fileID,'actual activity(arb. units),predicted activity (arb. units)\n');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 6.csv'],[data.actualAll data.predictedAll],'delimiter',',','-append','coffset',0);
fclose(fileID);
end
