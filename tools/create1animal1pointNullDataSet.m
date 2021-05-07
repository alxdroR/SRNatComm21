function [durations,varargout]=create1animal1pointNullDataSet(varargin)
options = struct('K',10,...
    'summaryStat',@nanmedian,'computeChangeStat',true,'changeType','percent');
options = parseNameValueoptions(options,varargin{:});

% eye traces from ablation only experiments (some of these also had imaging) 
[fidArray2Use,expCond,expInd0] = listAnimalsWithImaging('coarseAblationRegistered',true);
fidArray2Use = fidArray2Use(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
expInd0 = expInd0(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
expCond = expCond(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
expName0 = fidArray2Use;
expCond0 = repmat({'B'},1,length(expName0));
% [caudalAblation,otherAblations,controls]=ablationDataFiles;
% fidArray2Use = [otherAblations(1:end-1) caudalAblation controls];
% missingData = [3;5;9;14;15;(21:24)']; % for some reason these indices have not been processed.
% fidArray2Use = fidArray2Use(setdiff(1:length(fidArray2Use),missingData));
% [fid,symAblation]=ablDamSymTemp;
% symNotOutlier = cellfun(@(x) checkSymOutlierConditions(x,[],fid,symAblation),fidArray2Use);
% expName0 = fidArray2Use(symNotOutlier);
% expCond0 = repmat({'B'},1,length(expName0));

% eye traces from experiments with imaging (only use the animals not
% inlcuded in the above data set)
[expName1,expCond1] = listAnimalsWithImaging('singleCellAblations',false);
expInd1 = (1:20)';
animalsWImagingOnly = cellfun(@isempty,expCond1);
expName1 = expName1(animalsWImagingOnly); expCond1 = expCond1(animalsWImagingOnly);
expInd1 = expInd1(animalsWImagingOnly);

% single cell ablation data
[expName2,expCond2] = listAnimalsWithImaging('singleCellAblations',true);
expInd2 = (1:length(expName2))' + max(expInd0);
expName = [expName0 expName1 expName2];
expCond = [expCond0 expCond1 expCond2];
expInd = [expInd0 ;expInd1; expInd2];
numAnimals = length(expName);
durations = struct('dLStat',[],'dRStat',[],'dBothStat',[]);
durations.dLStat = NaN(numAnimals,1);
durations.dRStat = NaN(numAnimals,1);
% determine which animals have the most fixations 
numFixations = struct('L',[],'R',[],'both',[]);
for i=1:numAnimals
    %fileInfo = struct('expDates',[],'animalNumbers',[]);
    %fileInfo.expDates = expDates(i);
   % fileInfo.animalNumbers = animalNumbers(i);
    
    [dL,dR] = computeSaveWithinPlaneDurations(expName{i},expCond{i});
    %[dL,dR]=loadDataForComputingNull(fileInfo);
    diffStatL =computeChangeStat(dL,options.K);
     diffStatR =computeChangeStat(dR,options.K);
    diffStatBoth =computeChangeStat([dL;dR],options.K);
    durations.dLStat(i) = diffStatL;
    durations.dRStat(i) = diffStatR;
    durations.dBothStat(i) = diffStatBoth;
    numFixations.L = [numFixations.L;length(dL)];
    numFixations.R = [numFixations.R;length(dR)];
    numFixations.both = [numFixations.both;length([dL;dR])];
end
% select 10 that have the most fixations (so that random sampling yields
% the greatest diversity)
%[nfsorted,nfind] = sort(numFixations.both,'descend');
%durations.dBothStat(nfind(1:10));
varargout{1} = numFixations;
varargout{2} = expName;
varargout{3} = expInd;
end
function diffStat =computeChangeStat(duration,K)
if length(duration)>(K)
    sample1 = randsample(duration,K);
    sample2 = randsample(duration,K);
   % sample1 = duration(1:K);
   % sample2 = duration(K+1:2*K);
    medAfter= nanmedian(sample1);
    medBefore = nanmedian(sample2);
    afterMinusBefore = medBefore - medAfter;
    diffStat = 100*afterMinusBefore./medBefore;
else
    diffStat = NaN;
end
end

