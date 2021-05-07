function plotActiveNonActiveLabelledCells()
% plotActiveNonActiveLabelledCells
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

clear 
[fid,expCond]= listAnimalsWithImaging;
caudalPlane = 2;
planeIndex = 1;
expIndex = 13;
activeColor = [255 44 30]./255; nonActiveColor = [199 181 98]./255;
[nonActiveStat,activeStat,nonActiveCells,activeCells,fluorescence]=compareActiveNonActive(expIndex,planeIndex,0,'non-active complement');
[nonActiveStat,activeStat]=compareActiveNonActiveUseMOandNMFROIs(expIndex,planeIndex,0.8,'stat','Max');
fprintf('median peak activity in non-Active and active =%0.2f, %0.2f respectively\n',median(nonActiveStat),median(activeStat)) 
dFFSize = 2;
eyeobj = eyeData('fishid',fid{expIndex},'expcond',expCond{expIndex});
% eye positions
E = eyeobj.centerEyesMethod('planeIndex',planeIndex);
time = eyeobj.time{planeIndex}(:,1);

leftEyeColor = [1 1 1]*0.4;
rightEyeColor = [1 1 1]*0;
%%
figure;
ax(1)=subplot(2,2,1);
nPlots = min(20,length(activeCells));
[~,sortIndex] = sort(activeStat,'descend');
for k=1:nPlots
    plot((k-1)*dFFSize+dff(fluorescence{planeIndex}(:,activeCells(sortIndex(k)))),'color',activeColor); hold on;
    if k==1
        plot([1 1]*301,[0 1],'k','LineWidth',0.5);
    end
end
ylim([0 dFFSize*nPlots]+[-0.8 0.5]);
title('selected','FontSize',9,'FontName','Arial','color','k');
%plot([1 1]*25,[0 1],'k')
box off;axis off;
%set(gca,'YTick',[],'YTickLabel',[],'YColor','w','FontSize',7,'FontName','Arial','XColor','k')

ax(2)=subplot(2,2,2);
nPlots = min(20,length(nonActiveCells));
for k=1:nPlots
     plot((k-1)*dFFSize+dff(fluorescence{planeIndex}(:,nonActiveCells(k))),'color',nonActiveColor); hold on;
     if k==1
        plot([1 1]*301,[0 1],'k','LineWidth',0.5);
    end
end
ylim([0 dFFSize*nPlots]+[-0.5 0.5]);
title('not-selected','FontSize',9,'FontName','Arial','color','k');
box off;axis off;
%set(gca,'YTick',[],'YTickLabel',[],'YColor','w','FontSize',7,'FontName','Arial','XColor','k')

ax(3)=subplot(2,2,3);
plot(time,E(:,1),'color',leftEyeColor); hold on; plot(time,E(:,2),'color',rightEyeColor);
%lineAtEyeBaselineColor = [1 1 1]*0.4; plot([0 time(end)],[1 1]*0,'--','color',lineAtEyeBaselineColor)
plot([1 1]*305,[0 10],'k','LineWidth',0.5);
set(gca,'YTick',[],'YTickLabel',[],'YColor','w','FontSize',7,'FontName','Arial','XColor','k')
xlabel('time (s)','FontSize',7,'FontName','Arial','color','k');
box off;  setFontProperties(gca);


ax(4)=subplot(2,2,4);
plot(time,E(:,1),'color',leftEyeColor); hold on; plot(time,E(:,2),'color',rightEyeColor);
%lineAtEyeBaselineColor = [1 1 1]*0.4; plot([0 time(end)],[1 1]*0,'--','color',lineAtEyeBaselineColor)
plot([1 1]*305,[0 10],'k','LineWidth',0.5);
set(gca,'YTick',[],'YTickLabel',[],'YColor','w','FontSize',7,'FontName','Arial','XColor','k')
xlabel('time (s)','FontSize',7,'FontName','Arial','color','k');
box off;  setFontProperties(gca);

linkaxes(ax,'x'); xlim([0 306]);

eyeSubPlotHeightShrink = 0.25;axesOverlap = 0.24;
% shrink the second axes 
ax(3).Position(4) = ax(3).Position(4)*eyeSubPlotHeightShrink;
% bring the axes closer together
ax(3).Position(2)=ax(1).Position(2)-ax(1).Position(4)+axesOverlap;ax(3).YColor = 'w'; ax(3).XColor='k'; 

ax(4).Position(4) = ax(4).Position(4)*eyeSubPlotHeightShrink;
ax(4).Position(2)=ax(2).Position(2)-ax(2).Position(4)+axesOverlap;ax(4).YColor = 'w'; ax(4).XColor='k'; 

global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    set(gcf,'PaperPosition',[0 0 4 7],'InvertHardcopy','off','Color',[1 1 1])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
     end
    print(gcf,'-dpdf',[figurePDir thisFileName])
   % print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\plotActiveNonActiveLabelledCells'])
end

