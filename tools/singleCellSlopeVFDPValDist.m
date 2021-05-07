function singleCellSlopeVFDPValDist(varargin)
% singleCellSlopeVFDPValDist
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
% count how many cells pass GOF criteria
numCells = length(analysisCell);


slopeVrtPval = NaN(numCells,1);
directionOfSlope = NaN(numCells,1);
for cIndex = 1 : numCells
    singleCellGOF = analysisCell{(cIndex)}(:,5) >= 0.4;
     allSlopesForThisCell = analysisCell{(cIndex)}(singleCellGOF,1); % slope
    allRiseTimesForThisCell = analysisCell{(cIndex)}(singleCellGOF,2); % rise-time
    
    % determine if there are enough samples for analysis 
    [keepThisCell] = singleCellFDPropertiesCutData(allRiseTimesForThisCell,allSlopesForThisCell,'minNumSamp',5,'iqrCut',1); 
 
    if keepThisCell 
        normRiseTimeVSlopeRegressionObject = LinearModel.fit(allRiseTimesForThisCell,allSlopesForThisCell);
        x1pval = normRiseTimeVSlopeRegressionObject.Coefficients.pValue(2);
        slopeVrtPval(cIndex) = x1pval;
        directionOfSlope(cIndex) = sign(normRiseTimeVSlopeRegressionObject.Coefficients.Estimate(2));
    end
end
%%
%riseTimeBins = 0.5:0.5:20; 
figure;ecdf(slopeVrtPval);hold on;plot([1 1]*0.05,[0 1],'k--');box off; 
%xlabel('p-value of slope coefficients relating rate of anticipatory rise versus time of rise');
xlabel('p-value');
ylabel('cumulative fraction of SR cells');setFontProperties(gca)
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
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\singleCellSlopeVFDPValDist'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% results
sigCells = slopeVrtPval<0.05;
numberSigWithPositiveSlope = sum(directionOfSlope(sigCells)==1);

fprintf('\n\n At the individual cell level, this positive correlation\n was apparent for %0.3f percent of SR cells \n\n',100*numberSigWithPositiveSlope / sum(~isnan(slopeVrtPval)))
%% Supp Figure Caption 4F
fprintf('\n\nwas greater than or equal to 1 second; n=%d cells passing criteria (dummy check that total # cells is %d)\n',sum(~isnan(slopeVrtPval)),length(slopeVrtPval)) 
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 4f.csv'],'a');
    fprintf(fileID,'Panel\nf\n');
    fprintf(fileID,'p-values\n');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 4f.csv'],slopeVrtPval,'delimiter',',','-append');
    fclose(fileID);
end
