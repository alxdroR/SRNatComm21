classdef scorePlotClass < figures & srPaperPlots
    % scorePlotClass - plot PCA scores of cell saccade-triggered averages
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
        xlim
        ylim
        zlim
        markerSize
        axisLineWidth
        axisLim
        textLocations
    end
    
    methods
        function obj = scorePlotClass(varargin)
            options = struct('xlim',[],'ylim',[],'zlim',[],'markerSize',[],'axisLineWidth',[],'axisLim',[],'textLocations',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            thisFileName = mfilename;
            className = thisFileName;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 0 2.5 2.5];
            obj.xlim = options.xlim;
            obj.ylim = options.ylim;
            obj.zlim = options.zlim;
            obj.markerSize = options.markerSize;
            obj.axisLineWidth = options.axisLineWidth;
            obj.axisLim = options.axisLim;
            obj.textLocations = options.textLocations;
        end
        
        function obj=compute(obj,varargin)
            options = struct('scores',[],'explainedVar',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.scores) || isempty(options.explainedVar)
                % run PCA
                script2RunPCAOnSTA;
                % format data to plot into a sharable format
                options.scores = score;
                options.explainedVar = expl;
            end
            
            data = obj.createDataStruct(options.scores,options.explainedVar);
            obj.data = data;
        end
        
        function data=createDataStruct(obj,score,expl)
            data.scores = score;
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
            rselction=randperm(size(obj.data.scores,1),2000);
            
            figure;plot3(obj.data.scores(rselction,1),obj.data.scores(rselction,2),obj.data.scores(rselction,3),'.','MarkerSize',obj.markerSize); hold on;
            if ~isempty(obj.xlim)
                if ischar(obj.xlim)
                    mnX = min(obj.data.scores(:,1)); mxX=max(obj.data.scores(:,1));
                    obj.xlim = [mnX mxX];
                end
                xlim(obj.xlim);
            end
            if ~isempty(obj.ylim)
                if ischar(obj.ylim)
                    mnY = min(obj.data.scores(:,2)); mxY=max(obj.data.scores(:,2));
                    obj.ylim = [mnY mxY];
                end
                 ylim(obj.ylim);
            end
            if ~isempty(obj.zlim)
                if ischar(obj.zlim)
                    mnZ = min(obj.data.scores(:,3)); mxZ=max(obj.data.scores(:,3));
                    obj.zlim = [mnZ mxZ];
                 end
                 zlim(obj.zlim);
            end
            
            plot3([obj.axisLim(1) obj.axisLim(2)],[0 0],[0 0],'k','LineWidth',obj.axisLineWidth)
            plot3([0 0],[obj.axisLim(1) obj.axisLim(2)],[0 0],'k','LineWidth',obj.axisLineWidth);
            plot3([0 0],[0 0],[obj.axisLim(1) obj.axisLim(2)],'k','LineWidth',obj.axisLineWidth)
            
            if false
            txC1L=obj.textLocations(1,:);text(txC1L(1),txC1L(2),txC1L(3),'c_1','FontName',obj.FontName,'FontSize',obj.FontSize,'Color',obj.FontColor);
            txC2L=obj.textLocations(2,:);text(txC2L(1),txC2L(2),txC2L(3),'c_2','FontName',obj.FontName,'FontSize',obj.FontSize,'Color',obj.FontColor);
            txC3L=obj.textLocations(3,:);text(txC3L(1),txC3L(2),txC3L(3),'c_3','FontName',obj.FontName,'FontSize',obj.FontSize,'Color',obj.FontColor);
            end
            view(120,20);
            axis off
            set(gcf,'PaperPosition',obj.paperPosition,'InvertHardcopy','off','Color',[1 1 1])
            
            obj.printAndSave;
        end
        function toCSV(obj)
            global saveCSV
            if saveCSV
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 3c.csv'],'a');
                fprintf(fileID,'Panel\nc\nSTA Coefficients\n');
                fprintf(fileID,',STA Index,c1,c2,c3\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 3c.csv'],[(1:size(obj.data.scores,1))' obj.data.scores(:,1:3)],'delimiter',',','-append','coffset',1);
                fclose(fileID);
            end
        end
        function printAndSave(obj)
            % print and save
            obj.printFigure
            printAndSave(obj.filename,'data',obj.data,'formattype','-dpng','addPrintOps','-r700')
        end
    end
end




