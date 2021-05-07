function SRLRLocs1DHistoZBrainBigWarp(varargin)
% SRLRLocs1DHistoZBrainBigWarp - histogram left-right location of SR
% cells
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
global saveCSV 

options = struct('sigLeft',[],'sigRight',[],'Coordinates',[],'perCellWeight',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.sigLeft) || isempty(options.sigRight) || isempty(options.Coordinates)
    [CAntic,~,rcpix2micron,~,~,perCellWeight] = SRLocs1DHistoZBrainBigWarp;
else
    if isempty(options.perCellWeight)
        [CAntic,~,rcpix2micron,~,~,perCellWeight] = SRLocs1DHistoZBrainBigWarp(varargin{:});
    else
        perCellWeight = options.perCellWeight;
        CAntic = options.Coordinates(options.sigLeft|options.sigRight,:);
        rcpix2micron = 1/0.798;
    end
end

midlineRegion = 300;
d =  midlineRegion-CAntic(:,2);

% format data to plot into a sharable format
data.location = d./rcpix2micron;
data.sampleWeight = perCellWeight;

% plot
bw=10; % microns
binCenters = -100:bw:100;
pB = plotBinner([data.location data.sampleWeight],binCenters);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',false,'sum',true);
XLIM = [-100 100]; XLABEL = {'distance from midline (microns)'};

axisFontSize = 6;
PAPERPOSITION =[4 5 2.5 2.5];
barColor = [0,0.45,0.74];
YLIM = [0 0.2]; YLABEL = 'fraction of pre-saccadic rise cells';YTICK = (0:5:20)./100;YTICKLABEL = (0:5:20)./100;

figure;hold on;
totalNumCellPerFish = nansum(binnedData);
bh=bar(binCenters,binnedData./totalNumCellPerFish); hold on;
bh.FaceColor=barColor;
xlim(XLIM);ylim(YLIM);

ylabel(YLABEL);xlabel(XLABEL);
set(gca,'YTick',YTICK,'YTickLabel',YTICKLABEL);setFontProperties(gca,'fontSize',axisFontSize);
set(gcf,'PaperPosition',PAPERPOSITION,'InvertHardcopy','off','Color',[1 1 1])

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 6.csv'],'a');
    fprintf(fileID,'Panel\nb\n');
    fprintf(fileID,',left-right distance from midline (microns)');
    dlmwrite([fileDirs.scDataCSV 'Figure 6.csv'],binCenters(~isnan(binnedData)),'delimiter',',','-append','coffset',1);
    fprintf(fileID,',Weighted fraction of SR cells');
    wf = (binnedData./totalNumCellPerFish)';
    dlmwrite([fileDirs.scDataCSV 'Figure 6.csv'],wf(~isnan(binnedData)),'delimiter',',','-append','coffset',1);
    fclose(fileID);
end

