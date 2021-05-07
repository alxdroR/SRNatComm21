classdef pcVectorPlotClass < figures & srPaperPlots
    % pcVectorPlotClass -  plot first three principal components of saccade-triggered averages
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
        numPCs2show = 3;
    end
    
    methods
        function obj = pcVectorPlotClass(varargin)
            thisFileName = mfilename;
            className = thisFileName;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 1 2.5 2.5];
        end
        
        function obj=compute(obj,varargin)
            options = struct('coef',[],'time',[],'explainedVar',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.coef) || isempty(options.time) || isempty(options.explainedVar)
                % run PCA
                script2RunPCAOnSTA;
                options.coef = coef;
                options.time = tauPCA;
                options.explainedVar = expl;
            end
            
            data = obj.createDataStruct(options.coef,options.time,options.explainedVar);
            obj.data = data;
        end
        
        function data=createDataStruct(obj,coef,tauPCA,expl)
            data.coef = coef;
            data.time = tauPCA;
            data.explainedVar = expl;
            
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            
            % plot
            XLIM = [obj.data.time(1) obj.data.time(end)];
            YLIM = [-0.01 max(max(obj.data.coef(:,1:obj.numPCs2show)))-min(min(obj.data.coef(:,1:obj.numPCs2show)))];
            
            figure;
            for pcIndex = 1 : obj.numPCs2show
                subplot(obj.numPCs2show,1,pcIndex)
                coefOffset = obj.data.coef(:,pcIndex) - min(obj.data.coef(:,pcIndex));
                plot(obj.data.time,coefOffset,'LineWidth',1);hold on; plot([1 1]*0,[YLIM(1) YLIM(2)],'k--','LineWidth',0.3);
                if pcIndex ~= obj.numPCs2show
                    set(gca,'XTick',[-4 -2 0 2 4],'XTickLabel',[]);
                else
                    set(gca,'XTick',[-4 -2 0 2 4],'XTickLabel',{'-4' '-2' '0' '2' '4'});
                    xlabel({'time relative to saccade (s)'});
                end
                set(gca,'YTick',[],'YTickLabel',[]);
                box off;
                setFontProperties(gca,'fontName',obj.FontName,'fontSize',obj.FontSize,'fontColor',obj.FontColor);
                set(gca,'YColor','w');
                text(0.7,0.97,{['component ' num2str(pcIndex)] ['(' num2str(round(obj.data.explainedVar(pcIndex))) '%)']},...
                    'FontName',obj.FontName,'Color',obj.FontColor,'FontSize',obj.FontSize,'Units','Normalized');
                xlim(XLIM);ylim(YLIM);
            end
            set(gcf,'PaperPosition',obj.paperPosition,'InvertHardcopy','off','Color',[1 1 1])
            
            obj.printAndSave;
        end
        function toCSV(obj)
            global saveCSV
            if saveCSV
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 3b.csv'],'a');
                fprintf(fileID,'Panel\nb\n');
                fprintf(fileID,',time relative to saccade(s)');
                dlmwrite([fileDirs.scDataCSV 'Figure 3b.csv'],obj.data.time,'delimiter',',','-append','coffset',1);
                for pcIndex = 1 : obj.numPCs2show
                    
                    fprintf(fileID,',Component %d values (arb. units)',pcIndex);
                    coefOffset = obj.data.coef(:,pcIndex) - min(obj.data.coef(:,pcIndex));
                    dlmwrite([fileDirs.scDataCSV 'Figure 3b.csv'],coefOffset','delimiter',',','-append','coffset',1);
                end
                fclose(fileID);
            end
        end
        function printAndSave(obj)
            % print and save
            obj.printFigure
        end
    end
end