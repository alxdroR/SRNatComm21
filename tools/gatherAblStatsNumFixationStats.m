function minNumFixations = gatherAblStatsNumFixationStats(behaviorStat,fidArray2Use,varargin)
%gatherAblStatsNumFixationStats - after running  gatherAblationStatistics
%use this function to determine the minimum number of fixations for each
%animal and the minimum across all animals 
options = struct('statistic','ISI');
options = parseNameValueoptions(options,varargin{:});

nAll = length(fidArray2Use); % all the animals we will check
minNumFixations = NaN(nAll,1);
for expIndex = 1  : nAll
    if strcmp(options.statistic,'ISI')
        [ISIBeforeSinglAnimal,ISIAfterSinglAnimal] = gASPullSingleAnimal(behaviorStat,fidArray2Use{expIndex});
    elseif strcmp(options.statistic,'fixationTimeConstant')
        [~,~,itauBefore,itauAfter,itauAGBefore,itauAGAfter] = gASCombineStats(behaviorStat,'ablationCondition','before and after');
        squaredErrorBefore = [behaviorStat.leftEye.before.other;behaviorStat.rightEye.before.other];
        goodFits = squaredErrorBefore<=0.1;
        ISIBeforeSinglAnimal = itauBefore(goodFits);
        ISIAfterSinglAnimal = itauAfter;
    end
    GASFunctionDidNotCut = ~isempty(ISIAfterSinglAnimal) && ~isempty(ISIBeforeSinglAnimal);
    
    if GASFunctionDidNotCut
        numBefore = sum(~isnan(ISIBeforeSinglAnimal));
        numAfter = sum(~isnan(ISIAfterSinglAnimal));
        minNumFixations(expIndex) = min(numBefore,numAfter);
        if minNumFixations(expIndex)==0
            minNumFixations(expIndex) = NaN;
        end
    end
end
end

