function riseTimeHistos(varargin)
% riseTimeHistos - histogram times when SR activity increases relative to
% upcoming saccade
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

options = struct('AnticipatoryAnalysisMatrix',[],'analysisCell',[],'IDsFromCellsOfInterest',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.AnticipatoryAnalysisMatrix) || isempty(options.analysisCell) || isempty(options.IDsFromCellsOfInterest)
   loadSRSlopes
else
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
    analysisCell = options.analysisCell;
    IDsFromCellsOfInterest = options.IDsFromCellsOfInterest;
end
Rtimes = AnticipatoryAnalysisMatrix(:,2); % rise-times 

% count how many fish and cells end up passing 
%Ncells =length(analysisCell) ;
%eventsIndexedByCell = [];
%for i=1:Ncells
%    nEventsPerCell = size(analysisCell{i},1);
%    eventsIndexedByCell = [eventsIndexedByCell;ones(nEventsPerCell,1)*i];
%end
%eventsIndexedByCell = eventsIndexedByCell(~isnan(Rtimes));
%uniqueCellIndicesPassingCut = unique(eventsIndexedByCell);
%numCellsUsed = length(uniqueCellIndicesPassingCut);
%numFish = length(unique(IDsFromCellsOfInterest(uniqueCellIndicesPassingCut,1)));
%nEvents = sum(~isnan(Rtimes));
[numCellsUsed,numFish]=getSampleSizeFromSRMatrix(analysisCell,IDsFromCellsOfInterest,Rtimes);

% format data to plot into a sharable format
data.riseUS = Rtimes(~isnan(Rtimes));
data.numFish = numFish;
data.numCells = numCellsUsed;

% plot
figure; 
histogram(data.riseUS,-30.5:0.5:0,'Normalization','probability');box off; xlabel({'activity rise-time' 'relative to upcoming saccade (s)'});ylabel('fraction of all fixations'); setFontProperties(gca)
xlim([-30 0]);ylim([0 0.08])
set(gcf,'PaperPosition',[1 1 2.2 2.2])

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

% print stats quoted in the paper
Rtime_quantiles = -quantile(data.riseUS,[0.1 0.5 0.9]);
fprintf('\n\n Across cells and fixations, activity rose over a range of times\nbetween %0.2f and %0.2f seconds relative to the\n upcoming saccade (10 and 90 quantiles; median time = %0.3f seconds) \n\n',Rtime_quantiles(1),Rtime_quantiles(3),Rtime_quantiles(2))

nevents = sum(~isnan(data.riseUS));
fprintf('\n\n (n=%d fixations from %d cells from %d fish) \n\n',nevents,data.numCells,data.numFish)

