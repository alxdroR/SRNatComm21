classdef fig5 < figures & srPaperPlots
    %fig5 - print figure panels in figure 4
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        dFFRange
        eyeRange
        dFFLineWidth
        dFFLineColor
        deconvLineWidth
        deconvLineColor
        ID = [0 0 0]
        dFF
        timeF
        E
        eyeTime
        deconvAU
        deconvScale
        deconvOffset
        showScale
    end
    
    methods
        function obj = fig5(varargin)
            options = struct('dFFRange',[],'eyeRange',[],'dFFLineWidth',[],'dFFLineColor',[],...
                'deconvLineWidth',[],'deconvLineColor',[0 0 0],'paperPosition',[],'showScale',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % set properties fixed across all subpanels
            obj.dFFRange = options.dFFRange;
            obj.eyeRange = options.eyeRange;
            if isempty(options.dFFLineWidth)
                obj.dFFLineWidth = obj.LineWidth;
            else
                obj.dFFLineWidth = options.dFFLineWidth;
            end
            if isempty(options.dFFLineColor)
                obj.dFFLineColor = obj.LineColor;
            else
                obj.dFFLineColor = options.dFFLineColor;
            end
            if isempty(options.deconvLineWidth)
                obj.deconvLineWidth = obj.LineWidth;
            else
                obj.deconvLineWidth = options.deconvLineWidth;
            end
            obj.deconvLineColor = options.deconvLineColor;
            obj.showScale = options.showScale;
            % paperPosition has default values if user doesn't provide
            % values
            if ~isempty(options.paperPosition)
                obj.paperPosition = options.paperPosition;
            end
        end
        function obj=runFig5b(obj,ID,varargin)
            obj=runPlotActivityWEyesClass(obj,ID,varargin{:});
        end   
        function obj=runPlotActivityWEyesClass(obj,ID,varargin)
            options = struct('timeOffset2plot',[],'timeWidth',[],'axesOverlap',[],'showAxis',true,'showDeconv',false,'traceFilename',[],...
                'AnticipatoryAnalysisMatrix',[],'ISIMatrix',[],'fixationIDs',[],'showSlopes',false,'slopeColor',[],'slopeLineWidth',[],'textYLoc',[],...
                'slopesFromDeconv',true,'riseTimeMarker','.','riseTimeColor','k','riseTimeMarkerSize',8);
            options = parseNameValueoptions(options,varargin{:});
            
            if any(ID ~= obj.ID)
                expIndex = ID(1);planeIndex = ID(2);cellIndex = ID(3);
                [caobj,eyeobj] = plotActivityWEyes.loadCaEyeObjs(expIndex);
                if options.showDeconv
                    [dFF,timeF,E,eyeTime,deconvAU,matchingScale,matchingOffset] = plotActivityWEyes.extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndex,'runDFF',true,'returnDeconvF',true,'haveDeconvMatchDFF',true);
                    obj.deconvAU = deconvAU;
                    obj.deconvScale = matchingScale;
                    obj.deconvOffset = matchingOffset;
                else
                    [dFF,timeF,E,eyeTime] = plotActivityWEyes.extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndex,'runDFF',true,'returnDeconvF',false);
                    obj.deconvAU = [];
                    obj.deconvScale = NaN;
                    obj.deconvOffset = NaN;
                end
                obj.ID = ID;
                obj.dFF = dFF;
                obj.timeF = timeF;
                obj.E = E;
                obj.eyeTime = eyeTime;
            end
            activityEyeObj = plotActivityWEyes('filename',options.traceFilename,'paperPosition',obj.paperPosition,...
                'eyeTime',obj.eyeTime,'angle',obj.E,'leftEyeIndex',1,'rightEyeIndex',2,'caTime',obj.timeF,'dFF',obj.dFF,'deconvF',obj.deconvAU,...
                'dFRange',obj.dFFRange,'timeWidth',options.timeWidth,'eyeRange',obj.eyeRange,'timeOffset2plot',options.timeOffset2plot,...
                'axesOverlap',options.axesOverlap,'dFFLineWidth',obj.dFFLineWidth,'dFFLineColor',obj.dFFLineColor,...
                'deconvLineWidth',obj.deconvLineWidth,'deconvLineColor',obj.deconvLineColor,'showAxis',options.showAxis,...
                'showScale',obj.showScale);
            ax=activityEyeObj.plot;
            
            % possibly add slopes
            if isempty(options.AnticipatoryAnalysisMatrix) || isempty(options.ISIMatrix) || isempty(options.fixationIDs)
                if options.showSlopes
                    loadSRSlopes
                end
            else
                AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
                ISIMatrix = options.ISIMatrix;
                fixationIDs = options.fixationIDs;
                options.showSlopes = true; % cleary user wants slopes to be shown
            end
            if options.showSlopes
                if isempty(options.slopeColor)
                    options.slopeColor = obj.LineColor;
                end
                if isempty(options.slopeLineWidth)
                    options.slopeLineWidth = obj.LineWidth;
                end
                if isempty(options.textYLoc)
                    options.textYLoc = max(max(obj.dFF));
                end
                fid = listAnimalsWithImaging;
                expIndex = ID(1);planeIndex = ID(2);cellIndex = ID(3);
                nameValue = str2double(fid{expIndex}(2:end));
                if isnan(nameValue)
                    nameValue = fid{expIndex}(2:end);
                end
                nameValue = expIndex;
                exemplarSRMeasurements = AnticipatoryAnalysisMatrix(fixationIDs(:,1)== nameValue & fixationIDs(:,2) == planeIndex & fixationIDs(:,3) == cellIndex,:);
                fixationDurations = ISIMatrix(fixationIDs(:,1)== nameValue & fixationIDs(:,2) == planeIndex & fixationIDs(:,3) == cellIndex);
                data.fd = fixationDurations;
                if isnan(obj.deconvScale)
                    data.slopes = exemplarSRMeasurements(:,1);
                    data.offset = exemplarSRMeasurements(:,6);
                else
                    data.slopes = obj.deconvScale*exemplarSRMeasurements(:,1);
                    data.offset = obj.deconvScale*exemplarSRMeasurements(:,6) + obj.deconvOffset;
                   end
                data.rtUS = exemplarSRMeasurements(:,2);
                data.fixationStartTimes = exemplarSRMeasurements(:,7);
                axes(ax(1))
                for fixationIndex=1:length(data.fixationStartTimes)
                    if ~isnan(data.rtUS(fixationIndex))
                        % draw line
                        absoluteRiseTime = data.fixationStartTimes(fixationIndex)+data.fd(fixationIndex)+data.rtUS(fixationIndex);
                        upcomingSaccadeTime = data.fixationStartTimes(fixationIndex)+data.fd(fixationIndex);
                        tau = linspace(absoluteRiseTime,upcomingSaccadeTime,100);
                        plot(tau,data.slopes(fixationIndex)*(tau-tau(end)) + data.offset(fixationIndex),'-','Color',options.slopeColor,'lineWidth',options.slopeLineWidth)
                        if ~isempty(data.slopes(fixationIndex))
                            st=sprintf('%0.0f',data.slopes(fixationIndex)/obj.deconvScale);
                            text(absoluteRiseTime-4,options.textYLoc,st,'color',options.slopeColor,'FontName',obj.FontName,'FontSize',obj.FontSize-1)
                        end
                        % highlight rise time
                        [~,timeInd] = min(abs(absoluteRiseTime-obj.timeF));
                        if options.slopesFromDeconv
                            plot(absoluteRiseTime,obj.deconvAU(timeInd),'Color',options.riseTimeColor,'Marker',options.riseTimeMarker,'MarkerSize',options.riseTimeMarkerSize);
                        else
                             plot(absoluteRiseTime,obj.dFF(timeInd),'Color',options.riseTimeColor,'Marker',options.riseTimeMarker,'MarkerSize',options.riseTimeMarkerSize);
                        end
                    end
                end
                % print the updated figure
                obj.filename = options.traceFilename;
                obj.printFigure
                obj.filename = [];
            end
        end
    end
end

