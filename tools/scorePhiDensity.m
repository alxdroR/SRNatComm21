function scorePhiDensity(varargin)
% scorePhiDensity - plot the density of normalized PCA scores for
% coefficients 1 and 2 combined together as the angle phi
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

% load data
% run PCA

options = struct('lon',[],'OFFCut',[],'YLIM',[0 0.006]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.lon)
    script2RunPCAOnSTA;
    OFFCut = 90;
    lon =  shiftLongitude(lon,OFFCut,'reorder',false);
else
    lon = options.lon;
    OFFCut = options.OFFCut;
end

% compute density
[lonDen,XI]=ksdensity(lon-OFFCut,0:0.5:360);
[pks,lcs]=findpeaks(lonDen,XI);
% remove spurious peak at middle
lcs = lcs(pks>min(pks));
pks = pks(pks>min(pks));

% format data to plot into a sharable format
data.PHIpdf = lonDen;
data.pdfBins = XI;
data.peakIndices = lcs;


% plot
figure;
PAPERPOSITION =[0 0 4.7 0.6];
axisFontSize = 6;axesSpacing = 0.001;
XLIM = [0 360];YTICK = [0 2e-3 4e-3];YTICKLABEL = [0 0.2 0.4];XTICK = 0:45:360;XTICKLABEL = [(90:45:180-45) (-180:45:0) (45:45:90)];
binColor = [0 0.45*256 0.74*256]./256; lineColor = 'k';
plot(data.pdfBins,data.PHIpdf,'color',lineColor); hold on;
shadeWidth = 15;
for bindex = 1 : length(data.peakIndices)
    [~,clseIndexM] = min(abs(data.pdfBins - (data.peakIndices(bindex)-shadeWidth/2 )));
    [~,clseIndexP] = min(abs(data.pdfBins - (data.peakIndices(bindex)+shadeWidth/2 )));
    fill([[1 1]*(data.peakIndices(bindex)-shadeWidth/2) [1 1]*(data.peakIndices(bindex)+shadeWidth/2)],[0 data.PHIpdf(clseIndexM) data.PHIpdf(clseIndexP) 0],binColor)
end
xlim(XLIM);ylim(options.YLIM);
hold on;
set(gca,'XTick',XTICK,'XTickLabel',XTICKLABEL);
box off;xh=xlabel('\phi','FontWeight','bold');
ylabel({'100 X probability' 'density'});set(gca,'YTick',YTICK,'YTickLabel',YTICKLABEL);setFontProperties(gca,'fontSize',axisFontSize);
xh.FontSize = axisFontSize+1;
set(gcf,'PaperPosition',PAPERPOSITION )

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

% note that for the angles to allign with 3Biii all angles from 90 to 360 are decreased by 270 degreees
% the angles from 0 to 90 after increased by 90.
properAngle = data.peakIndices+OFFCut;
properAngle(properAngle>(-180+360)) = properAngle(properAngle>(-180+360)) - 360;
fprintf('peaks in the density plot of longitudinal angles(phi=%0.4f and %0.3f degrees)\n',properAngle);