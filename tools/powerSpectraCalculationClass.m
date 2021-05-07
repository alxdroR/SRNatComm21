classdef powerSpectraCalculationClass < figures & srPaperPlots
    % powerSpectraCalculationClass - analyzing spontaneous eye movements in the frequency domain. Plot power spectral density averaged across animals
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
        ID
    end
    
    methods
        function obj = powerSpectraCalculationClass(varargin)
            thisFileName = mfilename;
            className = thisFileName;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 0 2 2];
        end
        
        function obj=compute(obj,varargin)
            options = struct('powerSamples',[],'ID',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.powerSamples)
                [PSDALL,F,obj.ID]=powerSpectraPopAggregate;
                options.powerSamples = struct('PSD',PSDALL,'F',F);
            end
            if ~isempty(options.ID)
                obj.ID = options.ID;
            end
            
            data = obj.createDataStruct(options.powerSamples);
            obj.data = data;
        end
        
        function data=createDataStruct(obj,powerSamples)
            data.psdsamples = powerSamples.PSD;
            data.freq = powerSamples.F;
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            [mPS,sumy,~,lowerError,upperError,~] = powerSpectraCalculationClass.computePowerStats(obj.data);
            % plot
            figure;
            fill([obj.data.freq fliplr(obj.data.freq)],[upperError fliplr(lowerError)],[1 1 1]*0.6,'LineStyle','none'); hold on;
            plot(obj.data.freq,100*mPS/sumy,'color',[0 114 189]./256); hold on;
            xlim([0 0.5])
            ylabel('% total power','FontName',obj.FontName,'FontSize',obj.FontSize,'color',obj.FontColor);
            xlabel('frequency (Hz)','FontName',obj.FontName,'FontSize',obj.FontSize,'color',obj.FontColor);
            set(gca,'FontName',obj.FontName,'FontSize',obj.FontSize,'XColor','k');
            box off
            set(gcf,'PaperPosition',obj.paperPosition)
        end
        function printAndSave(obj)
            % print and save
            obj.printFigure
        end
        function toCSV(obj)
            global saveCSV
            if saveCSV
                [~,sumy] = powerSpectraCalculationClass.computePowerStats(obj.data);
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 1d.csv'],'a');
                fprintf(fileID,'Panel\nd,%% total power\n');
                fprintf(fileID,'\n,,frequency(Hz)');
                dlmwrite([fileDirs.scDataCSV 'Figure 1d.csv'],obj.data.freq,'delimiter',',','-append','coffset',1);
                fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Sample Index\n');
                N = size(obj.data.psdsamples,1);
                dlmwrite([fileDirs.scDataCSV 'Figure 1d.csv'],[obj.ID (1:N)' 100*obj.data.psdsamples./sumy],'delimiter',',','-append');
                fclose(fileID);
            end
        end
    end
    methods (Static)
        function [mPS,sumy,se,lowerError,upperError,nsamples]=computePowerStats(psData)
            nsamples = size(psData.psdsamples,1);
            mPS = mean(psData.psdsamples);
            sumy = sum(mPS);
            se = std(psData.psdsamples)./sqrt(nsamples);
            lowerError = 100*(mPS-se)/sumy;
            upperError = 100*(mPS+se)/sumy;
        end
    end
end

