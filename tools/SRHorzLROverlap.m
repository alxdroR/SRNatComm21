function varargout = SRHorzLROverlap(varargin)
% SRHorzLROverlap
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

options = struct('sigLeft',[],'sigRight',[],'Coordinates',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.sigLeft) || isempty(options.sigRight)
   loadAnticipatorySelectionCriteria
else
    sigRight = options.sigRight;
    sigLeft = options.sigLeft;
end

if isempty(options.Coordinates)
    Coordinates = registeredCellLocationsBigWarp('register2Zbrain',false);
    varargout{1} = Coordinates;
else
    Coordinates = options.Coordinates;
end
[midlineRegion,midlineSTD] = midline('display','off');
if false
CAntic = Coordinates(sigLeft|sigRight,:);
% bin sizes and reference brain
[~,~,fileDirs] = rootDirectories;
fixedImages = rawData.loadTIFF(fileDirs.twoPBridgeBrain,'useImread',false);

fixedImages = double(fixedImages);
fixedImages = imadjust3d_stretch(fixedImages,[0.6 0.99]);

rawobj = rawData('fishid',14,'fileNumber',17);
largeScale = rawobj.micron2pixel(50);rcpix2micron = largeScale/50;
bw = round(rcpix2micron*12); % 12 micron binwidt
dvplane2micron = 1/3;
bwDV = dvplane2micron*12;

% coordinates of midline and Mauthner
[midlineRegion,midlineSTD] = midline('display','off','refbrain',fixedImages);
[rbndries,~,regions,mauthnerCellCoord] = rborders('display','off','refbrain',fixedImages);
rbndries = [-Inf rbndries Inf];
textLocations = [rbndries(2)/2 diff(rbndries(2:end-1))/2 + rbndries(2:end-2) rbndries(end-1)+(1285-rbndries(end-1))/2];
rctext = {'r1' regions{:}};
mauthnerCellCoord = mean(mauthnerCellCoord);

% colormap will have a lower and upper saturation at [minCount maxCount]
minCount = 0;
mapType = 'probability';
NormFactor = size(CAntic,1);
maxCount = 100*(8/NormFactor);

% we mainly worry about sampling error in rc
%[~,smallDataPath] = rootDirectories;
%nSampleMap = regionsSampled;
%load([smallDataPath 'temp/regionsSampledMarch232018'],'nSampleMap');
%[~,weightNorm] = sampleDensities1d(nSampleMap,'axis','rc','minRelDensity',0.05); % nSampleMap is loaded in loadAnticipatorySelectionCriteria>loadSTAANOVACut>loadNumAnimalsCut
% setting this ones prevents weighting
weightNorm = ones(1,1476);
%% Show laterality and location using color mixing to reflect degree of L/R overlap
% probably should show a merged map where values show number of cells and 
% amount of mixing is shown by merging of colors 
deepOrange = [255 99 0]./255;
deepBlue = [0 15 204]./255;
% colormap from mixing
P = 63;
mixPortion = 0:1/P:1-1/P;
mixColorMap=mixPortion'*deepBlue + (1-mixPortion)'*deepOrange; 
% 0 mix (no left coding all right coding) is orange


CoorInput =  Coordinates(sigLeft ,:);
%NormFactor = 'weightedCount';
NormFactor = [];
 displayIndex = 30;
locationSRHelper_Coor2FusedMap;
weightedValuesLeft = weightedValues;


CoorInput =  Coordinates(sigRight,:);
hALL = histogram2(CoorInput(:,1),CoorInput(:,2),XEdges,YEdges,'DisplayStyle','tile');title('Anticipatory cells')
weightedValuesRight = weightCounts(hALL.Values',hALL.XBinEdges,weightNorm,'normalization',NormFactor);

sumMatrix = (weightedValuesLeft+weightedValuesRight);
mixMatrix = weightedValuesLeft./sumMatrix;
mixMatrix(sumMatrix==0)=(1+2/P)-(1+2/P)/P; % this special value gets its own color
mixColorMap = [mixColorMap;[1 1 1]];

% create RGB matrix of weighted counts using current colormap
wvrgb = matrix2ColorMatrix(mixMatrix,mixColorMap,[0 (1+2/P)]);

% expand this matrix to the same dimensions as fixedImages
weightedValuesBig = matrixExpand(wvrgb,size(fixedImages,1),size(fixedImages,2),YEdges,XEdges);
 %figure;imagesc(weightedValuesBig)

 % now fuse this 
% fuse 
If = 0.1*I + (1-0.1)*weightedValuesBig;
set2background = weightedValuesBig(:,:,1)==1 & weightedValuesBig(:,:,2)==1 & weightedValuesBig(:,:,3)==1;
set2background3d = false(size(If));
set2background3d(:,:,1) = set2background;
set2background3d(:,:,2) = set2background;
set2background3d(:,:,3) = set2background;

If(set2background3d) = I(set2background3d);

figure;imagesc(If); hold on;
% plot a 20 micron scale bar
rectangle('Position',[1000,1000,20*rcpix2micron,10],'FaceColor','w')
axis off

global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    set(gcf,'PaperPosition',[0 0 3.4 2.5])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
     end
    print(gcf,'-dpdf',[figurePDir thisFileName])
  %  print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\SRHorzLROverlap'])
end
%%
% make the colorbar
 CB =ones(P,2,3);
 for index = 1 : P 
     CB(index,1,1) = mixColorMap(index,1); 
     CB(index,1,2) = mixColorMap(index,2);
     CB(index,1,3) = mixColorMap(index,3);
 end
 figure;imagesc(CB); %axis off 
 hold on;
 
 colorSpacing  = (1+2/P)/(P+1);
 index2mixpro = 0:(1+2/P)/(P+1):(1+2/P) - (1+2/P)/(P+1); % this is used in matrix2ColorMatrix
 ylabel('% of cells that anticipate saccades to the right or left','FontName','Arial','FontSize',7,'Color','k')
set(gca,'FontName','Arial','FontSize',7,'XColor','w','YColor','k','XTickLabel',[],'XTick',[],...
    'YTick',[(0:0.25:1)./colorSpacing+1],'YTickLabel',{'all R' '25/75 (R/L)' '50/50 (R/L)' '75/25 (R/L)' 'all L'})

 if printOn
    set(gcf,'PaperPosition',[0 0 3.4 2.5])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
     end
    print(gcf,'-dpdf',[figurePDir thisFileName 'Colorbar'])
  %  print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\SRHorzLROverlapColorbar'])
 end
end
%% quantify number of ipsi and contraversive cells
numberIpsi = sum(Coordinates(sigRight,2)<midlineRegion(2)) + sum(Coordinates(sigLeft,2)>midlineRegion(2));
nAntic = sum(sigLeft|sigRight);
fprintf('The fraction of ipsiversive SR cells is %0.4f\n',numberIpsi/nAntic);