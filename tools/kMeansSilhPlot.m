function kMeansSilhPlot(varargin)
% kMeansSilhPlot
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202
global saveCSV


options = struct('scoreNormed',[],'pcaModel',[],'idx',[]);
options = parseNameValueoptions(options,varargin{:});

% use the same model as used in the other figures
K = 10;
kmeansops = statset; kmeansops.UseParallel=true;
if isempty(options.pcaModel) || isempty(options.idx)
    if isempty(options.scoreNormed)
        script2RunPCAOnSTA;
    else
        scoreNormed = options.scoreNormed;
    end
    [bestSilValue,bestNumClus,meanSSE,meanSil,pcaModel] = KMeansOnSTAPCAScores(scoreNormed,K);
    % compute centers
    [idx,C]=kmeans(pcaModel,bestNumClus,'Replicates',5,'Options',kmeansops);
else
    pcaModel = options.pcaModel;
    idx = options.idx;
end

%%
axisFontSize = 7;
%%
figure;
[SilVals,HSilVal]=silhouette(pcaModel,idx);
ylabel('cluster');xlabel('silhouette value');
text(0.9,-0.22,{'most similar' 'to assigned cluster'},'FontSize',axisFontSize-1,'units','normalized','FontName','Arial')
text(-0.13,-0.22,{'equally well' 'described by' 'any cluster'},'FontSize',axisFontSize-1,'units','normalized','FontName','Arial')
box off; setFontProperties(gca,'fontSize',axisFontSize);


global printOn

if isempty(printOn)
    printOn = false;
end
if printOn
    set(gcf,'PaperPosition',[4 5 2 2])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
    %print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\kMeansSilhPlot'])
end
%%
% add a silhouette plot of 4
[idx4,C]=kmeans(pcaModel,4,'Replicates',5,'Options',kmeansops);

figure;
[SilVals,HSilVal]=silhouette(pcaModel,idx4);
ylabel('cluster');xlabel('silhouette value');
text(0.9,-0.22,{'most similar' 'to assigned cluster'},'FontSize',axisFontSize-1,'units','normalized','FontName','Arial')
text(-0.13,-0.22,{'equally well' 'described by' 'any cluster'},'FontSize',axisFontSize-1,'units','normalized','FontName','Arial')
box off; setFontProperties(gca,'fontSize',axisFontSize);


if printOn
    set(gcf,'PaperPosition',[4 5 2 2])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
    end
    print(gcf,'-dpdf',[figurePDir thisFileName '-additional'])
    % print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\kMeansSilhPlot-additional'])
end
