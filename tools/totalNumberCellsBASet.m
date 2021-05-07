function [numCells,numPlanesV,ID] = totalNumberCellsBASet(expcond)
%numCells = totalNumberCells returns total number of
%cells in each plane in the entire data set
%   
%
% OUTPUT
% numCells - Np x1 vector. Np is the total number of planes in the data
%           set. Np(i) gives the number of cells found in plane i. 
%           The ordering of planes is based on the order of animals in 
%           listAnimalsWithImaging and on the ordering of planes used when 
%           analyzing movies (see rawData class).
%
% numPlanesV - 20 x 1 vector giving number of planes per animal
%fid=listAnimalsWithImaging;
fid = {'H','X','K','C','D','E'};

numCells = [];
numPlanesV = [];
ID = []; 
for expIndex = 1 : length(fid)
    caFileName = getFilenames(fid{expIndex},'expcond',expcond,'fileType','catraces');
    caFileNameBAR = [caFileName 'BARedux'];
    load(caFileNameBAR)    
    if strcmp(expcond,'before')
        F = yB;
    elseif strcmp(expcond,'after')
        F = yA;
    end
    
    numPlanes = length(F);
    numPlanesV = [numPlanesV;numPlanes];
    for planeIndex = 1 : numPlanes
        numCellsInPlane = size(F{planeIndex},2);
        numCells = [numCells;numCellsInPlane];
        for cellIndex = 1 : numCellsInPlane
            ID = [ID; [expIndex planeIndex cellIndex] ];
        end
    end
end


end

