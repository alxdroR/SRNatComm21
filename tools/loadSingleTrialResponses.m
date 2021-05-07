function [YOutAcrossPlanes,TOutAcrossPlanes,animalOutAcrossPlanes,keptIndices]=loadSingleTrialResponses(Y,TF,IDsFromCellsOfInterest,varargin)
%  = loadSingleTrialResponses(rate,TF,IDsFromCellsOfInterest,relSigLeft)
% Load dF/F from individual fixations for cells that match a varity of user
% input criteria.
% INPUT:
% Y                -- cell of cells. Y{indexA}{indexB} holds a TxN
%                        matrix of activity that we will run ramp/slope
%                        analysis on. THE DATA MUST BE SORTED ACCORDING
%                        TO EXP,PLANE,CELL INDICES! THIS CAN BE DONE
%                        FOR EXAMPLE USING THE OUTPUT FROM LOADFULLDATA
%
% TF                -- cell of cells. TF{indexA}{indexB} holds a TxN
%                        matrix of times that Y was recorded
%
% IDsFromCellsOfInterest -- list of expIndex,planeIndex,cellIndices
%                           of activity we will be analyzing. Needed
%                           to load saccade times and saccade direction
%                           The order of the IDs does not matter. The data
%                           will load eye position files in a sorted order
%                           of animal indices, plane indices, and cell
%                           indices
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

options = struct('cells','all','direction','following left','ISI','all','ISIwidth',NaN,'ONdirection',[],'interp2gridThenCat',false,...
    'binTimes',[],'binTimesPreceeding',[],'binTimesFollowing',[],'tau','past saccade','useOldSaccadeTimeBug',false,...
    'removeSaccadeTimesWNoImaging',true,'sVelConditionCenter',NaN,'sVelConditionWidth',NaN,'randomSaccadeTimes',false);
options = parseNameValueoptions(options,varargin{:});

if options.interp2gridThenCat
    YOutAcrossPlanes = [];
    if isempty(regexp(options.direction,'surrounding','end'))
        TOutAcrossPlanes = options.binTimes;
    else
        TOutAcrossPlanes = [options.binTimesPreceeding options.binTimesFollowing];
    end
    animalOutAcrossPlanes = [];
else
    YOutAcrossPlanes =  cell(size(IDsFromCellsOfInterest,1),1);
    TOutAcrossPlanes = YOutAcrossPlanes;
    animalOutAcrossPlanes = YOutAcrossPlanes;
    cnt = 1;
end

NCells = size(IDsFromCellsOfInterest,1);
if isnumeric(options.cells)
    cellV = options.cells;
    if max(cellV) > NCells
        error('There are not as many cells in the input as the user wants as specified in `cells`');
    elseif min(cellV) < 1
        error('when specificy `cells` as a vector, the numbers in the vector must be integers within the set 1:size(Y,2)');
    end
    cellsCurrentlyProcessed = 0;
elseif ~strcmp(options.cells,'all')
    error('`cells` must be a string set to `all` or a vector of integers');
end

if ~isnan(options.sVelConditionCenter)
    if isnan(options.sVelConditionWidth)
        error('Bin width and center needed to condition on saccade velocity');
    end
end

keptIndices = [];
[fid,expCond] = listAnimalsWithImaging;
uniqueAnimals = unique(IDsFromCellsOfInterest(:,1));
for indexA = 1:length(uniqueAnimals(:))
    expIndex = uniqueAnimals(indexA);
    eyeobj = eyeData('fishid',fid{expIndex},'expcond',expCond{expIndex});
    eyeobj = eyeobj.saccadeDetection;
    
    animalBoolSelectionVector = IDsFromCellsOfInterest(:,1)==expIndex;
    uniquePlanes = unique( IDsFromCellsOfInterest(animalBoolSelectionVector,2) );
    for indexB = 1:length(uniquePlanes(:))
        planeIndex = uniquePlanes(indexB);
        
        [saccadeTimes,saccadeDirection,saccadeVelocity] = combineSaccadeTimesAcrossEyes(eyeobj,planeIndex,...
            'useOldSaccadeTimeBug',options.useOldSaccadeTimeBug,'removeSaccadeTimesWNoImaging',options.removeSaccadeTimesWNoImaging...
            ,'returnVelocity',true);
        animalPlaneBoolSelectionVector = IDsFromCellsOfInterest(:,1)==expIndex & IDsFromCellsOfInterest(:,2)==planeIndex;
        
        
        %saccadeTimes = eyeobj.saccadeTimes{planeIndex}{1};
        %saccadeDirection = eyeobj.saccadeDirection{planeIndex}{1};
        
        if ~isempty(options.ONdirection)
            leftIsOn = options.ONdirection(animalPlaneBoolSelectionVector);
        else
            leftIsOn = [];
        end
        if isnumeric(options.cells)
            cellsCurrentlyProcessed = (1:size(Y{indexA}{indexB},2)) + cellsCurrentlyProcessed(end);
            [~,cells2process] = intersect(cellsCurrentlyProcessed,cellV);
        else
            cells2process = 'all';
        end
      %  saccadeTimes = round(saccadeTimes*1e4)/1e4;
     
      %  fds = round(fds*1e4)/1e4;
      %  saccadeTimes = [saccadeTimes(1,1);fds];
      %  saccadeTimes = [saccadeTimes (saccadeTimes+1)];
        if options.randomSaccadeTimes
            % randST = rand(size(saccadeTimes,1),1)*eyeobj.time{planeIndex}(end,1);
            % randST = sort(randST);
            % saccadeTimes = [randST (randST+1)];
            stbu=saccadeTimes;sdbu=saccadeDirection;svbu = saccadeVelocity;
            
            fds = diff(saccadeTimes(:,1));
            nPassing = sum(abs(fds - options.ISI)<=options.ISIwidth/2);
            if nPassing ~= 0
                % use the exact same durations but at randomly selected
                % times
                stStart = find(abs(fds - options.ISI)<=options.ISIwidth/2);
                st1 = rand*(eyeobj.time{planeIndex}(end,1) - nPassing*(options.ISI-options.ISIwidth));
                saccadeTimesR = [st1;st1+cumsum(ones(nPassing,1)*options.ISI)];
                saccadeTimes=[saccadeTimesR saccadeTimesR+1];
                
                %                randST = rand(nPassing,1)*(eyeobj.time{planeIndex}(end,1) - options.ISI-options.ISIwidth);
                saccadeDirection = [0;saccadeDirection(stStart+1)];
                %  saccadeTimes = sort([randST;randST+options.ISI]);
                %  saccadeTimes = [saccadeTimes saccadeTimes+1];
            end
            %      st1 = rand*saccadeTimes(1);
       %     st1 = round(st1*1e4)/1e4;
            %st1 = saccadeTimes(1);
%             P = randperm(length(fds));
%             fdShuffled = fds(P);
%             saccadeTimesR = [st1;st1+cumsum(fdShuffled)];
%             saccadeTimes=[saccadeTimesR saccadeTimesR+1];
%             sdfd= saccadeDirection(2:end);
%             svfd = saccadeVelocity(2:end);
%             saccadeDirection = [saccadeDirection(1);sdfd(P)];
%             saccadeVelocity = [saccadeVelocity(1) svfd(P)];
        end
        if ~isempty(cells2process)
            [YOut,TOut,trialsCellsUsed]=segregateSTResponses(Y{indexA}{indexB},saccadeTimes,saccadeDirection,TF{indexA}{indexB},...
                'cells',cells2process,'direction',options.direction,'ISI',options.ISI,'ISIwidth',options.ISIwidth,...
                'ONdirection',leftIsOn,'interp2gridThenCat',options.interp2gridThenCat,'binTimes',options.binTimes,...
                'binTimesPreceeding',options.binTimesPreceeding,'binTimesFollowing',options.binTimesFollowing,'tau',options.tau,...
                'sVelocity',saccadeVelocity,'sVelConditionCenter',options.sVelConditionCenter,'sVelConditionWidth',options.sVelConditionWidth);
            
%             [YOutbu,TOutbu,trialsCellsUsedbu]=segregateSTResponses(Y{indexA}{indexB},stbu,sdbu,TF{indexA}{indexB},...
%                 'cells',cells2process,'direction',options.direction,'ISI',options.ISI,'ISIwidth',options.ISIwidth,...
%                 'ONdirection',leftIsOn,'interp2gridThenCat',options.interp2gridThenCat,'binTimes',options.binTimes,...
%                 'binTimesPreceeding',options.binTimesPreceeding,'binTimesFollowing',options.binTimesFollowing,'tau',options.tau,...
%                 'sVelocity',svbu,'sVelConditionCenter',options.sVelConditionCenter,'sVelConditionWidth',options.sVelConditionWidth);
%             if size(YOutbu,1)~=size(YOut,1)
%                 keyboard;
%             end
            if options.interp2gridThenCat
                YOutAcrossPlanes = [YOutAcrossPlanes;YOut];
                if ~isempty(YOut)
                    numEvents = size(YOut,1);
                    cellNames = IDsFromCellsOfInterest(animalPlaneBoolSelectionVector,3);
                  %  nameValue = str2double(fid{expIndex}(2:end));
                   % if isnan(nameValue)
                    %    nameValue = fid{expIndex}(2:end);
                    %end
                    nameValue = expIndex;
                    animalOutAcrossPlanes = [animalOutAcrossPlanes;[ones(numEvents,1)*[nameValue planeIndex] cellNames(trialsCellsUsed(:,1)) trialsCellsUsed(:,2)]];
                    keptIndices = [keptIndices;find(animalPlaneBoolSelectionVector)];
                end
            else
                for outIndex =1 : length(YOut)
                    if ~isempty(YOut{outIndex})
                        YOutAcrossPlanes{cnt} = YOut{outIndex};
                        TOutAcrossPlanes{cnt} = TOut{outIndex};
                        animalOutAcrossPlanes{cnt} = expIndex;
                        cnt = cnt + 1;
                    end
                end
            end
        end
    end
end

% remove empty cells if necessary
if ~options.interp2gridThenCat
    outputD1 = cell(cnt-1,1);
    outputD2 = cell(cnt-1,1);
    outputD3 = cell(cnt-1,1);
    for outIndex =1 : cnt -1
        outputD1{outIndex} = YOutAcrossPlanes{outIndex};
        outputD2{outIndex} = TOutAcrossPlanes{outIndex};
        outputD3{outIndex} = animalOutAcrossPlanes{outIndex};
    end
    YOutAcrossPlanes = outputD1;
    TOutAcrossPlanes = outputD2;
    animalOutAcrossPlanes = outputD3;
end

end

