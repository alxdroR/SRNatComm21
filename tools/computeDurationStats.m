function [durationStat,varargout] = computeDurationStats(duration,varargin)
options = struct('animalNumber','1','estimateCI',true,'stat2compute',@nanmedian,'numResamples',[],'numFix',[]);
options = parseNameValueoptions(options,varargin{:});

if ~isempty(options.numResamples) && ~isempty(options.numFix)
    durationStat = NaN(options.numResamples,1);
    for i = 1 : options.numResamples
        equalFixSizeSample = randsample(duration,options.numFix);
        durationStat(i) = options.stat2compute(equalFixSizeSample);
    end
else
    durationStat = options.stat2compute(duration);
end
if options.estimateCI
    bootSamples=bootstrp(1000,options.stat2compute,duration);
    % 95% confidence intervals of bootstrapped distribution
    durationStatCI = quantile(bootSamples,[0.05  0.95]);
    varargout{1} = durationStatCI;
end

end

