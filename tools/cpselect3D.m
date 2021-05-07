function [movingPoints,fixedPoints]=cpselect3D(movingImages,varargin)
options = struct('fixedData',[],'movingPoints',[],'fixedPoints',[]);
options = parseNameValueoptions(options,varargin{:});

% load reference image if not loaded
if isempty(options.fixedData)
    [~,smallDataPath] = rootDirectories;
    fixedImagesFile =  [smallDataPath 'rf2March2019ImgOrientation.tif'];
    fizexImageInfo = imfinfo(fixedImagesFile);
    fixedImages = zeros(fizexImageInfo(1).Height, fizexImageInfo(1).Width,...
        length(fizexImageInfo),'uint16');
    TifLink = Tiff(fixedImagesFile,'r');
    for i = 1:length(fizexImageInfo)
        TifLink.setDirectory(i)
        fixedImages(:,:,i) = TifLink.read();
    end
    TifLink.close();
    
else
    fixedImages = options.fixedData;
end
movingImages = imadjust3d_stretch(movingImages,[0.01 0.99]);
% show images -- fused if user inputed coordinate points
[Hlocal,Wlocal,Nlocal]=size(movingImages);
[Hglobal,Wglobal,Nglobal]=size(fixedImages);
movingPoints = options.movingPoints;
fixedPoints = options.fixedPoints;
if ~isempty(movingPoints)
    [transform3d,registeredZCoordinates] = approx3dTransform(movingPoints,fixedPoints,Nlocal,Nglobal);
    % hack until I re-learn/re-write
    % approx3dTransform
    if 0
        % caobj.fishID == 1
        sRemPlanes = 5:5:5*length(registeredZCoordinates(41:end));
        sFixedPlanes = 3:3:(sRemPlanes(end)+2);
        bestMatchFixedInd = zeros(length(sRemPlanes),1);
        indFixedPlanes = [1:length(sFixedPlanes)]+10;
        for jj=1:length(sRemPlanes)
            [~,bestMatchSubInd]=min(abs(sFixedPlanes-sRemPlanes(jj)));
            bestMatchFixedInd(jj) = indFixedPlanes(bestMatchSubInd);
        end
        registeredZCoordinates(41:end) = bestMatchFixedInd;
        % caobj.fishID == 7
    elseif 0
        sRemPlanes = 5:5:5*length(registeredZCoordinates(31:end));
        sFixedPlanes = 3:3:(sRemPlanes(end)+2);
        bestMatchFixedInd = zeros(length(sRemPlanes),1);
        indFixedPlanes = [1:length(sFixedPlanes)]+13;
        for jj=1:length(sRemPlanes)
            [~,bestMatchSubInd]=min(abs(sFixedPlanes-sRemPlanes(jj)));
            bestMatchFixedInd(jj) = indFixedPlanes(bestMatchSubInd);
        end
        registeredZCoordinates(31:end) = bestMatchFixedInd;
    end
    
    [Ifuse,fh]=fuseAndView(movingImages,fixedImages,transform3d,'registeredZ',registeredZCoordinates,'zconstraint',4);
    disp('registered Z Coordinates')
    registeredZCoordinates
    implay(Ifuse);
    %  figure;
    % montage(reshape(movingImages,[Hlocal,Wlocal,1,Nlocal]))
else
    figure;
    montage(reshape(movingImages,[Hlocal,Wlocal,1,Nlocal]))
    figure;
    montage(reshape(fixedImages,[Hglobal,Wglobal,1,Nglobal]))
    keyboard
end

terminateRegistration = false;
continueResponse = input('continue registration? Y/N : ','s');
if ~strcmpi(continueResponse,'y')
    terminateRegistration = true;
end
implay(fixedImages)
while ~terminateRegistration
    plane2register = input('please enter the index of the non-registered image you wish to register\n');
    registeredZCoord = input('please enter the index of the reference image you believe best corresponds to the image you wish to register\n');
    noinit = true; % no initialization for cpselect
    if ~isempty(movingPoints)
        mp =movingPoints(movingPoints(:,3)==plane2register,1:2); % moving points for this plane
        fp  = fixedPoints(fixedPoints(:,3)==registeredZCoord,1:2); % fixed points for this plane
        if ~isempty(mp) && ~isempty(fp)
            noinit = false;
        end
    end
    disp('close the registration window to proceed')
    if noinit
        [movingPoints2d,fixedPoints2d]=cpselect(movingImages(:,:,plane2register),fixedImages(:,:,registeredZCoord),...
            'Wait',true);
    else
        [movingPoints2d,fixedPoints2d]=cpselect(movingImages(:,:,plane2register),fixedImages(:,:,registeredZCoord),...
            mp,fp,'Wait',true);
    end
    
    
    
    nselectedPoints = size(movingPoints2d,1);
    movingPoints = [movingPoints;[movingPoints2d plane2register*ones(nselectedPoints,1)]];
    fixedPoints = [fixedPoints;[fixedPoints2d registeredZCoord*ones(nselectedPoints,1)]];
    
    % option for checking registration quality
    checkRegResponse = input('check registration quality? Y/N : ','s');
    if strcmpi(checkRegResponse,'y')
        if size(movingPoints,1)>3
            % check current quality of registration
            [transform3d,registeredZCoordinates] = approx3dTransform(movingPoints,fixedPoints,Nlocal,Nglobal);
            registeredZCoordinates
            [~,fh]=fuseAndView(movingImages,fixedImages,transform3d,'registeredZ',registeredZCoordinates,'zconstraint',4);
        else
            disp('first select points!')
        end
    end
    continueResponse = input('continue registration? Y/N : ','s');
    if strcmpi(checkRegResponse,'y')
        if size(movingPoints,1)>3
            close(fh)
        end
    end
    if ~strcmpi(continueResponse,'y')
        terminateRegistration = true;
    end
end