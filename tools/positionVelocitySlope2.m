function [pvRegresionCoef,position,velocity,time,positionArray,timeArray,abstime,positionNobin,cutData,timeSegments,absTimeSeg] = positionVelocitySlope2(position,time,trigPoint,varargin)
%    The function of positionVelocitySlope in eyeData has largely been replaced by the plotSegments method. Since writing plotSegments, 
%    I have mainly used this code as a way of calling saccadeTrigCut2 function to pull out cutData, timeSegments, absTimeSeg output.
%    For a long time this was fine. Now I need to call saccadeTrigCut2 in a manner that allows for disconjugate saccades.
%    positionVelocitySlope was not compatible with this. I image the
%    pvregression method is also not compatiable with this.
%    positionVelocitySlope2 spits out garbage values that are of proper types and sizes for everything but the
%    cutData, timeSegments, absTimeSeg column.  
%            Some day I intend to clean this up. The value of positionVelocitySlope is that is has 
%            code for calculating position and velocity slopes using a binning/averaging method and using a 
%            kalman filtering method. Some day I hope to restructure the
%            function calls so that only one function is used for
%            calculating position and velocity slopes. 
%            adr-2/10/2016
%      
%   
% 
% positionVelocitySlope - regression coefficient for eye position vs velocity
%      Computes the regression coefficients for a regression of position (independent variable)
%      vs. velocity.
% [pvRegresionCoef,position,velocity] = positionVelocitySlope(position,time,trigPoint)
%      INPUT:
%               position - Nxp matrix of positions, where N and p are integers equal to the
%                      number of samples and number of dimensions(p=2 for eye traces).
%               time - Nxp matrix of sampling times
%               trigPoint - Mx2 matrix of trigger points specifying position regions to neglect, where M is an integer
%                           specifying the number of trigger points. These are saccade start and stop times
%                           for eye position position. It assumed that all p variables
%                           have the same trigger points. trigPoint(:,1) gives the
%                           start of the regions we neglect and trigPoint(:,2) gives the
%                           end of the regions we neglect. These must be specified in the same units as time.
%      OUTPUT:
%             pvRegressionCoef  - px1 matrix of regression coefficients
%             position - Wxp matrix of position traces used to compute
%                        regression coeffcient. W equals N minus total
%                        number of samples cut by the trigger points
%                        specification.
%             velocity - Wxp matrix of velocity traces used to compute
%                        regression coeffcient.
%
% algorithm:
%   - parse inputs:
%       - velocity selection algorithm and kalman smoother parameter(todo)
%
%   - segment eye position traces by saccade times
%
%   - use a kalman smoother to estimate velocity
%           use a median filter as a crude state estimate and assume the
%           tracking algorithm has a standard deviation of 1/2 a degree
%   - calculate regression coefficient
%
% Hidden parameters:
%   1.) filter order for the median filter
%   2.) both variances for the Kalman filter, intial mean and variance of
%   position/velocity for Kalman filter.


% - parse inputs
options = struct('binData',true,'startSegment',1,'stopSegment',5,'binTime',0.1);
options = parseNameValueoptions(options,varargin{:});
[Tbig,p]=size(position);
pvRegresionCoef = zeros(p,1);
options.binTime=0.1;
if options.binData
    if 1
        % 10/2/2015 -- everything in the else statement of this
        % conditional is what was functioning for the previous analyses
        % I had presented at Cosyne and data presentations
        % As far as I can tell, I didn't used the Kalman filter
        % and I didn't segment the data according to saccades before binning
        % I'm adding scripts to segement the data according to saccades
        
        [cutData,timeSegments,~,~,~,absTimeSeg] = saccadeTrigCut2(position,trigPoint,options.startSegment,options.stopSegment,time);
        identicalPoints = false;
        if ~isempty(trigPoint{1})
            if size(trigPoint{1},1) == size(trigPoint{2},1)
                identicalPoints = sum(trigPoint{1}(:,1) - trigPoint{2}(:,1)) == 0;
            end
        end
        % remove any empty cells
        cutDataTemp = cell(2,1);
        timeSegTemp = cell(2,1);
        absTimeSegTemp = cell(2,1);
        for eyeInd=1:2
            %   - segment eye position traces by saccade times
            
            if ~isempty(cutData{eyeInd})
                cutDataTemp{eyeInd} = cell(1,1);
                timeSegTemp{eyeInd} = cell(1,1);
                absTimeSegTemp{eyeInd} = cell(1,1);
                cnt = 1;
                for segInd =1:length(absTimeSeg{eyeInd})
                    if isempty(cutData{eyeInd}{segInd})
                        %  'stop here'
                    else
                        cutDataTemp{eyeInd}{cnt} = cutData{eyeInd}{segInd};
                        timeSegTemp{eyeInd}{cnt} = timeSegments{eyeInd}{segInd};
                        absTimeSegTemp{eyeInd}{cnt} = absTimeSeg{eyeInd}{segInd};
                        cnt = cnt+1;
                    end
                end
            end
        end
        cutData = cutDataTemp;
        timeSegments = timeSegTemp;
        absTimeSeg = absTimeSegTemp;
        % bin and then combine segments-------
        position = [];
        positionNobin = [];
        time = [];
        abstime = [];
        velocity = [];
        % find out how many useful segments we have
        nuseful = 0;
        eyeInd = 1;
        for segInd =1:length(absTimeSeg{eyeInd})
            if 0
                % smart way not compatible with plot binner
                totalSegmentTime = timeSegments{eyeInd}{segInd}(end)-timeSegments{eyeInd}{segInd}(1);
                binCenterTimes = [options.binTime/2:options.binTime:totalSegmentTime];
                numBins = length(binCenterTimes);
                if numBins>2
                    nuseful = nuseful + 1;
                end
            end
            if ~isempty(timeSegments{eyeInd}{segInd})
                if timeSegments{eyeInd}{segInd}(end)>options.stopSegment - options.startSegment | ischar(options.stopSegment) | ischar(options.startSegment)
                    segmentLength = length(cutData{eyeInd}{segInd});
                    samplingTimeIntervals = diff(timeSegments{eyeInd}{segInd});
                    medianSamplingTime = median(samplingTimeIntervals);
                    binInt = round(options.binTime/medianSamplingTime);
                    binCenters = [0+round(binInt/2):binInt:segmentLength-round(binInt/2)];
                    if numel(binCenters)>2
                        nuseful = nuseful + 1;
                    end
                end
            end
        end
        positionArray = cell(nuseful,p);
        timeArray = cell(nuseful,p);
        
        for eyeInd=1:p
            usefulSegCounter = 1;
            combinedBinnedSingleEyeIndPos = [];
            combinedSingleEyeIndPos = [];
            combinedBinnedSingleEyeIndTime = [];
            combinedBinnedSingleEyeIndAbsTime = [];
            combinedBinnedSingleEyeIndVel = [];
            for segInd =1:length(absTimeSeg{eyeInd})
                % necessary condition for analyzing segments that are of
                % the proper size. This condition is not sufficient.
                % Inhomogenous sampling can result in a long fixation
                % interval only sampled with too few points to estimate
                % velocity
                if 0
                    totalSegmentTime = timeSegments{eyeInd}{segInd}(end)-timeSegments{eyeInd}{segInd}(1);
                    binCenterTimes = [options.binTime/2:options.binTime:totalSegmentTime];
                    numBins = length(binCenterTimes);
                    binCenters = zeros(numBins,1);
                    for centerIndex =1 :numBins
                        [~,binCenters(centerIndex)] = min(abs(timeSegments{eyeInd}{segInd}-timeSegments{eyeInd}{segInd}(1)-binCenterTimes(centerIndex)));
                    end
                end
                if ~isempty(timeSegments{eyeInd}{segInd})
                
                if timeSegments{eyeInd}{segInd}(end)>options.stopSegment - options.startSegment  | ischar(options.stopSegment) | ischar(options.startSegment)
                    %
                    segmentLength = length(cutData{eyeInd}{segInd});
                    samplingTimeIntervals = diff(timeSegments{eyeInd}{segInd});
                    medianSamplingTime = median(samplingTimeIntervals);
                    binInt = round(options.binTime/medianSamplingTime);
                    binCenters = [0+round(binInt/2):binInt:segmentLength-round(binInt/2)];
                    if numel(binCenters)>2
                        binob = plotBinner([[1:segmentLength]' cutData{eyeInd}{segInd}],binCenters);
                        binobTime = plotBinner([[1:segmentLength]' timeSegments{eyeInd}{segInd}],binCenters);
                        binnedPos=binob.binData;
                        binnedTime = binobTime.binData;
                        binnedVelocity = diff(binnedPos)./diff(binnedTime);
                        
                        combinedBinnedSingleEyeIndPos =[ combinedBinnedSingleEyeIndPos ;binnedPos(1:end-1)];
                        combinedSingleEyeIndPos =[ combinedSingleEyeIndPos ;cutData{eyeInd}{segInd}];
                        combinedBinnedSingleEyeIndTime =[ combinedBinnedSingleEyeIndTime ;binnedTime(1:end-1)];
                        combinedBinnedSingleEyeIndAbsTime =[ combinedBinnedSingleEyeIndAbsTime ;absTimeSeg{eyeInd}{segInd}];
                        combinedBinnedSingleEyeIndVel =[ combinedBinnedSingleEyeIndVel ;binnedVelocity];
                        
                        positionArray{usefulSegCounter,eyeInd} = binnedPos;
                        timeArray{usefulSegCounter,eyeInd} = binnedTime;
                        usefulSegCounter = usefulSegCounter +1;
                    end
                    %plot(absTimeSeg{eyeInd}{segInd},cutData{eyeInd}{segInd},'ko')
                end
                end
            end
            
            % these quantities need to be cell arrays 
            % to handle disconjugate saccades
           if  identicalPoints
            position =[position  combinedBinnedSingleEyeIndPos];
            positionNobin =[positionNobin  combinedSingleEyeIndPos];
            time =[time combinedBinnedSingleEyeIndTime];
            abstime =[abstime combinedBinnedSingleEyeIndAbsTime];
            velocity = [velocity combinedBinnedSingleEyeIndVel];
           end
        end
        % end bin and combine-----
        try
            if ~isempty(position)
                covariates=[ones(size(position,1),1) position];
                CoefWoffset = pinv(covariates)*velocity;
                pvRegresionCoef(eyeInd) =CoefWoffset(2);
            else
                pvRegresionCoef = [];
            end
        catch me
            me
            keyboard
        end
        % end 10/2/2015 modification-----
    else
        if Tbig > 50
            binCenters = [1:10:Tbig];
            velocity = zeros(length(binCenters)-1,2);
            binnedPos = zeros(length(binCenters),2);
            binnedTime= binnedPos;
            for eyeInd=1:2
                binob = plotBinner([[1:Tbig]' position(:,eyeInd)],binCenters);
                binnedData=binob.binData;
                try
                    velocity(:,eyeInd) = diff(binnedData)./mean(diff(time(binCenters,eyeInd)));
                    binnedPos(:,eyeInd)=binnedData;
                    binnedTime(:,eyeInd) = time(binCenters,eyeInd);
                    
                    covariates=[ones(size(binnedTime(:,eyeInd))) binnedPos(:,eyeInd)];
                    CoefWoffset = pinv(covariates(1:end-1,:))*velocity(:,eyeInd);
                    pvRegresionCoef(eyeInd) =CoefWoffset(2);
                catch me
                    me
                    keyboard
                end
            end
            position = binnedPos(1:end-1,:);
            time = binnedTime(1:end-1,:);
            notSaccades = abs(velocity)<=3;
            notSaccades = notSaccades(:,1) & notSaccades(:,2);
            position = position(notSaccades,:);
            velocity = velocity(notSaccades,:);
            time = time(notSaccades,:);
        else
            position = [];
            velocity = [];
            time = [];
        end
    end
else
    
    
    
    %   - segment eye position traces by saccade times
    %options.startSegment = 0; % don't cut before saccade time
    %options.stopSegment = 'all';  % take the entire inter-saccade interval
    cutSacDur = true;  % don't include saccadeDuration in PV plot
    endPointTrim = 5;
    
    % kalman filter paramters
    transitionMatrix = [[1 0];[0 1]];
    C = [1 0];
    R = (0.5)^2;
    filterOrder = 1; % in seconds;
    
    % segment the position
     [cutData,timeSegments,~,~,~,absTimeSeg] = saccadeTrigCut(position,trigPoint,options.startSegment,options.stopSegment, ...
        time,cutSacDur);
    % initialize position and velocity
    W = zeros(1,p);
    for eyeInd = 1:p
        for segmentInd = 1:length(cutData{eyeInd})
            dt = median(diff(timeSegments{eyeInd}{segmentInd}));
            % filter order in terms of samples
            fOSamples = round(filterOrder/dt);
            T = length(cutData{eyeInd}{segmentInd}) - endPointTrim;
            if T>=2*fOSamples && fOSamples>0
                W(eyeInd) = W(eyeInd) + T;
            end
        end
    end
    if any(W~=W(1))
        error('saccadeTrigCut is buggy:all dimensions should have the same total number of segmented points');
    end
    position = zeros(W(1),p);
    velocity = zeros(W(1),p);
    time =  zeros(W(1),p);
    if W(1)>0
        for eyeInd = 1:p
            stateEst = []; % running total of position and velocity
            timeSegs = [];
            for segmentInd = 1:length(cutData{eyeInd})
                %   - median filter the segment to estimate true position
                dt = median(diff(timeSegments{eyeInd}{segmentInd}));
                % filter order in terms of samples
                fOSamples = round(filterOrder/dt);
                T = length(cutData{eyeInd}{segmentInd})-endPointTrim;
                if T>=2*fOSamples && fOSamples>0
                    
                    filtPositionSegment = medfilt1(cutData{eyeInd}{segmentInd},fOSamples);
                    filtPositionSegment(1) = cutData{eyeInd}{segmentInd}(1);
                    % kalman filter paramters that depend on the segment
                    b = zeros(2,T-1);
                    transitionMatrix(1,2) = dt;
                    position0 = filtPositionSegment(1);
                    % local constant velocity model
                    velocity0 = (filtPositionSegment(min(fOSamples*2,T))-filtPositionSegment(1))/(timeSegments{eyeInd}{segmentInd}(min(2*fOSamples,T))-timeSegments{eyeInd}{segmentInd}(1));
                    x0 = [position0;velocity0];
                    % maximum likelihood estimate under strong assumptions for
                    % position ...
                    % change if I think of something better
                    % Also assume position and velocity have the same noise
                    % variance since we don't have a good estimate of the velocity
                    Q = eye(2)*(1/(T-1))*sum((filtPositionSegment(2:end)-(filtPositionSegment(1:end-1) +dt*velocity0)).^2);
                    P0 = Q;
                    % we have little confidence in our prior over the initial point
                    % .. so let's place a large variance on this point
                    P0(2,2) = range(cutData{eyeInd}{segmentInd})^2;
                    
                    
                    % kalman filter estimate of velocity and position
                    [~,stateEstSeg] = kalmansmooth(transitionMatrix,b,C,Q,R,x0,P0,reshape(cutData{eyeInd}{segmentInd}(1:T),[1,1,T]));
                    stateEstSeg = squeeze(stateEstSeg); % position (stateEstSeg(1,:)) and velocity (stateEstSeg(2,:) estimates
                    stateEst = [stateEst stateEstSeg];
                    
                    timeSegs = [timeSegs;absTimeSeg{eyeInd}{segmentInd}(1:T)];
                end
            end
            %   - calculate regression coefficient
            nsamples = size(stateEst,2);
            
            % CoefWoffset = pinv([ones(nsamples,1) stateEst(2,:)'])*stateEst(1,:)';
            % I trust the variance estimate from the position signal more than
            % the velocity signal, therefore in the linear regression use the
            % position as the dependent variable
            CoefWoffset = pinv([ones(nsamples,1) stateEst(1,:)'])*stateEst(2,:)';
            
            pvRegresionCoef(eyeInd) =CoefWoffset(2);
            position(:,eyeInd) = stateEst(1,:);
            velocity(:,eyeInd) = stateEst(2,:);
            
            time(:,eyeInd) = timeSegs;
        end
    end
end
end

