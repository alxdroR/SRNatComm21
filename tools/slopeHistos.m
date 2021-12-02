function slopeHistos(varargin)
% slopeHistos - histogram slope of SR dF/F activity before upcoming saccade (on directions)
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
global saveCSV

options = struct('AnticipatoryAnalysisMatrix',[],'analysisCell',[],'IDsFromCellsOfInterest',[],'XLIM',[],'xlabel',[],'binEdges',[],'SRMatrixIDs',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.AnticipatoryAnalysisMatrix) || isempty(options.analysisCell) || isempty(options.IDsFromCellsOfInterest)
    loadSRSlopes
else
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
    analysisCell = options.analysisCell;
    IDsFromCellsOfInterest = options.IDsFromCellsOfInterest;
    fixationIDs = options.SRMatrixIDs; 
end
% For the slopes to have any meaning the linear model must be valid. There
% are cases where this is not true
gof = AnticipatoryAnalysisMatrix(:,5);
gofCriteria = gof>=0.4;
slopes = AnticipatoryAnalysisMatrix(:,1); % slopes
Rtimes = AnticipatoryAnalysisMatrix(:,2); % rise-times
riseMeasured = ~isnan(Rtimes);

% count how many fish and cells end up passing
Ncells =length(analysisCell) ;
eventsIndexedByCell = [];
for i=1:Ncells
    nEventsPerCell = size(analysisCell{i},1);
    eventsIndexedByCell = [eventsIndexedByCell;ones(nEventsPerCell,1)*i];
end
eventsIndexedByCell = eventsIndexedByCell(gofCriteria & riseMeasured);
uniqueCellIndicesPassingCut = unique(eventsIndexedByCell);
numCellsUsed = length(uniqueCellIndicesPassingCut);
numFish = length(unique(IDsFromCellsOfInterest(uniqueCellIndicesPassingCut,1)));
nEvents = sum(riseMeasured & gofCriteria);


% format data to plot into a sharable format
data.slopes = slopes(riseMeasured & gofCriteria); % fixation durations x time until saccade
data.nEvents = nEvents;
data.numFish = numFish;
data.numCells = numCellsUsed;
data.numRiseDetected = sum(riseMeasured);

% plot
figure;
if isempty(options.binEdges)
    histogram(data.slopes,'Normalization','probability');
else
    histogram(data.slopes,options.binEdges,'Normalization','probability');
end
box off; xlabel(options.xlabel);ylabel('fraction of all fixations'); setFontProperties(gca)
if ~isempty(options.XLIM)
    xlim(options.XLIM);
end
set(gcf,'PaperPosition',[0 0 2.2 2.2])

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)


% print stats quoted in the paper
% main text
%percent_above_cutoff = length(data.slopes)/data.numRiseDetected;
%fprintf('\n\nlinear approximation reasonble for %0.3f percent of the fixations\n\n',percent_above_cutoff);

slope_quantiles = quantile(data.slopes,[0.01 0.99]);
mean_slope = mean(data.slopes);
fprintf('\n\n Across cells and fixations, the rate of rise\nvaried between %0.3f - %0.3f (dF/F)/s (1 and 99 percent quantiles, mean=%0.3f\n\n',slope_quantiles(1),slope_quantiles(2),mean_slope)

% figure Caption 5C
fprintf('\n\n Histogram of rates of pre-saccadic fluorescence increases \n fit (n= %d events from %d cells across %d fish).\n\n',data.nEvents,data.numCells,data.numFish)
[nc,nf,ne]=getSampleSizeFromSRMatrix(fixationIDs(riseMeasured & gofCriteria,:));
fprintf('%d fixations from %d cells examined over %d independent fish\n',ne,nc,nf)
if saveCSV
    fixationIDsUsed = fixationIDs(riseMeasured & gofCriteria,:);
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 5c.csv'],'a');
    fprintf(fileID,'Panel\nc\n');
    fprintf(fileID,',Animal ID,Imaging Plane ID,Within-Plane Cell ID,Fixation Sample Index,slope(arb. units)\n');
    dlmwrite([fileDirs.scDataCSV 'Figure 5c.csv'],[fixationIDsUsed (1:length(data.slopes))' data.slopes],'delimiter',',','-append','coffset',1);
    fclose(fileID);
end