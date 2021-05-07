function obj = convertVideo2AnglesIDSCamera(obj,varargin)
options = struct('frameRate','full','plotEllipse',false,'plotPeriod',0.5,'verbose',true,'progRate',0.1);
options = parseNameValueoptions(options,varargin{:});
% [leye_position,reye_position] = convertVideo2AnglesIDSCamera(obj,varargin)
% options = struct('frameRate','full','plotEllipse',false,'plotPeriod',0.5,'verbose',true,'progRate',0.1,'saveName',[]);
% options = parseNameValueoptions(options,varargin{:});
% adr
% ea lab
% weill cornell medicine
% 10/2012 -202x

if ~isfield(obj.video2AngleParameters,'thresholdL')
    obj = obj.setVideoParameters; 
end

startTime = tic;
counter = 0;
if ischar(options.frameRate)
    estNumFrames2Save = round(obj.vrObj.Duration*obj.vrObj.FrameRate)+10; % this is much faster than using the get method.
    condition2Continue = hasFrame(obj.vrObj);
else
    estNumFrames2Save = round(obj.vrObj.Duration*options.frameRate)+10;
    analysisPeriod = 1/options.frameRate;
    condition2Continue = (counter*analysisPeriod) <obj.vrObj.Duration;
end
leye_position = NaN(2,estNumFrames2Save);
reye_position= NaN(2,estNumFrames2Save);
epropDisp = cell(estNumFrames2Save,1);
if options.plotEllipse
    plotStarted=false;
    nextUpdateTime = options.plotPeriod;
end
if options.verbose
    nextVerboseUpdateVal = options.progRate;
end

obj.vrObj.CurrentTime=0;
while condition2Continue
    if options.verbose
        currentProgress = obj.vrObj.CurrentTime/obj.vrObj.Duration;
        if (nextVerboseUpdateVal - currentProgress)<0
            fprintf('%0.2f percent of the way done\n',currentProgress);
            nextVerboseUpdateVal = nextVerboseUpdateVal + options.progRate;
        end
    end
    if ~ischar(options.frameRate)
        obj.vrObj.CurrentTime = counter*analysisPeriod;
    end
    currentFrame = readFrame(obj.vrObj);
    % analysis -----------------------
    alteredFrame = obj.fillInImage(currentFrame(:,:,1));
    image2AnalyzeL =  alteredFrame<obj.video2AngleParameters.thresholdL & obj.video2AngleParameters.ROILeft;
    image2AnalyzeR =  alteredFrame<obj.video2AngleParameters.thresholdR & obj.video2AngleParameters.ROIRight;
    eprop = regionprops(image2AnalyzeL,...
        'Area', 'Orientation','Centroid','MajorAxisLength','MinorAxisLength');
    % since multiple connected components may be present, we take the
    % components with the largest areas as the eyes.
    [~,eyeIndex]=max(cat(1,eprop.Area));
    epropDisp{counter+1}(1) = eprop(eyeIndex);
    leye_position(2,counter+1) = eprop(eyeIndex).Orientation;
    leye_position(1,counter+1) = obj.vrObj.CurrentTime;
    eprop = regionprops(image2AnalyzeR,...
        'Area', 'Orientation','Centroid','MajorAxisLength','MinorAxisLength');
    [~,eyeIndex]=max(cat(1,eprop.Area));
    epropDisp{counter+1}(2) = eprop(eyeIndex);
    reye_position(2,counter+1) = eprop(eyeIndex).Orientation;
    reye_position(1,counter+1) = obj.vrObj.CurrentTime;
    % update plot
    if options.plotEllipse
        if (nextUpdateTime - obj.vrObj.CurrentTime)<0
            
            thresholdedImage = image2AnalyzeL | image2AnalyzeR;
            if ~plotStarted
                fh = figure;
                imh = imagesc(thresholdedImage);colormap('gray');hold on;
                plotStarted = true;
            else
                set(imh,'CData',thresholdedImage);
                delete(ph)
                delete(phMA)
            end
            [~,~,ph,phMA]= obj.visualize_ellipse(epropDisp{counter+1},fh,1);
            pause(0.001);
            nextUpdateTime = nextUpdateTime + options.plotPeriod;
        end
    end
    counter = counter + 1;
    if ischar(options.frameRate)
        condition2Continue = hasFrame(obj.vrObj);
    else
        condition2Continue = (counter*analysisPeriod) <obj.vrObj.Duration;
    end
end

toc(startTime)
obj.leftEye = leye_position(:,1:counter);
obj.rightEye = reye_position(:,1:counter);
obj.fitProps = epropDisp(1:counter);
end

