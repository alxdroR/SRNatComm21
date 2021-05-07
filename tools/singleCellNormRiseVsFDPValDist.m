function singleCellNormRiseVsFDPValDist(varargin)
% singleCellNormRiseVsFDPValDist
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

%XLABEL = {'p-value of slope coefficients relating normalized risetime versus fixation duration'};
YLABEL = 'cumlative fraction of SR cells';
XLABEL = {'p-value'};
%%
numCells = length(analysisCell);
fdVnrtPval = NaN(numCells,1);
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
        normRiseTimeVISIRegressionObject = LinearModel.fit(allISIValuesForThisCell,normedRiseTimes);
        x1pval = normRiseTimeVISIRegressionObject.Coefficients.pValue(2);
        fdVnrtPval(cIndex) = x1pval;
        directionOfSlope(cIndex) = sign(normRiseTimeVISIRegressionObject.Coefficients.Estimate(2));
    end
end
%%
figure;ecdf(fdVnrtPval);hold on;plot([1 1]*0.05,[0 1],'k--');box off; xlabel(XLABEL);ylabel(YLABEL);setFontProperties(gca)
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
sigCut = 0.05;
numSigCells = sum(fdVnrtPval<sigCut);
numCellsTotal = sum(~isnan(fdVnrtPval));
percentSig = numSigCells/numCellsTotal;
fprintf('\n\n Only %0.3f percent of cells had slopes with a t-test p-value < %0.3f\n',percentSig,sigCut)
%%
numberSigWithPositiveSlope = sum(directionOfSlope(fdVnrtPval<0.05)==1)/numSigCells;
fprintf('Amongst significant trending cells, %0.2f have the same trend as the population\n',numberSigWithPositiveSlope);
if 0
    fprintf('\n\n Cumulative distribution of the p-values reported in (C)\n for all  pre-saccadic rise cells in the population \n\n')
    sum(~isnan(fdVnrtPval))
end
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 4d.csv'],'a');
    fprintf(fileID,'Panel\nd\n');
    fprintf(fileID,'p-values\n');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 4d.csv'],fdVnrtPval,'delimiter',',','-append');
    fclose(fileID);
end