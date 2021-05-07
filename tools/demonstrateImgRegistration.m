function demonstrateImgRegistration()
% demonstrateImgRegistration - 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020


clear
expIndex = 17;planeIndex = 5;
[fid,expCond] = listAnimalsWithImaging;
caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'loadCCMap',false,'NMF',true,'loadImages',true);

% load bridge brain
[~,~,fileDirs]=rootDirectories;
bridgeBrainFile = fileDirs.twoPBridgeBrain;
BBImg = rawData.loadTIFF(bridgeBrainFile,'useImread',false);
imgPlaneIndex = 27;
BBImgAdj2Show = imadjust(BBImg(:,:,imgPlaneIndex),[0 0.008]);
% transform demoplane and fuse
numChannelsInFile = 3;
fishScaleMetaData = load([getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','averageImages') '.mat'],'expMetaData');
fish2Register = [getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','averageImages') '.tif'];
fish2BridgeLandmarksFile = getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','regLandmarks');
[Itransformed,~]=fuseAffineTransFromBigWarp(fish2Register,bridgeBrainFile,fish2BridgeLandmarksFile,'numMoveChannels',numChannelsInFile,'moveMetaData',fishScaleMetaData.expMetaData,'targetIsImageJFile',true);
IFuse = imfuse(imadjust(Itransformed(:,:,imgPlaneIndex),[0 0.002]),BBImgAdj2Show,'ColorChannels',[1,2,0]);

% show control points in plane of interest and add the demo points mp, fp 
load(fileDirs.registration.demoLandmarks,'fp','mp');
coorPoints = dlmread(fish2BridgeLandmarksFile,',');
bridgeBrainMeta = rawData.grabMetaData(bridgeBrainFile,'isImageJFile',true,'checkIfScanImageFile',false);
bridgeBrainMicOverPix = [bridgeBrainMeta.XMicPerPix,bridgeBrainMeta.YMicPerPix,bridgeBrainMeta.ZMicPerPlane];
[~,~,XMicPerPix] = rawData.mic2pix(1,fishScaleMetaData.expMetaData.scanParam{1});
ZMicPerPlane = str2double(fishScaleMetaData.expMetaData.zspacing(1));
micOverPixScale = [XMicPerPix,XMicPerPix,ZMicPerPlane];
Umu = coorPoints(:,1:3);
Xmu = coorPoints(:,4:6);
%Xmu = affineTransformBigWarp(Umu,coorPoints(:,1:3),coorPoints(:,4:6));
X = Xmu.*(repmat(1./bridgeBrainMicOverPix,size(Xmu,1),1))+0.5;
U = Umu.*(repmat(1./micOverPixScale,size(Umu,1),1))+0.5;
U(:,3) = U(:,3) + 1;
X(:,3) = X(:,3) + 1;

% add actual landmarks along with additional points for demo purposes (fp and mp )
points2view = abs(U(:,3)-planeIndex)<1;
mp = [mp;U(points2view,1:2)];
fp = [fp;X(points2view,1:2)];

% add a scale bar
scaleBarWidth = 50;
%rawobj = rawData('fishid',fid{expIndex},'fileNumber',planeIndex);
%largeScale = rawobj.micron2pixel(50);
largeScale = 139;
rcpix2micron = largeScale/50;

figure;
imagesc(BBImgAdj2Show); hold on; colormap('gray'); hold on;
plot(fp(:,1),fp(:,2),'r.','MarkerSize',5);
axis off;
hold on;
plot([0 rcpix2micron*scaleBarWidth]+643,[1 1]*1013,'w')
set(gcf,'PaperPosition',[0 0 1.5*(1.36+0.08) 1.5],'InvertHardcopy','off','Color',[1 1 1]);
thisFileName = mfilename;
printAndSave([thisFileName '-1']);

figure;
imagesc(IFuse);axis off;
set(gcf,'PaperPosition',[0 0 1.5*(1.36+0.08) 1.5],'InvertHardcopy','off','Color',[1 1 1]) 
printAndSave([thisFileName '-3']);

Iadj = imadjust(uint16(caobj.images.channel{1}(:,:,planeIndex)),[0 0.004]);
figure;
subplot(4,4,[1:2,5:6]);imagesc(Iadj);colormap('gray');hold on;
plot(mp(:,1),mp(:,2),'r.','MarkerSize',5);
axis off;hold on;
plot([0 rcpix2micron*scaleBarWidth]+340,[1 1]*497,'w')
set(gcf,'PaperPosition',[0 0 3.0 3.0],'InvertHardcopy','off','Color',[1 1 1]) 
printAndSave([thisFileName '-2']);
