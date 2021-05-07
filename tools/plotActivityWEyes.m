classdef plotActivityWEyes < figures & srPaperPlots
    %plotActivityWEyes - plot cell activity traces along with eye movements
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 202x
    
    properties
        dFRange % range of dF/F to show
        timeWidth  % amount of time to show in seconds
        eyeRange % range in degrees to show eye movements
        timeOffset2plot
        axesOverlap
        dFFLineWidth
        deconvLineWidth
        dFFLineColor
        deconvLineColor
        multiCellTraceSpacing
        eyeAxisShrinkFactor
        numberTraces
        showAxis
        showScale
    end
    
    methods
        function obj = plotActivityWEyes(varargin)
            options = struct('filename',[],'paperPosition',[0 0 8.5 11],...
                'eyeTime',[],'angle',[],'leftEyeIndex',1,'rightEyeIndex',2,'caTime',[],'dFF',[],'deconvF',[],...
                'dFRange',[],'timeWidth',[],'eyeRange',[],'timeOffset2plot',[],'axesOverlap',[],'dFFLineWidth',1,'dFFLineColor',[1 0 1],...
                'deconvLineWidth',1,'deconvLineColor',[0 0 0],'multiCellTraceSpacing',1,'eyeAxisShrinkFactor',[],'showAxis',true,'numberTraces',false,...
                'showScale',false);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.filename)
                obj.filename = [mfilename '-' date];
            else
                obj.filename = options.filename;
            end
            obj.paperPosition = options.paperPosition;
            obj.dFRange = options.dFRange;
            obj.timeWidth = options.timeWidth;
            obj.eyeRange = options.eyeRange;
            obj.timeOffset2plot = options.timeOffset2plot;
            obj.axesOverlap = options.axesOverlap;
            obj.dFFLineWidth = options.dFFLineWidth;
            obj.dFFLineColor = options.dFFLineColor;
            obj.deconvLineWidth = options.deconvLineWidth;
            obj.deconvLineColor = options.deconvLineColor;
            obj.multiCellTraceSpacing = options.multiCellTraceSpacing;
            obj.eyeAxisShrinkFactor = options.eyeAxisShrinkFactor;
            obj.showAxis = options.showAxis;
            obj.numberTraces = options.numberTraces;
            obj.showScale = options.showScale;
            if isempty(options.eyeTime) || isempty(options.angle) || isempty(options.caTime) || isempty(options.dFF)
                % try to load based on other information
            else
                obj = obj.createDataStruct(varargin{:});
            end
        end
        function obj=createDataStruct(obj,varargin)
            options = struct('eyeTime',[],'angle',[],'leftEyeIndex',1,'rightEyeIndex',2,'caTime',[],'dFF',[],'deconvF',[],'stimTime',[],'stim',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            obj.data = struct('lefteye',struct('time',options.eyeTime(:,options.leftEyeIndex),'angle',options.angle(:,options.leftEyeIndex)),...
                'righteye',struct('time',options.eyeTime(:,options.rightEyeIndex),'angle',options.angle(:,options.rightEyeIndex)),...
                'caTime',options.caTime,'dFF',options.dFF,'deconvF',options.deconvF,...
                'stimTime',options.stimTime,'stim',options.stim);
        end
        
        function ax=plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data) && ~isempty(options.sourceDataFile)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            if ~isempty(obj.data)
                % plot
                
                nCells = size(obj.data.dFF,2);
                figure;ax(1)=subplot(2,1,1);
                if nCells > 1
                    plotKTraces(obj.data.caTime,obj.data.dFF,'traceSpacing',obj.multiCellTraceSpacing,'traceColor',obj.dFFLineColor,'traceLineWidth',obj.dFFLineWidth,...
                        'showTraceIndex',false,'axes',ax(1),'numberTraces',obj.numberTraces);
                else
                    plot(obj.data.caTime,obj.data.dFF,'color',obj.dFFLineColor,'LineWidth',obj.dFFLineWidth); hold on;
                end
                if ~isempty(obj.data.deconvF)
                    if nCells > 1
                        plotKTraces(obj.data.caTime,obj.data.deconvF,'traceSpacing',obj.multiCellTraceSpacing,'traceColor',obj.deconvLineColor,'traceLineWidth',obj.deconvLineWidth,...
                            'showTraceIndex',false,'axes',ax(1),'numberTraces',obj.numberTraces);
                    else
                        plot(obj.data.caTime,obj.data.deconvF,'color',obj.deconvLineColor,'LineWidth',obj.deconvLineWidth); hold on;
                    end
                end
                if ~isempty(obj.dFRange)
                    ylim([0 obj.dFRange]+min(obj.data.dFF(:,1))-0.1);
                end
                if ~obj.showAxis
                    axis off
                end
                if obj.showScale
                    plot([1 1]*44,[0 0.5]+0.15,'k');
                end
                box off;
                
                ax(2)=subplot(2,1,2);
                plot(obj.data.lefteye.time,obj.data.lefteye.angle,'color',obj.leftEyeColor); hold on; plot(obj.data.righteye.time,obj.data.righteye.angle,'color',obj.rightEyeColor);
                minPlotValue = min([min(obj.data.lefteye.angle),min(obj.data.righteye.angle)]);
                maxPlotValue = max([max(obj.data.lefteye.angle),min(obj.data.righteye.angle)]);
                if ~isempty(obj.data.stim)
                    zeroOne=@(x) (x-min(x))/(max(x)-min(x))-1;
                    plot(obj.data.stimTime,(maxPlotValue-minPlotValue)*zeroOne(obj.data.stim)+minPlotValue,'color',obj.rightEyeColor,'LineStyle','--')
                end
                if ~isempty(obj.eyeRange)
                    ylim([0 obj.eyeRange]+ minPlotValue)
                end
                if obj.showScale
                    plot([1 1]*44,[-10 0],'k');
                    plot([0 5]+44,[1 1]*-10,'k');
                end
                linkaxes(ax,'x');
                if ~isempty(obj.timeWidth) && ~isempty(obj.timeOffset2plot)
                    xlim([0 obj.timeWidth]+obj.timeOffset2plot);
                end
                
                if ~obj.showAxis
                    axis off
                end
                box off;
                setFontProperties(gca,'fontName',obj.FontName,'fontSize',obj.FontSize,'fontColor',obj.FontColor);
                
                if ~isempty(obj.eyeAxisShrinkFactor)
                    % shrink the second axes
                    ax(2).Position(4) = ax(2).Position(4)*obj.eyeAxisShrinkFactor;
                end
                if ~isempty(obj.axesOverlap)
                    % bring the axes closer together
                    ax(2).Position(2)=ax(1).Position(2)-ax(1).Position(4)+obj.axesOverlap;
                end
                set(gcf,'PaperPosition',obj.paperPosition)
                
                % print and save
                obj.printFigure
            else
                warning('No cells or cell ids given to plot');
            end
        end
        function ax = plotAllignedSTA(obj,varargin)
            options = struct('tau',[],'sta',[],'rightColor','g','plotLineAtZero',true);
            options = parseNameValueoptions(options,varargin{:});
            
            if ~isempty(options.sta)
                % plot
                
                nCells = size(obj.data.dFF,2);
                figure;ax(1)=subplot(2,1,1);
                if nCells > 1
                    plotKTraces(options.tau',squeeze(options.sta(:,:,1))','traceSpacing',obj.multiCellTraceSpacing,'traceColor',obj.dFFLineColor,'traceLineWidth',obj.dFFLineWidth,...
                        'showTraceIndex',false,'axes',ax(1));
                else
                    plot(options.tau,squeeze(options.sta(:,:,1)),'color',obj.dFFLineColor,'LineWidth',obj.dFFLineWidth); hold on;
                end
                if nCells > 1
                    plotKTraces(options.tau',squeeze(options.sta(:,:,2))','traceSpacing',obj.multiCellTraceSpacing,'traceColor',options.rightColor,'traceLineWidth',obj.dFFLineWidth,...
                        'showTraceIndex',false,'axes',ax(1));
                else
                    plot(options.tau,squeeze(options.sta(:,:,2)),'color',options.rightColor,'LineWidth',obj.dFFLineWidth); hold on;
                end
                if ~isempty(obj.data.deconvF)
                    if nCells > 1
                        plotKTraces(obj.data.caTime,obj.data.deconvF,'traceSpacing',obj.multiCellTraceSpacing,'traceColor',obj.deconvLineColor,'traceLineWidth',obj.deconvLineWidth,...
                            'showTraceIndex',false,'axes',ax(1));
                    else
                        plot(obj.data.caTime,obj.data.deconvF,'color',obj.deconvLineColor,'LineWidth',obj.deconvLineWidth); hold on;
                    end
                end
                if ~isempty(obj.dFRange)
                    ylim([0 obj.dFRange]+min(obj.data.dFF(:,1))-0.1);
                end
                if options.plotLineAtZero
                    YLIM = get(gca,'YLim');
                    plot([0 0],[YLIM(1) YLIM(2)],'k--');
                end
                if ~obj.showAxis
                    axis off
                end
                box off;
                
               % ax(2)=subplot(2,1,2);
                %plot(obj.data.lefteye.time,obj.data.lefteye.angle,'color',obj.leftEyeColor); hold on; plot(obj.data.righteye.time,obj.data.righteye.angle,'color',obj.rightEyeColor);
                
               % if ~isempty(obj.eyeRange)
               %     ylim([0 obj.eyeRange]+ min([min(obj.data.lefteye.angle),min(obj.data.righteye.angle)]))
               % end
             %   linkaxes(ax,'x');
                if ~isempty(obj.timeWidth) && ~isempty(obj.timeOffset2plot)
                    xlim([0 obj.timeWidth]+obj.timeOffset2plot);
                end
                
                if ~obj.showAxis
                    axis off
                end
                box off;
                setFontProperties(gca,'fontName',obj.FontName,'fontSize',obj.FontSize,'fontColor',obj.FontColor);
                
              %  if ~isempty(obj.eyeAxisShrinkFactor)
                    % shrink the second axes
               %     ax(2).Position(4) = ax(2).Position(4)*obj.eyeAxisShrinkFactor;
               % end
               % if ~isempty(obj.axesOverlap)
                    % bring the axes closer together
              %      ax(2).Position(2)=ax(1).Position(2)-ax(1).Position(4)+obj.axesOverlap;
              %  end
                set(gcf,'PaperPosition',obj.paperPosition)
                
                % print and save
                obj.printFigure
            else
                warning('No STAs given to plot');
            end
        end
    end
    methods (Static)
        function [dFF,timeF,E,eyeTime,varargout] = extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndex,varargin)
            options = struct('runDFF',false,'returnDeconvF',false,'haveDeconvMatchDFF',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % single-cell fluorescence and sample times
            if options.runDFF
                dFF = dff(caobj.fluorescence{planeIndex}(:,cellIndex));
            else
                dFF = caobj.fluorescence{planeIndex}(:,cellIndex);
            end
            timeF = caobj.time{planeIndex}(:,cellIndex);
            % eye positions
            E = eyeobj.centerEyesMethod('planeIndex',planeIndex);
            eyeTime = eyeobj.time{planeIndex};
            if options.returnDeconvF
                deconv = caobj.nmfDeconvF{planeIndex}(:,cellIndex);
                if options.haveDeconvMatchDFF
                    [varargout{1},varargout{2},varargout{3}] = matchRange(deconv,dFF);
                else
                    varargout{1} = deconv;
                end
            end
        end
        function [caobj,eyeobj]=loadCaEyeObjs(expIndex)
            [fid,expCond] = listAnimalsWithImaging; % actual animal names for translating the experimentIndex variable
            eyeobj = eyeData('fishid',fid{expIndex},'expcond',expCond{expIndex});
            caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'NMF',true,'loadImages',false,'loadCCMap',false);
        end
    end
end

