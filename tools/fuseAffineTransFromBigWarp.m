function [mbrainTransformedWarp,fusedImage] = fuseAffineTransFromBigWarp(moveInput,targetInput,coordFile,varargin)
% fuseAffineTransFromBigWarp
%
options = struct('numMoveChannels',NaN,'moveIsImageJFile',false,'moveMetaData',[],...
    'numTargetChannels',NaN,'targetIsImageJFile',false,'targetMetaData',[],...
    'interp','linear','onlySaveNonFused',false,...
    'saveName',[],...
    'ZMicPerPlaneM',1,'XMicPerPixM',1,'YMicPerPixM',1,'ZMicPerPlaneT',1,'XMicPerPixT',1,'YMicPerPixT',1);
options = parseNameValueoptions(options,varargin{:});

% load moving image
[movingImages,movingRef] = loadImageAndRef(moveInput,'numChannels',options.numMoveChannels,'isImageJFile',options.moveIsImageJFile,...
    'metaData',options.moveMetaData,...
    'ZMicPerPlane',options.ZMicPerPlaneM,'XMicPerPix',options.XMicPerPixM,'YMicPerPix',options.YMicPerPixM);

% load target image
[targetImages,targetRef] = loadImageAndRef(targetInput,'numChannels',options.numTargetChannels,'isImageJFile',options.targetIsImageJFile,...
    'metaData',options.targetMetaData,...
    'ZMicPerPlane',options.ZMicPerPlaneT,'XMicPerPix',options.XMicPerPixT,'YMicPerPix',options.YMicPerPixT);

% load coordinates of landmarks
corrPoints =  dlmread(coordFile,',');

% load transformation
movingIs3D = size(movingImages,3)>1;
targetIs3D = size(targetImages,3)>1;
corrAre3D = size(corrPoints,2)==6;
if movingIs3D && targetIs3D && corrAre3D
    [~,transformStructure] = affineTransformBigWarp(NaN,corrPoints(:,1:3),corrPoints(:,4:6),'useMatrixMult',false,'onlyComputeTransform',true);
elseif ~movingIs3D && targetIs3D && corrAre3D
    % remove the target plane that matches the landmark in Z
    avgTargetPlaneMicrons = mean(corrPoints(:,6));
    micPerPlane = diff(targetRef.ZWorldLimits)/diff(targetRef.ZIntrinsicLimits);
    avgTargetPlaneIndex = round(avgTargetPlaneMicrons/micPerPlane)+1;
    targetImages = targetImages(:,:,avgTargetPlaneIndex);
    targetRef = imref2d(targetRef.ImageSize(1:2),targetRef.XWorldLimits,targetRef.YWorldLimits);
    targetIs3D = false;
    
    % load transform
    [~,transformStructure] = affineTransformBigWarp(NaN,corrPoints(:,1:2),corrPoints(:,4:5),'useMatrixMult',false,'onlyComputeTransform',true);
elseif movingIs3D && ~targetIs3D && corrAre3D
    % remove the moving plane that matches the landmark in Z
    avgMovingPlaneMicrons = mean(corrPoints(:,3));
    micPerPlane = diff(movingRef.ZWorldLimits)/diff(movingRef.ZIntrinsicLimits);
    avgMovingPlaneIndex = round(avgMovingPlaneMicrons/micPerPlane)+1;
    movingImages = movingImages(:,:,avgMovingPlaneIndex);
    movingRef = imref2d(movingRef.ImageSize(1:2),movingRef.XWorldLimits,movingRef.YWorldLimits);
    movingIs3D = false;
    
    [~,transformStructure] = affineTransformBigWarp(NaN,corrPoints(:,1:2),corrPoints(:,4:5),'useMatrixMult',false,'onlyComputeTransform',true);
elseif ~movingIs3D && ~targetIs3D && ~corrAre3D
    [~,transformStructure] = affineTransformBigWarp(NaN,corrPoints(:,1:2),corrPoints(:,3:4),'useMatrixMult',false,'onlyComputeTransform',true);
else
    error('Image sizes and dimension of landmarks does not match')
end

% save as a fused image with different colors
mbrainTransformedWarp = imwarp(movingImages,movingRef,transformStructure,'OutputView',targetRef,'interp',options.interp);
if targetIs3D && movingIs3D
    fusedImage = zeros([targetRef.ImageSize(1:2),3,targetRef.ImageSize(3)],'uint8');
    nSlices = size(targetImages,3);
else
    fusedImage = zeros([targetRef.ImageSize(1:2),3],'uint8');
    nSlices = 1;
end
for i = 1:nSlices
    if options.onlySaveNonFused
        currentImage2Save = mbrainTransformedWarp(:,:,i);
    else
        fusedImage(:,:,:,i) = imfuse(mbrainTransformedWarp(:,:,i),imadjust(targetImages(:,:,i)),...
            'falsecolor','Scaling','independent','ColorChannels',[1,2,0]);
        currentImage2Save = fusedImage(:,:,:,i);
    end
    if ~isempty(options.saveName)
        if i==1
            imwrite(currentImage2Save,options.saveName);
        else
            imwrite(currentImage2Save,options.saveName,'WriteMode','append');
        end
    end
end
end

function [images,refObj] = loadImageAndRef(imageInput,varargin)
options = struct('numChannels',NaN,'isImageJFile',false,'metaData',[],'ZMicPerPlane',1,'XMicPerPix',1,'YMicPerPix',1);
options = parseNameValueoptions(options,varargin{:});

if ischar(imageInput)
    inputIsAFileName = true;
    inputIsNumeric = false;
elseif isnumeric(imageInput)
    inputIsNumeric = true;
    inputIsAFileName = false;
else
    error('target and moving inputs must be filenames or images or image stacks');
end
if inputIsNumeric && options.isImageJFile
    error('target/moving input must be a filename if isImageJFile is true');
end

% determine scale to use
if ~isempty(options.metaData)
    [scaleOut,hasZInfo] = rawData.extractScaleFromMetaDataStruct(options.metaData);
    if ~hasZInfo
        ZMicPerPlane = options.ZMicPerPlane;
    else
        ZMicPerPlane = scaleOut(3);
    end
    XMicPerPix = scaleOut(1);
    YMicPerPix = scaleOut(2);
elseif options.isImageJFile
    % then check if the image is an imageJ file. If so use metadata saved
    % with the file
    metaData = rawData.grabMetaData(imageInput,'isImageJFile',true,'checkIfScanImageFile',false);
    if ~isfield(metaData,'numChannels')
        error(['Image[] was not saved with FIJI:[]=' imageInput])
    end
    ZMicPerPlane = metaData.ZMicPerPlane;
    XMicPerPix = metaData.XMicPerPix;
    YMicPerPix = metaData.YMicPerPix;
    if isnan(options.numChannels)
        options.numChannels = metaData.numChannels;
    end
else
    % go with defaults
    ZMicPerPlane = options.ZMicPerPlane;
    XMicPerPix = options.XMicPerPix;
    YMicPerPix = options.YMicPerPix;
end

% load images
if inputIsAFileName
    images = rawData.loadTIFF(imageInput,'useImread',false);
    if ~isnan(options.numChannels)
        images = images(:,:,1:options.numChannels:end); % hard-code always using the green channel
    end
elseif inputIsNumeric
    images = imageInput;
end

[d1,d2,d3]=size(images);
if d3 == 1
    refObj = imref2d([d1,d2],([0 d1]-0.5)*XMicPerPix,([0 d2]-0.5)*YMicPerPix);
elseif d3 > 1
    refObj = imref3d([d1,d2,d3],([0 d2]-0.5)*XMicPerPix,([0 d1]-0.5)*YMicPerPix,([0 d3]-0.5)*ZMicPerPlane); % in microns
end
end
