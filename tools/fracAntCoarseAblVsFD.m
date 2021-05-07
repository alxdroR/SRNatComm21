function data = fracAntCoarseAblVsFD(varargin)
%ccPvalueDistFracAntAblVsISIAksayBoot - compute multiple sets of change in
%fixation duration after coarse ablation, variable y in related methods
%section of the paper. Compute the correlation coefficient of the
%quantities plotted in Figure 7D.
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

options = struct('constantRadius',true,'radius',15,'cylLength',20,...
    'weightRCAxis',false,'nSampleMap',[],'useSCControls',false,...
    'sigLeft',[],'sigRight',[],'STACriteria',[],'Coordinates',[],...
    'minSacRatePerDirection',5);
options = parseNameValueoptions(options,varargin{:});

% this took over an hour to run. If possible load the saved results
% intstead of re-running
if isempty(options.sigLeft) || isempty(options.sigRight) || isempty(options.STACriteria)
    % loadNumAnimalsCut
    [finalActiveCellCriteria] = createFootprintSelector('cutCellsWLowSignal',true,'staDFFFilename','calcSTA2NMFOutput','lowSigPercentile',0.01);
    % loadSTAANOVACut
    STACriteria = createEyeMovementSelector('filename','calcSTA2NMFOutput','selectionCriteria',finalActiveCellCriteria);
    [sigLeft,sigRight] = createSRCellSelector('filename','calcAnticCorrAllCellsOutput','selectionCriteria',STACriteria);
else
    sigLeft = options.sigLeft;
    sigRight = options.sigRight;
    STACriteria = options.STACriteria;
end
if isempty(options.Coordinates)
    Coordinates = registeredCellLocationsBigWarp('register2Zbrain',false);
else
    Coordinates = options.Coordinates;
end

[fidArray2Use,expCond] = listAnimalsWithImaging('coarseAblationRegistered',true);
fidArray2Use = fidArray2Use(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
expCond = expCond(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
constantRadius = true;weightRCAxis=false;
fracAblatedPerAnimal = gatherFracAbl('constantRadius',constantRadius,'radius',15,'cylLength',20,'weightRCAxis',weightRCAxis,'sigLeft',sigLeft,'sigRight',sigRight,'STACriteria',STACriteria,'Coordinates',Coordinates,'fidArray2Use',fidArray2Use,'expCond',expCond);
behaviorStat = gatherAblationStatistics('maxRecordingTimeAfter',30,'minSacRatePerDirection',options.minSacRatePerDirection,'statistic','ISI');
minNumFixations = gatherAblStatsNumFixationStats(behaviorStat,fidArray2Use,'statistic','ISI');
data = struct('fracAblated',[],'changeFD',[],'animals',[],'conditions',[],'minNumFixations',[]);
data.animals = fidArray2Use(~isnan(minNumFixations));
data.conditions = expCond(~isnan(minNumFixations));
data.minNumFixations = minNumFixations;
data.fracAblated = fracAblatedPerAnimal;
% set random number generator
rng('default')
numRuns = 100;

% options for gatherFracAblAndBehEffect
effectMeasurement = 'fractional'; singleAnimalAnalysis=true;
% ----loop over numFix cutoffs (a second cut=off criteria)
minCutoffs = 25:10:300;
data.effectSize = cell(length(minCutoffs),1);
data.effectAnID = cell(length(minCutoffs),1);
data.medCCVsFAbl = cell(length(minCutoffs),1);
data.medCCVsFAblShuff = cell(length(minCutoffs),1);
medCC = NaN(length(minCutoffs),2);
numFish = NaN(length(minCutoffs),1);
numFixations =  NaN(length(minCutoffs),1);
count = 1;
for cutoff = minCutoffs
    minNumFixCut = minNumFixations;
    minNumFixCut(minNumFixations<cutoff)=NaN;
    numFish(count) = sum(~isnan(minNumFixCut));
    Nmin = min(minNumFixCut);
    numFixations(count) = Nmin;
    numResamples = round(minNumFixCut./Nmin);
    fracAblated = expandGFAbl2Resamples(fracAblatedPerAnimal,numResamples);
    [effectSize,anID] = extractEffectSizeFromBehaviorStat('statistic','ISI','aksayBootMethod',true,'numRuns',numRuns,'numResamples',numResamples,'Nmin',Nmin,...
        'behaviorStat',behaviorStat,'effectMeasurement',effectMeasurement,'singleAnimalAnalysis',singleAnimalAnalysis);
    data.effectSize{count} = effectSize;
    data.effectAnID{count} = anID;
    nsampTotal = size(effectSize,1);
    controlStats = zeros(numRuns,1);
    effectStats = zeros(numRuns,1);
    for j = 1 : numRuns
        cc = nancorr(fracAblated.Ant,effectSize(:,j));
        effectStats(j,:) = cc;
        
        ccControl = nancorr(randsample(fracAblated.Ant,nsampTotal),...
        randsample(effectSize(:,j),nsampTotal));
        controlStats(j) = ccControl;
    end
    data.medCCVsFAbl{count} = effectStats;
    data.medCCVsFAblShuff{count} = controlStats;    
    medCC(count,2) = median(controlStats);
    medCC(count,1) = median(effectStats);
    
    [~,p]=kstest2(controlStats,effectStats,'tail','larger');
    if p>0.01
        error('control not significant')
        fprintf('and differed significantly from randomly shuffled controls (p = %0.6f; one-sided two-sample KS Test\n)',p);
    end
    count = count+1;
end
data.NminFloorValues = minCutoffs;
data.Nmins = numFixations;
data.numFish = numFish;
figure;subplot(121)
plot(minCutoffs,medCC,'b:.');
subplot(122);
plot(numFish,medCC,'b:.')
xlabel('min num fixations');ylabel('median cc(frac ablated, effect size)')

fprintf('Mean (median CC across %d runs)=%0.3f using %d-%d min fixations (%d-%d animals)\n',numRuns,mean(medCC(4:16)),numFixations(16),numFixations(4),numFish(16),numFish(4))
fprintf('Mean (median CC across %d runs)=%0.3f using %d-%d min fixations (%d-%d animals)\n',numRuns,mean(medCC(9:16)),numFixations(16),numFixations(9),numFish(16),numFish(9))


