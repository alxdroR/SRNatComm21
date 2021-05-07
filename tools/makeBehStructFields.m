function behaviorStructure = makeBehStructFields(N,statisticName)

behaviorStructure = struct(statisticName,NaN(N,1),...
    'animalName',NaN(N,1),'animalIndex',NaN(N,2),'ablationLocation',NaN(N,1),'ablationGroup',NaN(N,1),'other',NaN(N,1));

behaviorStructure.animalName = cell(N,1);
behaviorStructure.ablationGroup = cell(N,1);


end

