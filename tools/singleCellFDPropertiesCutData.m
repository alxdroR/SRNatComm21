function [keepThisCell] = singleCellFDPropertiesCutData(xAxisVariable,yAxisVariable,varargin)
% singleCellFDPropertiesCutData. Determines whether a cell has enough samples and is well-coniditioned enough to perform single-cell anlayses. 
% [keepThisCell] = singleCellFDPropertiesCutData(xAxisVariable)
% INPUT: 
%       xAxisVariable - Nx1 vector of single-cell measurements. 
% OUTPUT:
%       keepThisCell - boolean scalar equal to true if the measurments pass
%       the hardcoded constraints on number of samples and variance 

options = struct('minNumSamp',10,'iqrCut',3.5);
options = parseNameValueoptions(options,varargin{:});



numSamples = sum(~isnan(xAxisVariable) & ~isnan(yAxisVariable));

% cut 1 : 
enoughSamples = numSamples >= options.minNumSamp; 

% cut 2 : 
xVar = iqr(xAxisVariable);
largeEnoughRange = xVar >= options.iqrCut;

keepThisCell = largeEnoughRange & enoughSamples;
end

