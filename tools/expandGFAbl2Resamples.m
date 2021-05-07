function fracAblatedExpanded = expandGFAbl2Resamples(fracAblated,numResamplesV)
expandedN=nansum(numResamplesV);
fracAblatedExpanded = struct('Ant',zeros(expandedN,1),'nonAnt',zeros(expandedN,1),'rccenter',zeros(expandedN,1),'expIndex',zeros(expandedN,1));
nAnimal = length(fracAblated.Ant);
for expInd = 1 : nAnimal
    if ~isnan(numResamplesV(expInd))
        indices = (1:numResamplesV(expInd)) + nansum(numResamplesV(1:expInd-1));
        fracAblatedExpanded.Ant(indices) = fracAblated.Ant(expInd);
        fracAblatedExpanded.nonAnt(indices) = fracAblated.nonAnt(expInd);
        fracAblatedExpanded.rccenter(indices) = fracAblated.rccenter(expInd);
        fracAblatedExpanded.expIndex(indices) = expInd;
    end
end
end

