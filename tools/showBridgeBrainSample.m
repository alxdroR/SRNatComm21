function showBridgeBrainSample
% showBridgeBrainSample - show a sample plane from the bridge brain. 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 
 
[~,~,fileDirs] = rootDirectories;
fixedImages = rawData.loadTIFF(fileDirs.twoPBridgeBrain,'useImread',false);

% load scale bar pixel conversion factor
bridgeBrainMetaData = rawData.grabMetaData(fileDirs.twoPBridgeBrain,'isImageJFile',true,'checkIfScanImageFile',false);

% make a green image
I2display = single(fixedImages(:,:,30));
I = zeros([size(I2display),3]);
slc = @(x) (x- min(x(:)))./(max(x(:))-min(x(:)));
I(:,:,2) = imadjust(slc(I2display),[0.03 0.3]);

scaleBarWidth = 100; % microns
figure;
imagesc(I);
hold on;
plot([0 scaleBarWidth/bridgeBrainMetaData.XMicPerPix]+1009,[1 1]*847,'w','LineWidth',1)
set(gcf,'Units','inches'); view(gca,90,90);
set(gcf,'PaperPosition',[0 0 2.67*((1050/1501)+0.07) 2.67],'InvertHardCopy','off')

thisFileName = mfilename;
%printAndSave(thisFileName)
printAndSave(thisFileName,'formattype','-dtiffn','addPrintOps','-r720');
