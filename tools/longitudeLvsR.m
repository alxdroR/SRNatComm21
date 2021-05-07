function longitudeLvsR(varargin)
% longitudeLvsR
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202


options = struct('lon',[],'bestModelClustCenters',[],'S',[]);
options = parseNameValueoptions(options,varargin{:});


addScaleBar = true;
addKMeansCenters = true;
add2DKMeansSegregation = false;


% k-means analysis
kmeansops = statset; kmeansops.UseParallel=true;
if addKMeansCenters || add2DKMeansSegregation
    if isempty(options.lon) || isempty(options.bestModelClustCenters)
        % run PCA
        script2RunPCAOnSTA;
        lon=shiftLongitude(lon,90,'reorder',false);
        % seperate the left and right longitudes
        N = size(STACAT,1)/2;
        
        % use the same model as used in the other figures
        K = 10;
        [bestSilValue,bestNumClus,meanSSE,meanSil,pcaModel] = KMeansOnSTAPCAScores(scoreNormed,K);
        
        % compute centers
         [~,bestModelClustCenters] = kmeans(pcaModel,bestNumClus,'Replicates',5,'Options',kmeansops);
    else
        bestModelClustCenters = options.bestModelClustCenters;
        lon = options.lon;
        N = length(lon)/2;
        S = options.S;
    end
    % convert the centers to longitude
    [latC,lonC,hC]=ecef2geodetic(S,[bestModelClustCenters(:,1);bestModelClustCenters(:,4)],[bestModelClustCenters(:,2);bestModelClustCenters(:,5)],[bestModelClustCenters(:,3);bestModelClustCenters(:,6)]);
    OFFCut=90;
    lonC =  shiftLongitude(lonC,OFFCut,'reorder',false);
    
    lonL = lon(1:N); lonR = lon(N+1:2*N);
    [idx,C] = kmeans([lonL lonR],2,'Replicates',5,'Options',kmeansops);
    lonC = [C(1,1) C(2,1) C(1,2) C(2,2)];
    if add2DKMeansSegregation
        x1 = 0:5:360;x2=x1;
        [x1G,x2G] = meshgrid(x1,x2);
        XGrid = [x1G(:),x2G(:)]; % Defines a fine grid on the plot
        idx2Region = kmeans(XGrid,2,'MaxIter',1,'Start',[[lonC(1) lonC(3)];[lonC(2) lonC(4)]]);
    end
    clusterColors = [ [0,0.75,0.75]; [0.75,0,0.75] ];
end

%% plot lonL vs lonR distribution
axisFontSize = 7;
XTICK = 0:45:360;XTICKLABEL = [(90:45:180-45) (-180:45:0) (45:45:90)];
YTICK = XTICK; YTICKLABEL= XTICKLABEL;
fAll = figure;
hH = histogram2(lonL-OFFCut,lonR-OFFCut,'BinWidth',3,'DisplayStyle','tile'); colormap(flipud(gray));
hH.Parent.CLim = [0 30];
xh=xlabel('\phi for averages triggered on saccades to the left','FontWeight','bold');xh.FontSize = axisFontSize+1;
%yh=ylabel('\phi for averages triggered on saccades to the right','FontWeight','bold');yh.FontSize = axisFontSize+1;
xlim([0 360]);ylim([0 360]);
set(gca,'clim',[0 10])
if addKMeansCenters
    hold on;numC = 2;
    for kindex = 1 : numC
        plot(lonC(kindex)-OFFCut,lonC(kindex+numC)-OFFCut,'x','MarkerSize',5,'color',clusterColors(kindex,:),'LineWidth',1)
    end
    % lh = legend('','cluster 1','cluster 2');
    % set(lh,'Box','off','FontSize',axisFontSize,'FontName','Arial');
end
if add2DKMeansSegregation
    gscatter(XGrid(:,1),XGrid(:,2),idx2Region,clusterColors,'..');
end


set(gca,'XTick',XTICK,'XTickLabel',XTICKLABEL,'YTick',YTICK,'YTickLabel',YTICKLABEL);
box off; setFontProperties(gca,'fontSize',axisFontSize);


if addScaleBar
    ch=colorbar;
   % ch.Label.String = 'Number of cells';
    ch.FontName = 'Arial';
    ch.FontSize = 6;
    ch.Color='k';
    ch.LineWidth=0.3;
    ch.Position(3)=0.02;
    ch.Position(4)=0.3;
    ch.Position(1)=0.92;
    ch.Position(2)=0.1;
end
set(gca,'XTickLabel',[],'YTickLabel',[]);xlabel('');

set(gcf,'PaperPosition',[0.5 0.5 3 3])
thisFileName = mfilename;
printAndSave(thisFileName,'formattype','-dpng','addPrintOps','-r700')
% global printOn
% 
% if isempty(printOn)
%     printOn = false;
% end
% if printOn
%     set(gcf,'PaperPosition',[0.5 0.5 3 3])
%     figurePDir = figurePanelPath;
%     thisFileName = mfilename;
%     if isempty(thisFileName)
%         error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
%     end
%     %print(gcf,'-dpdf',[figurePDir thisFileName])
%     print(gcf,'-dpdf',[figurePDir thisFileName])
%     %print(gcf,'-dpdf',[rootLocation '\figures\figurePanels\longitudeLvsR'])
% end

