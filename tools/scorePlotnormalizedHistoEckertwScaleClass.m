classdef scorePlotnormalizedHistoEckertwScaleClass < fig3
    % scorePlotnormalizedHistoEckertwScaleClass - - plot PCA scores of cell
    % saccade-triggered averages in spherical coordinates (normalized to have
    % unit radius) using an Eckert projection
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    
    properties
        xlim
        ylim
    end
    
    methods
        function obj = scorePlotnormalizedHistoEckertwScaleClass(varargin)
            options = struct('xlim',[],'ylim',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            className = mfilename;
            obj.filename = className(1:end-5);
            obj.paperPosition = [0 0 8 8];
            obj.xlim = options.xlim;
            obj.ylim = options.ylim;
        end
        
        function obj=compute(obj,varargin)
            options = struct('bw',3,'lon',[],'lat',[],'BandWidth',[10 3]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(options.lon) || isempty(options.lat)
                % run PCA
                script2RunPCAOnSTA;
                % format data to plot into a sharable format
                options.lon = lon;
                options.lat = lat;
            end
            % make a histogram of normalized scores
            latBinEdges = -90:options.bw:90; % latitude bins
            lonBinEdges = (90-3):options.bw:(360+90+options.bw); % longitude bins
            [LON,LAT] = meshgrid(lonBinEdges(1:end-1)+options.bw/2,latBinEdges(1:end-1)+options.bw/2);
            % compute two-dimensional kernal density
            histogramOutput = ksdensity([options.lon options.lat],[LON(:) LAT(:)],'BandWidth',options.BandWidth);
            histogramOutput = reshape(histogramOutput,size(LON));
            histogramOutput = histogramOutput*100;
            
            data = obj.createDataStruct(histogramOutput,latBinEdges,lonBinEdges,LAT,LON);
            obj.data = data;
        end
        
        function data=createDataStruct(~,histogramOutput,latBinEdges,lonBinEdges,LAT,LON)
            data.pdf2d = histogramOutput;
            data.phiBins = latBinEdges;
            data.thetaBins = lonBinEdges;
            data.thetaGrid = LON;
            data.phiGrid = LAT;
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data)
                if ~isempty(options.sourceDataFile)
                    obj = obj.loadData('sourceDataFile',options.sourceDataFile);
                end
            end
            
            % plot
            feck=figure; axesm eckert4;
            mline = -135:45:135;
            geoshow(obj.data.phiGrid,obj.data.thetaGrid+90,obj.data.pdf2d,'DisplayType','texture'); axis off
            gridm('GLineWidth',0.5,'GLineStyle','-','MLineLocation',mline,'PLineLocation',[-90:45:90]);
            
            % match labels with text (x,y) locations
            mline = mline - 90;
            mline(1) = mod(mline(1),360);
            if false
            text(-1.4,1.4,{[num2str(mline(1)) ' \circ']},'FontName','Arial','FontSize',8,'Color','k');
            text(-0.9,1.4,{[num2str(mline(2)) ' \circ']},'FontName','Arial','FontSize',8,'Color','k');
            text(-0.4,1.4,{[num2str(mline(3)) ' \circ']},'FontName','Arial','FontSize',8,'Color','k');
            text(0,1.4,{[num2str(mline(4)) ' \circ']},'FontName','Arial','FontSize',8,'Color','k');
            text(0.35,1.4,{[num2str(mline(5)) ' \circ']},'FontName','Arial','FontSize',8,'Color','k');
            text(0.75,1.4,{[num2str(mline(6)) ' \circ']},'FontName','Arial','FontSize',8,'Color','k');
            text(1.0,1.4,{[num2str(mline(7)) ' \circ']},'FontName','Arial','FontSize',8,'Color','k');
            text(-2.5,0.9,{'45 \circ'},'FontName','Arial','FontSize',8,'Color','k');
            text(-2.75,0,{'0 \circ'},'FontName','Arial','FontSize',8,'Color','k');
            text(-2.55,-0.9,{'-45 \circ'},'FontName','Arial','FontSize',8,'Color','k');
            end
            % create a color map where the hue and value are fixed and the saturation varies
            map = colormap(gca);
            origHSV = rgb2hsv(map);
            origHSV(:,1) = origHSV(1,1);
            origHSV(:,3) = origHSV(1,3);
            origHSV(:,2) = linspace(0.015,1,size(map,1));
            modRGB = hsv2rgb(origHSV);
            colormap(modRGB)
            cbh = colorbar('Position',[0.85 0.35 0.01 0.1],'FontName','Arial','FontSize',8,'Color','k');
            if false
            cbh.Label.String = {'100 X probability' 'density'};
            end
            cbh.Label.Rotation = -90;cbh.Label.Position = [9.2 0.0072 0];
            set(gcf,'PaperPosition',obj.paperPosition,'InvertHardcopy','off','Color',[1 1 1])
            
           % setFontProperties(gca,'fontName',obj.FontName,'fontSize',obj.FontSize,'fontColor',obj.FontColor);
            if ~isempty(obj.xlim)
                xlim(obj.xlim);
            end
            if ~isempty(obj.ylim)
                ylim(obj.ylim);
            end
            
            obj.printAndSave;
        end
        function toCSV(obj,varargin)
            global saveCSV
            options = struct('lon',[],'lat',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if saveCSV
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 3d.csv'],'a');
                fprintf(fileID,'Panel\nd\nSTA Coefficients in Spherical Coordinates (after unit normalization)\n');
                fprintf(fileID,',STA Index,Phi,Theta\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 3d.csv'],[(1:length(options.lon))' options.lon options.lat],'delimiter',',','-append','coffset',1);
                fclose(fileID);
            end
        end
        function printAndSave(obj)
            % print and save
            printAndSave(obj.filename,'data',obj.data,'formattype','-dpng','addPrintOps','-r700')
        end
    end
end
