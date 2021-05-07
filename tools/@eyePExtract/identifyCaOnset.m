function [obj,varargout] = identifyCaOnset(obj,varargin)
options = struct('startTime','load','checkUptoTime',6,'manual',true,'semiAutoThr',0.1,'verbose',true,'progRate',0.1);
options = parseNameValueoptions(options,varargin{:});

if ischar(options.startTime)
    % first load date and time when laser began 
    [imageStart,obj] = obj.loadLaserStartTime;
end

% load frames 
estimatedNumFrames = round(options.checkUptoTime*obj.vrObj.FrameRate)+100;
I = zeros(obj.vrObj.Height,obj.vrObj.Width,estimatedNumFrames,'uint8');
timesObs = NaN(estimatedNumFrames,1);

if options.verbose
    fprintf('loading video to determine when laser starts\n');
    nextVerboseUpdateVal = options.progRate;
end
k = 1;
obj.vrObj.CurrentTime=0;
while obj.vrObj.CurrentTime < options.checkUptoTime
    if options.verbose
        currentProgress = obj.vrObj.CurrentTime/options.checkUptoTime;
        if (nextVerboseUpdateVal - currentProgress)<0
            fprintf('%0.2f percent of the way done\n',currentProgress);
            nextVerboseUpdateVal = nextVerboseUpdateVal + options.progRate;
        end
    end
    
    currentFrame = readFrame(obj.vrObj);
    I(:,:,k) = currentFrame(:,:,1);
    timesObs(k) = obj.vrObj.CurrentTime;
    k = k + 1;
end
actualNumberFrames = k - 1;
% if you add an option to not start at 0, remember that if user says 
% frameStart =1 , the actual value is 1 + however many frames were not
% shown
if options.manual
    implay(I);
    movieFrame = input('enter frame number where laser starts\n');
    frameStart = movieFrame;
else
    if ~isfield(obj.video2AngleParameters,'laserRegion')
        obj.video2AngleParameters.laserRegion = obj.runRoipolyOnImg(I(:,:,1),'numROIs',1,'dispText',{{'circle current position of laser'}});
    end
    avgIntHB = zeros(actualNumberFrames,1);
    for k=1:actualNumberFrames
        I2view = I(:,:,k);
        avgIntHB(k) = mean(I2view(obj.video2AngleParameters.laserRegion));
    end
        startMean=mean(avgIntHB(1:10));
        %figure;plot(avgIntHB./startMean,'b:.')
        frameStart = find(avgIntHB./startMean < (1-options.semiAutoThr),1);
end

% note that previous value of beg_time was
timeRelMovieStart = timesObs(frameStart);
if ischar(options.startTime)
    dateAndTimeLaserStarts = datenum(imageStart);
    beg_time = datevec(dateAndTimeLaserStarts - timeRelMovieStart/(60*60*24));
elseif isnumeric(options.startTime)
    % user wants the time relative to some known start time
    beg_time = datevec(options.startTime - timeRelMovieStart/(60*60*24));
else
    beg_time = [];
end
obj.laserStartTime = timeRelMovieStart;
obj.laserStartFrame = frameStart;
obj.movieStartDateTime = beg_time;
if options.manual
    obj.laserStartTimeEvidence = 'manual';
else
    obj.laserStartTimeEvidence = struct('avgIInLaserRegion',avgIntHB,...
        'avgINormFactor',startMean,'threshold',1-options.semiAutoThr);
end
varargout{1} = beg_time;
varargout{2} = timeRelMovieStart;
varargout{3} = frameStart;
end

