function singleCellSlopeVFDExamples(varargin)
% singleCellSlopeVFDExamples
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202x
rng(1)
options = struct('analysisCell',[],'YLABEL','slope (dF/F)/s)','YLIM',[]);
options = parseNameValueoptions(options,varargin{:});

if  isempty(options.analysisCell) 
   loadSRSlopes
else
    analysisCell = options.analysisCell;
end
XLABEL = {'rise-time (s)'};

XLIM = [0 40];YLIM = [-20 0];
numRows=5; numC = 3;
% ISI is fixed to ISICenter +- ISIWidth. Set ISI width to a really large value  
ISIWidth = 1; ISICenters = 2:ISIWidth:20;
%%
% show individual samples
figure; numRows=5; numC = 3;
col2keepYlabel = 1:numC:numRows*numC;
% pick cells to view
numCellsTotal = length(analysisCell);
cindexV = 1:numCellsTotal;
counter = 1; 
for cindex = 1 : numCellsTotal
    singleCellGOF = analysisCell{cindexV(cindex)}(:,5) >= 0.4;
     singleCellGOF = singleCellGOF | any(singleCellGOF);
     
    allSlopesForThisCell = analysisCell{cindexV(cindex)}(singleCellGOF,1); % slope
    allRiseTimesForThisCell = analysisCell{cindexV(cindex)}(singleCellGOF,2); % rise-time
    
    % determine if there are enough samples for analysis
    [keepThisCell] = singleCellFDPropertiesCutData(allRiseTimesForThisCell,allSlopesForThisCell,'minNumSamp',8,'iqrCut',3.5);
    
    if keepThisCell
          subplot(numRows,numC,counter)
  
        plot(allRiseTimesForThisCell,allSlopesForThisCell,'.');
        xlim([-10 0]);
        if ~isempty(options.YLIM)
            ylim(options.YLIM);
        end
        box off;setFontProperties(gca) ; hold on;
        
        
        % add a statistic to try and characterize the plot
        % calculate best fit line for normalized data
        normRiseTimeVSlopeRegressionObject = LinearModel.fit(allRiseTimesForThisCell,allSlopesForThisCell);
        x1pval = normRiseTimeVSlopeRegressionObject.Coefficients.pValue(2);
        r2 = normRiseTimeVSlopeRegressionObject.Rsquared.Adjusted;
        txtStr = sprintf('p=%0.2f\n',x1pval);
        text(-2,1500,txtStr,'FontName','Arial','FontSize',6,'Color','k')
        
        if ~any(counter == col2keepYlabel)
            set(gca,'YTickLabel',[]);
        end
        if counter < numC*(numRows-1)+1
            set(gca,'XTickLabel',[]);
        end
        if counter==numC*(numRows-1)+1
            xlabel(XLABEL);ylabel(options.YLABEL);setFontProperties(gca)
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
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\singleCellSlopeVFDExamples'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
