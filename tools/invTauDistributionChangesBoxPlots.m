function invTauDistributionChangesBoxPlots()
% invTauDistributionChangesBoxPlots
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202
clear
global saveCSV
tstart = tic;
group2GroupComparison = true; % compare before/after between equal groups (rx with rx) as opposed to lumping all values before ablation together
%% loop across all animals and combine inverse fixation time constants
loadPreRunData = false;
[~,~,fileDirs]=rootDirectories;
if loadPreRunData
    load([fileDirs.coarseAbl.invTauEffect 'gASFixationTimeConstant'],'behaviorStat');
else
    % loop across all animals and combine inverse fixation time constants
    [behaviorStat,saccRates] = gatherAblationStatistics('minSacRatePerDirection',5,'statistic','fixationTimeConstant','gofMeasure','residualVar','goodnessOFitCut',0,'maxRecordingTimeAfter',30);
end
%% combine across eyes and remove poorly fit data before ablation
[fidArray2Use,expCond] = listAnimalsWithImaging('coarseAblationRegistered',true);
fidArray2Use = fidArray2Use(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
expCond = expCond(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));

[~,~,itauBefore,itauAfter,itauAGBefore,itauAGAfter,keepB,keepA,namesB,namesA,eCB,eCA,itB,itA] = gASCombineStats(behaviorStat,'ablationCondition','before and after','fidArray2Use',fidArray2Use,'expCond',expCond);
%[~,~,itauBefore,itauAfter,itauAGBefore,itauAGAfterA] = gASCombineStats(behaviorStat,'ablationCondition','before and after');
%%
%squaredErrorBefore = [behaviorStat.leftEye.before.other;behaviorStat.rightEye.before.other];
squaredErrorBefore = itB;
goodFits = squaredErrorBefore<=0.1;

itau = [itauBefore(goodFits);itauAfter];
keep = [keepB(goodFits);keepA];
if group2GroupComparison
    itauAG = cat(1,itauAGBefore(goodFits),itauAGAfter);
    names = cat(1,namesB(goodFits),namesA);
    ec = cat(1,eCB(goodFits),eCA);
else
    itauAG = cat(1,repmat({'Before'},sum(goodFits),1),itauAGAfter);
end

[GNSort,sortIndex]=sort(itauAG);
itauSort = itau(sortIndex);
keep = keep(sortIndex);
ec = ec(sortIndex);
names = names(sortIndex);
%% plot the data
figure;
if group2GroupComparison
    boxplot(itauSort,GNSort,'Colors','kr','ColorGroup',[1 0 1 0 1 0 1 0],'OutlierSize',0.1,'Symbol','w'...
        ,'GroupOrder',{'r14B','r14A','r56B','r56A','r78B','r78A','scB','scA'},...
        'Widths',0.70,'Positions',[0 0.75 2 2.75 4 4.75 6 6.75],'medianstyle','line')
else
    boxplot(itauSort,GNSort,'Colors','kr','ColorGroup',[0 1 1 1 1],'OutlierSize',0.1,'Symbol','w'...
        ,'GroupOrder',{'Before','r14A','r56A','r78A','scA'},...
        'Widths',0.70)
end
ylim([-0.15 0.2]); ylabel('1 / \tau (1/s)');xlabel('ablation site');box off;setFontProperties(gca);
%set(gca,'XTickLabel',[]);
h=annotation('doublearrow',[0.88 0.88],[0.2 0.85],'LineWidth',0.4);
h.Head1Length = 3;h.Head1Width=3;h.Head2Length = 3;h.Head2Width = 3;
text(0.999,0.89,{'leaky'},'units','normalized','Rotation',-90,'FontName','Arial','FontSize',6);
text(0.999,0.51,{'stable'},'units','normalized','Rotation',-90,'FontName','Arial','FontSize',6)
text(0.999,0.2,{'unstable'},'units','normalized','Rotation',-90,'FontName','Arial','FontSize',6)
%%
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
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\invTauDistributionChangesBoxPlots'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% Supp Fig 6 Caption

[p,~,stats]=anova1(itauSort,GNSort);
%[p,~,stats]=kruskalwallis(itauSort,GNSort,'off');
%multcompare(stats,'Alpha',0.001,'CType','bonferroni');
alpha = 0.001;
%%
for j=1:length(stats.gnames)
    groupNumber = cellfun(@(x) strcmp(x,stats.gnames{j}),GNSort);
    fprintf('n=%d fixations %s\n',stats.n(j),stats.gnames{j});
    uniNames = unique(names(groupNumber & keep));
    fprintf('from %d fish\n',length(uniNames));
end
%%
if 0 
% number of fish and number of events
numFishBefore = numberAnimalsEachGroup(behaviorStat.leftEye.before);
%numBefore = sum(goodFits); % number of fixations (combined across both eyes) before ablation that pass GOF test
[numFishAfter,numFixationsAfterLeft] = numberAnimalsEachGroup(behaviorStat.leftEye.after);
[~,numFixationsAfterRight] = numberAnimalsEachGroup(behaviorStat.rightEye.after);
numAfter = numFixationsAfterLeft + numFixationsAfterRight;

[~,numFixationsBLeft] = numberAnimalsEachGroup(behaviorStat.leftEye.before);
[~,numFixationsBRight] = numberAnimalsEachGroup(behaviorStat.rightEye.before);
numBefore = numFixationsBLeft + numFixationsBRight;

fprintf(1,'\n The rate of eye position decay following saccades was measured using an\n exponential function with time constant tau.  Boxplot of inverse tau values\n before (gray) and after (red) ablations grouped according to ablation location.\n Large positive values of 1/tau correspond to events where the eyes rapidly returned to nasal resting position.\n Negative values of 1/tau correspond to events where the eyes continued to move away from nasal resting position after saccade.\n Central mark shows the median, edges of the box are the 25th and 75th percentiles, whiskers show the range of values.\n')
fprintf(1,'Stars show significant differences\n (p<%0.3f, two-sample t-tests using Bonferroni correction to control for familywise error rate;\n n=%d fixations before and %d fixations after from %d fish for rhombomeres 1-4,\n n=%d fixations before and n=%d fixations after from %d fish for rhombomeres 5-6,\n n=%d fixations before and n=%d fixations after from %d fish for rhombomeres 7-8,\n n=%d fixations before and n=%d fixations after from %d fish for spinal cord ablations).\n',...
    alpha,numBefore(1),numAfter(1),numFishBefore(1),numBefore(2),numAfter(2),numFishBefore(2),numBefore(3),numAfter(3),numFishBefore(3),numBefore(4),numAfter(4),numFishBefore(4));
fprintf(1,'\n The number of fish used before/after ablations is %d/%d for r1-4,\n %d/%d for r5-6, %d/%d\n for r7-8, %d/%d for s.c\n',...
    numFishBefore(1),numFishAfter(1),numFishBefore(2),numFishAfter(2),numFishBefore(3),numFishAfter(3),numFishBefore(4),numFishAfter(4));
end
tstop = toc(tstart);
tstop
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 8b.csv'],'a');
    fprintf(fileID,'Panel\nb\n');
    fprintf(fileID,'Fixation Duration(s)\n');
    groups = {'r14B','r14A','r56B','r56A','r78B','r78A','scB','scA'};
    numSamp = zeros(length(groups),1);
    for k = 1 : length(groups) 
        cellSelection = cellfun(@(x) strcmp(x,groups{k}),GNSort);
        X = itauSort(cellSelection);
        X = X(~isnan(X),:);
        numSamp(k) = size(X,1);
    end
    XMat = NaN(max(numSamp),length(groups));
    for k =1 : length(groups)
        cellSelection = cellfun(@(x) strcmp(x,groups{k}),GNSort);
         X = itauSort(cellSelection);
        X = X(~isnan(X),:);
        XMat(1:numSamp(k),k) =X;
    end
        %fprintf(fileID,'Condition=%s\n',groupNames{k});
        fprintf(fileID,'r1-4 Before,r1-4 After,r5-6 Before,r5-6 After,r7-8 Before,r7-8 After,spinal cord Before,spinal cord After\n');
        %fprintf(fileID,'\nAnimal ID,Fixation Sample Index,Sample Index,Fixation Duration(s)\n');
        dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 8b.csv'],XMat,'delimiter',',','-append');

    fclose(fileID);
end