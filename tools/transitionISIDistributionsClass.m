classdef transitionISIDistributionsClass < figures & srPaperPlots
    % transitionISIDistributionsClass - histogram fixation durations of spontaneous eye movements in the dark 
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
    end
    
    methods
        function obj = transitionISIDistributionsClass(varargin)
            thisFileName = mfilename;
            className = thisFileName;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 0 2 2];
        end
        
        function [obj,varargout]=compute(obj,varargin)
            options = struct('popFD',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            
            if isempty(options.popFD)
                % marginal distributions of fixation duration
                durations = jointISIDistributionPopAggregatev2;
                options.popFD = [durations.left;durations.right];
                varargout{1} = durations;
            end
            
            data = obj.createDataStruct(options.popFD);
            obj.data = data;
        end
        
        function data=createDataStruct(obj,samplesBoth)
            data.fd = samplesBoth;
        end
        function toCSV(obj)
            global saveCSV
            if saveCSV
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 1c.csv'],'a');
                fprintf(fileID,'Panel\nc\n');
                fprintf(fileID,',Fixation Sample Index,Fixation Duration(s)\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 1c.csv'],[(1:length(obj.data.fd))' obj.data.fd],'delimiter',',','-append','coffset',1);
                fclose(fileID);
            end
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
            histogram(obj.data.fd,0:80,'Normalization','probability');
            xlim([0 80]);
            xlabel('fixation duration (s)','FontName',obj.FontName,'FontSize',obj.FontSize,'color',obj.FontColor)
            ylabel('fraction of fixations','FontName',obj.FontName,'FontSize',obj.FontSize,'color',obj.FontColor)
            set(gca,'FontName',obj.FontName,'FontSize',obj.FontSize,'XColor','k','YColor','k',...
                'XTick',[0 10 20 30 40 50 60 70 80],'XTickLabel',[0 10 20 30 40 50 60 70 80])
            box off
            set(gcf,'PaperPosition',obj.paperPosition) 
        end
        function printAndSave(obj)
            % print and save
            obj.printFigure
        end
    end
end

