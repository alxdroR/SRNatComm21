function varargout = ISIDistributionChangesBoxPlotsHbvsSC()
% ISIDistributionChangesBoxPlotsHbvsSC
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 
global saveCSV

behaviorStat = gatherAblationStatistics('minSacRatePerDirection',5,'statistic','ISI','maxRecordingTimeAfter',30);
[ISISort,GNSort,~,~,~,~,ISISortAnID] = gASCombineStats(behaviorStat,'ablationCondition','before and after','removeHBLocationLabel',true);
varargout{1} = behaviorStat;
%%
figure;
boxplot(ISISort,GNSort,'Colors','kr','ColorGroup',[1 0 1 0],'OutlierSize',0.1,'Symbol','w'...
    ,'GroupOrder',{'hB','hA','scB','scA'},...
    'Widths',0.70,'Positions',[0 0.75 2 2.75]);
ylim([0 45]); ylabel('fixation duration (s)');box off;setFontProperties(gca);
%xlabel('ablation site');
set(gca,'XTickLabel',[]);
global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    set(gcf,'PaperPosition',[0.5 0.5 3 2.2],'InvertHardcopy','off','Color',[1 1 1])
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\ISIDistributionChangesBoxPlotsHbvsSC'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% statistics in text 
isSCAblation = cellfun(@(x) strcmp(x,'sc'),behaviorStat.leftEye.before.ablationGroup);
numSCFish = length(unique(behaviorStat.leftEye.before.animalName(isSCAblation)));
numHBFish = length(unique(behaviorStat.leftEye.before.animalName(~isSCAblation)));
[p,anovatab,stats]=anova1(ISISort,GNSort,'off');
c=multcompare(stats,'Alpha',0.01,'CType','bonferroni');
fprintf('\nWe rejected the null hypothesis that mean fixation durations\nwere equal before or after ablations in the hindbrain or spinal cord\n');
fprintf('(one-way ANOVA; F=%0.2f, p=%0.4f;',anovatab{2,5},p);
fprintf('mean fixation duration before and after ablations\nin the hindbrain equaled %0.2f and %0.2f seconds respectively\n',stats.means(2),stats.means(1));
fprintf('(n=%d fixations before and %d after from %d fish)\n',stats.n(2),stats.n(1),numHBFish);
fprintf('mean fixation duration before and after ablations\nin the spinal cord equaled %0.2f and %0.2f seconds respectively\n',stats.means(4),stats.means(3));
fprintf('(n=%d fixations before and %d after from %d fish)\n',stats.n(4),stats.n(3),numSCFish);
fprintf('We rejected the null hypothesis that the mean fixation duration before and after hindbrain ablations were equal\n');
fprintf('(difference in means and 95 percnt CI equaled %0.3f, [%0.3f,%0.3f] seconds,p=%0.6f two-s t-test Bonforonni corrected\n',c(1,4),c(1,3),c(1,5),c(1,6))

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 8a.csv'],'a');
    fprintf(fileID,'Panel\na\n');
    fprintf(fileID,'Fixation Duration(s)\n');
    groups = {'hB','hA','scB','scA'};
    groupNames = {'hindbrain before ablation','hindbrain after ablation', 'spinal cord before ablation', 'spinal cord after ablation'};
    numSamp = zeros(4,1);
    for k = 1 : 4 
        cellSelection = cellfun(@(x) strcmp(x,groups{k}),GNSort);
        X = [ISISortAnID(cellSelection,:) ISISort(cellSelection)];
        X = X(~isnan(X(:,3)),:);
        numSamp(k) = size(X,1);
    end
    XMat = NaN(max(numSamp),4);
    for k =1 : 4
        cellSelection = cellfun(@(x) strcmp(x,groups{k}),GNSort);
        X = [ISISortAnID(cellSelection,:) ISISort(cellSelection)];
        X = X(~isnan(X(:,3)),:);
        XMat(1:numSamp(k),k) =X(:,3);
    end
        %fprintf(fileID,'Condition=%s\n',groupNames{k});
        fprintf(fileID,'Hindbrain Before Ablation,Hindbrain After Ablation,Spinal Cord Before Ablation,Spinal Cord After Ablation\n');
        %fprintf(fileID,'\nAnimal ID,Fixation Sample Index,Sample Index,Fixation Duration(s)\n');
        dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8a.csv'],XMat,'delimiter',',','-append');

    fclose(fileID);
end
