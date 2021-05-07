function pcSortedPopAverageLat(varargin)
% pcSortedPopAverageLat
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202


options = struct('lon',[],'lat',[],'STACAT',[],'tauPCA',[],'bw',15,'percent2ShowCut',0.0042,'useLeftOnly',false,'useRightOnly',false);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.lon) || isempty(options.STACAT)
    script2RunPCAOnSTA;
else
    lon = options.lon;
    lat = options.lat;
    STACAT = options.STACAT;
    tauPCA = options.tauPCA;
end


N = size(STACAT,1)/2;
if options.useLeftOnly || options.useRightOnly
    isLeftSaccade = [true(N,1);false(N,1)];
    if options.useLeftOnly
        extraCondition = isLeftSaccade;
    elseif options.useRightOnly
        extraCondition = ~isLeftSaccade;
    end
else 
    extraCondition = true(2*N,1);
end
pairedIndex = [(1:2*N)',[(1:N)'+N;(1:N)']];
binCenters = [-60:options.bw:90]; % latitude binCenters
minNumCells = round(N*options.percent2ShowCut);

% fix the longitude
lonCenter = 0;
lonCondition = lon >= lonCenter-options.bw/2 & lon <lonCenter+options.bw/2;
popAvgPlotObj = plotBinnedPopAvgs('filename',['pcSortedPopAverageLat-LatAtLon' num2str(lonCenter)],'autoSubplotSpacing',false,'axesSpacing',0.01,...
    'Marker','.','MarkerSize',3,'FaceAlpha',0.1,'FontSize',6,'paperPosition',[0 1 6 1.8],'XLIM',[-4.666 5.333],'YLIM',[-17 1090],...
    'zeroLineYMax',1090,'zeroLineWidth',0.3,'zeroLineColor',[0 0 0],'zeroLineStyle','--',...
    'XTick',[-4 -2 0 2 4],'XTickLabel',{'-4' '-2' '0' '2' '4'},'XLabel',{'time relative' 'to saccade (s)'},'XLabelOffset',0.06,'YLabel','deconvolved averages (arb.units)',...
    'YLabelPosition',[-0.25,0.1],'sortName','\bf \theta ','sortNameLabelPosition',[-5.667,1100.05],'sortNameEqualPosition',[-3.467,1100.04],'sortNameValuePosition',[1,1100.05],...
    'numSamplePercentCutoff',minNumCells,'setAvgMin',0,'X',STACAT,'sortValue',lat,'extraBinCriteria',lonCondition & extraCondition,...
    'addAlternateDirection',pairedIndex,'altDirLineColor',[1 1 1]*0.7,...
    'samplesWNorm2Match',[],'binCenters',binCenters,'time',tauPCA);
popAvgPlotObj.plot

% fix the longitude
lonCenter = 45;
lonCondition = lon >= lonCenter-options.bw/2 & lon <lonCenter+options.bw/2;
popAvgPlotObj = plotBinnedPopAvgs('filename',['pcSortedPopAverageLat-LatAtLon' num2str(lonCenter)],'autoSubplotSpacing',false,'axesSpacing',0.01,...
    'Marker','.','MarkerSize',3,'FaceAlpha',0.1,'FontSize',6,'paperPosition',[0 1 6 1.8],'XLIM',[-4.666 5.333],'YLIM',[-17 1090],...
    'zeroLineYMax',1090,'zeroLineWidth',0.3,'zeroLineColor',[0 0 0],'zeroLineStyle','--',...
    'XTick',[-4 -2 0 2 4],'XTickLabel',{'-4' '-2' '0' '2' '4'},'XLabel',{'time relative' 'to saccade (s)'},'XLabelOffset',0.06,'YLabel','deconvolved averages (arb. units)',...
    'YLabelPosition',[-0.25,0.1],'sortName','\bf \theta ','sortNameLabelPosition',[-5.667,1100.05],'sortNameEqualPosition',[-3.467,1100.04],'sortNameValuePosition',[1,1100.05],...
    'numSamplePercentCutoff',minNumCells,'setAvgMin',0,'X',STACAT,'sortValue',lat,'extraBinCriteria',lonCondition & extraCondition,...
    'addAlternateDirection',pairedIndex,'altDirLineColor',[1 1 1]*0.7,...
    'samplesWNorm2Match',[],'binCenters',binCenters,'time',tauPCA);
popAvgPlotObj.plot