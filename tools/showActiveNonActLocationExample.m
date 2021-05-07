function showActiveNonActLocationExample()
% showActiveNonActLocationExample
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

clear 
fid = listAnimalsWithImaging;
caudalPlane = 2;
planeIndex = 1;
expIndex = 13;
activeColor = [255 44 30]./255; nonActiveColor = [199 181 98]./255;

[nonActiveStat,activeStat,nonActiveCells,activeCells,fluorescence]=compareActiveNonActive(expIndex,planeIndex,0,'non-active complement');

viewLocationsIMOpen(fid{expIndex},planeIndex,'indices2show',nonActiveCells,'color',nonActiveColor,'MarkerSize',5,'plotPoints',true); hold on;
viewLocationsIMOpen(fid{expIndex},planeIndex,'indices2show',activeCells,'color',activeColor,'MarkerSize',5,'figureHandle',gcf,'plotPoints',true);
axis off;title([])

% add a scale bar
scaleBarWidth = 10;
%rawobj = rawData('fishid',fid{expIndex},'fileNumber',planeIndex);
%largeScale = rawobj.micron2pixel(50);
largeScale = 139;
rcpix2micron = largeScale/50;

% scale bar should show typical nucleus size (5 microns)
hold on;
plot([0 rcpix2micron*scaleBarWidth]+388,[1 1]*484,'w')

global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn    set(gcf,'PaperPosition',[0 0 2.0 2.0],'InvertHardcopy','off','Color',[1 1 1])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
     end
    print(gcf,'-dpdf',[figurePDir thisFileName])
    %print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\showActiveNonActLocationExample'])
end


