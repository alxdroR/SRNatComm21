function [cutData,timeSegments,intervalBefore,intervalAfter,usableInt,absTimeSegments] = saccadeTrigCut(data,triggerPoints,startPoint,endPoint,varargin)
%saccadeTrigCut returns data segments cut from input
%
%[cutData,timeSegments,intervalBefore,intervalAfter,usableInt] = saccadeTrigCut(data,triggerPoints,startPoint,endPoint)
%   Segment samples in data into intervals around triggerPoints input.
%
%                                         (. triggerPoint(1,2)=13) . . (. stopPoint=3)
%                                       .
%                                     .
%  . . . . . (. startPoint =4)  . . . (. triggerPoint(1,1)=10)
%
%  Segment interval is specified according
%   to startPoint and endPoint relative to triggerPoints. triggerPoints, startPoint and endPoint must all be in the same units.
%   trigger points and sampling rate is assumed to be uniform and equal for all data inputs.
% INPUT:
%       data - Nxp data matrix whose p columns will be sectioned according to
%              triggerPoints. N is the number of samples
%       triggerPoints - Mx2 matrix of trigger start, triggerPoints(:,1), and trigger stop
%               points, triggerPoints(:,2).  It is assumed that each column
%               is sectioned according to the same trigger points.
%       startPoint = scalar double or character
%                   point to start relative to triggerPoints. Specify as a
%                   string ('all') if user wants to cut the entire interval
%                   before each trigger point.
%       endPoint = scalar double or character
%                   point to end relative to triggerPoints. Specify as a
%                   string ('all') if user wants to cut the entire interval
%                   after each trigger point. If a scalar, endPoint must be greater than
%                   startPoint.
% OUTPUT
%      cutData{i}{j} - jth data segment for the ith column of data. For example, if data is from an eyeData object then
%                       data(:,1) represents left eye movements and
%                       data(:,2) represents right eye movements.  In this
%                       case cutData{1}{j} would be a segment from the left
%                       eye and cutData{2}{j} would be a segment from the
%                       right eye
%[cutData,timeSegments,intervalBefore,intervalAfter,usableInt] = saccadeTrigCut(data,triggerPoints,startPoint,endPoint,unitTime)
%   Allow user to specify sample times for each data dimension.  If
%   unitTime is a scalar, it is assumed that this gives the unit/sample
%   conversion factor for all uniformly sampled data segments.  unitTime
%   can be a vector which allows the algorithm to deal with non-uniformly sampled data.
%   unitTime can also be a matrix which allows for each data column to be
%   sampled both non-uniformly and at different times
%
% [cutData,timeSegments,intervalBefore,intervalAfter,usableInt] = saccadeTrigCut(data,triggerPoints,startPoint,endPoint,unitTime,cutSacDuration)
%   Boolean variable that allows the option of removing portions of the cut
%   data corresponding to the trigger duration. Default is to keep this
%   portion in the cut segments.
%
% Example: cutting out a portion of random 2D, non-uniformly sampled data
%       t = [ [0 1 1.1 1.3 1.4 1.5 3 4 8 9 10]' [0:10]'];
%       data = rand(11,1);
%       data = [data data];
%       triggerPoints = [2.0 3.0];
%       startPoint = -1;
%       endPoint = 4;
%      [cutData,tSeg] =  saccadeTrigCut(data,triggerPoints,startPoint,endPoint,t);
%  The interval we have specified is [ triggerPoints(1)+startPoint, triggerPoints(1)+endPoint]
%  For a more detailed example and to verify that this code works, see the
%  script verifySaccadetrigCut
%
% see also verifySaccadeTrigCut

%
% algorithm:
%       - parse inputs
%       - determine which saccade points satisfy the constraints implicitly
%         specified by startPoint and endPoint
%      -  compute start, stop and cut points in user-inputed units
%      -  compute these times in terms of indices
%      -  cut data
% parse input to determine units and number of dimensions and saccade
% duration removal

options = struct('removeInvalids',true,'useSaccadeDuration',false); % changing this option to a defaul value of false 3/22/2018; adr
options = parseNameValueoptions(options,varargin{:});

[numDataSamp,dataDim] = size(data);
removeSacDuration = false;
if ~isempty(varargin)
    unitTime = varargin{1};
    if length(varargin)>1
        removeSacDuration = varargin{2};
    end
else
    unitTime = 1;
end
if ~isscalar(unitTime)
    [~,uTdim] = size(unitTime);
    if uTdim ~= dataDim && uTdim ~= 1
        error('if unit time is not a scalar, it must contain the same number of columns as input data or one');
    end
else
    unitPoints = [0:numDataSamp-1]'*unitTime;
end
% initialize cut data
cutData = cell(1,dataDim);
timeSegments = cutData;
absTimeSegments = cutData;

if isempty(triggerPoints)
    return
else
    numTriggerPoints = size(triggerPoints,1);
end
intervalBefore = zeros(numTriggerPoints,dataDim);
intervalAfter = zeros(numTriggerPoints,dataDim);
usableInt = false(numTriggerPoints,dataDim);

for dim=1:dataDim
    % ------------------------------------------------------------------------------
    %       - determine which saccade points satisfy the constraints implicitly
    %         specified by startPoint and endPoint
    %
    % a saccade point can be used if: 1.) the interval before it, negative by convention,
    % is larger (more negative) than the startPoint. 2.) the intervals
    % after it are larger than (positive) endPoints. In cases where startPoint
    % or endPoint is a character equal to 'all', this condition is fufilled by
    % assumption
    
    
    if uTdim == dataDim
        % in this case each dimension can have its own non-uniform sampling times
        % and we must retrieve the sampling times for dimension dim
        unitPoints = unitTime(:,dim);
    end
    % find out if any triggerPoints start before data start time
    % or if they end after data stops
   % properTriggerSegment = unitPoints(1)<=triggerPoints(:,1) & unitPoints(end)>= triggerPoints(:,2);
    % I know longer try and estimate the saccade duration so triggerPoints(:,2) no longer has meaning 
    % adr - 3/22/2018 
    properTriggerSegment = unitPoints(1)<=triggerPoints(:,1) & unitPoints(end)>= triggerPoints(:,1);
    
    % compute saccade durations as trigger stop minus trigger start------
    saccDur = diff(triggerPoints,[],2);
    saccDur = saccDur(properTriggerSegment);
    % interval before each saccade including saccade duration if
    % unitPoints(1) < triggerPoints(1,1);
    
    ivalBfrePlusSaccDur = diff([unitPoints(1);triggerPoints(properTriggerSegment,1)]);
    % interval after each saccade including saccade duration if
    % unitPoints(end) > triggerPoints(end,1)
    ivalAftrPlusSaccDur = diff([triggerPoints(properTriggerSegment,1);unitPoints(end)]);
    if options.useSaccadeDuration
        intervalBefore(properTriggerSegment,dim) = -(ivalBfrePlusSaccDur - [0;saccDur(1:end-1)]);
    else
        intervalBefore(properTriggerSegment,dim) = -ivalBfrePlusSaccDur;
    end
    %   intervalAfter(properTriggerSegment,dim) = ivalAftrPlusSaccDur - saccDur;
    intervalAfter(properTriggerSegment,dim) = ivalAftrPlusSaccDur ;
    % ------
    % check which intervals before trigger-start pass
    if ~ischar(startPoint)
        usableIntBefore = intervalBefore(properTriggerSegment,dim) <= startPoint;
    else
        % by assumption ALL pass
        usableIntBefore = true(size(triggerPoints(properTriggerSegment,:),1),1);
    end
    % check which intervals after trigger-end pass
    if ~ischar(endPoint)
        usableIntAfter = intervalAfter(properTriggerSegment,dim) >= endPoint;
    else
        usableIntAfter = true(size(triggerPoints(properTriggerSegment,:),1),1);
    end
    usableInt(properTriggerSegment,dim) = usableIntBefore & usableIntAfter;
    numberUsable = sum(usableInt(:,dim));
    % ------
    % somewhere up there
    if options.removeInvalids
        cutData{dim} = cell(numberUsable,1);
        timeSegments{dim} = cell(numberUsable,1);
        absTimeSegments{dim} = cell(numberUsable,1);
    else
        cutData{dim} = cell(numTriggerPoints,1);
        timeSegments{dim} = cell(numTriggerPoints,1);
        absTimeSegments{dim} = cell(numTriggerPoints,1);
    end
    % only keep saccades that pass constraints
    usableTriggerPoints = triggerPoints(usableInt(:,dim),:);
    sacNumInd=1;
    %for sacNumInd=1:numberUsable
    for triggerIndex = 1 : numTriggerPoints
        if usableInt(triggerIndex,dim)
            % compute start, stop and cut points in user-inputed units
            triggerPoint = usableTriggerPoints(sacNumInd,:);
            
            % start time
            if ~ischar(startPoint)
                cutStart = triggerPoint(1) + startPoint;
                % translate this time into indices
                % [~,cutStarti] = min(abs(unitPoints-cutStart));
                % we don't want to use the abs(diff) because we want
                % to exclude times below the specified starting point
                % (6/30-adr)
                [~,cutStarti] = min(barrierALEX(unitPoints-cutStart,0,Inf));
                
            else
                if sacNumInd > 1
                    cutStart = usableTriggerPoints(sacNumInd-1,2);
                else
                    cutStart = unitPoints(1);
                end
                % translate this time into indices
                [~,cutStarti] = min(barrierALEX(unitPoints-cutStart,0,Inf));
            end
            
            % stop time
            if ~ischar(endPoint)
                cutStop = triggerPoint(1) + endPoint;
                % translate this time into indices
                %[~,cutStopi] = min(abs(cutStop-unitPoints));
                [~,cutStopi] = min(barrierALEX(cutStop-unitPoints,0,Inf));
            else
                if sacNumInd ~= numberUsable
                    cutStop = usableTriggerPoints(sacNumInd+1,1);
                    % translate this time into indices
                    [~,cutStopi] = min(barrierALEX(cutStop-unitPoints,0,Inf));
                else
                    cutStop = unitPoints(end);
                    cutStopi = length(unitPoints); % added this line and moved the min(barrier..) line to only be used in the other case. adr 3/22/2018
                end
                
            end
            
            
            window = cutStarti:cutStopi;
            if removeSacDuration
                % determine trigger points in terms of sample number
                [~,tstart] = min(barrierALEX(triggerPoint(1)-unitPoints,0,Inf));
                [minval,tstop] = min(barrierALEX(unitPoints-triggerPoint(2),0,Inf));
                if isinf(minval)
                    tstop = length(unitPoints)+1;
                end
                window = [cutStarti:tstart tstop:cutStopi];
            end
            % cut segment out
            if options.removeInvalids
                index = sacNumInd;
            else
                index = triggerIndex;
            end
            cutData{dim}{index} = data(window,dim);
            timeSegments{dim}{index} = unitPoints(window)-triggerPoint(1);
            absTimeSegments{dim}{index} = unitPoints(window);
            sacNumInd = sacNumInd+1;
        elseif ~options.removeInvalids
            cutData{dim}{triggerIndex} = NaN;
            timeSegments{dim}{triggerIndex} = NaN;
            absTimeSegments{dim}{triggerIndex} = NaN;
        end
    end
end

