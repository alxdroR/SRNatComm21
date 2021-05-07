classdef sampleEyeTraceClass < figures & srPaperPlots
    % sampleEyeTraceClass - show a sample of spontaneous zebrafish eye movements in the dark as a function of time
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
        % which eye movement trace to plot
        exampleAnimal = 'f14';
        examplePlane = 1;
        
        % which time period to plot
        Twidth = 120; % seconds
        Tstart = 90;
        
        % convention for where eyes are stored by eyeData
        leftEyeIndex = 1;
        rightEyeIndex = 2;
        
        timeScaleBarWidth = 5;
        angleScaleBarHeight = 10;
    end
    
    methods
        function obj = sampleEyeTraceClass(varargin)
            thisFileName = mfilename;
            className = thisFileName;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 0 1.4 2];
        end
        
        function obj=compute(obj,varargin)
            % load data
            eyeobj=eyeData('fishid',obj.exampleAnimal);
            
            % remove the mean from eye-position traces then plot
            E = eyeobj.centerEyesMethod('planeIndex',obj.examplePlane);
            
            data = obj.createDataStruct(eyeobj,E);
            obj.data = data;
        end
        
        function data=createDataStruct(obj,eyeobj,E)
            data.lefteye.time = eyeobj.time{obj.examplePlane}(:,obj.leftEyeIndex);
            data.lefteye.angle = E(:,obj.leftEyeIndex);
            data.righteye.time = eyeobj.time{obj.examplePlane}(:,obj.rightEyeIndex);
            data.righteye.angle = E(:,obj.rightEyeIndex);
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
             % load data
            if isempty(obj.data)
               obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            
            % plot
            subplot(211);plot(obj.data.lefteye.time,obj.data.lefteye.angle,'color',obj.leftEyeColor)
            xlim([0 obj.Twidth]+obj.Tstart);ylim([-20 20])
            axis off
            
            subplot(212);plot(obj.data.righteye.time,obj.data.righteye.angle,'color',obj.rightEyeColor)
            xlim([0 obj.Twidth]+obj.Tstart);ylim([-20 20])
            rectangle('Position',[obj.Tstart,-15,obj.timeScaleBarWidth,0.1],'FaceColor','k','LineWidth',0.5);
            timeScaleString = sprintf('%s seconds',obj.timeScaleBarWidth);
            text(obj.Tstart,-17,timeScaleString,'FontName',obj.FontName,'FontSize',obj.FontSize)
            angleScaleString = sprintf('%s^0',obj.angleScaleBarHeight);
            ht = text(obj.Tstart,0,angleScaleString,'FontName',obj.FontName,'FontSize',obj.FontSize);set(ht,'Rotation',90);
            rectangle('Position',[obj.Tstart,0,0.1,obj.angleScaleBarHeight],'FaceColor','k','LineWidth',0.5);
            axis off
            set(gcf,'PaperPosition',obj.paperPosition); 
        end
        function printAndSave(obj)
            % print and save
            obj.printFigure
        end
    end
end

