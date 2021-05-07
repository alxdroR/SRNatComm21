function [densityEstimate,weightNorm] = sampleDensities1d(nSampleMap,varargin)

options = struct('axis','rc','minRelDensity',0.1);
options = parseNameValueoptions(options,varargin{:});

if strcmp(options.axis,'rc')
    axisIndex = 2;
    
elseif strcmp(options.axis,'dv')
    axisIndex = 3;
    
elseif strcmp(options.axis,'lm')
    axisIndex = 1;
    
end
squeezeDim = setdiff(1:3,axisIndex);
densityEstimate = squeeze(sum(sum(nSampleMap,squeezeDim(1)),squeezeDim(2)));
densityEstimate = densityEstimate/sum(densityEstimate);

iweightNorm = densityEstimate;
iweightNorm(iweightNorm/max(iweightNorm)<options.minRelDensity)=NaN;
weightNorm=1./(iweightNorm);

A = find(~isnan(weightNorm),1);
B = find(~isnan(weightNorm),1,'last');
weightNorm(1:A) = weightNorm(A+1);
weightNorm(B+1:end) = weightNorm(B);

end

