classdef pcCumVarPlotClass < fig3
    % pcCumVarPlotClass - plot PCA cumulative variance of saccade-triggered averages
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
        xlim
        ylim
    end
    
    methods
        function obj = pcCumVarPlotClass(varargin)
            options = struct('xlim',[],'ylim',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            className = mfilename;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 1 2.1 1];
            obj.xlim = options.xlim;
            obj.ylim = options.ylim;
        end
        
        function obj=compute(obj,varargin)
            options = struct('cumVar',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.cumVar)
                % run PCA
                script2RunPCAOnSTA;
                % format data to plot into a sharable format
                options.cumVar = cumsum(expl);
            end
            
            data = obj.createDataStruct(options.cumVar);
            obj.data = data;
        end
        
        function data=createDataStruct(obj,cumVar)
            data.cumVar =cumVar;
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            % plot
            figure;
            stem(obj.data.cumVar,'filled','MarkerSize',1);box off;
            xlabel({'component index'});ylabel({'cumulative %' 'variance explained'});
            setFontProperties(gca,'fontName',obj.FontName,'fontSize',obj.FontSize,'fontColor',obj.FontColor);
            if ~isempty(obj.xlim)
                xlim(obj.xlim);
            end
            if ~isempty(obj.ylim)
                ylim(obj.ylim);
            end
            set(gcf,'PaperPosition',obj.paperPosition)
            
            obj.printAndSave;
        end
        function toCSV(obj)
            global saveCSV
            if saveCSV
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 3a.csv'],'a');
                fprintf(fileID,'Panel\na\n');
                fprintf(fileID,',Component Index,cumulative %% variance explained\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 3a.csv'],[(1:length(obj.data.cumVar))' obj.data.cumVar],'delimiter',',','-append','coffset',1);
                fclose(fileID);
            end
        end
        function printAndSave(obj)
            % print and save
            obj.printFigure
        end
    end
end
