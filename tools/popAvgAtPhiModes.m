function popAvgAtPhiModes(varargin)
% popAvgAtPhiModes - plot the population average of all STAs whose PCA
% value of PHI is near the mode
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

options = struct('lon',[],'OFFCut',[],'STACAT',[],'tauPCA',[],'binWidth',15,'ID',[],...
    'XLabel','time relative to saccade (s)','YLabel','deconvolved averages (a.u.)','paperPosition',[0 1 2 0.75]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.lon) || isempty(options.STACAT)
    script2RunPCAOnSTA;
    OFFCut = 90;
    lon =  shiftLongitude(lon,OFFCut,'reorder',false);
else
    lon = options.lon;
    OFFCut = options.OFFCut;
    STACAT = options.STACAT;
    tauPCA = options.tauPCA;
end

% find locations of phi density peaks
[lonDen,XI]=ksdensity(lon-OFFCut,0:0.5:360);
[pks,phiDenPeakIndices]=findpeaks(lonDen,XI);

N = size(STACAT,1)/2; % total number of cells (number of STAs  / 2 )
pairedIndex = [(1:2*N)',[(1:N)'+N;(1:N)']];
binCenters = phiDenPeakIndices+OFFCut;
popAvgPlotObj = plotBinnedPopAvgs('filename','popAvgAtPhiModes','autoSubplotSpacing',false,'axesSpacing',0.01,...
    'Marker','.','MarkerSize',3,'FaceAlpha',0.1,'FontSize',6,'paperPosition',options.paperPosition,'XLIM',[-4.666 5.333],'YLIM',[-17 700],...
    'zeroLineYMax',0.77,'zeroLineWidth',0.3,'zeroLineColor',[0 0 0],'zeroLineStyle','--',...
    'XTick',[-4 -2 0 2 4],'XTickLabel',{'-4' '-2' '0' '2' '4'},'XLabel',{options.XLabel},'XLabelOffset',0.06,'YLabel',options.YLabel,...
    'YLabelPosition',[-0.25,0.1],'sortName','\bf \phi ','sortNameLabelPosition',[-5.667,700.09],'sortNameEqualPosition',[-3.467,700.085],'sortNameValuePosition',[-1,700.085],...
    'numSamplePercentCutoff',0,'setAvgMin',0,'X',STACAT,'sortValue',lon,'binCenters',binCenters,'binWidth',options.binWidth,'time',tauPCA,...
    'addAlternateDirection',pairedIndex,'altDirLineColor',[1 1 1]*0.7);
popAvgPlotObj.plot
for bindex = 1 : length(popAvgPlotObj.binCenters)
    staInds = popAvgPlotObj.STAIndicesAtBins{bindex};
    staInds(staInds>N) = staInds(staInds>N)-N;
    [nc,nf,ne]=getSampleSizeFromSRMatrix(options.ID(staInds,:));
    fprintf('bin %0.2f : %d fixations from %d cells examined over %d independent fish\n',binCenters(bindex),ne,nc,nf)
end


