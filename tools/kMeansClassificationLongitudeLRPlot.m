function kMeansClassificationLongitudeLRPlot(varargin)
% kMeansClassificationLongitudeLRPlot
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202

options = struct('lon',[],'OFFCut',[]);
options = parseNameValueoptions(options,varargin{:});

global saveCSV
if isempty(options.lon) 
    % run PCA
    script2RunPCAOnSTA;
else
    lonNonShifted = options.lon;
    lon = shiftLongitude(lonNonShifted,90,'reorder',false);
    OFFCut = options.OFFCut;
end
% seperate the left and right longitudes
N = length(lon)/2;
lonL = lon(1:N); lonR = lon(N+1:2*N);

% compute centers
kmeansops = statset; kmeansops.UseParallel=true;
%[idx,C] = kmeans(pcaModel,2,'Replicates',5,'Options',kmeansops);
[idx,C] = kmeans([lonL lonR],2,'Replicates',5,'Options',kmeansops);
%%
clusterColors = [ [0,0.75,0.75]; [0.75,0,0.75] ];
axisFontSize = 7;
XTICK = 0:45:360;XTICKLABEL = [(90:45:180-45) (-180:45:0) (45:45:90)];
YTICK = XTICK; YTICKLABEL= XTICKLABEL;
%%
figure;
gscatter(lonL-OFFCut,lonR-OFFCut,idx,clusterColors);hold on;legend off;
xh=xlabel('\phi for averages triggered on saccades to the left','FontWeight','bold');xh.FontSize = axisFontSize+1;
yh=ylabel('\phi for averages triggered on saccades to the right','FontWeight','bold');yh.FontSize = axisFontSize+1;
xlim([0 360]);ylim([0 360]);

set(gca,'XTick',XTICK,'XTickLabel',XTICKLABEL,'YTick',YTICK,'YTickLabel',YTICKLABEL);
box off; setFontProperties(gca,'fontSize',axisFontSize);

global printOn

if isempty(printOn)
    printOn = false;
end
if printOn
    set(gcf,'PaperPosition',[0 0 3 3])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
    %print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\kMeansClassificationLongitudeLRPlot'])
end
if saveCSV
    lonNonShiftedL = lonNonShifted(1:N);
    lonNonShiftedR = lonNonShifted(N+1:2*N);
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],'a');
     fprintf(fileID,'\n\n\n,phi Left,phi Right,cluster ID\n');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],[lonNonShiftedL lonNonShiftedR idx],'delimiter',',','-append','coffset',1);
    fclose(fileID);
end


