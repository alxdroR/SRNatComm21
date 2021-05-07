function [CAntic,mauthnerCellCoord,rcpix2micron,rombLocations,rctext,perCellWeight,dvplane2microns] = SRLocs1DHistoZBrainBigWarp(varargin)
% SRLocs1DHistoZBrainBigWarp Load data required to run SRRCLocs1DHistoZBrainBigWarp,SRLRLocs1DHistoZBrainBigWarp,SRDVLocs1DHistoZBrainBigWarp 
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

options = struct('sigLeft',[],'sigRight',[],'Coordinates',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.sigLeft) || isempty(options.sigRight) || isempty(options.Coordinates)
   loadAnticipatorySelectionCriteria
else
    sigRight = options.sigRight;
    sigLeft = options.sigLeft;
    Coordinates = options.Coordinates;
end
CAntic = Coordinates(sigLeft|sigRight,:);

rcpix2micron = 1/0.798;
dvplane2microns = 1/2;
[~,~,fileDirs]=rootDirectories;
load([fileDirs.maps 'numFishZBrainTrans.mat'],'numFishZB');
nSampleMap = numFishZB;  % load the appropriate sample map not what is loaded in loadAnticipatorySelectionCriteria

numFishSamplePerCoord = NaN(size(Coordinates,1),1);
for j = 1 : size(Coordinates,1)
    coorRoundPixel = round(Coordinates(j,:));
    numFishSamplePerCoord(j) = nSampleMap(coorRoundPixel(2),coorRoundPixel(1),coorRoundPixel(3));
end
numFishSamplePCAntic = numFishSamplePerCoord(sigLeft|sigRight);

% compute zbrain midline, mauthner cell location, rhombomere location
load(fileDirs.ZBrainMasks,'MaskDatabase','MaskDatabaseOutlines','height','width','Zs');
rhomInd = 219:225; mauthInd = 184;
rbndries = zeros(length(rhomInd)+1,1);
rhMaskAll = zeros(height,width,Zs);
for j=1: length(rhomInd)
    rhOutline = reshape(full(MaskDatabase(:,rhomInd(j))),height,width,Zs);
    rhMask = rhOutline(:,:,81);
    rhMask = rhMask'; rhMask = flipud(rhMask);
    if j ==1
        rbndries(j) = find(rhMask(300,:),1,'First');
    end
    rbndries(j+1) = find(rhMask(300,:),1,'Last');
    rhMaskAll = rhMaskAll + j*double(rhOutline);
end
textLocations =  rbndries(1:end-1) + diff(rbndries)/2;
rctext = {'r1' 'r2' 'r3' 'r4' 'r5' 'r6' 'r7-8'};

mauthOutline =  reshape(full(MaskDatabaseOutlines(:,mauthInd)),height,width,Zs);
mauthnerCellCoord = zeros(1,3);
leftMCRC = (find(mauthOutline(:,253,74),1,'First') + find(mauthOutline(:,253,74),1,'Last'))/2;
rightMCRC = (find(mauthOutline(:,374,74),1,'First') + find(mauthOutline(:,374,74),1,'Last'))/2;
mauthnerCellCoord(1) = mean([leftMCRC,rightMCRC]); 
% for some reason the mask has the Mauthner cell at 74 but in the RFP image
% the MC is clearly largest at 67?
mauthnerCellCoord(3) = 67;

rombLocations = zeros(length(rbndries)-1,1);
correctionSoR4InPrintAllignedAtZero = 0;
for ind=2:length(rbndries)
    rombLocations(ind-1) = (mauthnerCellCoord(1)-textLocations(ind-1)+correctionSoR4InPrintAllignedAtZero)/rcpix2micron;
end

% calculate weighting so that weighted sum is the appropriate average for number of cells/fish
perCellWeight = 1./numFishSamplePCAntic; perCellWeight(numFishSamplePCAntic==0)=NaN;


end

