function SRPercent(varargin)
% SRPercent
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

options = struct('STACriteria',[],'Hcc',[],'AnticipatoryAnalysisMatrix',[],'analysisCell',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.STACriteria) || isempty(options.Hcc) || isempty(options.AnticipatoryAnalysisMatrix) || isempty(options.analysisCell)
    loadSRSlopes
else
    STACriteria = options.STACriteria;
    Hcc = options.Hcc;
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
    analysisCell = options.analysisCell;
end

% determine how many cell's passed the CC test
numberPassingCC = sum(Hcc(:,1) | Hcc(:,2));

% determine the subset of these that are not direction selective 
numNonDSSelective = sum(Hcc(:,1) & Hcc(:,2));

% determine how many DS cell's are
% usable in that at least 1 time of rise was detected
NDSCells =length(analysisCell);
eventsIndexedByCell = [];
for i=1:NDSCells
    nEventsPerCell = size(analysisCell{i},1);
    eventsIndexedByCell = [eventsIndexedByCell;ones(nEventsPerCell,1)*i];
end
Rtimes = AnticipatoryAnalysisMatrix(:,2);
eventsIndexedByCell = eventsIndexedByCell(~isnan(Rtimes));
uniqueCellIndicesPassingCut = unique(eventsIndexedByCell);
numUsableDSCells = length(uniqueCellIndicesPassingCut);


numberEyeRelated = sum(STACriteria);
numberAnticipatory = numUsableDSCells + numNonDSSelective;
percentAntic = 100*numberAnticipatory/numberEyeRelated;
fprintf('\n\nWe found that %0.3f percent (n=%d) of eye-movement related\n hindbrain neurons had fluorescent activity ...\n',round(percentAntic),numberAnticipatory);
fprintf('(we are reporting the number of cells with at least 1 time of rise + the number of non-direction selective  cells\ntotal number of cells passing the CC test is %d\n',numberPassingCC)