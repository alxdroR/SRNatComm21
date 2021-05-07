function singleFishExampleOfAbl()
% singleFishExampleOfAbl - show example planes before and after cluster ablations 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020

fontname = 'Arial';
fontsize = 10;
abobj = ablationViewer('fishid','fBB','refsize',[1084 1476 76],'loadImages',true);
abobj = abobj.rotateImages90;
plane2show = [1,3,5];
mic2pix = 184.4941/512;
titleStr = {'green ch','red ch','contrast'};
for planeIndex = 1:length(plane2show)
    for channel2show = 1:2
        subplot(5,2,2*(planeIndex-1) + channel2show)
        abobj.viewDamage('axisHandle',{gca},'fixedData',[],'plane',plane2show(planeIndex),'outline',false,'channel',channel2show,'average',true);
        ylim([0 330]+120);xlim([0 330]+60)
        axis on
        set(gca,'XColor','w','YColor','w','XTick',[],'YTick',[])
    end
end
subplot(5,2,10);subplot(5,2,6)
rectangle('Position',[250 400 round(30/(mic2pix)) 0.1],'FaceColor','w')
set(gcf,'PaperPosition',[0 0 5 5])

% format data that is plotted into a sharable format
data.images = abobj.images;
data.mic2pixScale = mic2pix;
data.channelNames = {'green','red','contrast'};

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)