function scoreHistogramLat(varargin)
% scoreHistogramLat
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202

options = struct('lon',[],'lat',[],'lonCenter',45,'bw',15);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.lon) || isempty(options.lat)
    script2RunPCAOnSTA;
else
    lon = options.lon;
    lat = options.lat;
end
% condition for being within the appropriate bin
lonCondition = lon > options.lonCenter-options.bw/2 & lon <=options.lonCenter+options.bw/2;
endingForPrintedFileName = ['-LatAtLon' num2str(mod(options.lonCenter,360))];
YLIM=[0 0.010];
XLIM = [-90 90];
axisFontSize = 6;
YTICK = [0 2e-3 4e-3 6e-3 8e-3 1e-2];
YTICKLABEL = [0 0.2 0.4 0.6 0.8 1];
XTICK = -90:30:90;
XTICKLABEL =  -90:30:90;
if options.lonCenter==45
    PAPERPOSITION =[0 0 1.7 1.25];
elseif options.lonCenter ==0
    PAPERPOSITION =[0 0 1.7 1.25];
else
    PAPERPOSITION =[0 0 6.5 1.25];
end
% plot
figure;
histogram([NaN(sum(~lonCondition),1);lat(lonCondition)],-90:5:90,'Normalization','probability');
xlim(XLIM);ylim(YLIM);
hold on;
set(gca,'XTick',XTICK,'XTickLabel',XTICKLABEL);
box off;
xh=xlabel('\theta','FontWeight','bold');
ylabel({'percent of' 'all STAs'});
set(gca,'YTick',YTICK,'YTickLabel',YTICKLABEL);setFontProperties(gca,'fontSize',axisFontSize);
xh.FontSize = axisFontSize+1;
set(gcf,'PaperPosition',PAPERPOSITION )

thisFileName = mfilename;
printAndSave([thisFileName endingForPrintedFileName])
