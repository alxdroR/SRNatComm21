function demoImage()
% demoImage - plot exemplar cell locations found by the morphological opening algorithm
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020


% load data
fid = listAnimalsWithImaging;
expIndex = 3;
planeIndex = 9;
avgImgFile = getFilenames(fid{expIndex},'fileType','averageImages');
load([avgImgFile '.mat'],'images');

% make a green image
I = zeros([size(images.channel{1}(:,:,planeIndex)),3]);
slc = @(x) (x- min(x(:)))./(max(x(:))-min(x(:)));
I(:,:,2) = imadjust(slc(images.channel{1}(:,:,planeIndex)),[0 0.9]);

% load points selected by morphological opening algorithm
IMCoor = viewLocationsIMOpen(fid{expIndex},planeIndex,'indices2show','all','expCond',[]);

% load scale bar pixel conversion factor
%rawobj = rawData('fishid',fid{expIndex},'fileNumber',planeIndex);
%largeScale = rawobj.micron2pixel(50);
largeScale = 139;
rcpix2micron = largeScale/50;

% format data to plot into a sharable format
data.avgImage = I;
data.pix2micron = rcpix2micron;
data.cellCenters = IMCoor;

% plot
Width2view = 105; % pixels
rcWindowForCells = [0 Width2view] + 285;
lmWindowForCells = [0 Width2view] + 285;
scaleBarWidth = 5; % microns
figure;
imagesc(data.avgImage);
hold on;
plot([0 data.pix2micron*scaleBarWidth]+285,[1 1]*385,'w')
axis off
xlim(rcWindowForCells)
ylim(lmWindowForCells)
set(gcf,'PaperPosition',[0 0 2 2],'InvertHardCopy','off');
% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'formattype','-dtiffn','addPrintOps','-r1500')

% add the locations found by the morphological opening algorithm
plot(data.cellCenters(:,1),data.cellCenters(:,2),'.','color','r','MarkerSize',6)
set(gcf,'PaperPosition',[0 0 2 2],'InvertHardCopy','off')

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)
