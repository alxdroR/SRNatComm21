function [numCells,numFish,numEvents,numCellPerDur,numFishPerDur,numEventsPerDur] = getSampleSizeFromLoadSingleTrialResponses(animalOut)
mixedMatrix = cell2mat(animalOut);
[numCells,numFish,numEvents] = IDMatrix2Samps(mixedMatrix);

numCellPerDur = zeros(length(animalOut),1,'uint32');
numFishPerDur = zeros(length(animalOut),1,'uint32');
numEventsPerDur = zeros(length(animalOut),1,'uint32');
for fdIndex = 1 : length(animalOut)
     [numCellPerDur(fdIndex),numFishPerDur(fdIndex),numEventsPerDur(fdIndex)] = IDMatrix2Samps(animalOut{fdIndex});
end
end

function [numCells,numFish,numEvents] = IDMatrix2Samps(A)
% A(:,1) fid 
% A(:,2) planes
% A(:,3) cells
% A(:,4) fixation or trial
fidUnique = unique(A(:,1));
numFish = length(fidUnique);
numCells = 0;
numEvents = size(A,1);
for index1 = 1 : numFish
    expIndex = fidUnique(index1);
    inThisAni = A(:,1)==expIndex;
    uniquePlanesInF = unique(A(inThisAni,2));
    for index2 = 1 : length(uniquePlanesInF)
        planeIndex = uniquePlanesInF(index2);
        inThisPlane = A(:,1)==expIndex & A(:,2) == planeIndex;
        numCells = numCells + length(unique(A(inThisPlane,3)));
    end
end

end
