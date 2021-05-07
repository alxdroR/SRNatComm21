% loadSTAANOVACut - Construct a Boolean Variable over All NMF footprints
% that states whether or not the cell is registered to a region sampled by
% 3 or more fish AND is eye-movement responsive
% 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 
loadNumAnimalsCut; 
[STACriteria,STA,bt,anovaPvals,nTrialsL,nTrialsR,STCIL,STCIU,STS,pSign,numCompPsign,alphaSTA,anovaPKeep] = createEyeMovementSelector('selectionCriteria',numFishCriteria);


