function Y = initializePlotModelFitsCells(IDsFromCellsOfInterest)


uniqueAnimals = unique(IDsFromCellsOfInterest(:,1));
Y = cell(length(uniqueAnimals),1);

for index1 = 1:length(uniqueAnimals(:))
    expIndex = uniqueAnimals(index1);
    animalBoolSelectionVector = IDsFromCellsOfInterest(:,1)==expIndex;
    uniquePlanes = unique( IDsFromCellsOfInterest(animalBoolSelectionVector,2) );
    Y{index1} = cell(length(uniquePlanes),1);
end


end

