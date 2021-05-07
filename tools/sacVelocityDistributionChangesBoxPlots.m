function sacVelocityDistributionChangesBoxPlots()
% sacVelocityDistributionChangesBoxPlots
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202
global saveCSV
behaviorStatVel = gatherAblationStatistics('minSacRatePerDirection',5,'statistic','saccadeVelocity','maxRecordingTimeAfter',30);
behaviorStatAmp = gatherAblationStatistics('minSacRatePerDirection',5,'statistic','saccadeAmplitude','maxRecordingTimeAfter',30);
behaviorStatVelBackup = behaviorStatVel; behaviorStatAmpBackup = behaviorStatAmp;
notUseable = isinf(behaviorStatVel.leftEye.before.saccadeVelocity);

behaviorStatVel.leftEye.before.saccadeVelocity(notUseable) = NaN;
behaviorStatAmp.leftEye.before.saccadeAmplitude(notUseable) = NaN;
%%
%[ISISort,GNSort] = gASCombineStats(behaviorStat,'ablationCondition','before and after');
vL = behaviorStatVel.leftEye.before.saccadeVelocity;
vR = behaviorStatVel.rightEye.before.saccadeVelocity;
vBefore = [vL;vR];

aL = behaviorStatAmp.leftEye.before.saccadeAmplitude;
aR = behaviorStatAmp.rightEye.before.saccadeAmplitude;
aBefore = [aL;aR];

groupBefore = [behaviorStatVel.leftEye.before.ablationGroup;behaviorStatVel.rightEye.before.ablationGroup];


vL = behaviorStatVel.leftEye.after.saccadeVelocity;
vR = behaviorStatVel.rightEye.after.saccadeVelocity;
vAfter = [vL;vR];

aL = behaviorStatAmp.leftEye.after.saccadeAmplitude;
aR = behaviorStatAmp.rightEye.after.saccadeAmplitude;
aAfter = [aL;aR];

groupAfter = [behaviorStatVel.leftEye.after.ablationGroup;behaviorStatVel.rightEye.after.ablationGroup];

pBAggreg = plotBinner([aBefore vBefore],-40:5:40);[aggMeans,aggVar,aggN,aggbinCenters] = binData(pBAggreg,'median',false);
%%
% plot the median +== sem
figure; %plotOrder = {'r23','r46','r78','sc'};
plotOrder = {'r14','r56','r78','sc'};
plotTitles = {'r1-4','r5-6','r7-8','spinal cord'};
numSaccades = struct('before',zeros(4,1),'after',zeros(4,1));
for gindex = 1 : 4
    subplot(2,2,gindex)
    properGroupB = cellfun(@(z) strcmp(z,plotOrder{gindex}),groupBefore);properGroupA = cellfun(@(z) strcmp(z,plotOrder{gindex}),groupAfter);
    
    %errorbar(aggbinCenters,aggMeans,sqrt(aggVar./aggN),sqrt(aggVar./aggN),ones(length(aggbinCenters),1)*2.5,ones(length(aggbinCenters),1)*2.5,'Color',[1 1 1]*0.3); hold on;
    % errorbar(aggbinCenters,aggMeans,sqrt(aggVar./aggN),sqrt(aggVar./aggN),ones(length(aggbinCenters),1)*2.5,ones(length(aggbinCenters),1)*2.5,'Color',[1 1 1]*0.3); hold on;
    
    pB = plotBinner([aBefore(properGroupB) vBefore(properGroupB)],-20:5:20);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',true);
    %errorbar(binCenters,binnedData,sqrt(binVar./numberSamp),sqrt(binVar./numberSamp),ones(length(binCenters),1)*2.5,ones(length(binCenters),1)*2.5,'Color','b'); hold on;
    errorbar(binCenters,binnedData,sqrt(binVar./numberSamp),'Color','k'); hold on;
    
    pB = plotBinner([aAfter(properGroupA) vAfter(properGroupA)],-20:5:20);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',true);
    %errorbar(binCenters,binnedData,sqrt(binVar./numberSamp),sqrt(binVar./numberSamp),ones(length(binCenters),1)*2.5,ones(length(binCenters),1)*2.5,'Color','r'); hold on;
    errorbar(binCenters,binnedData,sqrt(binVar./numberSamp),'Color','r'); hold on;
    
    xlim([-24 24]);ylim([-400 400]); title(plotTitles{gindex},'FontWeight','normal','FontName','Arial','FontSize',7);
    if gindex>=3 ;xlabel('saccade amplitude (deg)'); end
    if gindex ==1  || gindex ==3; ylabel('saccade velocity (deg/s)');  end;%legend('before all','before group-matched','after');
    box off;setFontProperties(gca);
    
    numSaccades.before(gindex) = sum(~isnan(vBefore(properGroupB)));numSaccades.after(gindex) = sum(~isnan(vAfter(properGroupA)));
end
%lh=legend('before','after','Location','SouthEast');lh.FontName = 'Arial';lh.FontSize=6;lh.Box = 'off';
%%
global printOn

if isempty(printOn)
    printOn = false;
end
if printOn
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    set(gcf,'PaperPosition',[0.5 0.5 3.5 2.7],'InvertHardcopy','off','Color',[1 1 1])
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\sacVelocityDistributionChangesBoxPlots'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% Supp Figure 6 Caption
fprintf(1,'\n Average saccade velocity, grouped according to ablation location,\n before (gray) and after (red) ablations as a function of saccade amplitude.\n')
fprintf(1,'\n n=%d saccades before and %d saccades after for rhombomeres 1-4,\n n= %d saccades before and %d saccades after for rhombomeres 5-6,\n n=%d saccades before and n=%d saccades after for rhombomeres 7-8,\n n=%d saccades before and n=%d saccades after for spinal cord ablations).\nError bars show standard error about the mean.\n\n',...
    numSaccades.before(1),numSaccades.after(1),numSaccades.before(2),numSaccades.after(2),numSaccades.before(3),numSaccades.after(3),numSaccades.before(4),numSaccades.after(4));

if sum(notUseable)==0
    numFishBefore = numberAnimalsEachGroup(behaviorStatVel.leftEye.before);
    numFishAfter = numberAnimalsEachGroup(behaviorStatVel.leftEye.after);
    fprintf(1,'\n The number of fish used before/after ablations is %d/%d for r1-4,\n %d/%d for r5-6, %d/%d\n for r7-8, %d/%d for s.c\n',...
        numFishBefore(1),numFishAfter(1),numFishBefore(2),numFishAfter(2),numFishBefore(3),numFishAfter(3),numFishBefore(4),numFishAfter(4));
end
binCenters = -20:5:20;
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 8c.csv'],'a');
    fprintf(fileID,'Panel\nc\n');
    for gindex = 1 : 4
        properGroupB = cellfun(@(z) strcmp(z,plotOrder{gindex}),groupBefore);
        vBeforeProp = vBefore(properGroupB);
        pB = plotBinner([aBefore(properGroupB) vBeforeProp],-20:5:20);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',true);
        XMatB = NaN(max(numberSamp),length(binCenters));
        indicesPerBin = pB.binData('onlyReturnIndicesPerBin',true);
        for k = 1 : length(binCenters)
            sampsAtBin = vBeforeProp(indicesPerBin{k});
            sampsAtBin(isinf(sampsAtBin)) = NaN;
            XMatB(1:length(sampsAtBin),k) = sampsAtBin;
        end
        fprintf(fileID,'\n,,,,,,saccade velocity(deg/s) [%s Before Ablation]\n\n',plotTitles{gindex});
        fprintf(fileID,'saccade amplitude(deg)');
        dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8c.csv'],binCenters,'delimiter',',','-append','coffset',1);
        
        %fprintf(fileID,'Sample Index\n');
        dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8c.csv'],[XMatB],'delimiter',',','-append','coffset',1);
        
        properGroupA = cellfun(@(z) strcmp(z,plotOrder{gindex}),groupAfter);
        vAfterProp = vAfter(properGroupA);
        pB = plotBinner([aAfter(properGroupA) vAfterProp],-20:5:20);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',true);
        
        XMatA = NaN(max(numberSamp),length(binCenters));
        indicesPerBin = pB.binData('onlyReturnIndicesPerBin',true);
        for k = 1 : length(binCenters)
            sampsAtBin = vAfterProp(indicesPerBin{k});
            sampsAtBin(isinf(sampsAtBin)) = NaN;
            XMatA(1:length(sampsAtBin),k) = sampsAtBin;
        end
        
        fprintf(fileID,'\n,,,,,,saccade velocity(deg/s) [%s After Ablation]\n\n',plotTitles{gindex});
        %fprintf(fileID,'%s After Ablation\n',plotTitles{gindex});
        fprintf(fileID,'saccade amplitude(deg)');
        dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8c.csv'],binCenters,'delimiter',',','-append','coffset',1);
        
        % fprintf(fileID,'Sample Index\n');
        dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8c.csv'],[XMatA],'delimiter',',','-append','coffset',1);
    end
    fclose(fileID);
end