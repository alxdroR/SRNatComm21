function singleCellNormRiseVsFDExamples(varargin)
% singleCellNormRiseVsFDExamples
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

options = struct('analysisCell',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.analysisCell) 
   loadSRSlopes
else
    analysisCell = options.analysisCell;
end
%%
% determine range of possible correlations
numCells = length(analysisCell);
fcc = NaN(numCells,1);
for cIndex = 1 : numCells
    allISIValuesForThisCell = analysisCell{cIndex}(:,12);
    allRiseTimesForThisCell = analysisCell{cIndex}(:,2);
    % normalized rise times 
    normedRiseTimes = allRiseTimesForThisCell./allISIValuesForThisCell; % rise-times w.r.t upcoming saccade divided by ISI
    
    % determine if there are enough samples for analysis 
    [keepThisCell] = singleCellFDPropertiesCutData(allISIValuesForThisCell,normedRiseTimes,'minNumSamp',10,'iqrCut',1); 
    
    if keepThisCell
        % add a statistic to try and characterize the plot
        % calculate best fit line for normalized data
        nonNaNPoints = ~isnan(normedRiseTimes);
        ccs = corr(allISIValuesForThisCell(nonNaNPoints),normedRiseTimes(nonNaNPoints),'type','Spearman');
        fcc(cIndex) = ccs;
     end
end
%%
XLABEL = {'fixation duration (s)'};YLABEL = {'activity rise-time' 'normalized by fixation duration'};

XLIM = [0 40];YLIM = [-20 0];
numRows=5; numC = 3;
% ISI is fixed to ISICenter +- ISIWidth. Set ISI width to a really large value  
ISIWidth = 1; ISICenters = 2:ISIWidth:20;


 % show individual samples
figure; 

% randomly pick cells to view
% set random number generator
rng('default')
useableCellIndices = find(~isnan(fcc));
cells2view = useableCellIndices(randperm(length(useableCellIndices),15));

numCellsTotal = length(analysisCell);
% pick indices that are evenly spaced across the rang of correlations seen 
%cindexV = [ 47    58    34   272   363   415   298   231   301   210   230   306   201   291   405];
%cindexV = 1:numCellsTotal;
col2keepYlabel = 1:numC:numRows*numC;
counter = 1; 
for cindex = cells2view'
    subplot(numRows,numC,counter)
    allISIValuesForThisCell = analysisCell{cindex}(:,12);
    allRiseTimesForThisCell = analysisCell{cindex}(:,2);
    % normalized rise times
    normedRiseTimes = allRiseTimesForThisCell./allISIValuesForThisCell; % rise-times w.r.t upcoming saccade divided by ISI
    
    % determine if there are enough samples for analysis
    [keepThisCell] = singleCellFDPropertiesCutData(allISIValuesForThisCell,normedRiseTimes,'minNumSamp',10,'iqrCut',1);
    if keepThisCell
        plot(allISIValuesForThisCell,normedRiseTimes,'.');xlim([0 30]);ylim([-1 0]);box off;setFontProperties(gca) ; hold on;
        
        % add a statistic to try and characterize the plot
        % calculate best fit line for normalized data
        normRiseTimeVISIRegressionObject = LinearModel.fit(allISIValuesForThisCell,normedRiseTimes);
        x1pval = normRiseTimeVISIRegressionObject.Coefficients.pValue(2);
        r2 = normRiseTimeVISIRegressionObject.Rsquared.Adjusted;
        ccs = corr(allISIValuesForThisCell(~isnan(normedRiseTimes)),normedRiseTimes(~isnan(normedRiseTimes)),'type','Spearman');
        txtStr = sprintf('cc=%0.2f\n',ccs);
        text(20,-0.94,txtStr,'FontName','Arial','FontSize',6,'Color','k')
        
        if ~any(counter == col2keepYlabel)
            set(gca,'YTickLabel',[]);
        end
        if counter < numC*(numRows-1)+1
            set(gca,'XTickLabel',[]);
        end
        
        if counter==numC*(numRows-1)+1
            xlabel(XLABEL);ylabel(YLABEL);setFontProperties(gca)
        end
        counter = counter + 1;
    end
    if counter > numRows*numC
        break
    end
end
%%
global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    set(gcf,'PaperPosition',[0 0 4 4],'InvertHardcopy','off','Color',[1 1 1]);
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\singleCellNormRiseVsFDExamples'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end