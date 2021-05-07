function [cutData,timeSegments,intervalBefore,intervalAfter,usableInt,absTimeSegments] = saccadeTrigCut2(data,triggerPoints,startPoint,endPoint,varargin)
%saccadeTrigCut2 is created from saccadeTrigCut and only involves 2 changes.
%  CHANGE 1
%   The cutData ouptut in saccadeTrigCut.m only returns segments of data that are of the size specified by startPoint and endPoint. 
%   For example, cutData will exclude a fixation that only lasts for 5 seconds and
%   endPoint is 10 since it is not possible to return a 10 second size
%   segment of data from this fixation. Or cutData will exclude a fixation that lasts for 10
%   seconds but the previous fixation lasts for 3 seconds, startPoint is -10
%   and endPoint is 10 since it is not possible to return a segment that extends 10 seconds before
%   fixation. These types of restrictions are helpful for making saccade
%   triggered averages.
%       saccadeTrigCut2 changes the restriction on endPoints to return segments of data that are less than or equal to the sizes 
%   specified by endPoint. This means that the first example given above
%   would have passed. This is helpful for looking at a portion of data
%   after a saccade. 
%   
%       Both codes probably have a bug on the restriction on startPoint. If
%       startPoint is say 5 and the fixation lasts 3 seconds, both programs
%       will still try and use this interval even though it is impossible. 
%
%  CHANGE 2 
%       triggerPoints is no longer an Mx2 matrix. It is a p dimensional
%       cell array with each cell containing Mx2 matrices of trigger start, triggerPoints{m}(:,1), and trigger stop
%               points, triggerPoints{m}(:,2).  
%   
% 
% 
%
%[cutData,timeSegments,intervalBefore,intervalAfter,usableInt] = saccadeTrigCut2(data,triggerPoints,startPoint,endPoint)
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
%       triggerPoints - seeabove
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
intervalBefore = cell(1,dataDim);
intervalAfter = cell(1,dataDim);
usableInt = cell(1,dataDim);
if isempty(triggerPoints{1}) && isempty(triggerPoints{2})
    return
end
for dim=1:dataDim
    intervalBefore{dim} = zeros(size(triggerPoints{dim},1),1);
    intervalAfter{dim} = zeros(size(triggerPoints{dim},1),1);
    usableInt{dim} = false(size(triggerPoints{dim},1),1);
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
    properTriggerSegment = unitPoints(1)<=triggerPoints{dim}(:,1) & unitPoints(end)>= triggerPoints{dim}(:,2);
    
    % compute saccade durations as trigger stop minus trigger start------
    saccDur = diff(triggerPoints{dim},[],2);
    saccDur = saccDur(properTriggerSegment);
    % interval before each saccade including saccade duration if
    % unitPoints(1) < triggerPoints(1,1);
    ivalBfrePlusSaccDur = diff([unitPoints(1);triggerPoints{dim}(properTriggerSegment,1)]);
    % interval after each saccade including saccade duration if 
    % unitPoints(end) > triggerPoints(end,1)
    ivalAftrPlusSaccDur = diff([triggerPoints{dim}(properTriggerSegment,1);unitPoints(end)]);
    intervalBefore{dim}(properTriggerSegment) = -(ivalBfrePlusSaccDur - [0;saccDur(1:end-1)]);
 %   intervalAfter(properTriggerSegment,dim) = ivalAftrPlusSaccDur - saccDur;
    intervalAfter{dim}(properTriggerSegment) = ivalAftrPlusSaccDur ;
    % ------
    % check which intervals before trigger-start pass
    if ~ischar(startPoint)
        usableIntBefore = intervalBefore{dim}(properTriggerSegment) <= startPoint;
    else
        % by assumption ALL pass
        usableIntBefore = true(size(triggerPoints{dim}(properTriggerSegment,:),1),1);
    end
    % check which intervals after trigger-end pass
    %if ~ischar(endPoint)
    %    usableIntAfter = intervalAfter(properTriggerSegment,dim) >= endPoint;
    %else
        usableIntAfter = true(size(triggerPoints{dim}(properTriggerSegment,:),1),1);
    %end
    usableInt{dim}(properTriggerSegment) = usableIntBefore & usableIntAfter;
    numberUsable = sum(usableInt{dim});
    % ------
    
    % only keep saccades that pass constraints
    usableTriggerPoints = triggerPoints{dim}(usableInt{dim},:);
    cutData{dim} = cell(numberUsable,1);
    timeSegments{dim} = cell(numberUsable,1);
    absTimeSegments{dim} = cell(numberUsable,1);
     for sacNumInd=1:numberUsable
        % compute start, stop and cut points in user-inputed units  
        triggerPoint = usableTriggerPoints(sacNumInd,:);
        
        % start time
        if ~ischar(startPoint)
            cutStart = triggerPoint(1) + startPoint;
            % translate this time into indices
            [~,cutStarti] = min(abs(unitPoints-cutStart));
            
        else
            if sacNumInd > 1
                cutStart = usableTriggerPoints(sacNumInd-1,2);
            else
                cutStart = unitPoints(1);
            end
            % translate this time into indices
            [~,cutStarti] = min(barrier(unitPoints-cutStart,0,Inf));
        end
        
        % stop time
        if ~ischar(endPoint) && intervalAfter{dim}(sacNumInd) >= endPoint
                cutStop = triggerPoint(1) + endPoint;
    
            % translate this time into indices
            [~,cutStopi] = min(abs(cutStop-unitPoints));
        else
            if sacNumInd ~= numberUsable
                cutStop = usableTriggerPoints(sacNumInd+1,1);
            else
                cutStop = unitPoints(end);
            end
            % translate this time into indices
            [~,cutStopi] = min(barrierALEX(cutStop-unitPoints,0,Inf));
        end
        
        
        window = cutStarti:cutStopi;
        if removeSacDuration
            % determine trigger points in terms of sample number
            [~,tstart] = min(barrier(triggerPoint(1)-unitPoints,0,Inf));
            [minval,tstop] = min(barrier(unitPoints-triggerPoint(2),0,Inf));
            if isinf(minval)
                tstop = length(unitPoints)+1;
            end
            window = [cutStarti:tstart tstop:cutStopi];
        end
        % cut segment out
        cutData{dim}{sacNumInd} = data(window,dim);
        timeSegments{dim}{sacNumInd} = unitPoints(window)-triggerPoint(1);
        absTimeSegments{dim}{sacNumInd} = unitPoints(window);
    end
end

