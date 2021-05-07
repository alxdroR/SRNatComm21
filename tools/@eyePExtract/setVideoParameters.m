function obj = setVideoParameters(obj,varargin)
% obj = setVideoParameters(obj,varargin)
% options = struct('checkParameter',false);
% options = parseNameValueoptions(options,varargin{:});
% adr
% ea lab
% weill cornell medicine
% 10/2012 -202x

options = struct('checkParameter',false);
options = parseNameValueoptions(options,varargin{:});


I = readFrame(obj.vrObj);
if ~isfield(obj.video2AngleParameters,'thresholdL')
    obj.video2AngleParameters.ROIHead = obj.runRoipolyOnImg(I,'numROIs',1,'dispText',{{'circle region around head to initialize threshold'}});
    obj.video2AngleParameters.bodyLocation = obj.runRoipolyOnImg(I,'numROIs',1,'dispText',{{'mark the center of the body (used to determine eye angle)'}});
    bodyProp=regionprops(obj.video2AngleParameters.bodyLocation,'Centroid');
    obj.bodyCentroid = bodyProp.Centroid;
    [obj.video2AngleParameters.thresholdL,obj.video2AngleParameters.thresholdR] = obj.determineThresholdLESeperate(I(:,:,1),'region2initTh',obj.video2AngleParameters.ROIHead);
    thresholdedImage = I(:,:,1)<obj.video2AngleParameters.thresholdL | I(:,:,1)<obj.video2AngleParameters.thresholdR;    
    [obj.video2AngleParameters.ROILeft, obj.video2AngleParameters.ROIRight] = obj.runRoipolyOnImg(thresholdedImage,'numROIs',2,'dispText',{{'please circle Left Eye','please circle the right eye'}});
    % ask user for regions we know must be below threshold because they are
    % within the eyes
    disp('Now fill in regions that will remain within the eyes no matter what the angle');
    [obj.video2AngleParameters.ROIInLeftEye, obj.video2AngleParameters.ROIInRightEye] = obj.runRoipolyOnImg(thresholdedImage,'numROIs',2,'dispText',{{'select region 2 fill in Left Eye','select region 2 fill in Left Eye'}});
elseif options.checkParameter
    % just because this global isn't empty doesn't mean it is set appropriately
    figure;
    subplot(121);
    imagesc(I(:,:,1)); colormap('gray')
    title('raw frame');
    
    [HROI,WROI] = size(obj.video2AngleParameters.ROILeft);
    [HCF,WCF] =  size(I(:,:,1));
    if HCF==HROI && WCF == WROI
        % the dimensions of the current frame and the ROI's are correct
        subplot(122)
        imagesc(I(:,:,1)<obj.video2AngleParameters.threshold & obj.video2AngleParameters.ROILeft ...
            |I(:,:,1)<obj.video2AngleParameters.threshold & obj.video2AngleParameters.ROIRight)
        title('thresholded frame within ROIs');
        
        yesOrNo = input('run algorithm parameters again? Type y or n for Yes or No \n','s');
    else
        subplot(122)
        imagesc(I(:,:,1)<obj.video2AngleParameters.threshold )
        title('thresholded frame within ROIs');
        
        % THE ROI IS NOT CORECT IN THIS CASE SO WE MUST RUN PARAMTERS AGAIN
        yesOrNo = 'y';
    end
    switch yesOrNo
        case 'n'
            disp('great! Extracting eye angles with these parameters');
        case 'y'
            fprintf('current threshold %d\n',obj.video2AngleParameters.threshold)
            obj.video2AngleParameters.threshold = obj.determineThreshold(I(:,:,1));
            [obj.video2AngleParameters.ROILeft, obj.video2AngleParameters.ROIRight] = obj.runRoipolyOnImg(I(:,:,1));
    end
end
close all
end

