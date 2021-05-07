function [fracAblated,effectSize,effectSamples] = gatherFracBinningAblBehEffectFishCombo(ablStats,behaviorStat,varargin)
options = struct('effectMeasurement','difference','demoMethod',false);
options = parseNameValueoptions(options,varargin{:});


binSize = nanmedian(ablStats.radius);
%binCenters = min(ablStats.rccenter):ceil(binSize/5):max(ablStats.rccenter);
binCenters = min(ablStats.rccenter):binSize:max(ablStats.rccenter); binEdges = [binCenters - binSize/2, binCenters(end)+binSize/2];
%binEdges = [300 361 400 490 571 655 740 865 950 1033 1080];binCenters = binEdges(1:end-1)+diff(binEdges)/2;
effectSize = nan(length(binCenters),1);
effectSamples = cell(length(binCenters),1);
fracAblated = struct('Ant',nan(length(binCenters),1),'nonAnt',nan(length(binCenters),1));
for binningIndex = 1 : length(binCenters)
    animalsInBin = find(ablStats.rccenter>=binEdges(binningIndex) & ablStats.rccenter <= binEdges(binningIndex+1));
    
    fracAblated.Ant(binningIndex) = nanmean(ablStats.fracAblated.Ant(animalsInBin));
    fracAblated.nonAnt(binningIndex) = nanmean(ablStats.fracAblated.nonAnt(animalsInBin));
    
    ISIBefore=[];ISIAfter=[];effect = 0;
    for an2CombineIndex = animalsInBin'
        [ISIBeforeSinglAnimal,ISIAfterSinglAnimal] = gASPullSingleAnimal(behaviorStat,ablStats.animalName{an2CombineIndex});
        ISIBefore = [ISIBefore;ISIBeforeSinglAnimal];
        ISIAfter = [ISIAfter;ISIAfterSinglAnimal];
        switch options.effectMeasurement
            case 'difference'
                effect = ( nanmedian(ISIAfterSinglAnimal)-nanmedian(ISIBeforeSinglAnimal));
            case 'fractional'
                effect = ( nanmedian(ISIAfterSinglAnimal)-nanmedian(ISIBeforeSinglAnimal))./nanmedian(ISIBeforeSinglAnimal);
        end
        
        effectSamples{binningIndex} = [effectSamples{binningIndex};effect];
    end
    effectSize(binningIndex) = nanmean(effectSamples{binningIndex});
    if length(animalsInBin)>1
        if nanstd(ablStats.fracAblated.Ant(animalsInBin)) > 0.1
            %  keyboard
        end
    end
    
    
    if options.demoMethod
        subplot(222);
        
        % show the bins
        plot([1 1]*binEdges(binningIndex),[0 0.15],'k--');
        plot([1 1]*binEdges(binningIndex+1),[0 0.15],'k--')
        
        % show the average fraction ablated
        plot(binCenters(binningIndex),fracAblated.Ant(binningIndex),'ko');
        plot(binCenters(binningIndex),fracAblated.nonAnt(binningIndex),'o','Color',[0.85 0.325 0.098]);
        text(binCenters(binningIndex),0.13,num2str(length(animalsInBin)),'color','r');
        
        
        % show the average fraction ablated vs effect
        subplot(224);
        plot(binCenters(binningIndex),100*effectSize(binningIndex),'b.'); hold on;
    end
end
end

