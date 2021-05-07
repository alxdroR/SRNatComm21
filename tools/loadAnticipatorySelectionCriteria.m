% loadAnticipatorySelectionCriteria - Construct a Boolean Variable over All NMF footprints
% that states whether or not the eye-movement responsive cells are SR cells 
% 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 
loadSTAANOVACut;
[sigLeft,sigRight,Hcc,uniqueIDsFromCOI,anticCC] = createSRCellSelector('filename','calcAnticCorrAllCellsOutput','selectionCriteria',STACriteria);
ID = getIDFullDataSet('NMF');
IDsFromCellsOfInterest = ID(uniqueIDsFromCOI,:);

