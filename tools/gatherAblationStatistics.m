function [behaviorStat,varargout] = gatherAblationStatistics(varargin)
% 4/20/2018
options = struct('maxRecordingTimeAfter',30,'minSacRatePerDirection',5,...
    'outliers',[],'randomOrder',false,'statistic','ISI','goodnessOFitCut',0.2,'gofMeasure','r2','loadSavedData',false);
options = parseNameValueoptions(options,varargin{:});


[rbndries,rspacing,regions] = rborders;

maxRecTimeAfterMinutes = options.maxRecordingTimeAfter;
maxRecordingTimeAfter = maxRecTimeAfterMinutes*60;
windowAssesment = 300; % 300 seconds
minSacRatePerDirection = options.minSacRatePerDirection;

switch options.statistic
    case 'ISI'
        statisticOption = 1;
    case 'fixationTimeConstant'
        statisticOption = 2;
    case 'saccadeVelocity'
        statisticOption = 3;
    case 'saccadeAmplitude'
        statisticOption = 4;
end
% list of all ablation-imaging experiment names
% [caudalAblation,otherAblations,controls]=ablationDataFiles;
% [fid,symAblation]=ablDamSymTemp;
%[fidVchb,fidVrhb] = rcExperiments;
epochInExp = {'B','A'};

% fidArray2Use = {otherAblations{1:end-1} caudalAblation{:} controls{:}};
% missingData = [3;5;9;14;15;(21:24)']; % for some reason these indices have not been processed.
% fidArray2Use = fidArray2Use(setdiff(1:length(fidArray2Use),missingData));
% fidArray2Use = {'fMM','fLL','fNN','fOO'};

[fidArray2Use,expCond,anmID] = listAnimalsWithImaging('coarseAblationRegistered',true);
fidArray2Use = fidArray2Use(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
anmID = anmID(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
expCond = expCond(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));

% 1) organize presentation according to rc location of ablation damage
nAll = length(fidArray2Use);
if options.randomOrder
    x = randperm(nAll,nAll)';
    presOrder = x;
else
    x= zeros(nAll,1);
    for expIndex = 1:nAll
        if strcmp(expCond{expIndex},'TBi')
            % find out where the ablation was located in the rostral caudal
            % dimension
            abobj = ablationViewer('fishid',fidArray2Use{expIndex});
            x(expIndex) = abobj.medianRegisteredRClocation;
        elseif strcmp(expCond{expIndex},'C')
            x(expIndex) = 1400;
        end
    end
    [x,presOrder] = sort(x);
end
fidArray2UseSorted = cell(nAll,1);
for expIndex = 1:nAll
    fidArray2UseSorted{expIndex} = fidArray2Use{presOrder(expIndex)};
end
fidArray2Use = fidArray2UseSorted;

outliers = options.outliers;%{'G','LL','MM','OO','NN','XX','PP','KK'}

% change the names of the fields

useOldCode = false;
if useOldCode
    %--boundaries and code  used prior to 4/26/2018
    ablationGroupNames = {'r23','r46','r78','sc'};
    [~,groupedIndicesOrigNames] = extractRhSegments(x,x,...
        'rostral',[rbndries(1)-5 rbndries(3)+20],'middle',[rbndries(4) rbndries(6)],'caudal',[rbndries(6) 1350],'tail',[1400 1400]);
    groupedIndices = struct( 'r23',[],'r46',[],'r78',[],'sc',[]);
    groupedIndices.r23 = groupedIndicesOrigNames.rostral; groupedIndices.r46 = groupedIndicesOrigNames.middle;
    groupedIndices.r78 = groupedIndicesOrigNames.caudal; groupedIndices.sc = groupedIndicesOrigNames.tail;
else
    ablationGroupNames = {'r14','r56','r78','sc'};
    borders =  struct( 'r14',[0 rbndries(4)],'r56',[rbndries(4) rbndries(6)],'r78',[rbndries(6) 1350],'sc',[1400 1400]);
    [~,groupedIndices] = extractRhSegments(x,x,'borderStructure',borders);
end

ablationGroupMatrix = [groupedIndices.(ablationGroupNames{1}), groupedIndices.(ablationGroupNames{2}), ...
    groupedIndices.(ablationGroupNames{3}), groupedIndices.(ablationGroupNames{4})];

if ~(options.loadSavedData && statisticOption == 2) % temporary option to avoid running the time-consuming fitExp2SingleFixations twice
    % adr 4/23/2018. I ran everything in this if statement and then saved the finalSize output.
    % Better long-term solutions include
    % : a) putting everything  within this if statement
    % in a function so that I can better see what I saved
    % b) figuring out a faster way to determine
    % finalSize for taus than calculating all taus
    % twice.
    % initialize global parameter for population statistics
    % determine how large the matrices will be
    finalSize = zeros(nAll,2,2);
    
    for BAIndex = 1 : 2
        for expIndex = 1:nAll
            eyeobj=eyeData('fishid',fidArray2Use{expIndex},'expcond',epochInExp{BAIndex});
            eyeobj = eyeobj.saccadeDetection;
            
            % Note that the final size for options 1,3,4 will be
            % the same, I just don't make use of this fact in the
            % code
            if statisticOption == 2
                invTimeConstants = fitExp2SingleFixations(eyeobj,'fastFit',true,'stopSegment',10,'lineApprox',true);
            end
            for eyeInd = 1 : 2
                if statisticOption == 1
                    % create a list of saccade times relative to the beginning of the experiment recording
                    saccadeTimesCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeTimes,'UniformOutput',false);
                    behaviorStatSingleAnimal = cell2mat(cellfun(@(z) nanPadISIVector(z,'useOldBug',false),saccadeTimesCell,'UniformOutput',false)); % I think this is supposed to be the
                elseif statisticOption == 2
                    % sometimes size(saccadeTimes,1) ~= length(invTauv)
                    % I don't know why. if I figure out the condition I
                    % can avoid calling this time-consuming function twice
                    behaviorStatSingleAnimal = invTimeConstants{eyeInd};
                elseif statisticOption == 3
                    % create a list of saccade velocitiess relative to the beginning of the experiment recording
                    saccadeVelCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeVelocity,'UniformOutput',false);
                    behaviorStatSingleAnimal = cell2mat(saccadeVelCell);
                elseif statisticOption == 4
                    % create a list of saccade velocitiess relative to the beginning of the experiment recording
                    saccadeAmpCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeAmplitude,'UniformOutput',false);
                    behaviorStatSingleAnimal = cell2mat(saccadeAmpCell);
                end
                if ~isempty(behaviorStatSingleAnimal)
                    finalSize(expIndex,BAIndex,eyeInd) = size(behaviorStatSingleAnimal,1);
                else
                    finalSize(expIndex,BAIndex,eyeInd) = 1;
                end
            end
        end
    end
else
    warning('hardcoded link')
    load('/Users/alexramirez/Dropbox/Science/research/onMyPlate/zfishEyeMapping/data/procT/gatherAblationStatisticsFixationTimeFinalSizeValueJul112018','finalSize');
end
% turn the list of individual experiment sizes into a list of indices when
% looping across animals.
startIndices = [ones(1,2,2);cumsum(finalSize(1:end-1,:,:))+1];
stopIndices = cumsum(finalSize);
NTotalBeforeLeftEye = stopIndices(end,1,1);
NTotalAfterLeftEye = stopIndices(end,2,1);
NTotalBeforeRightEye = stopIndices(end,1,2);
NTotalAfterRightEye = stopIndices(end,2,2);


auxStructBeforeLeftEye = makeBehStructFields(NTotalBeforeLeftEye,options.statistic);
auxStructAfterLeftEye = makeBehStructFields(NTotalAfterLeftEye,options.statistic);
auxStructBeforeRightEye = makeBehStructFields(NTotalBeforeRightEye,options.statistic);
auxStructAfterRightEye = makeBehStructFields(NTotalAfterRightEye,options.statistic);

BAStructLeftEye  = struct('before',auxStructBeforeLeftEye,'after',auxStructAfterLeftEye);
BAStructRightEye = struct('before',auxStructBeforeRightEye,'after',auxStructAfterRightEye);
behaviorStat = struct('leftEye',BAStructLeftEye,'rightEye',BAStructRightEye);
saccRates = struct('leftEye',struct('before',struct('rates',cell(nAll,1),'animalIndex',cell(nAll,1)),'after',struct('rates',cell(nAll,1),'animalIndex',cell(nAll,1))),...
    'rightEye',struct('before',struct('rates',cell(nAll,1),'animalIndex',cell(nAll,1)),'after',struct('rates',cell(nAll,1),'animalIndex',cell(nAll,1))));
condNames = {'before','after'};eyeNames={'leftEye','rightEye'};

for BAIndex = 1 : 2
    for expIndex = 1 : nAll
        eyeobj=eyeData('fishid',fidArray2Use{expIndex},'expcond',epochInExp{BAIndex});
        eyeobj = eyeobj.saccadeDetection;
        if statisticOption == 2
            [invTimeConstants,goodnessOfFit,~,absTime] = fitExp2SingleFixations(eyeobj,'fastFit',true,'stopSegment',10,...
                'lineApprox',true,'gofMeasure',options.gofMeasure);
        end
        for eyeInd = 1 : 2
            if statisticOption == 1
                saccadeTimesCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeTimes,'UniformOutput',false);
                behaviorStatSingleAnimal = cell2mat(cellfun(@(z) nanPadISIVector(z,'useOldBug',false),saccadeTimesCell,'UniformOutput',false)); % I think this is supposed to be the
            elseif statisticOption == 2
                % sometimes size(saccadeTimes,1) ~= length(invTauv)
                % I don't know why. if I figure out the condition I
                % can avoid calling this time-consuming function twice
                behaviorStatSingleAnimal = invTimeConstants{eyeInd};
                otherVar = goodnessOfFit{eyeInd}(:,1);
            elseif statisticOption == 3
                % create a list of saccade velocitiess relative to the beginning of the experiment recording
                saccadeVelCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeVelocity,'UniformOutput',false);
                behaviorStatSingleAnimal = cell2mat(saccadeVelCell);
            elseif statisticOption == 4
                % create a list of saccade velocitiess relative to the beginning of the experiment recording
                saccadeAmpCell = cellfun(@(z) z{eyeInd},eyeobj.saccadeAmplitude,'UniformOutput',false);
                behaviorStatSingleAnimal = cell2mat(saccadeAmpCell);
            end
            
            if ~isempty(behaviorStatSingleAnimal)
                behaviorStatSingleAnimal = behaviorStatSingleAnimal(:,1);
                
%                 if (expIndex ==35) && BAIndex ==2
%                     keyboard
%                 end
              %   if strcmp(fidArray2Use{expIndex},'fOO') && eyeInd ==1
              %       keyboard
              %   end
                % add conditions for which fixations to ignore
                % don't use saccade times larger than 30 minutes in after data
                
                
                    if BAIndex == 2
                        if statisticOption ~= 2
                            recorded30MinAfterStart = findSaccadesLongerThanTFromExpStart(eyeobj,maxRecordingTimeAfter,'eyeInd',eyeInd);
                        else
                            % because I haven't remembered the relationship
                            % between saccade times and absTime, I need to
                            % have separate code to create an index of useable
                            % and non-useable events
                            absTimeDouble = cellfun(@(z) z(1),absTime{eyeInd});
                            recorded30MinAfterStart = absTimeDouble > maxRecordingTimeAfter;
                        end
                    else
                        % we don't care if saccade times were recorded 30
                        % minutes after data start in this case, so we
                        % make this flag obsolete by setting it all to false
                        recorded30MinAfterStart = false(size(behaviorStatSingleAnimal));
                    end
                    useOldMethod = false;
               if useOldMethod
                    if statisticOption ~= 2
                        epochWithLowSaccades = findSaccadesInLowSaccadeRateEpochs(eyeobj,minSacRatePerDirection,windowAssesment,'eyeInd',eyeInd,'maxTime',maxRecordingTimeAfter);
                    else
                        % because I haven't remembered the relationship
                        % between saccade times and absTime, I need to
                        % have separate code to create an index of useable
                        % and non-useable events
                        absTimeDouble = cellfun(@(z) z(1),absTime{eyeInd});
                        epochWithLowSaccades = findSaccadesInLowSaccadeRateEpochs(eyeobj,minSacRatePerDirection,windowAssesment,'eyeInd',eyeInd...
                            ,'eventTimes',absTimeDouble);
                    end
                    behaviorStatSingleAnimal(epochWithLowSaccades(:) | recorded30MinAfterStart(:)) = NaN;
               end
                
                behaviorStatSingleAnimal(recorded30MinAfterStart(:)) = NaN;
                [passes,sacRate] = findSaccadesInLowSaccadeRateEpochs(eyeobj,minSacRatePerDirection,windowAssesment,'eyeInd',eyeInd,'maxTime',maxRecordingTimeAfter);
                % check if animal passes our critier to be kept otherwise
                % remove its activity with all nans
%                 if statisticOption ~= 2
%                     
%                 else
%                     absTimeDouble = cellfun(@(z) z(1),absTime{eyeInd});
%                     epochWithLowSaccades = findSaccadesInLowSaccadeRateEpochs(eyeobj,minSacRatePerDirection,windowAssesment,'eyeInd',eyeInd,'maxTime',maxRecordingTimeAfter,...
%                         'eventTimes',absTimeDouble);
%                 end
%                behaviorStatSingleAnimal(epochWithLowSaccades(:) | recorded30MinAfterStart(:)) = NaN;
                  if ~passes
                      behaviorStatSingleAnimal = NaN;
                  end
                if statisticOption==2
                    poorModelFits = goodnessOfFit{eyeInd}(:,1)<=options.goodnessOFitCut;
                    behaviorStatSingleAnimal(poorModelFits) = NaN;
                    otherVar(recorded30MinAfterStart(:)) = NaN;
                    if ~passes
                        otherVar = NaN;
                    end
                   % otherVar(epochWithLowSaccades(:) | recorded30MinAfterStart(:)) = NaN;
                end
            else
                behaviorStatSingleAnimal = NaN; % this isn't really necessary. The window for this ISI will be 0
            end
            windowForThisISI =  startIndices(expIndex,BAIndex,eyeInd) : stopIndices(expIndex,BAIndex,eyeInd);
            behaviorStat.(eyeNames{eyeInd}).(condNames{BAIndex}).(options.statistic)(windowForThisISI) = behaviorStatSingleAnimal;
            behaviorStat.(eyeNames{eyeInd}).(condNames{BAIndex}).animalName(windowForThisISI) = {fidArray2Use{expIndex}};
            behaviorStat.(eyeNames{eyeInd}).(condNames{BAIndex}).ablationLocation(windowForThisISI) = x(expIndex);
            behaviorStat.(eyeNames{eyeInd}).(condNames{BAIndex}).ablationGroup(windowForThisISI) = ablationGroupNames(ablationGroupMatrix(expIndex,:));
            behaviorStat.(eyeNames{eyeInd}).(condNames{BAIndex}).animalIndex(windowForThisISI,:) = [ones(length(windowForThisISI),1)*anmID(expIndex) (1:length(windowForThisISI))'];
            saccRates.(eyeNames{eyeInd}).(condNames{BAIndex})(expIndex).rates = sacRate;
            saccRates.(eyeNames{eyeInd}).(condNames{BAIndex})(expIndex).animalIndex = fidArray2Use{expIndex};
            if statisticOption==2
                behaviorStat.(eyeNames{eyeInd}).(condNames{BAIndex}).other(windowForThisISI) = otherVar;
            end
        end
    end
end
varargout{1} = saccRates;
end