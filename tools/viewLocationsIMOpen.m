function IMCoor = viewLocationsIMOpen(fishid,planeIndex,varargin)
% viewLocationsIMOpen(fishid,planeIndex) - load time-averaged images and points found by the morphological opening algorithm 
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

options = struct('indices2show','all','color','r','figureHandle',[],'MarkerSize',6,'plotPoints',false,'expCond','B');
options = parseNameValueoptions(options,varargin{:});

caTracesFileName = getFilenames(fishid,'expcond',options.expCond,'fileType','catraces','caTraceType','MO');
load(caTracesFileName,'localCoordinates');
IMCoor = localCoordinates{planeIndex};
if options.plotPoints
    if isempty(options.figureHandle)
        avgImgFile = getFilenames(fishid,'expcond',options.expCond,'fileType','averageImages');
        load([avgImgFile '.mat'],'images');
        I = images.channel{1}(:,:,planeIndex);
        highVal = quantile(I(:),0.97);
        figure;
        imagesc(I,[0 highVal]); colormap('gray'); hold on;
        title([num2str(fishid) '-' num2str(planeIndex)])
        
    else
        figure(options.figureHandle);
    end
    if strcmp(options.indices2show,'all')
        plot(IMCoor(:,1),IMCoor(:,2),'.','color',options.color,'MarkerSize',options.MarkerSize)
    else
        plot(IMCoor(options.indices2show,1),IMCoor(options.indices2show,2),'.','color',options.color,'MarkerSize',options.MarkerSize)
    end
end
end