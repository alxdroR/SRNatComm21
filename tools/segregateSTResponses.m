function [YOutput,TOutput,trialsCellsUsed] = segregateSTResponses(Y,saccadeTimes,saccadeDirection,time,varargin)
%  YOutput = segregateSTResponses(Y,saccadeTimes,saccadeDirection,time,varargin)
%options = struct('cells','all','direction','following left','ISI','all','ISIwidth',NaN,'ONdirection',[],'interp2gridThenCat',false,...
%   'binTimes',[]);
%
% switch options.direction
%     case 'following left'
%         dirCondition =dirInPlane{cellIndex}(1:end-1)==1;
%     case 'preceeding left'
%         dirCondition =dirInPlane{cellIndex}(2:end)==1;
%     case 'following right'
%         dirCondition =dirInPlane{cellIndex}(1:end-1)==0;
%     case 'preceeding right'
%         dirCondition =dirInPlane{cellIndex}(2:end)==1;
%     case 'following ON'
%         dirCondition =dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
%     case 'preceeding ON'
%         dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex);
%     case 'following OFF'
%         dirCondition =dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
%     case 'preceeding OFF'
%         dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex);
%     case 'all'
%         dirCondition =true(numTrialsTotal-1,1);
% end

% There should be an option for surrounding saccades. This option only
% makes sense for interpolated data.
options = struct('cells','all','direction','following left','ISI','all','ISIwidth',NaN,'ONdirection',[],'interp2gridThenCat',false,...
    'binTimes',[],'tau','past saccade','binTimesPreceeding',[],'binTimesFollowing',[],'sVelocity',NaN,'sVelConditionCenter',NaN,...
    'sVelConditionWidth',NaN,'verbose',false);
options = parseNameValueoptions(options,varargin{:});


% CHECKING VALUES OF THE OPTIONS--------------------------------------------------------------------
% check if user specificed the direction using ON or OFF. If so, was the
% additional necessary input given
if ~isempty(regexp(options.direction,'ON', 'once'))
    % check user also specified the ON direction
    if isempty(options.ONdirection)
        error('specify the on direction');
    else
        onDirection = options.ONdirection;
    end
elseif ~isempty(regexp(options.direction,'OFF', 'once'))
    % check user also specified the ON direction
    if isempty(options.ONdirection)
        error('specify the on direction');
    else
        onDirection = options.ONdirection;
    end
end

% check if user wants to reference events with respect to time until
directionType = regexp(options.direction,'preceeding','end');
interpSurround = false;
if isempty(directionType)
    directionType = regexp(options.direction,'following','end');
    if isempty(directionType)
        directionType = regexp(options.direction,'surrounding','end');
        if isempty(directionType)
            if ~strcmp(options.direction,'all')
                error('The beginning of `direction` must either be `all` or must start with the word following, preceeding or surrounding');
            end
        else
            interpSurround = true;
        end
    end
end

% check if user properly specified which cells to use
NCells = size(Y,2);
if strcmp(options.cells,'all')
    cellV = 1:NCells;
elseif isnumeric(options.cells)
    cellV = options.cells;
    if max(cellV) > NCells
        error('There are not as many cells in the input as the user wants as specified in `cells`');
    elseif min(cellV) < 1
        error('when specificy `cells` as a vector, the numbers in the vector must be integers within the set 1:size(Y,2)');
    end
else
    error('`cells` must be a string set to `all` or a vector of integers');
end

% check if user specified a condition for ISI
if isnumeric(options.ISI)
    if isnan(options.ISIwidth)
        error('If `ISI` is specified, the width must be given such that only trials where |ISI - options.ISI|<options.ISIwidth are examined');
    elseif ~isnumeric(options.ISIwidth)
        error('`ISIwidth must be a scalar');
    end
    ISI = saccadeTimes(2:end,1) - saccadeTimes(1:end-1,1);
    ISIcondition = abs(ISI-options.ISI)<= options.ISIwidth/2;
    
    if options.verbose
        fprintf('ISI condition is %0.3f <= ISI <= %0.3f\n',options.ISI-options.ISIwidth/2,options.ISI+options.ISIwidth/2)
        fprintf('%d out of %d fixation durations passed\n',sum(ISIcondition),length(ISI))
    end
end

if ~isnan(options.sVelConditionCenter)
    if isnan(options.sVelConditionWidth)
        error('Bin width and center needed to condition on saccade velocity');
    elseif isnan(options.sVelocity)
        error('Need to provide a saccade velocity to condition on this variable');
    end
    sVelCondition = abs(options.sVelocity - options.sVelConditionCenter) <= options.sVelConditionWidth/2;
    
    switch options.direction
        case 'following left'
            error('under construction');
            %dirCondition =dirInPlane{cellIndex}(1:end-1)==1;
        case 'preceeding left'
            error('under construction');
            %dirCondition =dirInPlane{cellIndex}(2:end)==1;
        case 'following right'
            error('under construction');
            % dirCondition =dirInPlane{cellIndex}(1:end-1)==0;
        case 'preceeding right'
            error('under construction');
            %dirCondition =dirInPlane{cellIndex}(2:end)==0;
        case 'surrounding left'
            sVelCondition  = sVelCondition(2:end,1);
        case 'surrounding right'
            sVelCondition  = sVelCondition(2:end,2);
        case 'following ON'
            error('under construction');
            %dirCondition =dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
        case 'preceeding ON'
            error('under construction');
            % dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex);
        case 'following OFF'
            error('under construction');
            % dirCondition =dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
        case 'preceeding OFF'
            error('under construction');
            % dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex);
        case 'all'
            error('under construction');
            %dirCondition =true(numTrialsTotal-1,1);
    end
end

% check if user specified a grid for interpolation if this was desired
if options.interp2gridThenCat
    
    if ~interpSurround
        % did not specify the surrounding condition
        if isempty(options.binTimes)
            error('interpolation desired but no grid specified in `binTimes`');
        else
            binTimes = options.binTimes;
        end
    else
        % surrounding specified. Both a forward and backwards grid must be
        % specified.
        if isempty(options.binTimesPreceeding) || isempty(options.binTimesFollowing)
            error('interpolation surrounding saccade desired but no grid specified in `binTimesPreceeding` AND `binTimesFollowing`');
        else
            binTimesF = options.binTimesFollowing;
            binTimesP = options.binTimesPreceeding;
        end
    end
end
% create saccade-triggered responses--------------------------------------------------------------------
if options.interp2gridThenCat
    
    % add the first point from the previous saccade to each trial so
    % that the interpolation can extend all the way from the time of saccade
    % to the end of fixation. Without this the
    % interpolation will only extend to the gridpoint that comes after
    % the first sampled point in the fixation.
    [STRInPlaneStartm1,timeForSegStartm1,~,absTimeStartm1] = STresponses(Y,saccadeTimes,saccadeDirection,time,'startpoint', ...
        -1.03,'endpoint','all','removeInvalids',false,'useSaccadeDuration',false);
    
    [STRInPlaneStartPastZero,timeForSegPastZero,dirInPlane,absTime] = STresponses(Y,saccadeTimes,saccadeDirection,time,'startpoint', ...
        0,'endpoint','all','removeInvalids',false,'useSaccadeDuration',false);
    
    if (strcmp(options.tau,'past saccade') || interpSurround)
        timeForSegExpand=timeForSegStartm1;
        STRExpand =STRInPlaneStartm1;
        
        for ii=1:length(absTimeStartm1)
            for jj=1:length(absTimeStartm1{ii})-1
                if ~any(isnan(timeForSegStartm1{ii}{jj}))
                    if ~isempty(timeForSegStartm1{ii}{jj+1})
                        if ~isnan(timeForSegStartm1{ii}{jj+1}(1))
                            timeForSegExpand{ii}{jj} = [timeForSegExpand{ii}{jj};timeForSegPastZero{ii}{jj+1}(1) + saccadeTimes(jj+1,1)-saccadeTimes(jj,1)];
                            STRExpand{ii}{jj} = [STRExpand{ii}{jj};STRInPlaneStartPastZero{ii}{jj+1}(1)];
                        end
                    end
                end
            end
        end
        timeForSeg = timeForSegExpand;
        STRInPlane = STRExpand;
    end
else
    [STRInPlaneStartPastZero,timeForSegPastZero,dirInPlane,absTime] = STresponses(Y,saccadeTimes,saccadeDirection,time,'startpoint', ...
        0,'endpoint','all','removeInvalids',false,'useSaccadeDuration',false);
    STRInPlane = STRInPlaneStartPastZero;
    timeForSeg = timeForSegPastZero;
end

if interpSurround
    STRInPlaneFollowing = STRInPlane;
end
% check if user wants to use time with respect to upcoming saccades or
% previous saccades
if strcmp(options.tau,'past saccade') && ~interpSurround
    relTimeCell = timeForSeg;
elseif strcmp(options.tau,'future saccade') || interpSurround
    
    
    if options.interp2gridThenCat
        % construct time relative to upcoming saccade index
        if length(absTimeStartm1{1})< length(saccadeTimes)
            timeRevSeg = constructTimeReverseSegments(absTimeStartm1,saccadeTimes(1:end-1,1));
        else
            timeRevSeg = constructTimeReverseSegments(absTimeStartm1,saccadeTimes(:,1));
        end
        
        % add the first point from the future saccade to each trial so
        % that the interpolation can extend all the way from the previous
        % fixation to the future saccade time. Without this the
        % interpolation will only extend to the gridpoint that comes before
        % the last sampled point before saccade.
        
        timeRevSegExpand=timeRevSeg;
        STRExpand =STRInPlaneStartm1;
        
        for ii=1:length(absTime)
            for jj=1:length(absTime{ii})-1
                if ~any(isnan(timeRevSeg{ii}{jj}))
                    if ~isempty(timeForSegPastZero{ii}{jj+1})
                        if ~isnan(timeForSegPastZero{ii}{jj+1}(1))
                            % 8-30-2019 .. there is some bug with
                            % STresponses where if saccade st(i-1)
                            % occurs earlier than the start point -1.03
                            % from st(i), the output will have the interval startpoint before st(i) to after st(i)
                            % be invalid AND it will artificially create an
                            % interval from st(i-1)-1.03 to st(i+1). The
                            % next if statement
                            % is a fudge to correct for that mistake
                            if ~any(timeRevSegExpand{ii}{jj}>0)
                                timeRevSegExpand{ii}{jj} = [timeRevSegExpand{ii}{jj};timeForSegPastZero{ii}{jj+1}(1)];
                                STRExpand{ii}{jj} = [STRExpand{ii}{jj};STRInPlaneStartPastZero{ii}{jj+1}(1)];
                            end
                        end
                    end
                end
            end
        end
        relTimeCell = timeRevSegExpand;
        STRInPlane = STRExpand;
    elseif interpSurround
        error('interpSurround cannot be true AND interp2gridThenCat false');
    else
        % construct time relative to upcoming saccade index
        if length(absTime{1})< length(saccadeTimes)
            timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(1:end-1,1));
        else
            timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(:,1));
        end
        
        relTimeCell = timeRevSeg;
    end
else
    error('interpSurround must be true or false and there are only two options for `tau` either `past saccade` or `future saccade`');
end

if options.interp2gridThenCat
    if interpSurround
        % interpolation of responses following saccade
        %  [STRInPlaneiF,indexLookUpF] = raggedArray2Matrix(timeForSeg,STRInPlaneFollowing,binTimesF);
        
        neighborTimesFollowing = diff(saccadeTimes(:,1));
        [STRInPlaneiF,indexLookUp] = raggedArray2Matrix(timeForSeg,STRInPlaneFollowing,binTimesF,'endInterpAtNeighboringSaccade',true,...
            'neighborTimes',neighborTimesFollowing);
        % interpolation of responses preceeding saccade
        % [ STRInPlaneiP,indexLookUpP] = raggedArray2Matrix(relTimeCell,STRInPlane,binTimesP);
        
        neighborTimesPreceeding = -neighborTimesFollowing;
        STRInPlaneiP = raggedArray2Matrix(relTimeCell,STRInPlane,binTimesP,'endInterpAtNeighboringSaccade',true,...
            'neighborTimes',neighborTimesPreceeding);
        
        useableIndicesPreceeding = indexLookUp(:,2)<length(STRInPlane{1}); useableIndicesFollowing = indexLookUp(:,2)>1;
        STRInPlanei = [STRInPlaneiP(useableIndicesPreceeding,:) STRInPlaneiF(useableIndicesFollowing,:)];
        
        indexLookUp = indexLookUp(useableIndicesPreceeding,:); %  the STA surround a saccade combines trials by necessity
        %  by convention below (dir(2:end) we effectively use this numbering scheme (1:end-1)
    else
        % interpolate responses
        % [STRInPlanei,indexLookUp] = raggedArray2Matrix(relTimeCell,STRInPlane,binTimes);
        if strcmp(options.tau,'past saccade')
            neighborTimesFollowing = diff(saccadeTimes(:,1));
            [STRInPlanei,indexLookUp] = raggedArray2Matrix(relTimeCell,STRInPlane,binTimes,'endInterpAtNeighboringSaccade',true,...
                'neighborTimes',neighborTimesFollowing);
        else
            neighborTimesPreceeding = -diff(saccadeTimes(:,1));
            [STRInPlanei,indexLookUp] = raggedArray2Matrix(relTimeCell,STRInPlane,binTimes,'endInterpAtNeighboringSaccade',true,...
                'neighborTimes',neighborTimesPreceeding);
            
        end
    end
end


% initialize output variable--------------------------------------------------------------------
nTrialsPassing = zeros(length(cellV),1);
if ~options.interp2gridThenCat
    YOutput = cell(length(cellV),1);
    TOutput = YOutput;
    cnt = 1;
end
trialsCellsUsed=[];
for cellIndex = cellV
    numTrialsTotal = length(STRInPlane{cellIndex});
    switch options.direction
        case 'following left'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==1;
        case 'preceeding left'
            dirCondition =dirInPlane{cellIndex}(2:end)==1;
        case 'following right'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==0;
        case 'preceeding right'
            dirCondition =dirInPlane{cellIndex}(2:end)==0;
        case 'surrounding left'
            dirCondition =dirInPlane{cellIndex}(2:end)==1;
        case 'surrounding right'
            dirCondition =dirInPlane{cellIndex}(2:end)==0;
        case 'following ON'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
        case 'preceeding ON'
            dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex);
        case 'following OFF'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
        case 'preceeding OFF'
            dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex);
        case 'preceeding ON and following ON'
            dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
        case 'preceeding OFF and following ON'
            dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
        case 'preceeding ON and following OFF'
            dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
        case 'preceeding OFF and following OFF'
            dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
        case 'all'
            dirCondition =true(numTrialsTotal-1,1);
    end
    
    behavioralCondition = true(size(dirCondition));
    if isnumeric(options.ISI)
        behavioralCondition = ISIcondition;
        %nTrialsPassing(cellIndex) = sum(dirCondition & ISIcondition); % removed 4/12
    else
        % nTrialsPassing(cellIndex) = sum(dirCondition ); % removed 4/12
    end
    if ~isnan(options.sVelConditionCenter)
        behavioralCondition = behavioralCondition & sVelCondition;
    end
    nTrialsPassing(cellIndex) = sum(dirCondition & behavioralCondition); % added 4/12
    if ~options.interp2gridThenCat
        YOutput{cnt} = cell(nTrialsPassing(cellIndex),1);
        TOutput{cnt} = YOutput{cnt};
        cnt = cnt + 1;
    end
end
if options.interp2gridThenCat
    if interpSurround
        TOutput = [binTimesP(:)' binTimesF(:)'];
        YOutput = NaN(sum(nTrialsPassing),length(TOutput));
    else
        YOutput = NaN(sum(nTrialsPassing),length(binTimes));
        TOutput = binTimes;
    end
end

% set output variable--------------------------------------------------------------------
    
cnt1 = 1;cnt = 1;
for cellIndex = cellV
    numTrialsTotal = length(STRInPlane{cellIndex});
    trials2useIndexOffset = 0;
    switch options.direction
        case 'following left'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==1;
        case 'preceeding left'
            dirCondition =dirInPlane{cellIndex}(2:end)==1;
            trials2useIndexOffset = 1;
        case 'following right'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==0;
        case 'preceeding right'
            dirCondition =dirInPlane{cellIndex}(2:end)==0;
            trials2useIndexOffset=1;
        case 'surrounding left'
            dirCondition =dirInPlane{cellIndex}(2:end)==1;
            trials2useIndexOffset=1;
        case 'surrounding right'
            dirCondition =dirInPlane{cellIndex}(2:end)==0;
        case 'following ON'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
        case 'preceeding ON'
            dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex);
            trials2useIndexOffset=1;
        case 'following OFF'
            dirCondition =dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
        case 'preceeding OFF'
            dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex);
            trials2useIndexOffset=1;
        case 'preceeding ON and following ON'
            dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
            trials2useIndexOffset=1;
        case 'preceeding OFF and following ON'
            dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==onDirection(cellIndex);
            trials2useIndexOffset=1;
        case 'preceeding OFF and following OFF'
            dirCondition =dirInPlane{cellIndex}(2:end)==~onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
            trials2useIndexOffset=1;
        case 'preceeding ON and following OFF'
            dirCondition =dirInPlane{cellIndex}(2:end)==onDirection(cellIndex) & dirInPlane{cellIndex}(1:end-1)==~onDirection(cellIndex);
            trials2useIndexOffset=1;
        case 'all'
            dirCondition =true(numTrialsTotal-1,1);
    end
    % if isnumeric(options.ISI) % removed adr 4/12
    %  trials2useBool = (dirCondition & ISIcondition);
    %else
    % trials2useBool =  (dirCondition );
    % end
    trials2useBool = (dirCondition & behavioralCondition);
    trials2useIndices = find(trials2useBool) ;
    trialsCellsUsed = [trialsCellsUsed;[repmat(cellIndex,length(trials2useIndices),1) saccadeTimes(trials2useIndices,1)]];
    
    cnt2 = 1;
    for trialIndex = find(trials2useBool)'
        if options.interp2gridThenCat
            yy = STRInPlanei(indexLookUp(:,1)==cellIndex & indexLookUp(:,2)==trialIndex , :);
            YOutput(cnt,:) = yy;
        else
            YOutput{cnt1}{cnt2} = STRInPlane{cellIndex}{trialIndex};
            TOutput{cnt1}{cnt2} = relTimeCell{cellIndex}{trialIndex};
        end
        
        cnt2 = cnt2 + 1;
        cnt = cnt + 1;
    end
    cnt1 = cnt1 + 1; % adr added 4/11/2018. Leaving this out felt like a bug.
end
if options.verbose
        fprintf('Condition on saccade direction is duration must occur %s\n',options.direction)
        fprintf('%d out of %d fixation durations passed\n',sum(dirCondition & behavioralCondition),sum(behavioralCondition))
end
end


