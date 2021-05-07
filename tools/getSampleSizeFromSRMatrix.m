function [numCells,numFish,nEvents] = getSampleSizeFromSRMatrix(calcSlope3Output,varargin)
if iscell(calcSlope3Output)
    if nargin < 3
        error('when suing analyisCell with getSampleSizeFromSRMatrix, one must also enter a matrix of cells IDs and a vector listing non-passing events as NaN');
    else
        IDsFromCellsOfInterest = varargin{1};
        statOfInterest = varargin{2};
    end
    Ncells =length(calcSlope3Output) ;
    % convert the cell to a matrix, eventsIndexedByCell, that contains cell
    % id information
    eventsIndexedByCell = [];
    for i=1:Ncells
        nEventsPerCell = size(calcSlope3Output{i},1);
        eventsIndexedByCell = [eventsIndexedByCell;ones(nEventsPerCell,1)*i];
    end
    nEvents = sum(~isnan(statOfInterest));
    eventsIndexedByCell = eventsIndexedByCell(~isnan(statOfInterest));
    uniqueCellIndicesPassingCut = unique(eventsIndexedByCell);
    numCells = length(uniqueCellIndicesPassingCut);
    numFish = length(unique(IDsFromCellsOfInterest(uniqueCellIndicesPassingCut,1)));
elseif isnumeric(calcSlope3Output)
    if size(calcSlope3Output,2)==3
        % in this case, we assume the user has already cut out events of
        % interest 
        nEvents = size(calcSlope3Output,1);
        fishExpIndex = unique(calcSlope3Output(:,1));
        numFish = length(fishExpIndex);
        % calc number of cells 
        numCells = 0; 
        for fishIndex = 1 : numFish
            expIndex = fishExpIndex(fishIndex);
            matchingEvents = calcSlope3Output(:,1) == expIndex;
            planeIndicesInThisFish = unique(calcSlope3Output(matchingEvents,2));
            for planeIndex = 1 : length(planeIndicesInThisFish)
                matchingEvents = calcSlope3Output(:,1) == expIndex & calcSlope3Output(:,2)==planeIndicesInThisFish(planeIndex);
                numCells = numCells + length(unique(calcSlope3Output(matchingEvents,3)));
            end
        end
    else
        error('getSampleSizeFromSRMatrix requires either the analysisCell variable or the animalNames variable');
    end
end

