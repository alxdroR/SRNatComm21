function [durations,ablationSizeStats,numFixations,iscontrol,varargout]=populationDurationStats(varargin)
options = struct('summaryStat',@nanmedian,'computeChangeStat',false,'changeType','percent','numSamp',[],'restrict2TwaitMinAfterAbl',false,'Twait',30,'aksayBootMethod',[]);
options = parseNameValueoptions(options,varargin{:});


expDates =      {'51419','51519','51519','51619','51619','52219','52219','52319','52319','52419','52919','53019','6519','6519','6619','6619','61219','61919','62019','62019','7119','7319','71019','71119','71119','71819'};
animalNumbers = {'1',     '1',      '2',    '1',    '2',   '1',     '2',        '1',    '2',    '1',    '1',   '1','1',   '2',    '1' ,   '2','1','1','1','2','1','1','1','1','2','1'};

durations = struct('B',[],'A',[]);
durations.B = struct('inSRRF',[],'outSRRF',[],'controlL',[],'controlR',[],'experiment',[],'control',[]);
durations.A = struct('inSRRF',[],'outSRRF',[],'controlL',[],'controlR',[],'experiment',[],'control',[]);
numFixations =  struct('B',NaN(length(expDates),2),'A',NaN(length(expDates),2));
iscontrol = false(length(expDates),1);
anIDs =  struct('experimentID',[],'controlID',[]);
if options.restrict2TwaitMinAfterAbl
    [stackPaths,stackTimes,expDates,animalNumbers] = grabBehaviorVideoFilenames;
    timeInfo = grabAblEndTimeFromFilename;
end
if ~isempty(options.aksayBootMethod)
    numFix4boot = options.aksayBootMethod;
    % numFix4boot needs to be a structure with the same fields and sizes as
    % numFixations. Add check with errors later
    
    % calculate the minimum number of fixations (across both left and right
    % directions)
   [nmin,Nmin,numResamples] = aksayResampleNumFixationStats(numFix4boot);
end
% combine data for plotting and group statistic purposes
conditionNames = {'B','A'};
for j=1:length(conditionNames)
    expCond = conditionNames{j};
    for i=1:length(expDates)
        expDate = expDates{i};
        animalNumber = animalNumbers{i};
        %[expDate '-' animalNumber]
        % [fishName,dataPaths,saveNames,fileNameEndings]=constructDurationFilenames(expDate,'expCond',expCond,'animalNumber',animalNumber);
        %ablationResults = numberTypeAblatedSingleCellAblationExps(expDate,'animalNumber',animalNumber);
        ablationResults = singleCellAblationKey(expDate,'animalNumber',animalNumber);
        if options.restrict2TwaitMinAfterAbl && strcmp(expCond,'A')
            fcount = find(cellfun(@(x) strcmp(x,expDate),expDates) & cellfun(@(x) strcmp(x,animalNumber),animalNumbers));
            [dL,dR] = computeSaveWithinPlaneDurations(['f' expDate '_' animalNumber '_'],expCond,'restrict2TwaitMinAfterAbl',true,...
                'Twait',options.Twait,'stackTimes',stackTimes(fcount),'ablationTimeMeta',timeInfo(fcount));
        else
            [dL,dR] = computeSaveWithinPlaneDurations(['f' expDate '_' animalNumber '_'],expCond);
        end
        % [dL,dR]=loadDurations(saveNames);
        
        nL = length(dL); nR = length(dR);
        numFixations.(expCond)(i,:) = [nL nR];
        if ~isempty(options.numSamp)
            if isnumeric(options.numSamp)
                %if strcmp(expCond,'before')
                if  nL >= options.numSamp && nR >= options.numSamp
                    dL = randsample(dL,options.numSamp);
                    dR = randsample(dR,options.numSamp);
                else
                    dL = NaN(size(dL));dR=NaN(size(dR));
                end
                %end
            else
                error('numSamp option must be an integer');
            end
        end
        
        
        % sort which fixation durations are "in/out SR receptive field" meaning which durations occur while the
        % ablated SR type would have ramped and which occur in the opposite
        % direction
        [inSamples,outSamples,~,controlAnimalCondition] = sortTypeofAblation(ablationResults,dL,dR);
        %fishName
        % run statistics
        [durationStatIn]=computeDurationStats(inSamples,'stat2compute',options.summaryStat,'estimateCI',false);
        [durationStatOut]=computeDurationStats(outSamples,'stat2compute',options.summaryStat,'estimateCI',false);
        if ~isempty(options.aksayBootMethod)
            [durationAll]=computeDurationStats([dL;dR],'stat2compute',options.summaryStat,'estimateCI',false,'numResamples',numResamples(i),'numFix',Nmin);
        else
            [durationAll]=computeDurationStats([dL;dR],'stat2compute',options.summaryStat,'estimateCI',false);
        end
        
        % store categorized size and ablation statistic
        if controlAnimalCondition==true
            % inSamples equal left by the arbitrary convention in sortTypeOfAblation
            durations.(expCond).controlL = [durations.(expCond).controlL;durationStatIn];
            durations.(expCond).controlR = [durations.(expCond).controlR;durationStatOut];
            durations.(expCond).control = [durations.(expCond).control;durationAll];
            if j == 1 && ~isempty(options.aksayBootMethod)
                anIDs.controlID = [anIDs.controlID;ones(numResamples(i),1)*i];
             end
            iscontrol(i)=true;
        else
            durations.(expCond).inSRRF = [durations.(expCond).inSRRF;durationStatIn];
            durations.(expCond).outSRRF = [durations.(expCond).outSRRF;durationStatOut];
            durations.(expCond).experiment = [durations.(expCond).experiment;durationAll];
            if j == 1 && ~isempty(options.aksayBootMethod)
                anIDs.experimentID = [anIDs.experimentID;ones(numResamples(i),1)*i];
            end
        end
        
    end
end
ablationSizeStats = struct('notControl',[],'control',[]);
if ~isempty(options.aksayBootMethod)
    numNotControl = length(durations.B.experiment);
    numControl = length(durations.B.control);
else
    numNotControl = length(durations.B.inSRRF);
    numControl = length(durations.B.controlL);
end
ablationSizeStats.notControl = struct('nSRLHit',zeros(numNotControl,1),'nSRRHit',zeros(numNotControl,1),...
    'nSigSTAHit',zeros(numNotControl,1),'nNotEye',zeros(numNotControl,1),...
    'total',zeros(numNotControl,1),'name',[]);
ablationSizeStats.notControl.name = cell(numNotControl,1);
ablationSizeStats.control = struct('nSRLHit',zeros(numControl,1),'nSRRHit',zeros(numControl,1),...
    'nSigSTAHit',zeros(numControl,1),'nNotEye',zeros(numControl,1),...
    'total',zeros(numControl,1),'name',[]);
ablationSizeStats.control.name = cell(numControl,1);

% change durations structure if user only cares about differences in effect
% size
if options.computeChangeStat
    durations = computeChangeStat(durations,'changeType',options.changeType);
end
varargout{1} = anIDs;
cntrlCount =1; notCCount=1;
for i=1:length(expDates)
    expDate = expDates{i};
    animalNumber = animalNumbers{i};
    
    %ablationResults = numberTypeAblatedSingleCellAblationExps(expDate,'animalNumber',animalNumber);
    ablationResults = singleCellAblationKey(expDate,'animalNumber',animalNumber);
    sizeStatFieldNmes = fieldnames(ablationSizeStats.control);
    ablResFieldNmes = fieldnames(ablationResults);
    fnRelevant = intersect(sizeStatFieldNmes,ablResFieldNmes);
    [~,~,~,controlAnimalCondition] = sortTypeofAblation(ablationResults,NaN,NaN);
    
    
    if controlAnimalCondition==true
        if ~isempty(options.aksayBootMethod)
            indices2save = (1:numResamples(i)) + (cntrlCount-1);
        else
            indices2save = cntrlCount;
        end
        ablationSizeStats.control.name(indices2save) = {[expDate '_' animalNumber]};
        for j=1:length(fnRelevant)
            ablationSizeStats.control.(fnRelevant{j})(indices2save) = ablationResults.(fnRelevant{j});
            ablationSizeStats.control.total(indices2save) = ablationSizeStats.control.total(indices2save) + ablationResults.(fnRelevant{j});
        end
        if ~isempty(options.aksayBootMethod)
            cntrlCount = cntrlCount + numResamples(i);
        else
            cntrlCount = cntrlCount + 1;
        end
    else
        if ~isempty(options.aksayBootMethod)
            indices2save = (1:numResamples(i)) + (notCCount-1);
        else
            indices2save = notCCount;
        end
        ablationSizeStats.notControl.name(indices2save) = {[expDate '_' animalNumber]};
        for j=1:length(fnRelevant)
            ablationSizeStats.notControl.(fnRelevant{j})(indices2save) = ablationResults.(fnRelevant{j});
            ablationSizeStats.notControl.total(indices2save) = ablationSizeStats.notControl.total(notCCount) + ablationResults.(fnRelevant{j});
        end
        if ~isempty(options.aksayBootMethod)
            notCCount = notCCount + numResamples(i);
        else
            notCCount = notCCount+1;
        end
    end
end
end

function [inSamples,outSamples,numberHit,controlAnimalCondition] = sortTypeofAblation(ablationResults,dL,dR)
% determine which field to store this duration result ----------
controlAnimalCondition = (ablationResults.nSRLHit==0 && ablationResults.nSRRHit==0);

% no right cells hit and  left cells hit
if ablationResults.nSRLHit>ablationResults.nSRRHit && ablationResults.nSRRHit<=1
    % place left in inSRRF
    inSamples = dL;
    outSamples = dR;
    
    numberHit = ablationResults.nSRLHit;
elseif ablationResults.nSRLHit<ablationResults.nSRRHit && ablationResults.nSRLHit<=1
    % place right in inSRRF
    inSamples = dR;
    outSamples = dL;
    numberHit = ablationResults.nSRRHit;
elseif controlAnimalCondition==true
    % arbitrarily label left as In and right as Out for coding purposes
    inSamples = dL;
    outSamples = dR;
    numberHit = ablationResults.nNotEye + ablationResults.nSigSTAHit;
end
end

function durationsUpdated = computeChangeStat(durations,varargin)
options = struct('changeType','absolute');
options = parseNameValueoptions(options,varargin{:});

durationsUpdated = struct;
groupNames = fieldnames(durations.B);
for i=1:length(groupNames)
    afterMinusBefore = durations.A.(groupNames{i}) - durations.B.(groupNames{i});
    beforeBase = durations.B.(groupNames{i});
    switch options.changeType
        case 'absolute'
            changeStat = afterMinusBefore;
        case 'percent'
            changeStat = 100*afterMinusBefore./beforeBase;
        case 'fraction'
            changeStat = afterMinusBefore./beforeBase;
    end
    durationsUpdated.(groupNames{i}) = changeStat;
end
end