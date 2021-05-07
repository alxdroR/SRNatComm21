function varargout=SRRCLocs1DHistoZBrainBigWarp(varargin)
% SRRCLocs1DHistoZBrainBigWarp - histogram rostral-caudal location of SR
% cells
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
global saveCSV
options = struct('sigLeft',[],'sigRight',[],'Coordinates',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.sigLeft) || isempty(options.sigRight) || isempty(options.Coordinates)
   [CAntic,mauthnerCellCoord,rcpix2micron,rombLocations,rctext,perCellWeight] = SRLocs1DHistoZBrainBigWarp;
else
    [CAntic,mauthnerCellCoord,rcpix2micron,rombLocations,rctext,perCellWeight] = SRLocs1DHistoZBrainBigWarp(varargin{:});
end
varargout{1} = perCellWeight;
d = mauthnerCellCoord(1)-CAntic(:,1);


% format data to plot into a sharable format
data.location = d./rcpix2micron;
data.sampleWeight = perCellWeight;
data.rombLocations = rombLocations;
data.romb = rctext;

% plot
bw=10; % microns
binCenters = -200:bw:150;
pB = plotBinner([data.location data.sampleWeight],binCenters);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',false,'sum',true);
XLIM = [-180 150];XLABEL = {'distance from Mauthner cell (microns)'};


axisFontSize = 6;
PAPERPOSITION =[4 5 2.5 2.5];
barColor = [0,0.45,0.74];
YLIM = [0 0.2]; YLABEL = 'fraction of pre-saccadic rise cells';YTICK = (0:5:20)./100;YTICKLABEL = (0:5:20)./100;

figure;hold on;
totalNumCellPerFish = nansum(binnedData);
wf = binnedData./totalNumCellPerFish;
bh=bar(binCenters,wf); hold on;
bh.FaceColor=barColor;
xlim(XLIM);ylim(YLIM);

% add text
correctionSoR4InPrintAllignedAtZero = 0;
for ind=2:length(data.romb)+1
    text(data.rombLocations(ind-1),0.13,data.romb{ind-1},'FontName','Arial','FontSize',axisFontSize,'Color','k')
end
ylabel(YLABEL);xlabel(XLABEL);
set(gca,'YTick',YTICK,'YTickLabel',YTICKLABEL);setFontProperties(gca,'fontSize',axisFontSize);
set(gcf,'PaperPosition',PAPERPOSITION,'InvertHardcopy','off','Color',[1 1 1])

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 6.csv'],'a');
    fprintf(fileID,'Panel\na\n');
    fprintf(fileID,',rostral-caudal distance from Mauthner cell (microns)');
    dlmwrite([fileDirs.scDataCSV 'Figure 6.csv'],binCenters(~isnan(binnedData)),'delimiter',',','-append','coffset',1);
    fprintf(fileID,',Weighted fraction of SR cells');
    wf = (binnedData./totalNumCellPerFish)';
    dlmwrite([fileDirs.scDataCSV 'Figure 6.csv'],wf(~isnan(binnedData)),'delimiter',',','-append','coffset',1);
    fclose(fileID);
end

