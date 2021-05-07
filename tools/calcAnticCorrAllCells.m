function anticipatoryCC=calcAnticCorrAllCells(cellFinderMethod,varargin)
options = struct('filterThenDeconvolve',false,'linearFilter',false,'maxTimeBack',4,'useTwitches',true,'timeAfterSaccade2Remove',2,'randomSaccadeTimes',false,'useDeconvF',false,'normFunction','dff');
options = parseNameValueoptions(options,varargin{:});

[numCells,numPlanesV] = totalNumberCells(cellFinderMethod,varargin{:});

totalNumCells = sum(numCells);

anticipatoryCC = zeros(totalNumCells,6);

if options.filterThenDeconvolve
    % build fluorescence filter
    dtDefault = (512*0.002); % most common dt
    LpDefault = designfilt('lowpassiir','PassbandFrequency',0.2,'StopbandFrequency',0.3,'DesignMethod','butter','SampleRate',1/dtDefault);
    % build deconvolution matrix
    TDefault = 293; % most common value of numSamples
    tauGCaMP=2;
    gammaDefault = exp(-dtDefault/tauGCaMP);
    GDefault = spdiags([ones(TDefault,1),-gammaDefault*ones(TDefault,1)],[0,-1],TDefault,TDefault);
end

[fid,expCond] = listAnimalsWithImaging(varargin{:});
for expIndex = 1:length(fid)
    eyeobj = eyeData('fishid',fid{expIndex},'expcond',expCond{expIndex});
    caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'EPSelectedCells',true,'loadImages',false,'loadCCMap',false);
    eyeobj = eyeobj.saccadeDetection;
    
    for planeIndex = 1 : numPlanesV(expIndex)
        [saccadeTimes,saccadeDirection] = combineSaccadeTimesAcrossEyes(eyeobj,planeIndex,...
            'removeSaccadeTimesWNoImaging',true);
        
        if options.useDeconvF
            F=caobj.nmfDeconvF;
        else
            F = caobj.fluorescence;
        end
        
        if ~options.useTwitches
            F = replaceTwitchSamplesWithNaN(F,caobj.twitchFrames);
        end
        
        if strcmp(options.normFunction,'dff')
            normalizedF = dff(F{planeIndex});
        elseif strcmp(options.normFunction,'zscore')
            normalizedF = (F{planeIndex}-nanmean(F{planeIndex}))./(ones(size(F{planeIndex},1),1)*nanstd(F{planeIndex}));
        else
            normalizedF = F{planeIndex};
        end
        
        if options.filterThenDeconvolve
            % 1) do we need to update filter because of sampling rate?
            dt = caobj.time{planeIndex}(2,1)-caobj.time{planeIndex}(1,1);
            T = size(normalizedF,1);
            if dt ~= dtDefault
                Lp = designfilt('lowpassiir','PassbandFrequency',0.2,'StopbandFrequency',0.3,'DesignMethod','butter','SampleRate',1/dt);
                gamma = exp(-dt/tauGCaMP);
                G = spdiags([ones(T,1),-gamma*ones(T,1)],[0,-1],T,T);
            else
                Lp = LpDefault;
                if T ~= TDefault
                    G = spdiags([ones(T,1),-gammaDefault*ones(T,1)],[0,-1],T,T);
                else
                    G = GDefault;
                end
            end
            
            yDeconv = zeros(size(normalizedF));
            for cellIndex = 1 : size(yDeconv,2)
                yFiltered = filtfilt(Lp,normalizedF(:,cellIndex));
                yDeconv(:,cellIndex) = G*yFiltered;
            end
            Y = yDeconv;
            if options.linearFilter
                regParameters = linearRegFilter(yDeconv,caobj.time{planeIndex},saccadeTimes,saccadeDirection,options.maxTimeBack);
                Y = squeeze(regParameters(1,:,:));
            end
        else
            Y = normalizedF;
            if options.linearFilter
                regParameters = linearRegFilter(normalizedF,caobj.time{planeIndex},saccadeTimes,saccadeDirection,options.maxTimeBack);
                Y = squeeze(regParameters(1,:,:));
            end
        end
        
        if options.randomSaccadeTimes
            randST = rand(size(saccadeTimes,1),1)*caobj.time{planeIndex}(end,1);
            %randST = sort(randST);
            saccadeTimes = [randST (randST+1)];
        end
        anticipatoryCCInPlane = anticipatoryCorrelationComputation(Y,saccadeTimes,saccadeDirection,caobj.time{planeIndex}...
            ,'timeAfterSaccade2Remove',options.timeAfterSaccade2Remove);
        numCellIndex = planeIndex + sum(numPlanesV(1:expIndex-1));
        allCellIndex = (1: numCells(numCellIndex)) + sum(numCells(1:numCellIndex-1));
        anticipatoryCC(allCellIndex,:) = anticipatoryCCInPlane;
        
    end
end



