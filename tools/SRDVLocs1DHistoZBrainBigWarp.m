function SRDVLocs1DHistoZBrainBigWarp(varargin)
% SRDVLocs1DHistoZBrainBigWarp - histogram dorsal-ventral location of SR
% cells
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
global saveCSV 
options = struct('sigLeft',[],'sigRight',[],'Coordinates',[],'perCellWeight',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.sigLeft) || isempty(options.sigRight) || isempty(options.Coordinates)
    [CAntic,mauthnerCellCoord,~,~,~,perCellWeight,dvplane2microns] = SRLocs1DHistoZBrainBigWarp;
    mauthnerCellZCoord = mauthnerCellCoord(3);
else
    if isempty(options.perCellWeight) 
        [CAntic,mauthnerCellCoord,~,~,~,perCellWeight,dvplane2microns] = SRLocs1DHistoZBrainBigWarp(varargin{:});
         mauthnerCellZCoord = mauthnerCellCoord(3);
    else
        perCellWeight = options.perCellWeight;
        mauthnerCellZCoord  = 67;
        CAntic = options.Coordinates(options.sigLeft|options.sigRight,:);
        dvplane2microns = 1/2;
    end
end
d =  mauthnerCellZCoord-CAntic(:,3);

% format data to plot into a sharable format
data.location = d./dvplane2microns;
data.sampleWeight = perCellWeight;

% plot
bw=10; % microns
binCenters = -50:bw:140;
pB = plotBinner([data.location data.sampleWeight],binCenters);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',false,'sum',true);
XLIM = [-45 120]; XLABEL = {'distance above Mauthner cell (microns)'};

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
    fprintf(fileID,'Panel\nc\n');
    fprintf(fileID,',dorsal-ventral distance from Mauthner cell (microns)');
    dlmwrite([fileDirs.scDataCSV 'Figure 6.csv'],binCenters(~isnan(binnedData)),'delimiter',',','-append','coffset',1);
    fprintf(fileID,',Weighted fraction of SR cells');
    wf = (binnedData./totalNumCellPerFish)';
    dlmwrite([fileDirs.scDataCSV 'Figure 6.csv'],wf(~isnan(binnedData)),'delimiter',',','-append','coffset',1);
    fclose(fileID);
end

