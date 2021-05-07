function numSampSag()
% numSampSag - create a saggital map of the number of fish sampled at a
% given location in the 2p reference brain
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

clear
if 0
    % compute the sagital map of number of samples
    [nSagMap,options] = numSamplesSagMap;
    
    % add rhombomeres  (we need to transform the coordinates using the same parameters of decimation used in numSamplesSagMap.m above)
    % coordinates of midline and Mauthner
    if ~exist('img')
        refbrainFile = refbrainFilename;
        load(refbrainFile,'img')
        img = imadjust3d_stretch(img,[0.6 0.99]);
    end
    RCSpacingIndex = 9/0.3597;
    [midlineRegion,midlineSTD] = midline('display','off','refbrain',img);
    [rbndries,~,regions,mauthnerCellCoord] = rborders('display','off','refbrain',img);
    rbndries = [-Inf rbndries Inf];
    textLocations = [rbndries(2)/2 diff(rbndries(2:end-1))/2 + rbndries(2:end-2) rbndries(end-1)+(1285-rbndries(end-1))/2];
    rctext = {'r1' regions{:}};
    
    rombLocations = zeros(length(rbndries)-1,1);
    for ind=2:length(rbndries)
        rombLocations(ind-1) = textLocations(ind-1)/round(RCSpacingIndex);
    end
end

% use Z-Brain registered map
[~,~,fileDirs]=rootDirectories;
load([fileDirs.maps 'numFishZBrainTrans.mat']);
if 0 
    % This is the equivalent Tiff file 
numFishFile =  [smallDataPath 'numFishZBrainTrans.tif'];
fizexImageInfo = imfinfo(numFishFile);
numFishZB = zeros(fizexImageInfo(1).Height, fizexImageInfo(1).Width,...
    length(fizexImageInfo),'uint16');
TifLink = Tiff(numFishFile,'r');
for i = 1:length(fizexImageInfo)
    TifLink.setDirectory(i)
    numFishZB(:,:,i) = TifLink.read();
end
TifLink.close();
numFishZB = numFishZB(:,:,2:2:end);
end
numFishZB = single(numFishZB);
sagImage = squeeze(max(numFishZB,[],1));

[H,W,N]=size(numFishZB);
% interpolation (1 micron hard coded spacing)
NInterpZ = 345;
highGrid = (1:NInterpZ)*0.798;
lowGrid = (1:N)*2;
sagLeft = permute(sagImage,[2 1 3 ]);
% interpolate ---- after meeting repeat this inerpolatin to other dv
% projections
sagLefti = zeros(NInterpZ,W);
for j=1:W
    sagLefti(:,j) = interp1(lowGrid,sagLeft(:,j),highGrid);
end

% format data to plot into a sharable format
data.numFishSampled = sagLefti;
%data.rombLocations = rombLocations;
%data.romb = rctext;
data.micPerPixel = 0.7980005;

% plot

figure;
imagesc(data.numFishSampled,[0 12])
hold on;colormap('gray');
plot([0 100/data.micPerPixel] + 950,[1 1]*288,'w')
axis off
if 0
    axisFontSize = 6;
    % add boundries
    for ind=2:length(data.romb)+1
        text(data.rombLocations(ind-1),25,data.romb{ind-1},'FontName','Arial','FontSize',axisFontSize,'Color','w'); hold on;
    end
end
set(gcf,'InvertHardCopy','off','PaperPosition',[0 0 4.5 1.1])
%set(gcf,'PaperPosition',[0 0 2*((60/25)-0.1) 2],'InvertHardcopy','off','Color',[1 1 1])


% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)




