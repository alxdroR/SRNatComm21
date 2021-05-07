function [effectSize,varargout] = extractEffectSizeFromBehaviorStat(varargin)
options = struct('maxRecordingTimeAfter',30,'minSacRatePerDirection',5,...
    'statistic','ISI','goodnessOFitCut',0.2,'gofMeasure','r2',...
    'effectMeasurement','difference','singleAnimalAnalysis',true,...
    'aksayBootMethod',false,'numRuns',100,'nonAnt','all',...
    'behaviorStat',[],'fidArray2Use',[],...
    'Nmin',[],'numResamples',[]);
options = parseNameValueoptions(options,varargin{:});
%----------- load population-related data and statistics
% animals with ablations
if isempty(options.fidArray2Use)
    [fidArray2Use,expCond,anmID] = listAnimalsWithImaging('coarseAblationRegistered',true);
    fidArray2Use = fidArray2Use(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
    anmID = anmID(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
else
    fidArray2Use = options.fidArray2Use;
end
nAll = length(fidArray2Use); % all the animals we will check
if isempty(options.behaviorStat)
    % all useable behavior stats; useable means gatherAblationStatatistics performs
    % cuts for symmetric ablations, etc.
    behaviorStat = gatherAblationStatistics('maxRecordingTimeAfter',options.maxRecordingTimeAfter,'minSacRatePerDirection',options.minSacRatePerDirection,...
        'statistic',options.statistic,...
        'goodnessOFitCut',options.goodnessOFitCut,'gofMeasure',options.gofMeasure);
else
    behaviorStat = options.behaviorStat;
end

if options.aksayBootMethod
    if isempty(options.numResamples) || isempty(options.Nmin)
        minNumFixations = gatherAblStatsNumFixationStats(behaviorStat,fidArray2Use,'statistic',options.statistic);
        Nmin = min(minNumFixations);
        numResamplesV = round(minNumFixations./Nmin);
    else
        Nmin = options.Nmin;
        numResamplesV = options.numResamples;
    end
end

if ~strcmp(options.nonAnt,'all')
    % determine position and burst cells used on arxiv paper
    script2RunPCAOnSTA;
    N = size(STACAT,1)/2;
    lonL = lon(1:N); lonR = lon(N+1:2*N);
    selectLON = lonL>lonR;
    selectRON = lonR>lonL;
    
    % convert values of longitude so that 100% contribution from PC 1 is centered at 0 degrees and anti-PC 1 is at -180
    lonL(lonL> 180 & lonL<=450) = lonL(lonL>180 & lonL<=450)-360;
    lonR(lonR> 180 & lonR<=450) = lonR(lonR>180 & lonR<=450)-360;
    
    % cuts defining 4 regions (2 x position, non-position)
    activityZones = false(size(ID,1),4);
    %activityZonesSub = [(lonL>=-90+270 & lonL<=30+270),(lonR>=-90+270 & lonR<=30+270),(lonL>=30+270 & lonL<=100+270),(lonR>=30+270 & lonR<=100+270)];
    cutTonMin = -75-15/2; cutTonicMax = -30+15/2; cutBurstMin=45-15/2;cutBurstMax = 60+15/2;
    activityZonesSub = [(lonL>=cutTonMin & lonL<=cutTonicMax) & selectLON,(lonR>=cutTonMin & lonR<=cutTonicMax) & selectRON,(lonL>=cutBurstMin & lonL<=cutBurstMax) & selectLON,(lonR>=cutBurstMin & lonR<=cutBurstMax) & selectRON];
    
    % note that I haven't re-run the map with updated values since sending
    % to ashwin 8/25/2019
    activityZones(STACriteria,:)=activityZonesSub;
    
    if strcmp(options.nonAnt,'pos')
        % position cells
        nonAnticLabel =  STACriteria & ~sigLeft & ~sigRight & (activityZones(:,1) | activityZones(:,2));
    elseif strcmp(options.nonAnt,'burst')
        % burst cells
        nonAnticLabel =  STACriteria & ~sigLeft & ~sigRight & (activityZones(:,3) | activityZones(:,4));
    end
end
if options.singleAnimalAnalysis
    if options.aksayBootMethod
        effectSize = NaN(nansum(numResamplesV),options.numRuns);
        effectSizeAID = NaN(nansum(numResamplesV),1);
    else
        effectSize = NaN(nAll,1);
    end
else
    effectSize = cell(nAll,1);
    ablStats = struct('fracAblated',struct('Ant',nan(nAll,1),'nonAnt',nan(nAll,1)),'rccenter',nan(nAll,1),...
        'radius',nan(nAll,1),'animalName',[]);
    ablStats.animalName=cell(nAll,1);
end
for expIndex = 1  : nAll
    if options.aksayBootMethod
        if ~isnan(numResamplesV(expIndex))
            if strcmp(options.statistic,'ISI')
                [ISIBeforeSinglAnimal,ISIAfterSinglAnimal] = gASPullSingleAnimal(behaviorStat,fidArray2Use{expIndex});
                numBefore = sum(~isnan(ISIBeforeSinglAnimal));
                numAfter = sum(~isnan(ISIAfterSinglAnimal));
                GASFunctionDidNotCut = min(numBefore,numAfter)>0;
            elseif strcmp(options.statistic,'fixationTimeConstant')
                [~,~,itauBefore,itauAfter,itauAGBefore,itauAGAfter] = gASCombineStats(behaviorStat,'ablationCondition','before and after');
                squaredErrorBefore = [behaviorStat.leftEye.before.other;behaviorStat.rightEye.before.other];
                goodFits = squaredErrorBefore<=0.1;
                ISIBeforeSinglAnimal = itauBefore(goodFits);
                ISIAfterSinglAnimal = itauAfter;
                GASFunctionDidNotCut = ~isempty(ISIAfterSinglAnimal) && ~isempty(ISIBeforeSinglAnimal);
            end
        else
            GASFunctionDidNotCut = false;
        end
    else
        if strcmp(options.statistic,'ISI')
            [ISIBeforeSinglAnimal,ISIAfterSinglAnimal] = gASPullSingleAnimal(behaviorStat,fidArray2Use{expIndex});
            numBefore = sum(~isnan(ISIBeforeSinglAnimal));
            numAfter = sum(~isnan(ISIAfterSinglAnimal));
            GASFunctionDidNotCut = min(numBefore,numAfter)>0;
        elseif strcmp(options.statistic,'fixationTimeConstant')
            [~,~,itauBefore,itauAfter,itauAGBefore,itauAGAfter] = gASCombineStats(behaviorStat,'ablationCondition','before and after');
            squaredErrorBefore = [behaviorStat.leftEye.before.other;behaviorStat.rightEye.before.other];
            goodFits = squaredErrorBefore<=0.1;
            ISIBeforeSinglAnimal = itauBefore(goodFits);
            ISIAfterSinglAnimal = itauAfter;
            GASFunctionDidNotCut = ~isempty(ISIAfterSinglAnimal) && ~isempty(ISIBeforeSinglAnimal);
        end
    end
    if GASFunctionDidNotCut
        if options.singleAnimalAnalysis
            if ~options.aksayBootMethod
                
                % Compute Single-Animal Behavioral Effect
                switch options.effectMeasurement
                    case 'difference'
                        effectSize(expIndex) = ( nanmedian(ISIAfterSinglAnimal)-nanmedian(ISIBeforeSinglAnimal));
                    case 'fractional'
                        effectSize(expIndex) = ( nanmedian(ISIAfterSinglAnimal)-nanmedian(ISIBeforeSinglAnimal))./nanmedian(ISIBeforeSinglAnimal);
                end
            else
                if ~isnan(numResamplesV(expIndex))
                    for k = 1 : options.numRuns
                        for sampleIndex = 1 : numResamplesV(expIndex)
                            indices = sampleIndex + nansum(numResamplesV(1:expIndex-1));
                            effectSizeAID(indices) = anmID(expIndex);
                            beforeSampleSubset = randsample(ISIBeforeSinglAnimal,Nmin);
                            afterSampleSubset = randsample(ISIAfterSinglAnimal,Nmin);
                            switch options.effectMeasurement
                                case 'difference'
                                    effectSize(indices,k) = ( nanmedian(afterSampleSubset)-nanmedian(beforeSampleSubset));
                                case 'fractional'
                                    effectSize(indices,k) = ( nanmedian(afterSampleSubset)-nanmedian(beforeSampleSubset))./nanmedian(beforeSampleSubset);
                            end
                        end
                    end
                end
            end
        end
    else
        fprintf('GASFunction cut %s\n',fidArray2Use{expIndex});
    end
end
if ~options.singleAnimalAnalysis
    error('gatherFracBinningAblBehEffectFishCombo should no longer be run within this function');
    [fracAblated,effectSize,effectSamples] = gatherFracBinningAblBehEffectFishCombo(ablStats,behaviorStat,'effectMeasurement',options.effectMeasurement,'demoMethod',options.demoMethod);
end
varargout{1} = effectSizeAID;
end

