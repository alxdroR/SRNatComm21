function [pvRegresionCoef,segmentedPosition,segmentedVelocity,segmentedTime,...
    segmentedPositionArray,segmentedTimeArray,pvRegresionCoefExtra,...
    segmentedAbsTime,segmentedPositionNobin,segmentedPositionArray2,segmentedTimeArray2,...
    segmentedAbsTimeArray] = pvregression(eyeobj,varargin)
% [pvRegresionCoef,segmentedPosition,segmentedVelocity,segmentedTime] = pvregression(eyeobj)
% pvregression - return the regression coefficient for eye
% position vs velocity (ignoring saccades)
% combined across all planes. Ignores monocular saccades
% and saccades where one eye moves sooner than the other.
%     velocity is determined by making multiple calls to the
% positionVelocitySlope function, which uses a kalman filter to
% calculate velocity.
%
% OUTPUT:
%   pvRegresionCoef - 2x1 vector of estimated position versus
%   velocity slope for both eyes (units are Hz 1/seconds or (degree/sec)/degress.
%   For a perfect exponential, -1/slope would yield the decay
%   time constant in seconds.
%   pvRegresionCoef(1) is the slope for the left eye
% see also positionVelocitySlope

options = struct('hemiPositionThreshold',2,'plane','all','startSegment',0,'stopSegment',5,'binTime',1,'calcReg',true,...
    'use4SaccadeTrigCutwConcatCallONLY',false);
options = parseNameValueoptions(options,varargin{:});

if strcmp(options.plane,'all')
    narrays = length(eyeobj.position);
    arrayIndV = 1 : narrays;
else
    narrays = length(options.plane);
    arrayIndV = options.plane;
end
eyePositionMeans = zeros(narrays,2);
for arrayInd = arrayIndV
    eyePositionMeans(arrayInd,:) = mean(eyeobj.position{arrayInd});
end
% spit out errors if saccade times haven't been calculated(todo)
if isempty(eyeobj.saccadeTimes{1})
    eyeobj = eyeobj.saccadeDetection;
end
% eyeobj = removeNonSimultaneous(eyeobj);

segmentedPosition = [];
segmentedPositionNobin = [];
segmentedVelocity = [];
segmentedTime = [];
segmentedAbsTime = [];
pvRegresionCoef = zeros(2,1);
pvRegresionCoefExtra = zeros(6,2);
timeOffset = 0;
segmentedPositionArray = cell(narrays,1);
segmentedTimeArray = cell(narrays,1);

segmentedPositionArray2 = cell(1,2);
segmentedTimeArray2 = cell(1,2);
segmentedAbsTimeArray = cell(1,2);

numSegments = [0 0];
for arrayInd = arrayIndV
    if 0
        % all saccadepoints
        allSacTimes = [eyeobj.saccadeTimes{arrayInd}{1}(eyeobj.conjugateSaccade{arrayInd}{1},:);...
            eyeobj.saccadeTimes{arrayInd}{1}(~eyeobj.conjugateSaccade{arrayInd}{1},:); ...
            eyeobj.saccadeTimes{arrayInd}{2}(~eyeobj.conjugateSaccade{arrayInd}{2},:)];
        [~,sortInd] = sort(allSacTimes(:,1));
        allSacTimes = allSacTimes(sortInd,:);
        
        % determine which are simultaneous and which are not
        simultaneousTime = [true(sum(eyeobj.conjugateSaccade{arrayInd}{1}),1);...
            false(sum(~eyeobj.conjugateSaccade{arrayInd}{1}),1); ...
            false(sum(~eyeobj.conjugateSaccade{arrayInd}{2}),1)];
        
        simultaneousTime = simultaneousTime(sortInd);
        
    end
    
    % center the position traces
    centeredPosition = bsxfun(@minus,eyeobj.position{arrayInd},eyePositionMeans(arrayInd,:));
    %                 endIndex =1;
    %                 for eyeInd=1:2
    %                 for time=15:15:eyeobj.time{arrayInd}(end,eyeInd)
    %                     [~,endIndexNEW] = min(abs(eyeobj.time{arrayInd}(:,eyeInd) - time));
    %                     window = endIndex:endIndexNEW;
    %                     centeredPosition(window,eyeInd) = eyeobj.position{arrayInd}(window,eyeInd) - mean(eyeobj.position{arrayInd}(window,eyeInd));
    %                     endIndex = endIndexNEW;
    %                 end
    %                 end
    
    % update posvelSlope to not wastefully, calculate regression-since this is calcualted on the final data piece(todo)
    % localPosNobin is not the same as a concatenated version
    % of localSegPosNoBin.  The former is conditioned on
    % segments that are both stopSegment seconds long AND
    % can be used to compute a velocity after binning.
    
    %
    [~,~,~,~,~,~,~,~,...
        localSegPosNoBin,localSegTimeNoBin,localSegAbsTimeNoBin] = positionVelocitySlope2(centeredPosition,...
        eyeobj.time{arrayInd},eyeobj.saccadeTimes{arrayInd},varargin{:});
    if ~options.use4SaccadeTrigCutwConcatCallONLY
        backwardCompatability{1} = eyeobj.saccadeTimes{arrayInd}{1};
        backwardCompatability{2} = eyeobj.saccadeTimes{arrayInd}{1};
        [~,localPos,localVel,localTimes,localPosArray,localTimeArray,localAbsTimes,localPosNobin]...
            = positionVelocitySlope2(centeredPosition,...
            eyeobj.time{arrayInd},backwardCompatability,varargin{:});
        
        
        segmentedPosition = [segmentedPosition;localPos];
        segmentedPositionNobin = [segmentedPositionNobin;localPosNobin];
        segmentedVelocity = [segmentedVelocity;localVel];
        %   segmentedTime = [segmentedTime;localTimes+timeOffset];
        segmentedTime = [segmentedTime;localTimes];
        segmentedAbsTime = [segmentedAbsTime;localAbsTimes+timeOffset];
        %timeOffset = segmentedTime(end);
        segmentedPositionArray{arrayInd} = localPosArray;
        segmentedTimeArray{arrayInd} = localTimeArray;
    end
    for eyeInd=1:2
        for k1=1:length(localSegPosNoBin{eyeInd})
            numSegments(eyeInd) = numSegments(eyeInd)+1;
            segmentedPositionArray2{eyeInd}{numSegments(eyeInd)} = localSegPosNoBin{eyeInd}{k1};
            segmentedTimeArray2{eyeInd}{numSegments(eyeInd)} = localSegTimeNoBin{eyeInd}{k1};
            segmentedAbsTimeArray{eyeInd}{numSegments(eyeInd)}=localSegAbsTimeNoBin{eyeInd}{k1} + timeOffset;
        end
    end
    timeOffset = timeOffset+eyeobj.time{arrayInd}(end);
    
end

if options.calcReg
    %             warning('setting unstable velocities to 0')
    %  segmentedVelocity= changeNonStableTraces(segmentedPosition,segmentedVelocity);
    if isempty(segmentedPosition)
        error('no acceptable position segments');
    end
    for eyeInd =1:2
        %  regressionObj = LinearModel.fit(segmentedPosition(:,eyeInd),segmentedVelocity(:,eyeInd));
        %  CoefWoffset = pinv([ones(nsamples,1) segmendtedPosition(:,eyeInd)])*segmentedVelocity(:,eyeInd);
        linearRegime = abs(segmentedPosition(:,eyeInd)) <=25;
        pB=plotBinner([segmentedPosition(linearRegime,eyeInd),segmentedVelocity(linearRegime,eyeInd)],options.binTime);
        [binData,binVar,numSamp,binCent]=pB.binData;
        
        regressionObj = LinearModel.fit(binCent(numSamp>5),binData(numSamp>5));
        
        pvRegresionCoef(eyeInd)=regressionObj.Coefficients.Estimate(2);
        pvRegresionCoefExtra(1:2,eyeInd) =  regressionObj.Coefficients.Estimate;
        
        posIndex = segmentedPosition(:,eyeInd)>options.hemiPositionThreshold;
        if sum(posIndex)>0
            regressionObj = LinearModel.fit(segmentedPosition(posIndex,eyeInd),segmentedVelocity(posIndex,eyeInd));
            pvRegresionCoefExtra(3:4,eyeInd) =  regressionObj.Coefficients.Estimate;
        end
        negIndex = segmentedPosition(:,eyeInd)<-options.hemiPositionThreshold;
        if sum(negIndex)>0
            regressionObj = LinearModel.fit(segmentedPosition(negIndex,eyeInd),segmentedVelocity(negIndex,eyeInd));
            pvRegresionCoefExtra(5:6,eyeInd) =  regressionObj.Coefficients.Estimate;
        end
    end
else
    pvRegresionCoef = [];
    pvRegresionCoefExtra = [];
end
end