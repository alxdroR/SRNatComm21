classdef fig1
    %fig1 - computes and stores main computations required for figure 1,
    %including statistics printed in the text
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        popSacAmp
        popFD
        popRange
        powerSamples
        durations
        ID
    end
    
    methods
        function obj = getPopFD(obj)
            durations=jointISIDistributionPopAggregatev2;
            obj.durations = durations;
            obj.popFD = [durations.left;durations.right];
        end
        function obj = getPopSacAmp(obj,varargin)
            obj.popSacAmp = jointSaccadeAmplitudeDistributionPopAggregate;
        end
        function obj = getPopRange(obj)
            rangeLower = 0.01;
            rangeUpper = 0.99;
            popRangeValues = posRangePopAggregate('rangeLower',rangeLower,'rangeUpper',rangeUpper);
            obj.popRange = struct('rangeLower',rangeLower,'rangeUpper',rangeUpper,'values',popRangeValues);
        end
        function obj = getPowerSamples(obj)
            [PSDALL,F,sampleIDs]=powerSpectraPopAggregate;
            obj.powerSamples = struct('PSD',PSDALL,'F',F);
            obj.ID = sampleIDs;
        end
        
        function posRngVectorTot = computeTotalRange(obj)
            posRngVectorTot = sum(abs(obj.popRange.values),2);
        end
        function obj = printTotalRange(obj)
            if isempty(obj.popRange)
                obj = obj.getPopRange;
            end
            posRngVectorTot = obj.computeTotalRange;
            mPosRng = mean(posRngVectorTot);
            sPosRng = std(posRngVectorTot);
            nanimals = size(posRngVectorTot,1);
            fprintf('The total range of eye position angles was %0.3f +- %0.3f degrees\n(average +- sem of the %0.1fst and %0.1fth quantiles averaged across both eyes)\n',mPosRng,sPosRng./sqrt(nanimals),...
                obj.popRange.rangeLower*100,obj.popRange.rangeUpper*100)
        end
        function obj = printSacAmpStats(obj)
            if isempty(obj.popSacAmp)
                obj = getPopSacAmp;
            end
            combineLeftRightEyes = [ obj.popSacAmp.left(:); obj.popSacAmp.right(:)];
            saccadeStats = quantile(abs(combineLeftRightEyes),[0.01 0.5 0.99]);
            fprintf('\n\n The size of saccades varied over %0.3f-%0.3f degrees (1 and 99 percent quantiles),\nwith a median amplitude of %0.3f degrees.\n',saccadeStats(1),saccadeStats(3),saccadeStats(2))
        end
        function obj = printFixationStats(obj)
            if isempty(obj.popFD)
                obj = obj.getPopFD;
            end
            fdStats = quantile(obj.popFD,[0.01 0.5 0.99]);
            n = sum(~isnan(obj.popFD));
            fprintf('\nfixations lasted between %1.0f-%1.0f seconds\n (1 and 99 prct quantiles) with a median duration\n of %0.3f seconds.\n\n',fdStats(1),fdStats(3),fdStats(2))
            fprintf('n=%d fixations\n',n)
        end
        function obj = printPowerFreqRange(obj,varargin)
            options = struct('powerData',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.powerData)
                if isempty(obj.powerSamples)
                    obj = obj.getPowerSamples;
                end
                psObj = powerSpectraCalculationClass;
                psObj = psObj.compute;
                options.powerData = psObj.data;
            end
            [y,sumy] = powerSpectraCalculationClass.computePowerStats(options.powerData);
            
            cumPower = cumsum(y./sumy);
            [~,minInd]=min(abs(cumPower-0.95));
            freq_95 = options.powerData.freq(minInd);
            fprintf('\n\n...we performed a Fourier analysis of the \nchanges in eye position and found that power was distributed over a range of frequencies,\n')
            fprintf('with 95 percent of total power between 0-%0.3f Hz \n',freq_95)
        end
        function obj=printPeakPower(obj,varargin)
            options = struct('powerData',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.powerData)
                if isempty(obj.powerSamples)
                    obj = obj.getPowerSamples;
                end
                psObj = powerSpectraCalculationClass;
                psObj = psObj.compute('powerSamples',obj.powerSamples);
                options.powerData = psObj.data;
            end
            [y,sumy] = powerSpectraCalculationClass.computePowerStats(options.powerData);
            [~,maxInd]=max(y(2:end)./sumy);
            freq_peak = options.powerData.freq(maxInd);
            fprintf('and peak power (excluding 0 Hz) at %0.3f Hz\n',freq_peak)
        end
        function obj=printSacDirAmpStats(obj,varargin)
            options = struct('sacAmpData',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.sacAmpData)
                if isempty(obj.popSacAmp)
                    obj = obj.getPopSacAmp;
                end
                saObj = saccadeAmplitudeClass;
                saObj = saObj.compute('popSacAmp',obj.popSacAmp);
                options.sacAmpData = saObj.data;
            end
            
            NTotal = length(options.sacAmpData.ampSamplesSame) + length(options.sacAmpData.ampSamplesOpp);
            fprintf('total number of saccades = %d\n',NTotal);
            probSame = length(options.sacAmpData.ampSamplesSame)/NTotal;
            probVar = probSame*(1-probSame);se = probVar/sqrt(NTotal);
            fprintf('\n\n as nearly a quarter of the time zebrafish made successive\n saccades in the same direction (%0.3f +- %0.3f,...\n\n',probSame,se)
            medSame = median(options.sacAmpData.ampSamplesSame);
            medOpp = median(options.sacAmpData.ampSamplesOpp);
            fprintf('median amplitude of saccade in the same direction as previous saccade equaled %0.2f degrees\n',medSame)
            fprintf('median amplitude of saccade in the opposite direction equaled %0.2f degrees\n',medOpp)
        end
    end
end

