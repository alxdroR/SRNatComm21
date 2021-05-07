function  effectSizeVsLocationAksayBoot(data,varargin)
% effectSizeVsLocationAksayBoot
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
global saveCSV 

options = struct('effectSize',[],'fracAblated',[],'sigLeft',[],'sigRight',[],'Coordinates',[],'STACriteria',[],'minSacRatePerDirection',5);
options = parseNameValueoptions(options,varargin{:});

ind2show=find(data.numFish==29);
%ind2show=find(data.numFish==10);
minNumFixCut = data.minNumFixations;
minNumFixCut(data.minNumFixations<data.NminFloorValues(ind2show))=NaN;
Nmin = min(minNumFixCut);
numResamples = round(minNumFixCut./Nmin);
fracAblated = expandGFAbl2Resamples(data.fracAblated,numResamples);

%%
% convert ablation location from pixels to microns away from Mauthner cell
[rbndries,~,regions,mauthnerCellCoord] = rborders;
largeScale = 139;
rcpix2micron = largeScale/50;
ablLocationMicrons = (mauthnerCellCoord(1)-fracAblated.rccenter)/rcpix2micron;
%%
% get rhombomere locations for plotting
rbndries = [-Inf rbndries Inf];
textLocations = [rbndries(2)/2 diff(rbndries(2:end-1))/2 + rbndries(2:end-2) rbndries(end-1)+(1285-rbndries(end-1))/2];
textLocations = (mauthnerCellCoord(1)-textLocations)/rcpix2micron;
rctext = {'r1' regions{:}};
%%
% format data to plot into a sharable format
data.location = repmat(ablLocationMicrons,100,1);
data.changeFD = data.effectSize{ind2show};
%%
if 1
    figure;hold on;
    binCenter = 30;
    binCenters = [-180:30:90];
    %x = repmat(ablLocationMicrons,100,1);
    pB = plotBinner([data.location 100*data.changeFD(:)],binCenters);[binnedDataTest,binVar,numberSamp] = binData(pB,'median',true);
    %pB = plotBinner([ablLocationMicrons 100*data.changeFD(:,1)],binCenters);[binnedDataTest,binVar,numberSamp] = binData(pB,'median',true);
    binnedDataTest(numberSamp<10)=NaN;%fprintf('We excluded time points that had fewer than 10 samples for computing the average rate of rise\n');
    ablLocation = binCenters(~isnan(binnedDataTest));
    effect = binnedDataTest(~isnan(binnedDataTest));
    sem = sqrt(binVar(~isnan(binnedDataTest))./numberSamp(~isnan(binnedDataTest)));
    horzBinLengths = ones(length(ablLocation),1)*binCenter/2;
    errorbar(ablLocation,effect,sem,sem,horzBinLengths,horzBinLengths); hold on;
    plot(ablLocationMicrons,100*data.changeFD(:,1),'.','Color',[1 1 1]*0.8)
    box off;ylim([-50 220]);
    set(gca,'XTick',[-256.8 -200:50:150],'XTickLabel',{'s.c.' [-200:50:150]},'YTick',-100:50:1000)
    xlim([-200 100]); 
    xlabel('rostral-caudal distance from Mauthner cell (microns)');ylabel('percent change in median fixation duration');
    setFontProperties(gca)
else
    fracAblatedIsNotNan  = ~isnan(multiRunData.data.fracAblated.Ant);
    X= [];Y=[];
    for zind = 1 : length(multiRunData.data.changeFD)
        X = [X;ablLocationMicrons(fracAblatedIsNotNan)];
        Y = [Y; 100*multiRunData.data.changeFD{zind}(fracAblatedIsNotNan)];
    end
    %%
    figure;
    binCenters = [-200:30:90];
    pB = plotBinner([X Y],binCenters);[binnedDataTest,binVar,numberSamp] = binData(pB,'median',false);
    binnedDataTest(numberSamp<10)=NaN;fprintf('We excluded time points that had fewer than 10 samples for computing the average rate of rise\n');
    errorbar(binCenters(~isnan(binnedDataTest)),binnedDataTest(~isnan(binnedDataTest)),sqrt(binVar(~isnan(binnedDataTest))./numberSamp(~isnan(binnedDataTest)))); hold on;
    plot(X,Y,'.','Color',[1 1 1]*0.8)
    xlim([-200 100]); box off;ylim([-100 1005]);
    set(gca,'XTick',[-256.8 -200:50:150],'XTickLabel',{'' [-200:50:150]},'YTick',-100:50:1000)
    xlabel('rostral-caudal distance from Mauthner cell (microns)');ylabel('percent change in median fixation duration');
    setFontProperties(gca)
end
% plot rhombomere boundaries
for ind=1:length(rbndries)-3
    text(textLocations(ind),210,rctext{ind},'FontName','Arial','FontSize',7,'Color','k')
end
ind = length(rbndries)-1;
text(textLocations(ind),210,'r7-8','FontName','Arial','FontSize',7,'Color','k')
set(gcf,'PaperPosition',[0 0 2.5 2.5])
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

minNumFixCut = data.minNumFixations(data.minNumFixations>=data.NminFloorValues(ind2show));
Nmin = min(minNumFixCut);
numResamples = round(minNumFixCut./Nmin);
fprintf('Each point is constructed using %d randomly selected samples from a single fish\n',Nmin);
fprintf('%d gray points sampled from %d fish are displayed\n',size(data.effectSize{ind2show},1),data.numFish(ind2show));
fprintf('Error bars: N = %d Bootstrap samples independently selected from %d fish (see Methods)\n',nansum(numberSamp),data.numFish(ind2show))
fprintf('The number of bootstrap samples per bin ranges from %d-%d\n',min(numberSamp),max(numberSamp))
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 8d.csv'],'a');
    fprintf(fileID,'Panel\nd\n');
    
    pB = plotBinner([data.location 100*data.changeFD(:)],binCenters);[binnedDataTest,binVar,numberSamp] = binData(pB,'median',true);
    XMat = NaN(max(numberSamp),length(binCenters));
    indicesPerBin = pB.binData('onlyReturnIndicesPerBin',true);
    for k = 1 : length(binCenters)
        sampsAtBin = 100*data.changeFD(indicesPerBin{k});
        sampsAtBin(isinf(sampsAtBin)) = NaN;
        XMat(1:length(sampsAtBin),k) = sampsAtBin;
    end
    binCentersRel = binCenters(numberSamp>=10);
    XMat = XMat(:,numberSamp>=10);
    fprintf(fileID,'\nTable of Percent Change in Median Fixation Duration\n\n');
    fprintf(fileID,'ablation location: rostral-caudal distance from Mauthner cell (microns)');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8d.csv'],binCentersRel,'delimiter',',','-append','coffset',1);
     dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8d.csv'],[XMat],'delimiter',',','-append','coffset',1);
    fclose(fileID);
end
