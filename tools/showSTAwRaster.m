function varargout= showSTAwRaster(yL,yR,bt,STA,STCIL,STCIU,varargin)
% varargout= showSTAwRaster(yL,yR,bt,STA,STCIL,STCIU,varargin) - plot saccade-triggered responses and average 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020

options = struct('dFRange',[0 1.6],'leftSTAColor',[60 11 178]./256,'rightSTAColor',[218 84 26]./256,'lineAtZeroWidth',1,'nrowsSpace',2 ...
,'xlim',[-10,10],'deconvSTA',[],'deconvMarker','--','deconvOffset',true);
options = parseNameValueoptions(options,varargin{:});


nrows =2;
nc = 1;

figure
mn = min(STCIU(:));
% combine left and right saccade-triggered responses into one matrix
lrComboSTR= [yL;ones(options.nrowsSpace,size(yL,2))*options.dFRange(2);yR];

ax(1)=subplot(nrows,nc,1);
imagesc(bt,[],lrComboSTR,[mn options.dFRange(2)-options.dFRange(1)+mn]); hold on;
axis off;colormap('gray')
plot([0 0],[0 size(lrComboSTR,1)],'w--','LineWidth',options.lineAtZeroWidth);

ax(2) = subplot(nrows,nc,2);
%errorbar(bt,STA(:,1),STA(:,1)-STCIL(:,1),-STA(:,1)+STCIU(:,1),'color',options.leftSTAColor); hold on;

ciLower = STCIL(:,1); ciUpper=STCIU(:,1); ciUpper = ciUpper(~isnan(ciLower));timeWoNaN = bt(~isnan(ciLower)); ciLower=ciLower(~isnan(ciLower));
fh=fill([timeWoNaN timeWoNaN(end) fliplr(timeWoNaN) timeWoNaN(1) ],[ciLower;ciUpper(end);flipud(ciUpper);ciLower(1)],options.leftSTAColor); hold on;
fh.FaceAlpha = 0.2;fh.EdgeColor = options.leftSTAColor;
plot(bt,STA(:,1),'color',options.leftSTAColor);
if ~isempty(options.deconvSTA)
    if options.deconvOffset
        baseline = max(max(STCIU)) + abs(min(min(options.deconvSTA))) + 0.05;
    else
        baseline = 0;
    end
    plot(bt,options.deconvSTA(:,1)+baseline,'color',options.leftSTAColor,'lineStyle',options.deconvMarker);
end

%errorbar(bt,STA(:,2),STA(:,2)-STCIL(:,2),-STA(:,2)+STCIU(:,2),'color',options.rightSTAColor)
ciLower = STCIL(:,2); ciUpper=STCIU(:,2); ciUpper = ciUpper(~isnan(ciLower));timeWoNaN = bt(~isnan(ciLower)); ciLower=ciLower(~isnan(ciLower));
fh=fill([timeWoNaN timeWoNaN(end) fliplr(timeWoNaN) timeWoNaN(1) ],[ciLower;ciUpper(end);flipud(ciUpper);ciLower(1)],options.rightSTAColor); hold on;
fh.FaceAlpha = 0.2;fh.EdgeColor = options.rightSTAColor;
plot(bt,STA(:,2),'color',options.rightSTAColor);
if ~isempty(options.deconvSTA)
    plot(bt,options.deconvSTA(:,2) + baseline,'color',options.rightSTAColor,'lineStyle',options.deconvMarker);
end

plot([0 0],[-1.3 2],'k--','LineWidth',options.lineAtZeroWidth);

if ~isempty(options.deconvSTA)
    ylim([0 options.dFRange(2)-options.dFRange(1)]+mn)
else
    ylim([0 options.dFRange(2)-options.dFRange(1)]+mn)
end
linkaxes(ax,'x');

xlim(options.xlim)

varargout{1} = ax;
end


