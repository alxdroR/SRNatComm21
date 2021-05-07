classdef fig3 < figures & srPaperPlots
    %fig3 - computes and stores main computations required for figure 3,
    %including statistics printed in the text
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        
    end
    
    methods
        function obj = fig3(obj)
        end
        function runFig3ai(obj,varargin)
            options = struct('cumVar',[],'xlim',[],'ylim',[],'toCSV',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.cumVar)
                % run PCA
                script2RunPCAOnSTA;
                % format data to plot into a sharable format
                options.cumVar = cumsum(expl);
            end
            fig3ai = pcCumVarPlotClass('xlim',options.xlim,'ylim',options.ylim);
            fig3ai = fig3ai.compute('cumVar',options.cumVar);
            fig3ai.plot;
            obj.printPercentCaptured('cumVar',options.cumVar);
            if options.toCSV
                fig3ai.toCSV;
            end
        end
        function printPercentCaptured(obj,varargin)
            options = struct('cumVar',[]);
            options = parseNameValueoptions(options,varargin{:});
            % print stats quoted in the paper
            fprintf('\n\nWe found that %0.3f of the variance in STAs could be explained by three principal components\n\n',options.cumVar(3))
        end
        function runFig3aii(~,varargin) 
            options = struct('coef',[],'time',[],'explainedVar',[],'toCSV',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.coef) || isempty(options.time) || isempty(options.explainedVar)
                % run PCA
                script2RunPCAOnSTA;
                options.coef = coef;
                options.time = tauPCA;
                options.explainedVar = expl;
            end
            
            fig3aii = pcVectorPlotClass;
            fig3aii = fig3aii.compute('coef',options.coef,'time',options.time,'explainedVar',options.explainedVar);
            fig3aii.plot;
            if options.toCSV
                fig3aii.toCSV;
            end
        end
        function runFig3bi(~,varargin)
            options = struct('scores',[],'explainedVar',[],'xlim',[],'ylim',[],'zlim',[],'markerSize',[],'axisLineWidth',[],'axisLim',[],'textLocations',[],'toCSV',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.scores) || isempty(options.explainedVar)
                % run PCA
                script2RunPCAOnSTA;
                options.scores = score;
                options.explainedVar = expl;
            end
            
            fig3bi = scorePlotClass('xlim',options.xlim,'ylim',options.ylim,'zlim',options.zlim,...
                'markerSize',options.markerSize,'axisLineWidth',options.axisLineWidth,...
                'axisLim',options.axisLim,'textLocations',options.textLocations);
            fig3bi = fig3bi.compute('scores',options.scores,'explainedVar',options.explainedVar);
            fig3bi.plot;
            if options.toCSV
                fig3bi.toCSV;
            end
        end
        function runFig3bii(~,varargin)
            options = struct('lon',[],'lat',[],'lonRange',[],'xlim',[],'ylim',[],'zlim',[],'markerSize',[],'axisLineWidth',[],'axisLim',[],'textLocations',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.lon) || isempty(options.lat)
                % run PCA
                script2RunPCAOnSTA;
                options.lon = lon;
                options.lat = lat;
                options.lonRange = [0 360] + OFFCut;
            end
            
            fig3bii = scorePlotnormalizedHistoSphereClass;
            fig3bii = fig3bii.compute('lon',options.lon,'lat',options.lat,'lonRange',options.lonRange);
            fig3bii.plot;
        end
        function runFig3biii(~,varargin)
            options = struct('lon',[],'lat',[],'bw',3,'BandWidth',[10 3],'toCSV',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.lon) || isempty(options.lat)
                % run PCA
                script2RunPCAOnSTA;
                options.lon = lon;
                options.lat = lat;
                lonNoShift = NaN;
            else
                lonNoShift = options.lon;
                options.lon = shiftLongitude(lonNoShift,90,'reorder',false);
             end
            
            fig3biii = scorePlotnormalizedHistoEckertwScaleClass;
            fig3biii = fig3biii.compute('lon',options.lon,'lat',options.lat,'bw',options.bw,'BandWidth',options.BandWidth);
            fig3biii.plot;
            if options.toCSV
                if ~isnan(lonNoShift)
                    fig3biii.toCSV('lon',lonNoShift,'lat',options.lat);
                else
                    error('cannot run automated lon calculation and CSV');
                end
            end
        end
    end
end

