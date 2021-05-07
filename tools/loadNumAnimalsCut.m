% loadNumAnimalsCut - Construct a Boolean Variable over All NMF footprints
% that states whether or not the cell is registered to a region sampled by
% 3 or more fish 
% 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 

[~,smallDataPath] = rootDirectories;
if 0 
    % old old method that relies on previous version of registration contorl
    % points
%nSampleMap = regionsSampled;
load([smallDataPath 'regionsSampledMarch232018'],'nSampleMap');
numAnimalsCutOff = 3;

% label which cells were in locations sampled in less than 3 animals
Coordinates = registeredCellLocations('EPSelectedCells',true);
numFishCriteria = minNumSampleCut(nSampleMap,Coordinates,numAnimalsCutOff);
end
[numFishCriteria,inMB,Coordinates] =createFootprintSelector('cutCellsWLowSignal',true,'staDFFFilename','calcSTA2NMFOutput','lowSigPercentile',0.01);
