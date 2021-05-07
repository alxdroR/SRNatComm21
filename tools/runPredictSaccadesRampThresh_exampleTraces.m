function varargout = runPredictSaccadesRampThresh_exampleTraces(varargin)
% runPredictSaccadesRampThresh_exampleTraces - print example traces of
% dF/F with time along with ramp-to-threshold predictions
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202


options = struct('sigLeft',[],'uniqueIDsFromCOI',[],'IDsFromCellsOfInterest',[],'FDFF',[],'TF',[],'allData',[],'durations',[],...
    'riseThreshold',0.04,'predictions',[],'actual',[],'showBinMedian',false,'minNumSamples',10,'missingSampVal',NaN,...
    'predictionBinEdges',[],'YLIM',[],'ylabel',[]);
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
% plot binned and averaged data
showAvg = true;
if showAvg
    if isempty(options.predictionBinEdges)
        rg = max(data.actualAll)-min(data.actualAll);
        pB = plotBinner([data.actualAll data.predictedAll],rg/10);
    else
        pB = plotBinner([data.actualAll data.predictedAll],options.predictionBinEdges);
    end
    [binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',options.showBinMedian,'minNumSamples',options.minNumSamples,'missingSampVal',options.missingSampVal);
    eh=errorbar(binCenters,binnedData,sqrt(binVar./numberSamp)); hold on;
    plot(binCenters,binnedData,'b:.');
    pointColor = [1 1 1]*0.6;
else
    pointColor = 'b';
end
eh.LineWidth=1;

% view some example traces as functions of time
figure;
for exIndex = 1:4
    relevantTime = data.actual{exIndex}(:,1);
    subplot(2,2,exIndex)
    plot(relevantTime,data.actual{exIndex}(:,2),':.','Color',[1 1 1]*0.6); hold on;
    plot(relevantTime,data.predicted{exIndex},'b');
    if ~isempty(options.YLIM)
        ylim(options.YLIM);
    end
    xlim([-15 0]); %axis off
    set(gca,'XTick',[-15 -10 -5 0],'XTickLabel',{'' '-10' '-5' '0'},'YTick',[],'YTickLabel',[]);box off
    if exIndex == 3 || exIndex ==4
        xlabel('time (s)');ylabel(options.ylabel);legend('actual','prediction');legend boxoff
    end
end

set(gcf,'PaperPosition',[0 0 2.2 2.2])

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)
%%
% print stats quoted in the paper
%fprintf('... using the entire period when SR activity increases(cc between model and data equaled %0.4f\n',corr(data.predictedAll,data.actualAll));
mse = mean( (data.actualAll-data.predictedAll).^2);
r2 = 1-mse/var(data.actualAll,1);
%fprintf('R2 = %0.4f\n',r2);

runOldStats = false;
if runOldStats
    %%
    % in this version, the threshold was not known but the offset where
    % activity began was known. Using a known threshold, slope as a parameter measured in training set and known starting
    % point, we can predict when threshold crossing will occur
    propCorrect = predictSaccadesRampThreshOLD(FDFF,TF,onDirection,IDsFromCellsOfInterest,'ISImin',ISImin,'ISImax',ISImax,'allData',allData,'fdDis',samplesBoth,'chooseKCellsAtRandom',[]);
    probCorrect = sum(propCorrect)/length(propCorrect);
    error = std(propCorrect)/sqrt(length(propCorrect));
    fprintf('A ramping approximation of SR population dynamics crosses the measured threshold\n within 20 percent of the correct saccade time %0.4f +- %0.4f%% of the time\n',probCorrect*100,error*100);
    %% use shuffled control
    propCorrect = predictSaccadesRampThreshOLD(FDFF,TF,onDirection,IDsFromCellsOfInterest,'ISImin',ISImin,'ISImax',ISImax,'allData',allData,'fdDis',samplesBoth,'useShuffleControl',true);
    probCorrect = sum(propCorrect)/length(propCorrect);
    error = std(propCorrect)/sqrt(length(propCorrect));
    fprintf('A ramping approximation of shuffled population dynamics crosses the measured threshold\n within 20 percent of the correct saccade time %0.4f +- %0.4f%% of the time\n',probCorrect*100,error*100);
    
    %% predicting with Non-anticipatory cells
    script2RunPCAOnSTA;
    % remove the shift in longitude used for visualization
    [lat,lon,h] = ecef2geodetic(S,scoreNormed(:,1),scoreNormed(:,2),scoreNormed(:,3));
    
    % seperate the left and right longitudes
    N = size(STACAT,1)/2;
    lonL = lon(1:N); lonR = lon(N+1:2*N);
    latL = lat(1:N); latR = lat(N+1:2*N);
    
    
    [~,maxDirIndex] = max([lonR lonL],[],2);
    onDir = maxDirIndex==2;
    
    uniqueNonAnticIDs = find(~(Hcc(:,1) & ~Hcc(:,2)) & ~(~Hcc(:,1) & Hcc(:,2)));
    %%
    idSTACrit = ID(STACriteria,:);
    nonAnticIDs= idSTACrit(uniqueNonAnticIDs,:);
    [FB,TFB,EcellB,TcellB] = loadfullData(nonAnticIDs,'useTwitches',false);
    onDirB = onDir(uniqueNonAnticIDs);
    
    allData = gatherPreSaccadeEventTraces(FB,TFB,onDirB,nonAnticIDs,[ISImin ISImax],...
        'binTimes',-30:1/3:0,'ISIwidth',0.5,'tau','future saccade','cutTimeGTISI',false,'NaNInvalidPoints',true);
    %% choose the same number of neurons as what is used for anticipatory cells
    numberSRCells = length(uniqueIDsFromCOI);
    propCorrect = predictSaccadesRampThreshOLD(FB,TFB,onDirB,nonAnticIDs,'ISImin',ISImin,'ISImax',ISImax,'allData',allData,'fdDis',samplesBoth,'chooseKCellsAtRandom',numberSRCells);
    probCorrect = sum(propCorrect)/length(propCorrect);
    error = std(propCorrect)/sqrt(length(propCorrect));
    fprintf('A ramping approximation of non-SR population dynamics crosses the measured threshold\n within 20 percent of the correct saccade time %0.4f +- %0.4f%% of the time\n',probCorrect*100,error*100);
    %% choose all the neurons to see if this does better
    propCorrect = predictSaccadesRampThreshOLD(FB,TFB,onDirB,nonAnticIDs,'ISImin',ISImin,'ISImax',ISImax,'allData',allData,'fdDis',samplesBoth,'chooseKCellsAtRandom',[]);
    probCorrect = sum(propCorrect)/length(propCorrect);
    error = std(propCorrect)/sqrt(length(propCorrect));
    fprintf('A ramping approximation of non-SR population dynamics crosses the measured threshold\n within 20 percent of the correct saccade time %0.4f +- %0.4f%% of the time\n',probCorrect*100,error*100);
end