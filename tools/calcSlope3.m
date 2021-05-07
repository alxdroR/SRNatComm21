function [analysisMatrix,ISI,analysisCell,animalNames,specialDFF,specialT,analysisMatrixOFF,ISIOFF]=calcSlope3(IDsFromCellsOfInterest,relSigLeft,varargin)
% [analysisMatrix,ISI,analysisCell]=calcSlope3(IDsFromCellsOfInterest,relSigLeft,rate,varargin)
% The function calcSlope3.m analyzes single fixations preceeding a user-specified direction from multiple animals and planes
% to perform essentially 2 computations:
% 1) it identifies a time where either dF/F crosses a baseline
% or where a user-input trace crosses a baseline and 2) computes the parameters and goodness-of-fit of a model that assumes activity changes
% linearly from the time identified in (1) to the end of the fixation.
% see demoFnc_calcSlope3.m
%
% Note the calcSlope3 main functions are simply loading the desired dF/F traces, the required saccade times and directions, calling
% the main function to perform the calculation --
% rampSlopeAndTimeComputation -- and compiling the results across animals
% and planes into the output matrices and vectors


options = struct('filterThenDeconvolve',false,'turnOffFilter',false,'linearFilter',false,'maxTimeBack',4,'calcMonoCC',false,'useTwitches',true,...
    'calcRiseTimeWithBaseline',true,'isAnticipatory',true,'useONDirection',true,...
    'tracesForThresholdCalc',[],'measureRelativeDFFAtSaccade',false,'tauGCaMP',2,'useDeconvF',false,'normFunction','dff');
options = parseNameValueoptions(options,varargin{:});

%[numCells,numPlanesV] = totalNumberCells(cellFinderMethod);
if 0
    relaxTime =4;
    
    eyeIndex = 1;
    totalNumCells = sum(numCells);
    STR = cell(totalNumCells,1);
    direction = cell(totalNumCells,1);
    slope.leftward= cell(totalNumCells,1);
    slope.rightward= cell(totalNumCells,1);
    
    ISI.leftward= cell(totalNumCells,1);
    ISI.rightward= cell(totalNumCells,1);
    
    if options.calcMonoCC
        anticipatoryCC = zeros(totalNumCells,4);
    end
end

analysisMatrix = [];analysisMatrixOFF = [];
analysisCell = cell(size(IDsFromCellsOfInterest,1),1);
animalNames = cell(size(IDsFromCellsOfInterest,1),1);
animalNames = [];
ISI = [];ISIOFF = [];
specialDFF = cell(2,1);specialT = cell(2,1);spcount=1;
if options.filterThenDeconvolve
    % build fluorescence filter
    dtDefault = (512*0.002); % most common dt
    LpDefault = designfilt('lowpassiir','PassbandFrequency',0.2,'StopbandFrequency',0.3,'DesignMethod','butter','SampleRate',1/dtDefault);
    % build deconvolution matrix
    TDefault = 293; % most common value of numSamples
    gammaDefault = exp(-dtDefault/options.tauGCaMP);
    GDefault = spdiags([ones(TDefault,1),-gammaDefault*ones(TDefault,1)],[0,-1],TDefault,TDefault);
end

[fid,expCond] = listAnimalsWithImaging;
uniqueAnimals = unique(IDsFromCellsOfInterest(:,1));
if ~options.calcRiseTimeWithBaseline
    rate = options.tracesForThresholdCalc;
    if isempty(rate)
        error('When `calcRiseTimeWithBaseline` is set to false, you must specify the traces used to perform the threshold computation.');
    end
    if length(rate)~=length(uniqueAnimals)
        error('The firing rate must correspond to the IDs. The number of animals specified in ID does not correspond to the number of animals in the rate');
    end
end
cnt = 1;
for indexA = 1:length(uniqueAnimals(:))
    expIndex = uniqueAnimals(indexA);
    fishid = fid{expIndex};
    animalBoolSelectionVector = IDsFromCellsOfInterest(:,1)==expIndex;
    uniquePlanes = unique( IDsFromCellsOfInterest(animalBoolSelectionVector,2) );
    if ~options.calcRiseTimeWithBaseline
        if length(uniquePlanes) ~= length(rate{indexA})
            error('The firing rate must correspond to the IDs. The number of planes specified in ID does not correspond to the number of planes in the rate');
        end
    end
    eyeobj = eyeData('fishid',fishid,'expcond',expCond{expIndex});
    caobj=caData('fishid',fishid,'expcond',expCond{expIndex},'NMF',true,'loadImages',false,'loadCCMap',false);
    eyeobj = eyeobj.saccadeDetection;
    
    for indexB = 1:length(uniquePlanes(:))
        planeIndex = uniquePlanes(indexB);
        
        % cell specific portion
        animalPlaneBoolSelectionVector = IDsFromCellsOfInterest(:,1)==expIndex & IDsFromCellsOfInterest(:,2)==planeIndex;
        cellIndicies = IDsFromCellsOfInterest(animalPlaneBoolSelectionVector,3);
        if ~options.calcRiseTimeWithBaseline
            if length(cellIndicies)~=size(rate{indexA}{indexB},2)
                error('The firing rate must correspond to the IDs. The number of cells specified in ID does not correspond to the number of cells in the rate');
            end
        end
        
        % lines 50-62 should be replaced by after verifying that this
        % doesn't change results by mistake -adr 2/27/2018 5:57pm
        [saccadeTimes,saccadeDirection] = combineSaccadeTimesAcrossEyes(eyeobj,planeIndex,'removeSaccadeTimesWNoImaging',true);
        if options.useDeconvF
            F=caobj.nmfDeconvF;
        else
            F = caobj.fluorescence;
        end
        
        
        if ~options.useTwitches && ~options.filterThenDeconvolve
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
                gamma = exp(-dt/options.tauGCaMP);
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
                if options.turnOffFilter
                    yFiltered = normalizedF(:,cellIndex);
                else
                    yFiltered = filtfilt(Lp,normalizedF(:,cellIndex));
                end
                yDeconv(:,cellIndex) = G*yFiltered;
            end
            Y = yDeconv;
            if options.linearFilter
                regParameters = linearRegFilter(yDeconv,caobj.time{planeIndex},saccadeTimes,saccadeDirection,options.maxTimeBack);
                Y = squeeze(regParameters(1,:,:));
            end
            if ~options.useTwitches
                Y = replaceTwitchSamplesWithNaN(Y,caobj.twitchFrames{planeIndex});
            end
        else
            Y = normalizedF;
            if options.linearFilter
                regParameters = linearRegFilter(normalizedF,caobj.time{planeIndex},saccadeTimes,saccadeDirection,options.maxTimeBack);
                Y = squeeze(regParameters(1,:,:));
            end
        end
        
        
        %    relSigLeft = sigLeft(uniqueIDsFromCOI);
        areSigLeftCells = relSigLeft(animalPlaneBoolSelectionVector);
        offDir = ~areSigLeftCells; % should be 0 (right) if areSigLeftCells=1 (left coding) or 1(left) if areSigLeftCells=0 (right coding)
        if options.calcRiseTimeWithBaseline
            [analysisMatrixSinglePlane,ISISinglePlane,dirInPlane] = rampSlopeAndTimeComputation(Y(:,cellIndicies),saccadeTimes,saccadeDirection,...
                caobj.time{planeIndex}(:,cellIndicies),offDir,'measureRelativeDFFAtSaccade',options.measureRelativeDFFAtSaccade,varargin{:});
        else
            [analysisMatrixSinglePlane,ISISinglePlane,dirInPlane,spDFF,spTime] = rampSlopeAndTimeComputation(Y(:,cellIndicies),saccadeTimes,saccadeDirection,...
                caobj.time{planeIndex}(:,cellIndicies),offDir,'firingRate',rate{indexA}{indexB},...
                'measureRelativeDFFAtSaccade',options.measureRelativeDFFAtSaccade,varargin{:});
        end
        
        for index1 = 1:length(analysisMatrixSinglePlane)
            ntrials = length(dirInPlane{index1});
            % these are the indices of the saccades we reference when
            % looking at their direction.
            if options.isAnticipatory
                indices2use = 2:ntrials;
            else
                indices2use = 1:ntrials-1;
            end
            if options.useONDirection
                if areSigLeftCells(index1)
                    trials2use = dirInPlane{index1}(indices2use);
                else
                    trials2use = ~dirInPlane{index1}(indices2use);
                end
            else
                if areSigLeftCells(index1)
                    trials2use = ~dirInPlane{index1}(indices2use);
                else
                    trials2use = dirInPlane{index1}(indices2use);
                end
            end
            analysisMatrix = [analysisMatrix;analysisMatrixSinglePlane{index1}(trials2use,:)];
            analysisMatrixOFF = [analysisMatrixOFF;analysisMatrixSinglePlane{index1}(~trials2use,:)];
            ISI = [ISI;ISISinglePlane{index1}(trials2use)];
            ISIOFF = [ISIOFF;ISISinglePlane{index1}(~trials2use)];
            
            %nameValue = str2double(fid{expIndex}(2:end));
            %if isnan(nameValue)
            %    nameValue = fid{expIndex}(2:end);
            %end
            nameValue = expIndex;
            animalNames = [animalNames;ones(sum(trials2use),1)*[nameValue,planeIndex,cellIndicies(index1)]];
            analysisCell{cnt} = [analysisMatrixSinglePlane{index1}(trials2use,:) ISISinglePlane{index1}(trials2use)];
            cnt  = cnt + 1;
        end
        if ~isempty(spDFF{1})
            % these are individaul fixations chosen because of a hard-coded
            % condition implemented in rampSlopeAdnTimeComputation. on
            % 8/13/2019 I was looking for a method to detect failures to
            % rise
            for index1 = 1 : length(spDFF)
                specialDFF{spcount}=spDFF{index1};
                specialT{spcount} = spTime{index1};
                spcount=spcount+1;
            end
        end
    end
end

