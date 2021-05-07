function singleCellNormRiseVsFDCCDist(varargin)
% singleCellNormRiseVsFDCCDist
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202
global saveCSV

options = struct('analysisCell',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.analysisCell) 
   loadSRSlopes
else
    analysisCell = options.analysisCell;
end

%%
%XLABEL = {'p-value of slope coefficients relating normalized risetime versus fixation duration'};
YLABEL = 'cumlative fraction of SR cells';
XLABEL = {'spearman correlation coefficient'};
%%
% set random number generator
rng('default')

numCells = length(analysisCell);
fdVnrtPval = NaN(numCells,1);
fcc = NaN(numCells,1);
fccControl = NaN(numCells,1);
numSingleCellSamples = NaN(numCells,1);
directionOfSlope = NaN(numCells,1);
for cIndex = 1 : numCells
    allISIValuesForThisCell = analysisCell{cIndex}(:,12);
    allRiseTimesForThisCell = analysisCell{cIndex}(:,2);
    % normalized rise times 
    normedRiseTimes = allRiseTimesForThisCell./allISIValuesForThisCell; % rise-times w.r.t upcoming saccade divided by ISI
    
    % determine if there are enough samples for analysis 
    [keepThisCell] = singleCellFDPropertiesCutData(allISIValuesForThisCell,normedRiseTimes,'minNumSamp',5,'iqrCut',1); 
    
    if keepThisCell
        % add a statistic to try and characterize the plot
        % calculate best fit line for normalized data
        nonNaNPoints = ~isnan(normedRiseTimes);
        shufRise = normedRiseTimes(nonNaNPoints); 
        permutedIndex = randperm(length(shufRise),length(shufRise));
        shuffNormedRiseTimes = shufRise(permutedIndex);
        ccs = corr(allISIValuesForThisCell(nonNaNPoints),normedRiseTimes(nonNaNPoints),'type','Spearman');
        ccsControl = corr(allISIValuesForThisCell(nonNaNPoints),shuffNormedRiseTimes,'type','Spearman');
        normRiseTimeVISIRegressionObject = LinearModel.fit(allISIValuesForThisCell,normedRiseTimes);
        x1pval = normRiseTimeVISIRegressionObject.Coefficients.pValue(2);
        fdVnrtPval(cIndex) = x1pval;
        fcc(cIndex) = ccs;
        fccControl(cIndex) = ccsControl;
        directionOfSlope(cIndex) = sign(normRiseTimeVISIRegressionObject.Coefficients.Estimate(2));
    end
end
%%
figure;
ecdf(fcc); hold on;
[F,X]=ecdf(fccControl); 
plot(X,F,'Color',[1 1 1]*0.651);box off; xlabel(XLABEL);ylabel(YLABEL);setFontProperties(gca)
%%
global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    set(gcf,'PaperPosition',[0 0 2 2],'InvertHardcopy','off','Color',[1 1 1]);
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\singleCellNormRiseVsFDPValDist'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% 
ccCutOff = 0.5;
numCorrCells = sum(fcc>ccCutOff);
numCellsPassing = sum(~isnan(fcc));
percentCorrelated = numCorrCells/numCellsPassing;
fprintf('%0.3f percent of cells had a Spearman correlation coefficient above %0.3f,..\n',100*percentCorrelated,ccCutOff)
%%
[~,p]=kstest2(fcc,fccControl);
fprintf('We rejected the null hypothesis that correlation coefficients across SR cells and shuffled controls come from the same distribution (p=%0.6f,n=%d)\n',p,numCellsPassing)
if 0 
fprintf('\n\n On a per cell basis, the time of normalized rise and fixation\n duration were only correlated for a small subset\n of SR neurons (less than 20percent, Supplemental Fig. 4C, 4D);\n\n')
numSigCells = sum(fdVnrtPval<0.05);
numSigCells/sum(~isnan(fdVnrtPval))
%%
numberSigWithPositiveSlope = sum(directionOfSlope(fdVnrtPval<0.05)==1)/numSigCells;
fprintf('Amongst significant trending cells, %0.2f have the same trend as the population\n',numberSigWithPositiveSlope); 
%% Supp Fig 4C. 
fprintf('\n\n Cumulative distribution of the p-values reported in (C)\n for all 94/420 pre-saccadic rise cells in the population \n\n')
sum(~isnan(fdVnrtPval))
end
if saveCSV
    NMax = max(length(fccControl),length(fcc));
    XMat = NaN(NMax,2);
    XMat(1:length(fcc),1)=fcc;
    XMat(1:length(fccControl),2)=fccControl;
     [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 4c.csv'],'a');
    fprintf(fileID,'Panel\nc\n');
    fprintf(fileID,'Spearman c.c.[SR cells],Spearman c.c.[control cells]\n');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 4c.csv'],XMat,'delimiter',',','-append');
    fclose(fileID);
end