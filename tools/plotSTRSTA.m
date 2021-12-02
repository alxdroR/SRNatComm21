classdef plotSTRSTA < figures & srPaperPlots
    %plotSTRSTA - plot saccade-triggered responses and average
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        dFRange % range of dF/F to show
        rightSTAColor
        leftSTAColor
        lineAtZeroWidth
        spaceBetweenSTRLR
        tauLimits
        strAXOffset
        strAXHeight
        staAXOffset
        staAXHeight
        deconvOffset
        addScaleBar
    end
    
    methods
        function obj = plotSTRSTA(varargin)
            options = struct('filename',[],'paperPosition',[0 0 8.5 11],...
                'time',[],'STRL',[],'STRR',[],'STA',[],'STACIL',[],'STACIU',[],'deconvSTA',[],...
                'dFRange',[],'rightSTAColor',[],'leftSTAColor',[],'lineAtZeroWidth',[],'spaceBetweenSTRLR',[],'tauLimits',[],...
                'strAXOffset',[],'strAXHeight',[],'staAXOffset',[],'staAXHeight',[],'deconvOffset',false,'addScaleBar',false);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.filename)
                obj.filename = [mfilename '-' date];
            else
                obj.filename = options.filename;
            end
            obj.paperPosition = options.paperPosition;
            obj.dFRange = options.dFRange;
            
            obj.rightSTAColor = options.rightSTAColor;
            obj.leftSTAColor = options.leftSTAColor;
            obj.lineAtZeroWidth = options.lineAtZeroWidth;
            obj.spaceBetweenSTRLR = options.spaceBetweenSTRLR; % space between STR left and right responses (in units of number of rows. minimum is 1);
            obj.tauLimits = options.tauLimits;
            obj.strAXOffset = options.strAXOffset;
            obj.strAXHeight = options.strAXHeight;
            obj.staAXOffset = options.staAXOffset;
            obj.staAXHeight = options.staAXHeight;
            obj.deconvOffset = options.deconvOffset;
            obj.addScaleBar = options.addScaleBar;
            if isempty(options.time) || isempty(options.STRL) || isempty(options.STRR) || isempty(options.STA)
                % try to load based on other information
            else
                obj = obj.createDataStruct(varargin{:});
            end
        end
        function obj=createDataStruct(obj,varargin)
            options = struct('time',[],'STRL',[],'STRR',[],'STA',[],'STACIL',[],'STACIU',[],'deconvSTA',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            obj.data = struct('time',options.time,'STRL',options.STRL,'STRR',options.STRR,'STA',options.STA,'STACIL',options.STACIL,'STACIU',options.STACIU,'deconvSTA',options.deconvSTA);
        end
        
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data) && ~isempty(options.sourceDataFile)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            if ~isempty(obj.data)
                % plot the loaded data -----------------
                ax = showSTAwRaster(obj.data.STRL,obj.data.STRR,obj.data.time,obj.data.STA,obj.data.STACIL,obj.data.STACIU,'dFRange',obj.dFRange,...
                    'rightSTAColor',obj.rightSTAColor,'leftSTAColor',obj.leftSTAColor,'lineAtZeroWidth',obj.lineAtZeroWidth,'nrowsSpace',obj.spaceBetweenSTRLR,...
                    'xlim',obj.tauLimits,'deconvSTA',obj.data.deconvSTA,'deconvOffset',obj.deconvOffset,'addScaleBar',obj.addScaleBar);
                box off;
                setFontProperties(ax(2),'fontName',obj.FontName,'fontSize',obj.FontSize,'fontColor',obj.FontColor);
                set(ax(2),'YTickLabel',[],'YTick',[],'YColor','w','XTick',-10:2:10,...
                    'XTickLabel',{'-10','-8','-6','-4','-2','0','2','4','6','8','10'})
                
                if ~isempty(obj.strAXHeight)
                    ax(1).Position(4) = obj.strAXHeight;
                end
                
                if ~isempty(obj.strAXOffset)
                    ax(1).Position(2) = obj.strAXOffset;
                end
                
                if ~isempty(obj.staAXOffset)
                    ax(2).Position(2) = obj.staAXOffset;
                end
                
                if ~isempty(obj.staAXHeight)
                    ax(2).Position(4) = obj.staAXHeight;
                end
                set(gcf,'PaperPosition',obj.paperPosition,'InvertHardcopy','off','Color',[1 1 1]);
                
                % print and save
                obj.printFigure
            else
                warning('No cells or cell ids given to plot');
            end
        end
    end
    methods (Static)
        function [sta2plot,staCIL2plot,staCIU2plot,STRL,STRR,bt,varargout] = extractSTRSTA(allIDs,desiredIDs,STA,STCIL,STCIU,F,timeF,varargin)
            options = struct('deconvSTA',[],'haveDeconvMatchDFF',false);
            options = parseNameValueoptions(options,varargin{:});
            
            expIndex = desiredIDs(1);planeIndex = desiredIDs(2);cellIndex = desiredIDs(3);
            index = find(allIDs(:,1) == expIndex & allIDs(:,2) == planeIndex & allIDs(:,3) == cellIndex);
            sta2plot = squeeze(STA(index,:,:)); % sta
            staCIL2plot = squeeze(STCIL(index,:,:));
            staCIU2plot = squeeze(STCIU(index,:,:)); % lower and upper 95% confidence intervals
            [STRL,bt]=loadSingleTrialResponses({{F}},{{timeF}},[expIndex planeIndex cellIndex],'direction','surrounding left',...
                'interp2gridThenCat',true,'binTimesPreceeding',-30:1/3:-1/3,'binTimesFollowing',0:1/3:30);
            STRR=loadSingleTrialResponses({{F}},{{timeF}},[expIndex planeIndex cellIndex],'direction','surrounding right',...
                'interp2gridThenCat',true,'binTimesPreceeding',-30:1/3:-1/3,'binTimesFollowing',0:1/3:30);
            
            if ~isempty(options.deconvSTA)
                deconvSTA = squeeze(options.deconvSTA(index,:,:));
                if options.haveDeconvMatchDFF
                    varargout{1} = [matchRange(deconvSTA(:,1),sta2plot(:,1)) matchRange(deconvSTA(:,2),sta2plot(:,2))];
                else
                    varargout{1} = deconvSTA;
                end
            end
        end
    end
end

