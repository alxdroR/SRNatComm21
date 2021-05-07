function [ID,numCellsV,numPlanesV] = getIDFullDataSet(cellFinderMethod,varargin)
% getIDFullDataSet(cellFinderMethod) - construct full IDs for all cells in
% the 20 animal imaging/eye-behavior data set
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

[numCellsV,numPlanesV] = totalNumberCells(cellFinderMethod,varargin{:});
fid=listAnimalsWithImaging(varargin{:});
totalNumCells = sum(numCellsV);
ID = zeros(totalNumCells,3); % Not concatenating is 16*18 times faster
for expIndex = 1 : length(fid)
    for planeIndex = 1 : numPlanesV(expIndex) 
        if expIndex > 1
            numCells = numCellsV(sum(numPlanesV(1:expIndex-1))+planeIndex);
        else
            numCells = numCellsV(planeIndex);
        end
        numCellIndex = planeIndex + sum(numPlanesV(1:expIndex-1));
        allCellIndex = (1: numCellsV(numCellIndex)) + sum(numCellsV(1:numCellIndex-1));
        ID(allCellIndex,:) = [ ones(numCells,1)*[expIndex planeIndex] (1:numCells)'];
     end
 end

end

