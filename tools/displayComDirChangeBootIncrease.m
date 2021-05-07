function displayComDirChangeBootIncrease()
% displayComDirChangeBootIncrease - show change in median fixation duration
% after single-cell ablations using re-sampling procedure
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 
global saveCSV

% boxplotPercentChangeMedianCombineDirectionAksayBoot old method
% load results from multiple runs of resampling using
% pvalDistMedCombDirAksayBoot.m
[~,~,fileDirs] = rootDirectories;
%allData=load([smallDataPath 'pvalDistMedCombDirAksayBoot.mat'],'data');
allData=load([fileDirs.scAblCVsTfd 'pvalDistMedCombDirAksayBoot.mat'],'data');
% compute the results for sham ablation 
[~,~,numFixations]=populationDurationStats('summaryStat',@nanmedian,'computeChangeStat',true,'changeType','percent');
[~,numFixations2use] = aksayResampleNumFixationStats(numFixations);
%numFixations2use = 33;
rng('default')
[shamNullDist,shamNumFix,~,shamAnIDs] = create1animal1pointNullDataSet('K',numFixations2use);
[~,nfind] = sort(shamNumFix.both,'descend');

% load animalIDs
[durations,asc,~,~,anID]=populationDurationStats('summaryStat',@nanmedian,'computeChangeStat',true,'changeType','percent','aksayBootMethod',numFixations);
[~,~,selC,selNC] = filterByAblationSize(durations,[7 25],asc,'aksayBootMethod',true);
[~,~,expInd] = listAnimalsWithImaging('coarseAblationRegistered',true);
anID.experimentID = anID.experimentID(selNC) + max(expInd);
anID.controlID = anID.controlID(selC) + max(expInd);
anID.shamID = shamAnIDs(nfind(1:length(anID.controlID)));
% loop over runs, find a `typical` run, then show data from this run
B = length(allData.data); 
meanSamples = NaN(B,2);
for b = 1 : B
    xbarExp = nanmean(allData.data(b).durations.experiment);
    xbarC = nanmean(allData.data(b).durations.control);
    meanSamples(b,1) = xbarExp;
    % mean difference 
    meanSamples(b,2) = xbarExp - xbarC;
end
avgChange = mean(meanSamples(:,2)); 
% find the typical index 
[~,index2show] = min(abs(avgChange - meanSamples(:,2)));

%data.sham = shamNullDist.dBothStat(~isnan(shamNullDist.dBothStat));
data.sham = shamNullDist.dBothStat(nfind(1:length(anID.controlID)));
data.control = allData.data(index2show).durations.control;
data.experiment = allData.data(index2show).durations.experiment;

% show a box plot 
labels = [repmat({'sham ablation'},length(data.sham),1) ...
    ;repmat({'4-7 control cells'},length(data.control),1) ...
    ;repmat({'4-7 SR cells'},length(data.experiment),1)];
combinedGroups = [data.sham';data.control;data.experiment];

figBox = figure;
boxPositions = [0:2];
colorMatrix = [ [1 1 1]*0.5... % light gray
                ;[1 1 1]*0.1 ... % dark gray 
                ;[1 0 0]]; % red for ablated
colorMatrix = 'k';
boxplot(combinedGroups,labels,'Colors',colorMatrix,'OutlierSize',0.1,'Symbol','w','Widths',0.70,'Positions',boxPositions,'medianstyle','line'); 
box off;hold on;

groups2show = {'sham','control','experiment'};
for groupIndex = 1 : length(groups2show)
    plot(boxPositions(groupIndex),data.(groups2show{groupIndex}),'.','MarkerSize',4,'Color',[255,140,0]./255);
end
ylim([-100 300])
title([]);set(gca,'XTickLabel',[]);ylabel('')
setFontProperties(gca);
set(gcf,'PaperPosition',[0 0 2.2 2.2],'InvertHardcopy','off','Color',[1 1 1]) 

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

[p,~,stats]=anova1(combinedGroups,labels);
cTable = multcompare(stats,'Alpha',0.05,'CType','bonferroni');
fprintf('t-test p=%0.6f control-experiment\n',cTable(3,6));
fprintf('t-test p=%0.6f sham-experiment\n',cTable(2,6));
fprintf('t-test p=%0.6f sham-control\n',cTable(1,6));

% print p-vals 
[p,h,stats]=ranksum(data.control,data.experiment);
fprintf('ranksum p=%0.3f control-experiment\n',p);
[p,h,stats]=ranksum(data.sham,data.experiment);
fprintf('ranksum p=%0.3f sham-experiment\n',p);
[p,h,stats]=ranksum(data.sham,data.control);
fprintf('ranksum p=%0.3f sham-control\n',p);
% print stats in figure caption
muExp = nanmean(data.experiment);
muCon = nanmean(data.control);
muSham = nanmean(data.sham);
nExp = sum(~isnan(data.experiment));
nCon = sum(~isnan(data.control));
nSham = sum(~isnan(data.sham));
semExp = nanstd(data.experiment)/sqrt(nExp);
semCon = nanstd(data.control)/sqrt(nCon);
semSham = nanstd(data.sham)/sqrt(nSham);
fprintf('The mean +- sem for SR-targeted, control-targeted, and sham ablations was\n');
fprintf('%0.3f +- %0.3f (n=%d from 10 animals)\n, %0.3f +- %0.3f (n=%d from 10 animals)\n, %0.3f +- %0.3f(n=%d from %d animals) percent\n, respectively\n',muExp,semExp,nExp,muCon,semCon,nCon,muSham,semSham,nSham,nSham);
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 7e.csv'],'a');
    fprintf(fileID,'Panel\ne\n');
    fprintf(fileID,'%% change median fixation duration');
    fprintf(fileID,'\nSample Index,Animal ID,SR ablated,Animal ID, control ablated,Animal ID, sham ablation\n');
    maxNumSamp = max(max(length(data.sham),length(data.control)),length(data.experiment));
    matrix2print = NaN(maxNumSamp,6);
    matrix2print(1:length(data.experiment),1)=anID.experimentID;
    matrix2print(1:length(data.experiment),2)=data.experiment;
    matrix2print(1:length(data.control),3)=anID.controlID;
    matrix2print(1:length(data.control),4)=data.control;
    matrix2print(1:length(data.sham),5)=anID.shamID;
    matrix2print(1:length(data.sham),6)=data.sham;
    matrix2print = [(1:maxNumSamp)' matrix2print];
    dlmwrite([fileDirs.scDataCSV 'Figure 7e.csv'],matrix2print,'delimiter',',','-append');
    fclose(fileID);
end
