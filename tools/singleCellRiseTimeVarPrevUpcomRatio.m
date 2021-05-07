function singleCellRiseTimeVarPrevUpcomRatio(varargin)
% singleCellRiseTimeVarPrevUpcomRatio
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202
global saveCSV

options = struct('analysisCell',[]);
options = parseNameValueoptions(options,varargin{:});

if  isempty(options.analysisCell) 
   loadSRSlopes
else
    analysisCell = options.analysisCell;
end
%%
%XLABEL = {'variance in time of rise relative to previous saccade/variance in time of rise relative to upcoming saccade'};YLABEL = 'fraction of SR cells';
XLABEL = {'\sigma^2_{previous}/\sigma^2_{upcoming}'};YLABEL = 'fraction of SR cells';

XLIM = [0 40];YLIM = [-20 0];
numRows=5; numC = 3;
binWidth =0.5;
minNumSamples = 5;
%%
 % show individual samples
figure; 


% COMPUTE TRIAL-VARIANCE TIMES OF RISE AT FIXED ISI -----
%----------
% initialize vectors that will store trial-averaged time of rise and the
% number of rise-times at fixed ISI sampled 
numCells = length(analysisCell);
trialVarRatio = NaN(numCells,1);
numSingleCellSamples = NaN(numCells,1);

for cIndex = 1 : numCells
    allRiseTimesForThisCell = analysisCell{cIndex}(:,2);
    RtimeFromLastSaccade = analysisCell{cIndex}(:,end) - abs(allRiseTimesForThisCell);
   
    numSingleCellSamples(cIndex) = sum(~isnan(allRiseTimesForThisCell));
    if numSingleCellSamples(cIndex) >= minNumSamples
        trialVarRatio(cIndex) = nanvar(RtimeFromLastSaccade)./nanvar(allRiseTimesForThisCell);
    end
end

ratioBins = binWidth:binWidth:20; 
histogram(trialVarRatio,ratioBins,'Normalization','probability');box off; xlabel(XLABEL);ylabel(YLABEL);setFontProperties(gca)
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
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\singleCellRiseTimeVarPrevUpcomRatio'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% 
totalNumCellsUsed = sum(~isnan(trialVarRatio));
varPercent = sum(trialVarRatio>1)/totalNumCellsUsed;
fprintf('%0.3f percent of cells had activity whose time of rise was more variable when measured relative to the previous saccade\n',varPercent)
%% Supp Fig Cap 4B
fprintf('\n\n Histogram across cells of the ratio of variances in time of rise (median ratio = %0.3f; n=%d cells)\n\n',nanmedian(trialVarRatio),totalNumCellsUsed)
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 4a.csv'],'a');
    fprintf(fileID,'Panel\nf\n');
    fprintf(fileID,',var previous/var upcoming\n');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 4a.csv'],trialVarRatio,'delimiter',',','-append','coffset',1);
    fclose(fileID);
end

