classdef scorePlotnormalizedHistoSphereClass < figures & srPaperPlots
    % scorePlotnormalizedHistoSphereClass - plot PCA scores of cell
    % saccade-triggered averages in spherical coordinates (normalized to have
    % unit radius)
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
        bw
        bandWidth
    end
    
    methods
        function obj = scorePlotnormalizedHistoSphereClass(varargin)
            thisFileName = mfilename;
            className = thisFileName;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 0 2.5 2.5];
            obj.bw = 3; % histogram bin size
            obj.bandWidth = [10 3]; % 2D Kernal Density BandWidth
        end
        
        function obj=compute(obj,varargin)
            options = struct('lon',[],'lat',[],'lonRange',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.lon) || isempty(options.lat) || isempty(options.lonRange)
                % run PCA
                script2RunPCAOnSTA;
                % format data to plot into a sharable format
                options.lon = lon;
                options.lat = lat;
                options.lonRange = [0 360] + OFFCut;
            end
            
            % histogram of normalized scores
            latBinEdges = [-90:obj.bw:90]; % latitude bins
            lonBinEdges = [options.lonRange(1)-obj.bw:obj.bw:(options.lonRange(2)+obj.bw) ]; % longitude bins
            [LON,LAT] = obj.makeLonLatMesh(lonBinEdges,latBinEdges);
            % compute two-dimensional kernal density
            histogramOutput = ksdensity([options.lon options.lat],[LON(:) LAT(:)],'BandWidth',obj.bandWidth);
            histogramOutput = reshape(histogramOutput,size(LON));
            histogramOutput = histogramOutput*100;
            
            data = obj.createDataStruct(histogramOutput,latBinEdges,lonBinEdges);
            obj.data = data;
        end
        function [LON,LAT]=makeLonLatMesh(obj,lonBinEdges,latBinEdges)
            [LON,LAT] = meshgrid(lonBinEdges(1:end-1)+obj.bw/2,latBinEdges(1:end-1)+obj.bw/2);
        end
        function data=createDataStruct(obj,histogramOutput,latBinEdges,lonBinEdges)
            data.pdf2d = histogramOutput;
            data.phiBins = latBinEdges;
            data.thetaBins = lonBinEdges;
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            
            % plot
            figure('Renderer','opengl')
            S = referenceSphere;
            ax = axesm('globe','Geoid',S,'Grid','on','GLineWidth',0.1,'GLineStyle','-',...
                'Gcolor',[1 1 1]*0);
            ax.Position = [0 0 1 1];
            axis equal off
            [LON,LAT] = obj.makeLonLatMesh(obj.data.thetaBins,obj.data.phiBins);
            geoshow(LAT,LON,obj.data.pdf2d,'DisplayType','texture'); hold on;
            view(108,20)
            % add arrows and text
            arrowLength = 0.25; pcHeadWidth = 5;pcHeadLength=5;
            plot3([1 1.1],[0 0],[0 0],'k','LineWidth',0.1);
            arrowAngle = 220; arrowPositionNormUnits = [0.39 0.383 arrowLength arrowAngle];
            annotation('arrow',[0 arrowPositionNormUnits(3)*cos(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(1),...
                [0 arrowPositionNormUnits(3)*sin(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(2),'LineWidth',0.3,'HeadWidth',pcHeadWidth,'HeadLength',pcHeadLength);
            
            arrowLength = 0.2;
            plot3([0 0],[1 1.1],[0 0],'k','LineWidth',0.1);
            arrowAngle = 360; arrowPositionNormUnits = [0.8 0.455 arrowLength arrowAngle];
            annotation('arrow',[0 arrowPositionNormUnits(3)*cos(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(1),...
                [0 arrowPositionNormUnits(3)*sin(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(2),'LineWidth',0.3,'HeadWidth',pcHeadWidth,'HeadLength',pcHeadLength);
            plot3([0 0],[0 0],[1 1.1],'k','LineWidth',0.1);
            arrowAngle = 90; arrowPositionNormUnits = [0.49 0.8 arrowLength arrowAngle];
            annotation('arrow',[0 arrowPositionNormUnits(3)*cos(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(1),...
                [0 arrowPositionNormUnits(3)*sin(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(2),'LineWidth',0.3,'HeadWidth',pcHeadWidth,'HeadLength',pcHeadLength);
            
            arrowLength = 0.3;
            arrowAngle = 320; arrowPositionNormUnits = [0.6 0.4 arrowLength arrowAngle];
            annotation('arrow',[0 arrowPositionNormUnits(3)*cos(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(1),...
                [0 arrowPositionNormUnits(3)*sin(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(2),'LineWidth',0.3,'HeadWidth',pcHeadWidth,'HeadLength',pcHeadLength);
            
            arrowAngle = 50; arrowPositionNormUnits = [0.61 0.59 arrowLength arrowAngle];
            annotation('arrow',[0 arrowPositionNormUnits(3)*cos(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(1),...
                [0 arrowPositionNormUnits(3)*sin(arrowPositionNormUnits(4)*pi/180)]+arrowPositionNormUnits(2),'LineWidth',0.3,'HeadWidth',pcHeadWidth,'HeadLength',pcHeadLength);
            if false
            % bitmap text size changes
            text(2.7,-0.35,0.2,{'c_1' },'FontName',obj.FontName,'FontSize',obj.FontSize,'Color',obj.FontColor);
            text(0.3,2.0,0,{'c_2' },'FontName',obj.FontName,'FontSize',obj.FontSize,'Color',obj.FontColor);
            text(0,-0.35,1.4,{'c_3' },'FontName',obj.FontName,'FontSize',obj.FontSize,'Color',obj.FontColor);
            end
            % modify the RGB scale
            map = colormap(gca);
            origHSV = rgb2hsv(map);
            origHSV(:,1) = origHSV(1,1);
            origHSV(:,3) = origHSV(1,3);
            origHSV(:,2) = linspace(0.15,1,size(map,1));
            modRGB = hsv2rgb(origHSV);
            colormap(modRGB)
            set(gcf,'PaperPosition',obj.paperPosition,'InvertHardcopy','off','Color',[1 1 1])
            
            obj.printAndSave;
        end
        function printAndSave(obj)
            % print and save
            %obj.printFigure
            printAndSave(obj.filename,'data',obj.data,'formattype','-dpng','addPrintOps','-r700')
        end
    end
end