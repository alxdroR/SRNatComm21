function [numFish,numFixations] = numberAnimalsEachGroup(behStructure)

groupNames = unique(behStructure.ablationGroup);

% in assigning groupNames(i) with a name, I assume that the names are 
% rxi1-xi2, with rostral numbers xi1 less than say middle numbers xj1 and then s.c. for spinal cord. 
% The code produces inaccurate results if this is the case. 
rostralBool = cellfun(@(z) strcmp(z,groupNames(1)),behStructure.ablationGroup);
middleBool = cellfun(@(z) strcmp(z,groupNames(2)),behStructure.ablationGroup);
caudalBool = cellfun(@(z) strcmp(z,groupNames(3)),behStructure.ablationGroup);
SCBool = cellfun(@(z) strcmp(z,groupNames(4)),behStructure.ablationGroup);

passingEyeconditions = ~isnan(behStructure.fixationTimeConstant);

numFish = [length(unique(behStructure.animalName(rostralBool & passingEyeconditions))); ...
    length(unique(behStructure.animalName(middleBool & passingEyeconditions))); ...
    length(unique(behStructure.animalName(caudalBool & passingEyeconditions))); ...
    length(unique(behStructure.animalName(SCBool & passingEyeconditions)))];
numFixations = [sum(rostralBool & passingEyeconditions) sum(middleBool & passingEyeconditions) sum(caudalBool & passingEyeconditions) sum(SCBool & passingEyeconditions)];
end

