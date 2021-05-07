function [Coordinates,Cmu] = registeredCellLocationsBigWarpOLD(varargin)
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


options = struct('EPSelectedCells',true,'MO',false,'register2Zbrain',false,'demoRegistration',false,'NMFDir',[]);
options = parseNameValueoptions(options,varargin{:});

[~,smallDataPath] = rootDirectories;
[~,~,fileDirs] = rootDirectories;
[fid,expCond]=listAnimalsWithImaging;

% createPreRegShiftScanStruc.m
regFilenames = [fileDirs.registration.createPreRegShiftScanStru 'createPreRegShiftScanStruc.mat'];
load(regFilenames);

if options.demoRegistration && ~options.register2Zbrain
    % load bridge brain
    fixedImagesFile =  [smallDataPath 'rf2March2019ImgOrientation.tif'];
    fizexImageInfo = imfinfo(fileDirs.twoPBridgeBrain);
    fixedImages = zeros(fizexImageInfo(1).Height, fizexImageInfo(1).Width,...
        length(fizexImageInfo),'uint16');
    TifLink = Tiff(fileDirs.twoPBridgeBrain,'r');
    for i = 1:length(fizexImageInfo)
        TifLink.setDirectory(i)
        fixedImages(:,:,i) = TifLink.read();
    end
    TifLink.close();
end

if options.demoRegistration
    demoPoints = struct('regPoints',cell(2,1),'figHandle',cell(2,1));
end
mic2pixscale = [0.3603001 0.3603001 5];
Coordinates = [];Cmu=[];
for expIndex = 1:length(fid)
    %for expIndex = 1:1
    if options.demoRegistration
        caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'loadImages',true,'EPSelectedCells',options.EPSelectedCells,'MO',options.MO,'loadCCMap',false,'NMFDir',options.NMFDir);
    else
        caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'loadImages',false,'EPSelectedCells',options.EPSelectedCells,'MO',options.MO,'loadCCMap',false,'NMFDir',options.NMFDir);
    end
    U = caobj.localCoordinates;
    animalName =caobj.fishID;
    if strcmp(animalName,'f1')
        numStacks = 39;
        U1 = U(U(:,3)<=numStacks,:);
        U1mu = U1.*repmat(mic2pixscale,size(U1,1),1);
        coorPoints = dlmread([fileDirs.registration.landmarks  num2str(caobj.fishID) caobj.expCond '-1-BigWarp-landmarks2.csv'],',');
        X1mu = affineTransformBigWarp(U1mu,coorPoints(:,1:3),coorPoints(:,4:6));
        
        
        U2 = U(U(:,3)>numStacks,:);
        U2(:,3) = U2(:,3) - numStacks;
        U2mu = U2.*repmat(mic2pixscale,size(U2,1),1);
        % remember that the coordinates 40 -> 1
        coorPoints = dlmread([fileDirs.registration.landmarks  num2str(caobj.fishID) caobj.expCond '-2-BigWarp-landmarks2.csv'],',');
        X2mu = affineTransformBigWarp(U2mu,coorPoints(:,1:3),coorPoints(:,4:6));
        Xmu = [X1mu;X2mu];
    elseif strcmp(animalName,'f7')
        numStacks = 29;
        U1 = U(U(:,3)<=numStacks,:);
        U1mu = U1.*repmat(mic2pixscale,size(U1,1),1);
        coorPoints = dlmread([fileDirs.registration.landmarks  num2str(caobj.fishID) caobj.expCond '-1-BigWarp-landmarks2.csv'],',');
        X1mu = affineTransformBigWarp(U1mu,coorPoints(:,1:3),coorPoints(:,4:6));
        
        
        U2 = U(U(:,3)>numStacks,:);
        U2(:,3) = U2(:,3) - numStacks;
        U2mu = U2.*repmat(mic2pixscale,size(U2,1),1);
        % remember that the coordinates 40 -> 1
        coorPoints = dlmread([fileDirs.registration.landmarks  num2str(caobj.fishID) caobj.expCond '-2-BigWarp-landmarks2.csv'],',');
        X2mu = affineTransformBigWarp(U2mu,coorPoints(:,1:3),coorPoints(:,4:6));
        Xmu = [X1mu;X2mu];
    elseif(strcmp(animalName,'fG'))
        numStacks = 6;
        U1 = U(U(:,3)<=numStacks,:);
        U1mu = U1.*repmat(mic2pixscale,size(U1,1),1);
        coorPoints = dlmread([fileDirs.registration.landmarks  num2str(caobj.fishID) caobj.expCond '-1-BigWarp-landmarks2.csv'],',');
        X1mu = affineTransformBigWarp(U1mu,coorPoints(:,1:3),coorPoints(:,4:6));
        
        
        U2 = U(U(:,3)>numStacks,:);
        U2(:,3) = U2(:,3) - numStacks;
        U2mu = U2.*repmat(mic2pixscale,size(U2,1),1);
        % remember that the coordinates 40 -> 1
        coorPoints = dlmread([fileDirs.registration.landmarks  num2str(caobj.fishID) caobj.expCond '-2-BigWarp-landmarks2.csv'],',');
        X2mu = affineTransformBigWarp(U2mu,coorPoints(:,1:3),coorPoints(:,4:6));
        Xmu = [X1mu;X2mu];
    else
        if(registrationShifts(expIndex).changesInShift)
            shiftX = preRegShift(registrationShifts(expIndex));
            N = length(shiftX);
            for n = 1 : N
                planeInd = U(:,3)==n;
                U(planeInd,1) = U(planeInd,1) + shiftX(n);
            end
        end
        Umu = U.*repmat(mic2pixscale,size(U,1),1);
        coorPoints = dlmread([fileDirs.registration.landmarks  num2str(caobj.fishID) caobj.expCond '-BigWarp-landmarks2.csv'],',');
        Xmu = affineTransformBigWarp(Umu,coorPoints(:,1:3),coorPoints(:,4:6));
    end
    Xpix = Xmu.*(repmat(1./mic2pixscale,size(Xmu,1),1));
    
    Coordinates = [Coordinates; Xpix];
    Cmu = [Cmu;Xmu];
    
    if options.demoRegistration
        % This is not necessary for registration, just to demonstrate its
        % performance
        selectPointsGlobal = false(size(Xpix,1),1);
        if animalName==1
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
            imagesc(fixedImages(:,:,uniPlanes(subInd)),[0 500]);hold on;
            selectPointsGlobal = abs(c2plot(:,3)-uniPlanes(subInd))<0.5;
            plot(c2plot(selectPointsGlobal,1),c2plot(selectPointsGlobal,2),'ro')
        end
    end
end

if options.register2Zbrain
    ZBtransformFileName = [fileDirs.registration.landmarks 'ref2Zbrain-BigWarp-landmarks2.csv'];
    coorPoints = dlmread(ZBtransformFileName,',');
    Cmu = affineTransformBigWarp(Cmu,coorPoints(:,1:3),coorPoints(:,4:6));
    Coordinates = Cmu.*(repmat(1./[0.798,0.798,2],size(Cmu,1),1));
end
end