classdef fig4 < figures & srPaperPlots
    %fig4 - print figure panels in figure 4
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        timeWidth
        eyeRange
        dFFLineWidth
        dFFLineColor
        deconvLineWidth
        deconvLineColor
        ID 
        dFF
        timeF
        E
        eyeTime
        deconvAU
    end
    
    methods
        function obj = fig4(varargin)
            options = struct('timeWidth',[],'eyeRange',[],'dFFLineWidth',1,'dFFLineColor',[0 0 1],...
                'deconvLineWidth',1,'deconvLineColor',[0 0 0],'paperPosition',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % set properties fixed across all subpanels
            obj.timeWidth = options.timeWidth;
            obj.eyeRange = options.eyeRange;
            obj.dFFLineWidth = options.dFFLineWidth;
            obj.dFFLineColor = options.dFFLineColor;
            obj.deconvLineWidth = options.deconvLineWidth;
            obj.deconvLineColor = options.deconvLineColor;       
        end
        function obj=runFig4a(obj,ID,varargin)
            if size(obj.ID,2) ~= size(ID,2)
                obj.ID = zeros(1,size(ID,2));
            end
            obj=runPlotActivityWEyesClass(obj,ID,varargin{:});pause(0.1);
        end
        
        function obj=runFig4b(obj,ID,varargin)
            if size(obj.ID,2) ~= size(ID,2)
                obj.ID = zeros(1,size(ID,2));
            end
            obj=runPlotActivityWEyesClass(obj,ID,varargin{:});pause(0.1);
        end
      
        function obj=runPlotActivityWEyesClass(obj,ID,varargin)
            options = struct('timeOffset2plot',[],'axesOverlap',[],'showAxis',true,'showDeconv',false,...
                'traceFilename',[],'cellIndices',[],'YAxisRange',[],'eyeRange',[],'paperPosition',[],'eyeAxisShrinkFactor',[]);
            options = parseNameValueoptions(options,varargin{:});
            
             if isempty(options.paperPosition)
                options.paperPosition = obj.paperPosition;
             end
            
            if any(ID ~= obj.ID)
                expIndex = ID(1);planeIndex = ID(2);
                if isempty(options.cellIndices)
                    cellIndex = ID(3);
                else
                    % this allows the user to plot more than one cell the
                    % given plane
                    cellIndex = options.cellIndices;
                end
                [caobj,eyeobj] = plotActivityWEyes.loadCaEyeObjs(expIndex);
                if options.showDeconv
                    [dFF,timeF,E,eyeTime,deconvAU] = plotActivityWEyes.extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndex,'runDFF',true,'returnDeconvF',true,'haveDeconvMatchDFF',true);
                    obj.deconvAU = deconvAU;
                else
                    [dFF,timeF,E,eyeTime] = plotActivityWEyes.extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndex,'runDFF',true,'returnDeconvF',false);
                    obj.deconvAU = [];
                end
                obj.ID = ID;
                obj.dFF = dFF;
                obj.timeF = timeF;
                obj.E = E;
                obj.eyeTime = eyeTime;
            end
            activityEyeObj = plotActivityWEyes('filename',options.traceFilename,'paperPosition',options.paperPosition,...
                'eyeTime',obj.eyeTime,'angle',obj.E,'leftEyeIndex',1,'rightEyeIndex',2,'caTime',obj.timeF,'dFF',obj.dFF,'deconvF',obj.deconvAU,...
                'dFRange',options.YAxisRange,'timeWidth',obj.timeWidth,'eyeRange',options.eyeRange,'timeOffset2plot',options.timeOffset2plot,...
                'axesOverlap',options.axesOverlap,'dFFLineWidth',obj.dFFLineWidth,'dFFLineColor',obj.dFFLineColor,...
                'deconvLineWidth',obj.deconvLineWidth,'deconvLineColor',obj.deconvLineColor,'multiCellTraceSpacing',2.0,...
                'eyeAxisShrinkFactor',options.eyeAxisShrinkFactor,'showAxis',options.showAxis);
            activityEyeObj.plot;
        end
    end
end

