function suppFig2()
% suppFig2
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

clear
activeColor = [255 44 30]./255; nonActiveColor = [199 181 98]./255;
%[nonActiveStat,activeStat,~,~,~,cellIDs,MOStat]=compareActiveNonActiveUseMOandNMFROIs('all','all',0.8,'stat','Max');
[nonActiveStat,activeStat,~,~,~,cellIDs,MOStat]=compareActiveNonActiveUseMOandNMFROIs('all','all',0.05,'stat','Max');

names = {'not selected','selected'};
[~,inMBCriteria] = createFootprintSelector('cutCellsWLowSignal',true,'staDFFFilename','calcSTA2NMFOutput','lowSigPercentile',0.01);
CoordinatesMO = registeredCellLocationsBigWarp('register2Zbrain',true,'caExtractionMethod','MO');
inMBMO = removeCellsRegistered2MB(CoordinatesMO);
activeStat = activeStat(~inMBCriteria,:);
nonActiveStat = MOStat(logical(cellIDs.MO(:,3)) & ~inMBMO);
figure;
boxplot([nonActiveStat;activeStat],names([ones(length(nonActiveStat),1);2*ones(length(activeStat),1)]),'Symbol','w','colors',[nonActiveColor;activeColor]);
box off
%ylim([0 4])
ylim([0 5]);
ylabel('peak dF/F','FontSize',7,'FontName','Arial','color','k');
set(gca,'FontSize',7,'FontName','Arial','XColor','k')
%%
global printOn

if isempty(printOn)
    printOn = false;
end
if printOn
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    set(gcf,'PaperPosition',[0 0 2.5 2.5])
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
        % print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\suppFig2-3-populationResults'])
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% Figure caption S1E stats
p=anova1([nonActiveStat;activeStat],names([ones(length(nonActiveStat),1);2*ones(length(activeStat),1)]));
fprintf('n=%d non-selected cells, n=%d selected cells\n',sum(~isnan(nonActiveStat)),sum(~isnan(activeStat)));

notAID = cellIDs.MO(logical(cellIDs.MO(:,3)) & ~inMBMO,:);
cellIDs.NMF = cellIDs.NMF(~inMBCriteria,:);

global saveCSV
if saveCSV
    X = [[cellIDs.NMF(:,1:3);[notAID(:,1:2) notAID(:,4)]]...
        [(1:size(cellIDs.NMF,1))';(1:size(notAID,1))']...
        [cellIDs.NMF(:,4);~notAID(:,4)],[activeStat;nonActiveStat]];
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Fig. 1.csv'],'a');
    fprintf(fileID,'Panel\ne\n');
    fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Within-Plane Cell ID,Sample Index,Selected (1=yes/0=no),Peak dF/F\n');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Fig. 1.csv'],X,'delimiter',',','-append');
    fclose(fileID);
    
end

