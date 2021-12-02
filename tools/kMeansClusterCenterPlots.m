function kMeansClusterCenterPlots(varargin)
% kMeansClusterCenterPlots
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202
global saveCSV

options = struct('tauPCA',[],'mu',[],'coef',[],'C',[],'YLIM',[],'plotScaleBarOnly',false);
options = parseNameValueoptions(options,varargin{:});


if ~options.plotScaleBarOnly
    kmeansops = statset; kmeansops.UseParallel=true;
    clusterColors = [ [0,0.75,0.75]; [0.75,0,0.75] ];
    if isempty(options.mu) || isempty(options.coef) || isempty(options.C)
        % run PCA
        script2RunPCAOnSTA;
        
        % use the same model as used in the other figures
        K = 10;
        [~,bestNumClus,~,~,pcaModel] = KMeansOnSTAPCAScores(scoreNormed,K);
        % compute centers
        
        [idx,C] = kmeans(pcaModel,bestNumClus,'Replicates',5,'Options',kmeansops);
    else
        tauPCA = options.tauPCA;
        mu = options.mu;
        coef = options.coef;
        C = options.C;
    end
    
end
%%
axisFontSize = 7;
XLIM  = [-4.5 5.2];
PAPERPOSITION = [0 0 1.5 1.5];
%%
global printOn

if isempty(printOn)
    printOn = false;
end
if ~options.plotScaleBarOnly
    numC = 2;
    for kindex = 1 : numC
        figure;
        plot(tauPCA,mu'+coef(:,1:3)*C(kindex,1:3)','color',clusterColors(kindex,:)); hold on;
        plot(tauPCA,mu'+coef(:,1:3)*C(kindex,4:6)','--','color',clusterColors(kindex,:));
        %lh = legend('Left','Right');set(lh,'Box','off','FontSize',axisFontSize-1,'FontName','Arial','TextColor',clusterColors(kindex,:),'Location','northwest');
        
        
        set(gca,'XTick',[-4 -2 0 2 4],'XTickLabel',{'-4' '-2' '0' '2' '4'});
        if kindex==2
            xh=xlabel({'time relative to saccade (s)'});
        end
        set(gca,'YTick',[],'YTickLabel',[]);
        box off;setFontProperties(gca,'fontSize',axisFontSize);
        set(gca,'YColor','w');
        
        % plot axis
        plot([1 1]*0,[-0.25 0.30],'k')
        % plot([-5 5],[0 0],'k')
        xlim(XLIM);
        if ~isempty(options.YLIM)
            ylim(options.YLIM)
        end
        %axis off
        
        if printOn
            set(gcf,'PaperPosition',PAPERPOSITION,'InvertHardcopy','off','Color',[1 1 1])
            figurePDir = figurePanelPath;
            thisFileName = mfilename;
            if isempty(thisFileName)
                error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
            end
            print(gcf,'-dpdf',[figurePDir thisFileName '-cluster' num2str(kindex)])
            %   print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\kMeansClusterCenterPlots-cluster' num2str(kindex)])
        end
    end
else
    
    figure;
    plot([1 1]*-3.5,[0 0.20]+0.1,'k'); hold on;
    %plot([0 1]+ -3,[1 1]*0.1,'k');
    box off
    xlim(XLIM);
    if ~isempty(options.YLIM)
        ylim(options.YLIM)
    end
    if printOn
        set(gcf,'PaperPosition',PAPERPOSITION)
        figurePDir = figurePanelPath;
        thisFileName = mfilename;
        if isempty(thisFileName)
            error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
        end
        print(gcf,'-dpdf',[figurePDir thisFileName 'ScaleBar'])
        %  print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\kMeansClusterCenterPlotsScaleBar'])
    end
end
if saveCSV & ~options.plotScaleBarOnly
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],'a');
    fprintf(fileID,'Panel\nc\n');
    kindex = 1;
    fprintf(fileID,'\ncluster center %d[saccades to the right]\n',kindex);
    fprintf(fileID,',time relative to saccade(s)');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],tauPCA,'delimiter',',','-append','coffset',1);
    fprintf(fileID,',Normalized Deconvolved Fluorescence');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],(mu'+coef(:,1:3)*C(kindex,1:3)')','delimiter',',','-append','coffset',1);
    
    fprintf(fileID,'\ncluster center %d[saccades to the left]\n',kindex);
    fprintf(fileID,',time relative to saccade(s)');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],tauPCA,'delimiter',',','-append','coffset',1);
    fprintf(fileID,',Normalized Deconvolved Fluorescence');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],(mu'+coef(:,1:3)*C(kindex,4:6)')','delimiter',',','-append','coffset',1);
    
    kindex = 2;
    fprintf(fileID,'\ncluster center %d[saccades to the right]\n',kindex);
    fprintf(fileID,',time relative to saccade(s)');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],tauPCA,'delimiter',',','-append','coffset',1);
    fprintf(fileID,',Normalized Deconvolved Fluorescence');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],(mu'+coef(:,1:3)*C(kindex,1:3)')','delimiter',',','-append','coffset',1);
    
    fprintf(fileID,'\ncluster center %d[saccades to the left]\n',kindex);
    fprintf(fileID,',time relative to saccade(s)');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],tauPCA,'delimiter',',','-append','coffset',1);
    fprintf(fileID,',Normalized Deconvolved Fluorescence');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 2c.csv'],(mu'+coef(:,1:3)*C(kindex,4:6)')','delimiter',',','-append','coffset',1);
    
    fclose(fileID);
end

