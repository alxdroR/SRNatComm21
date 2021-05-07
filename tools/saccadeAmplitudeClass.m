classdef saccadeAmplitudeClass < figures & srPaperPlots
    % saccadeAmplitudeClass - histogram of saccade amplitudes of spontaneous eye movements in the dark
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
    end
    
    methods
        function obj = saccadeAmplitudeClass(varargin)
            thisFileName = mfilename;
            className = thisFileName;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 0 2 2];
        end
        
        function obj=compute(obj,varargin)
            options = struct('popSacAmp',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.popSacAmp)
                options.popSacAmp = jointSaccadeAmplitudeDistributionPopAggregate;
            end
            
            % divide samples into saccades where previous saccade was in the same/opposite dir
            % previous saccade was to the left (combine left and right eye)
            indPrevLeft = options.popSacAmp.left(:,1)>=0;
            LEsamplesGivenLeft = options.popSacAmp.left(indPrevLeft,2);
            indPrevLeft = options.popSacAmp.right(:,1)>=0;
            REsamplesGivenLeft = options.popSacAmp.right(indPrevLeft,2);
            samplesGivenLeft = [LEsamplesGivenLeft;REsamplesGivenLeft];
            
            % previous saccade was to the right
            indPrev = options.popSacAmp.left(:,1)<0;
            LEsamplesGivenRight = options.popSacAmp.left(indPrev,2);
            indPrev = options.popSacAmp.right(:,1)<0;
            REsamplesGivenRight = options.popSacAmp.right(indPrev,2);
            samplesGivenRight = [LEsamplesGivenRight;REsamplesGivenRight];
            
            transitionSamples = [samplesGivenLeft;-samplesGivenRight];
            ampSamplesSame =transitionSamples(transitionSamples>=0);
            ampSamplesOpp =-transitionSamples(transitionSamples<0);
            
            
            data = obj.createDataStruct(ampSamplesSame,ampSamplesOpp);
            obj.data = data;
        end
        
        function data=createDataStruct(obj,ampSamplesSame,ampSamplesOpp)
            data.ampSamplesSame = ampSamplesSame;
            data.ampSamplesOpp = ampSamplesOpp;
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            
            NTotal = length(obj.data.ampSamplesSame) + length(obj.data.ampSamplesOpp);
            figure;
            hh=histogram(obj.data.ampSamplesSame,0:40,'Normalization','count');
            sameDirAmpHisto=hh.Values/NTotal; close(hh.Parent.Parent);
            figure;
            hh=histogram(obj.data.ampSamplesOpp,0:40,'Normalization','count');
            altDirAmpHisto=hh.Values/NTotal;
            
            % plot
            figure;bar(hh.BinEdges(1:end-1)+hh.BinWidth/2,altDirAmpHisto,'FaceAlpha',0.1,'FaceColor','r');hold on;
            bar(hh.BinEdges(1:end-1)+hh.BinWidth/2,sameDirAmpHisto,'FaceAlpha',hh.FaceAlpha,'FaceColor','b')
            close(hh.Parent.Parent);
            xlabel('amplitude (deg)','FontName',obj.FontName,'FontSize',obj.FontSize,'color',obj.FontColor);
            ylabel('fraction of all saccades','FontName',obj.FontName,'FontSize',obj.FontSize,'color',obj.FontColor);box off
            xlim([0 40]);ylim([0 0.06])
            set(gca,'FontName',obj.FontName,'FontSize',obj.FontSize,'XColor','k');set(gcf,'PaperPosition',obj.paperPosition);
        end
        function toCSV(obj)
            global saveCSV
            if saveCSV
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 1e.csv'],'a');
                fprintf(fileID,'Panel\ne\n');
                fprintf(fileID,'Sequential Saccades in the Same Direction\n');
                fprintf(fileID,',Fixation Sample Index,Amplitude(deg)\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 1e.csv'],[(1:length(obj.data.ampSamplesSame))' obj.data.ampSamplesSame],'delimiter',',','-append','coffset',1);
                fprintf(fileID,'\nSequential Saccades in the Opposite Direction\n');
                fprintf(fileID,',Fixation Sample Index,Amplitude(deg)\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 1e.csv'],[((1:length(obj.data.ampSamplesOpp))' + length(obj.data.ampSamplesSame)) obj.data.ampSamplesOpp],'delimiter',',','-append','coffset',1);
                  fclose(fileID);
            end
        end
        function printAndSave(obj)
            % print and save
            obj.printFigure
        end
    end
end

