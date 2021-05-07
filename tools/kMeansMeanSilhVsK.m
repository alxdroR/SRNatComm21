function varargout = kMeansMeanSilhVsK(varargin)
% kMeansMeanSilhVsK
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202
global saveCSV

options = struct('scoreNormed',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.scoreNormed) 
    script2RunPCAOnSTA;
else
    scoreNormed = options.scoreNormed;
end

% use the same model as used in the other figures
K = 10;
[bestSilValue,bestNumClus,meanSSE,meanSil,pcaModel,silValuesCell] = KMeansOnSTAPCAScores(scoreNormed,K);
% compute centers
kmeansops = statset; kmeansops.UseParallel=true;
[idx,C]=kmeans(pcaModel,bestNumClus,'Replicates',5,'Options',kmeansops);
varargout{1} = pcaModel;
varargout{2} = idx;
varargout{3} = C;
%%
axisFontSize = 7;
%%  
figure;
% plot silhouette scores versus K and show optimum
plot(2:K,meanSil(2:K),'b:.');xlabel('number of clusters');ylabel('mean silhouette value')
xlim([1.5 K + 0.5])
box off; setFontProperties(gca,'fontSize',axisFontSize);

global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    set(gcf,'PaperPosition',[0 0 2 2])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
     end
    print(gcf,'-dpdf',[figurePDir thisFileName])
    %print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\kMeansMeanSilhVsK'])
end
if saveCSV
    silValues = reshape(cell2mat(silValuesCell),length(silValuesCell{1}),K-1);
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 2a.csv'],'a');
    fprintf(fileID,'Panel\na\n');
    fprintf(fileID,'\nsilhouette values\n');
    fprintf(fileID,',Number of Clusters');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2a.csv'],2:K,'delimiter',',','-append','coffset',1);
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2a.csv'],silValues,'delimiter',',','-append','coffset',2);
    fclose(fileID);
end
