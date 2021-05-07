function displayPopAvgLeftLongPCSorted(varargin)
% displayPopAvgLeftLongPCSorted - plot the population average of all STAs
% sorted by PCA score's PHI value (in spherical coord)
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
options = struct('lon',[],'STACAT',[],'tauPCA',[],'bw',15,'percent2ShowCut',0.0042,'ID',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.lon) || isempty(options.STACAT)
    script2RunPCAOnSTA;
else
    lon = options.lon;
    STACAT = options.STACAT;
    tauPCA = options.tauPCA;
end


N = size(STACAT,1)/2;
isLeftSaccade = [true(N,1);false(N,1)];
binCenters = [-90:options.bw:180 -180+options.bw:options.bw:-90-options.bw]; % bin centers
minNumCells = round(N*options.percent2ShowCut);
% load colormaps
[~,~,fileDirs] = rootDirectories;
ROYGBIV = imread([fileDirs.maps 'STADisplayGradient'],'tif');

popAvgPlotObj = plotBinnedPopAvgs('filename','displayPopAvgLeftLongPCSorted','autoSubplotSpacing',false,'axesSpacing',0.01,...
    'LineColor',ROYGBIV,'Marker','.','MarkerSize',3,'FaceAlpha',0.1,'FontSize',6,'paperPosition',[0 0.5 11 4],'XLIM',[-4.666 5.333],'YLIM',[-17 700],...
    'zeroLineYMax',700,'zeroLineWidth',0.3,'zeroLineColor',[0 0 0],'zeroLineStyle','--',...
    'XTick',[-4 -2 0 2 4],'XTickLabel',{'-4' '-2' '0' '2' '4'},'XLabel',{'time relative' 'to saccade (s)'},'XLabelOffset',0.06,'YLabel',{'deconvolved averages (arb.units)'},...
    'YLabelPosition',[-0.25,0.1],'sortName','\bf \phi ','sortNameLabelPosition',[-5.667,700.09],'sortNameEqualPosition',[-3.467,700.085],'sortNameValuePosition',[-1,700.085],...
    'numSamplePercentCutoff',minNumCells,'setAvgMin',0,'X',STACAT,'sortValue',lon,'extraBinCriteria',isLeftSaccade,'binCenters',binCenters,'time',tauPCA,...
    'ID',options.ID);
popAvgPlotObj.plot
global saveCSV
if saveCSV
    popAvgPlotObj.toCSV('X',STACAT,'sortValue',lon,'extraBinCriteria',isLeftSaccade,'binCenters',binCenters,'time',tauPCA,...
        'ID',options.ID,'figureName','Figure 3g.csv');
end
for bindex = 1 : length(popAvgPlotObj.binCenters)
    staInds = popAvgPlotObj.STAIndicesAtBins{bindex};
    staInds(staInds>N) = staInds(staInds>N)-N;
    [nc,nf,ne]=getSampleSizeFromSRMatrix(options.ID(staInds,:));
    fprintf('bin %0.2f : %d fixations from %d cells examined over %d fish\n',binCenters(bindex),ne,nc,nf)
end