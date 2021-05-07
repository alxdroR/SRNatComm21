classdef plotBinner
    %plotBinner - class for binning then plotting scalar value pairs
    %
    % properties:
    % data - Nx2 matrix
    % binParameter - scalar value or vector of desired binned values. If a
    %           scalar value is given, data will be binned into equally
    %           spaced bins ranging from the minium value of data(:,1)
    %           and maximum value of data(:,1).
    %           If a vector value is given, vector elements will
    %           be interpretted as binedges
    %
    % methods:
    % plot - plot data(:,1) versus data(:,2) after binning data(:,2) into groups
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    
    
    properties
        data
        binParameter
    end
    
    methods
        function pB=plotBinner(data,binParameter)
            if nargin<2
                binParameter = 1;
                if nargin < 1
                    error('at least one input required');
                end
            end
            [nr,nc]=size(data);
            if any([nr,nc]==1)
                % in this case the user wants to bin according to data and
                % may want to see what the result is from performing mean,
                % median, mad ,etc of data within bins
                data = [data(:) data(:)];
            elseif (nr==2) && (nc>nr)
                data = data';
            end
            pB.data = data;
            pB.binParameter = binParameter;
        end
        
        function plot(pB)
            binnedData = binData(pB);
            figure;
            plot(binnedData(:,1),binnedData(:,2),'b')
        end
        
        function [varargout] = binData(pB,varargin)
            options = struct('median',true,'MAD',false,'sum',false,'onlyReturnIndicesPerBin',false,...
                'extraBinCriteriaBool',[],'binWidth',[],'minNumSamples',0,'missingSampVal',NaN);
            options = parseNameValueoptions(options,varargin{:});
            
            % method for binning the data contained in pB.data(:,2)
            binSize = pB.binParameter;
            if isscalar(binSize)
                minval = min(pB.data(:,1));
                maxval = max(pB.data(:,1));
                
                numBins = round((maxval-minval)/binSize);
                [~,binCenters]=hist(pB.data(:,1),numBins);
                binEdges = [binCenters(:)-binSize/2,binCenters(:)+binSize/2];
            else
                binCenters = pB.binParameter;
                numBins = length(binCenters);
                if isempty(options.binWidth)
                    binWidth = abs(binCenters(2)-binCenters(1));
                else
                    binWidth = options.binWidth;
                end
                binEdges = [binCenters(:)-binWidth/2,binCenters(:)+binWidth/2];
            end
            
            binnedData = NaN(numBins,1);
            numberSamp = NaN(numBins,1);
            binVar = NaN(numBins,1);
            binNumber = zeros(size(pB.data,1),1);
            indicesForEachBin = cell(numBins,1);
            for j=1:numBins
                % within bin condition
                if isempty(options.extraBinCriteriaBool)
                    withinBin = pB.data(:,1)>=binEdges(j,1) & pB.data(:,1)< binEdges(j,2);
                else
                    withinBin = pB.data(:,1)>=binEdges(j,1) & pB.data(:,1)< binEdges(j,2) & options.extraBinCriteriaBool;
                end
                indicesForEachBin{j} = find(withinBin);
                if ~options.onlyReturnIndicesPerBin
                    if any(withinBin)
                        if options.median
                            binnedData(j) = nanmedian(pB.data(withinBin,2));
                        elseif options.sum
                            binnedData(j) = nansum(pB.data(withinBin,2));
                        else
                            binnedData(j) = nanmean(pB.data(withinBin,2));
                        end
                        if options.MAD
                            m = nanmedian(pB.data(withinBin,2));
                            binVar(j) = 1.4826*nanmedian(abs(pB.data(withinBin,2)-m));
                        else
                            binVar(j) = nanvar(pB.data(withinBin,2));
                        end
                        numberSamp(j) = sum(~isnan(pB.data(withinBin,2)));
                        binNumber(withinBin) = j;
                    end
                end
            end
            if options.minNumSamples>0
                if isempty(options.missingSampVal)
                    binnedData = binnedData(numberSamp>=options.minNumSamples);
                    binCenters = binCenters(numberSamp>=options.minNumSamples);
                    binVar = binVar(numberSamp>=options.minNumSamples);
                    numberSamp = numberSamp(numberSamp>=options.minNumSamples);
                else
                    binnedData(numberSamp<options.minNumSamples)=options.missingSampVal;
                    binCenters(numberSamp<options.minNumSamples)=options.missingSampVal;
                    binVar(numberSamp<options.minNumSamples)=options.missingSampVal;
                    numberSamp(numberSamp<options.minNumSamples)=options.missingSampVal;
                end
            end
            if options.onlyReturnIndicesPerBin
                varargout{1} = indicesForEachBin;
            else
                varargout{1} = binnedData;
                varargout{2} = binVar;
                varargout{3} = numberSamp;
                varargout{4} = binCenters;
                varargout{5} = binNumber;
            end
        end
        
    end
    
end

