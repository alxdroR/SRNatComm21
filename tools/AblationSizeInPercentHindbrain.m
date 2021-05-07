function AblationSizeInPercentHindbrain()
cellNucRadius = 5/2; % microns 
cellNucVolume = (4/3)*pi*cellNucRadius^3;

ablationRadius = 30/2;
ablationLength = 60; 
ablationVolume = pi*ablationLength*ablationRadius^2;
biLateralAblationVolume = 2*ablationVolume;

numCellsInVolume = biLateralAblationVolume/cellNucVolume;

numCellsHindbrain = 40000;
fractionOfHindbrain = numCellsInVolume/numCellsHindbrain;

fprintf('\napproximately %d cells or %0.3f percent of the hindbrain, ablated per experiment\n',numCellsInVolume,fractionOfHindbrain);

