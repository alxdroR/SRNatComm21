function [Coordinates,Cmu] = registeredCellLocationsBigWarp(varargin)
% Coordinates = registeredCellLocations
% Return reference brain registered cell locations for all cells in the data set.
%
% OUTPUT :
% Coordinates : N x 3 array - where N is the total number of cells in the
% data set
%
% Optional Input
% 'EPSelectedCells'  {true,false}
% Use cells selected by NMF algorithm (true, default) or cells selected by
% correlation with eye position.
%
% 'register2Zbrain' {true,false}
% Perform a final registration to the Z-Brain Atlas
%
% 'demoRegistration' {true,false}
% Show some examples of registration quality
%
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020


options = struct('caExtractionMethod','NMF','register2Zbrain',false,'demoRegistration',false,'correctiveMetaData',[],'dir',[]);
options = parseNameValueoptions(options,varargin{:});

[~,~,fileDirs] = rootDirectories;
[fid,expCond]=listAnimalsWithImaging;

if isempty(options.correctiveMetaData)
    regFilenames = [fileDirs.registration.createPreRegShiftScanStru 'createPreRegShiftScanStruc.mat'];
    load(regFilenames,'registrationShifts');
    options.correctiveMetaData = registrationShifts;
end

if strcmp(options.caExtractionMethod,'MO')
        warning('make sure size cut-off here matches what was used when constructing MO files');
        maxCellArea = 12*12;
end
% load bridgeBrain Metadata
bridgeBrainFile =  fileDirs.twoPBridgeBrain;
bridgeBrainMeta = rawData.grabMetaData(bridgeBrainFile,'isImageJFile',true,'checkIfScanImageFile',false);
bridgeBrainMicOverPix = [bridgeBrainMeta.XMicPerPix,bridgeBrainMeta.YMicPerPix,bridgeBrainMeta.ZMicPerPlane];
bridgeBrainMicOverPix = round(bridgeBrainMicOverPix*10^3)/10^3;
if options.register2Zbrain
    ZBtransformFileName = getFilenames('ref2Zbrain','expcond',[],'fileType','regLandmarks');
    % load the Z-Brain scale used to convert pixels to microns ------------------------
    zBrainFile = fileDirs.ZBrain;
    zBrainMeta = rawData.grabMetaData(zBrainFile,'isImageJFile',true,'checkIfScanImageFile',false);
    ZBrainMicOverPix = [zBrainMeta.XMicPerPix,zBrainMeta.YMicPerPix,zBrainMeta.ZMicPerPlane];
    ZBrainMicOverPix = round(ZBrainMicOverPix*10^3)/10^3;
end
if options.demoRegistration
    demoPoints = struct('regPoints',cell(2,1),'figHandle',cell(2,1));
    if ~options.register2Zbrain
        bridgeBrainMovie = rawData.loadTIFF(bridgeBrainFile,'useImread',false);
        if ~isnan(bridgeBrainMeta.numChannels)
            bridgeBrainMovie = bridgeBrainMovie(:,:,1:bridgeBrainMeta.numChannels:end); % hard-code always using the green channel
        end
    end
end

Coordinates = [];Cmu=[];
for expIndex = 1:length(fid)
    [need2split,splitFrame] = spontDataSplitPlanes(fid{expIndex});
    if need2split
        coorPoints = {dlmread(getFilenames(fid{expIndex},'expcond',[expCond{expIndex} '-1'],'fileType','regLandmarks','dir',options.dir),','),...
            dlmread(getFilenames(fid{expIndex},'expcond',[expCond{expIndex} '-2'],'fileType','regLandmarks','dir',options.dir),',')};
    else
        coorPoints = dlmread(getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','regLandmarks','dir',options.dir),',');
    end
    coordinateFile = getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','catraces','caTraceType',options.caExtractionMethod,'dir',options.dir);
    if strcmp(options.caExtractionMethod,'MO')
        load(coordinateFile,'localCoordinates','cellArea');
        warning('make sure size cut-off here matches what was used when constructing MO files');
        passesSizeCut = cellfun(@(x) x'<=maxCellArea,cellArea,'UniformOutput',false);
        passesSizeCut = cat(1,passesSizeCut{:});
    else
        load(coordinateFile,'localCoordinates');
    end
    metaDataFile = getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','catraces','caTraceType','NMF','dir',options.dir);
    load(metaDataFile,'expMetaData');
    
    % load coordinates
    if strcmp(options.caExtractionMethod,'MO')
        localCoordinatesCellXYZ = cellfun(@(x,y) [x(:,1),x(:,2),repmat(y,size(x,1),1)],localCoordinates,num2cell((1:length(localCoordinates))',length(localCoordinates)),'UniformOutput',false);
    elseif strcmp(options.caExtractionMethod,'NMF')
        localCoordinatesCellXYZ = cellfun(@(x,y) [x(:,2),x(:,1),repmat(y,size(x,1),1)],localCoordinates,num2cell((1:length(localCoordinates))',length(localCoordinates)),'UniformOutput',false);
    end
    U = cat(1,localCoordinatesCellXYZ{:});
    if strcmp(options.caExtractionMethod,'MO')
        U = U(passesSizeCut,:);
    end
    % the -0.5 for the pixels and z-plane matches the convention in BigWarp (checked on 2/11/2021)
    % change plane index to z value
    U(:,3) = U(:,3)-1;
    % now change to coord in Big Warp.
    U = U-0.5;
    
    % load metadata
    micOverPixScale = rawData.extractScaleFromMetaDataStruct(expMetaData);
    micOverPixScale = round(micOverPixScale*10^3)/10^3;
    %micOverPixScale = [0.3603001 0.3603001 5]; previous value with mistake
    % correct coordinates
    if need2split
        USplit = {U(U(:,3)<=splitFrame,:),U(U(:,3)>splitFrame,:)};
        USplit{2}(:,3) = USplit{2}(:,3) - splitFrame;
        U = USplit;
    end
    if ~isempty(options.correctiveMetaData(expIndex))
        [~,~,shiftX] = spontDataSplitPlanes(fid{expIndex},options.correctiveMetaData(expIndex).shiftX);
        [~,~,scaleX] = spontDataSplitPlanes(fid{expIndex},options.correctiveMetaData(expIndex).scaleX);
        if need2split
            for splitIndex = 1 : 2
                U{splitIndex} = rawData.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},U{splitIndex},false);
            end
        else
            U = rawData.shiftDataWShiftStruct(shiftX,scaleX,U,false);
        end
    end
    if need2split
        XmuCell = cell(2,1);
        for splitIndex = 1 : 2
            XmuCell{splitIndex} = transformUInPixels(U{splitIndex},micOverPixScale,coorPoints{splitIndex});
        end
        Xmu = [XmuCell{1};XmuCell{2}];
    else
        Xmu = transformUInPixels(U,micOverPixScale,coorPoints);
    end
    Xpix = Xmu.*(repmat(1./bridgeBrainMicOverPix,size(Xmu,1),1))+0.5;
    Xpix(:,3) = Xpix(:,3) + 1;
    Coordinates = [Coordinates; Xpix];
    Cmu = [Cmu;Xmu];
    
    if options.demoRegistration
        caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'loadImages',true,'EPSelectedCells',options.EPSelectedCells,'MO',options.MO,'loadCCMap',false);
        
        % This is not necessary for registration, just to demonstrate its
        % performance
        selectPointsGlobal = false(size(Xpix,1),1);
        if fid{expIndex}==1
            % demo figures indexed 3-5 will not be featured with animal 1
            for plotIndex = 3 : length(demoPoints)
                demoPoints(plotIndex).regPoints = [demoPoints(plotIndex).regPoints;selectPointsGlobal];
            end
            
            % Show registration at the top of the brain
            selectPointsLocal = U(:,3)==1;
            demoPoints(1).figHandle = figure; subplot(1,4,1);
            imagesc(caobj.images.channel{1}(:,:,1)); hold on; plot(U(selectPointsLocal,1),U(selectPointsLocal,2),'ro')
            selectPointsGlobal(selectPointsLocal) = true;
            demoPoints(1).regPoints = [demoPoints(1).regPoints;selectPointsGlobal];
            
            % Show registration at the midbrain hindbrain border
            selectPointsLocal = U(:,3)==5;
            selectPointsGlobal = false(size(Xpix,1),1);
            selectPointsGlobal(selectPointsLocal) = true;
            demoPoints(2).figHandle = figure; subplot(1,4,1);
            imagesc(caobj.images.channel{1}(:,:,5)); hold on; plot(U(selectPointsLocal,1),U(selectPointsLocal,2),'ro')
            demoPoints(2).regPoints = [demoPoints(2).regPoints;selectPointsGlobal];
        else
            for plotIndex = 1 : length(demoPoints)
                demoPoints(plotIndex).regPoints = [demoPoints(plotIndex).regPoints;selectPointsGlobal];
            end
        end
    end
end
if options.demoRegistration && ~options.register2Zbrain
    for plotIndex = 1 : length(demoPoints)
        c2plot = Coordinates(logical(demoPoints(plotIndex).regPoints),:);
        figure(demoPoints(plotIndex).figHandle)
        uniPlanes = unique(round(c2plot(:,3)));
        for subInd = 1:min(3,length(uniPlanes))
            subplot(1,4,subInd+1)
            imagesc(bridgeBrainMovie(:,:,uniPlanes(subInd)),[0 500]);hold on;
            selectPointsGlobal = abs(c2plot(:,3)-uniPlanes(subInd))<0.5;
            plot(c2plot(selectPointsGlobal,1),c2plot(selectPointsGlobal,2),'ro')
        end
    end
end

if options.register2Zbrain
    coorPoints = dlmread(ZBtransformFileName,',');
    Cmu = affineTransformBigWarp(Cmu,coorPoints(:,1:3),coorPoints(:,4:6));
    Coordinates = Cmu.*(repmat(1./ZBrainMicOverPix,size(Cmu,1),1))+0.5;
    Coordinates(:,3) = Coordinates(:,3) + 1;
end
end

function Xmu = transformUInPixels(U,micOverPixScale,coorPoints)
Umu = U.*repmat(micOverPixScale,size(U,1),1);
Xmu = affineTransformBigWarp(Umu,coorPoints(:,1:3),coorPoints(:,4:6));
end
