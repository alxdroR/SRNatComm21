function varargout = predictSaccadesWMean(varargin)
% predictSaccadesWMean
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202x

options = struct('durations',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.durations)   
    % marginal distributions of ISI
    [durations,id]=jointISIDistributionPopAggregatev2;
    varargout{1} = durations;
    varargout{2} = id;
else
    durations = options.durations;
end
%%
samplesBoth = [durations.left;durations.right];
N = sum(~isnan(samplesBoth));

%% The above only uses predictions that are 'accurate' (absolute error < marginOfError*fixation Duration). Now calculate correlation of predictions and error without this
rng('default')
STEstimateV = [];
STV = [];
STEM = [];
numBoots = 1000;
trainSetFraction = 0.5;
Ntrain = round(trainSetFraction*N);
Ntest = N - Ntrain;

for i=1:numBoots
    trainSetIndices = randperm(N,Ntrain);
    testSetIndices = setdiff(1:N,trainSetIndices);
   % saccadeTimePrediction = mean(samplesBoth(trainSetIndices));
   % saccadeTimePrediction = median(samplesBoth(trainSetIndices));
     saccadeTimePrediction = mode(samplesBoth(trainSetIndices));
   
    actualTimes = samplesBoth(testSetIndices);
    STEstimateV = [STEstimateV; repmat(saccadeTimePrediction,length(actualTimes),1)];
    STV = [STV; actualTimes];
    STEM = [STEM;abs(actualTimes - saccadeTimePrediction)./actualTimes];
end
%%
[cc,pval] = corr(STEstimateV,STV);
fprintf('The correlation between all predictions and actual data is %0.4f\n (p=%0.5f)\n',cc,pval)

nsamp = sum(~isnan(STEM));
steSTEM = nanstd(STEM)./sqrt(nsamp); steSTEM(nsamp<5)=NaN; % standard error
mSTEM = nanmean(STEM);mSTEM(nsamp<5)=NaN;

fprintf('timing error of %0.4f +- %0.4f \n',mSTEM,steSTEM)
