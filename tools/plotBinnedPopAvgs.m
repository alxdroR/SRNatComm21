classdef plotBinnedPopAvgs < figures & srPaperPlots
    %plotBinnedPopAvgs - plot population average STAs binned by
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 202x
    properties
        autoSubplotSpacing
        axesSpacing
        FaceAlpha
        XLIM
        YLIM
        STAIndicesAtBins
        binCenters
        XTick
        XTickLabel
        XLabel
        XLabelOffset
        YLabel
        YLabelPosition
        sortName
        sortNameLabelPosition
        sortNameEqualPosition
        sortNameValuePosition
        zeroLineYMax
        zeroLineWidth
        zeroLineColor
        zeroLineStyle
        numSamplePercentCutoff
        setAvgMin
        altDirLineColor
    end
    
    methods
        function obj = plotBinnedPopAvgs(varargin)
            options = struct('filename',[],'autoSubplotSpacing',true,'axesSpacing',NaN,...
                'LineColor',[],'LineStyle',[],'LineWidth',[],'Marker',[],'MarkerSize',[],'FontSize',[],'paperPosition',[],...
                'FaceAlpha',0.1,'XLIM',[],'YLIM',[],'zeroLineYMax',1,'zeroLineWidth',1,'zeroLineColor',[0 0 0],'zeroLineStyle','-',...
                'XTick',[],'XTickLabel',[],'XLabel',[],'XLabelOffset',0,'YLabel',[],...
                'YLabelPosition',[0,0],'sortName','','sortNameLabelPosition',[0,0],'sortNameEqualPosition',[0,0],'sortNameValuePosition',[0,0],...
                'numSamplePercentCutoff',0,'setAvgMin',NaN,'X',[],'sortValue',[],'extraBinCriteria',[],'samplesWNorm2Match',[],'binCenters',[],'binWidth',[],'time',[],...
                'addAlternateDirection',[],'altDirLineColor',NaN);
            options = parseNameValueoptions(options,varargin{:});
            
            obj.autoSubplotSpacing = options.autoSubplotSpacing;
            obj.FaceAlpha = options.FaceAlpha;
            obj.zeroLineYMax = options.zeroLineYMax;
            obj.zeroLineWidth = options.zeroLineWidth;
            obj.zeroLineColor = options.zeroLineColor;
            obj.zeroLineStyle = options.zeroLineStyle;
            obj.XTick = options.XTick;
            obj.XTickLabel = options.XTickLabel;
            obj.XLabel = options.XLabel;
            obj.XLabelOffset = options.XLabelOffset;
            obj.YLabel = options.YLabel;
            obj.YLabelPosition = options.YLabelPosition;
            obj.sortName = options.sortName;
            obj.sortNameLabelPosition = options.sortNameLabelPosition;
            obj.sortNameEqualPosition = options.sortNameEqualPosition;
            obj.sortNameValuePosition = options.sortNameValuePosition;
            obj.XLIM = options.XLIM;
            obj.YLIM = options.YLIM;
            obj.binCenters = options.binCenters;
            obj.numSamplePercentCutoff = options.numSamplePercentCutoff;
            obj.setAvgMin = options.setAvgMin;
            if ~isempty(options.paperPosition)
                obj.paperPosition = options.paperPosition;
            end
            if ~options.autoSubplotSpacing && isnan(options.axesSpacing)
                obj.axesSpacing = 0.1;
                warning('set the axes spacing if you do not want auto subplot spacing to be used');
            else
                obj.axesSpacing = options.axesSpacing;
            end
            if isempty(options.filename)
                obj.filename = mfilename;
            else
                obj.filename = options.filename;
            end
            obj = obj.setLineColor(options.LineColor,'binCenters',options.binCenters);
            
            if ~isempty(options.LineStyle)
                obj.LineStyle = options.LineStyle;
            end
            if ~isempty(options.LineWidth)
                obj.LineWidth = options.LineWidth;
            end
            if ~isempty(options.Marker)
                obj.Marker = options.Marker;
            end
            if ~isempty(options.MarkerSize)
                obj.MarkerSize = options.MarkerSize;
            end
            if ~isempty(options.FontSize)
                obj.FontSize = options.FontSize;
            end
            if ~isempty(options.addAlternateDirection) & isnan(options.altDirLineColor)
                obj.altDirLineColor = [0 0 1];
            elseif ~isnan(options.altDirLineColor)
                obj.altDirLineColor = options.altDirLineColor;
            end
            obj = obj.compute(varargin{:});
        end
        function toCSV(obj,varargin)
            options = struct('X',[],'sortValue',[],'binCenters',[],'extraBinCriteria',[],...
                'binWidth',[],'time',[],'addAlternateDirection',[],'ID',[],'figureName','');
            options = parseNameValueoptions(options,varargin{:});
            
            pb=plotBinner(options.sortValue,options.binCenters);
            indicesPerBin = pb.binData('onlyReturnIndicesPerBin',true,'extraBinCriteriaBool',options.extraBinCriteria,'binWidth',options.binWidth);
            plotBinnedPopAvgs.avgSeries(options.X,indicesPerBin,'numSampMin',...
                obj.numSamplePercentCutoff,'setMin',obj.setAvgMin,'binValue',options.binCenters,'time',options.time,'ID',options.ID,...
                'saveSampleData',true,'figureName',options.figureName);
        end
        function obj = compute(obj,varargin)
            options = struct('X',[],'sortValue',[],'extraBinCriteria',[],'samplesWNorm2Match',[],'binCenters',[],'binWidth',[],'time',[],'addAlternateDirection',[],'ID',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if ~isempty(options.sortValue) && ~isempty(options.X) && ~isempty(options.binCenters)
                pb=plotBinner(options.sortValue,options.binCenters);
                indicesPerBin = pb.binData('onlyReturnIndicesPerBin',true,'extraBinCriteriaBool',options.extraBinCriteria,'binWidth',options.binWidth);
                [summaryStat,statVariability] = plotBinnedPopAvgs.avgSeries(options.X,indicesPerBin,'numSampMin',...
                    obj.numSamplePercentCutoff,'setMin',obj.setAvgMin,'binValue',options.binCenters,'time',options.time,'ID',options.ID);
                obj.STAIndicesAtBins = indicesPerBin;
                if ~isempty(options.addAlternateDirection)
                    alternateIndices = cell(size(indicesPerBin));
                    for index=1:length(indicesPerBin)
                        alternateIndices{index} = options.addAlternateDirection(indicesPerBin{index},2);
                    end
                    [summaryStatAltDir,statVarAltDir] = plotBinnedPopAvgs.avgSeries(options.X,alternateIndices,'numSampMin',obj.numSamplePercentCutoff,'setMin',obj.setAvgMin);
                end
                
                % set deconv norms equal to desired sample norms
                if ~isempty(options.samplesWNorm2Match)
                    popAvgOfDesiredNorms = plotBinnedPopAvgs.avgSeries(options.samplesWNorm2Match,indicesPerBin,'numSampMin',obj.numSamplePercentCutoff,'setMin',obj.setAvgMin);
                    [summaryStat,statVariability] = plotBinnedPopAvgs.matchNorm(summaryStat,popAvgOfDesiredNorms,'alsoMatch',statVariability);
                    if ~isempty(options.addAlternateDirection)
                        popAvgOfDesiredNormsAlt = plotBinnedPopAvgs.avgSeries(options.samplesWNorm2Match,alternateIndices,'numSampMin',obj.numSamplePercentCutoff,'setMin',obj.setAvgMin);
                        [summaryStatAltDir,statVarAltDir] = plotBinnedPopAvgs.matchNorm(summaryStatAltDir,popAvgOfDesiredNormsAlt,'alsoMatch',statVarAltDir);
                    end
                end
                if isempty(options.addAlternateDirection)
                    obj = obj.createDataStruct('binCenters',options.binCenters,'time',options.time,'summaryStat',summaryStat,'statVariability',statVariability);
                else
                    obj = obj.createDataStruct('binCenters',options.binCenters,'time',options.time,'summaryStat',summaryStat,'statVariability',statVariability,...
                        'summaryStatAltDir',summaryStatAltDir,'statVarAltDir',statVarAltDir);
                end
            else
                obj = obj.createDataStruct(varargin{:});
            end
        end
        function obj=createDataStruct(obj,varargin)
            options = struct('binCenters',[],'time',[],'summaryStat',[],'statVariability',[],'summaryStatAltDir',[],'statVarAltDir',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.summaryStatAltDir)
                obj.data = struct('binCenters',options.binCenters,'time',options.time,'summaryStat',options.summaryStat,'statVariability',options.statVariability);
            else
                obj.data = struct('binCenters',options.binCenters,'time',options.time,'summaryStat',options.summaryStat,'statVariability',options.statVariability,...
                    'summaryStatAltDir',options.summaryStatAltDir,'statVarAltDir',options.statVarAltDir);
            end
        end
        function obj=setLineColor(obj,CM,varargin)
            options = struct('binCenters',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            numBins = length(options.binCenters(:));
            if ischar(CM)
                error('Can not use character Color inputs with plotBinnedPopAvgs')
            elseif isnumeric(CM)
                numDims = ndims(CM);
                if numDims==2
                    [nColors,dim]=size(CM);
                    if dim==0
                        if numBins>0
                            % give all bins the default color
                            obj.LineColor = repmat(obj.LineColor,numBins,1);
                        end
                    elseif dim==3
                        
                        if numBins>0
                            if nColors >= numBins
                                obj.LineColor = CM(1:numBins,:);
                            else
                                % repeat the last color to fill in the rest
                                obj.LineColor = [CM;repmat(CM(end,:),numBins-nColors,1)];
                            end
                        end
                    else
                        error('If LineColor input is a numeric and not a coor image, it must be an Nx3 vector');
                    end
                elseif numDims ==3
                    if numBins > 0
                        obj.LineColor = plotBinnedPopAvgs.RGBGrad2Colors(CM,options.binCenters);
                    end
                else
                    error('If LineColor input is a numeric and not a coor image, it must be an Nx3 vector');
                end
            end
        end
        function plot(obj,varargin)
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % load data
            if isempty(obj.data) && ~isempty(options.sourceDataFile)
                obj = obj.loadData('sourceDataFile',options.sourceDataFile);
            end
            if ~isempty(obj.data)
                numBins = length(obj.data.binCenters);
                isFirstPlot = true;
                figure;
                for bindex = 1 : numBins
                    if ~obj.autoSubplotSpacing
                        if bindex == 1
                            subplot(1,numBins,bindex);
                            axisPos0 = get(gca,'Position');
                            axisX0 = axisPos0(1);
                            axisWidth = axisPos0(3);
                        else
                            subplot('position',[axisX0 + (axisWidth + obj.axesSpacing)*(bindex-1) axisPos0(2:end)]);
                            % set(gca,'Position',[axisX0 + (axisWidth + obj.axesSpacing)*(bindex-1) axisPos0(2:end)]);
                        end
                    else
                        subplot(1,numBins,bindex)
                    end
                    
                    hasData = ~all(isnan(obj.data.summaryStat(bindex,:))) & ~all(isnan(obj.data.statVariability(bindex,:)));
                    if hasData
                        % plot averages and error
                        plot(obj.data.time,obj.data.summaryStat(bindex,:),'Color',obj.LineColor(bindex,:),...
                            'LineStyle',obj.LineStyle,'LineWidth',obj.LineWidth,'Marker',obj.Marker,'MarkerSize',obj.MarkerSize);
                        hold on;
                        errLower = obj.data.summaryStat(bindex,:) - obj.data.statVariability(bindex,:); errUpper = obj.data.summaryStat(bindex,:) + obj.data.statVariability(bindex,:);
                        fh=fill([obj.data.time obj.data.time(end) fliplr(obj.data.time) obj.data.time(1) ],[errLower errUpper(end) fliplr(errUpper) errLower(1)],obj.LineColor(bindex,:));
                        fh.FaceAlpha = obj.FaceAlpha;fh.EdgeColor = obj.LineColor(bindex,:);fh.LineStyle = obj.LineStyle;fh.LineWidth = obj.LineWidth;fh.Marker = obj.Marker;fh.MarkerSize=obj.MarkerSize;
                        
                        if isfield(obj.data,'summaryStatAltDir')
                            plot(obj.data.time,obj.data.summaryStatAltDir(bindex,:),'Color',obj.altDirLineColor,...
                                'LineStyle',obj.LineStyle,'LineWidth',obj.LineWidth,'Marker',obj.Marker,'MarkerSize',obj.MarkerSize);
                            errLower = obj.data.summaryStatAltDir(bindex,:) - obj.data.statVarAltDir(bindex,:); errUpper = obj.data.summaryStatAltDir(bindex,:) + obj.data.statVarAltDir(bindex,:);
                            fh=fill([obj.data.time obj.data.time(end) fliplr(obj.data.time) obj.data.time(1) ],[errLower errUpper(end) fliplr(errUpper) errLower(1)],obj.LineColor(bindex,:));
                            fh.FaceAlpha = obj.FaceAlpha;fh.EdgeColor = obj.altDirLineColor;fh.LineStyle = obj.LineStyle;fh.LineWidth = obj.LineWidth;fh.Marker = obj.Marker;fh.MarkerSize=obj.MarkerSize;
                        end
                        
                        % add line at zero
                        if ~isempty(obj.YLIM)
                            plot([1 1]*0,[obj.YLIM(1) obj.zeroLineYMax],'Color',obj.zeroLineColor,'LineStyle',obj.zeroLineStyle,'LineWidth',obj.zeroLineWidth);
                        else
                            plot([1 1]*0,[0 obj.zeroLineYMax],'Color',obj.zeroLineColor,'LineStyle',obj.zeroLineStyle,'LineWidth',obj.zeroLineWidth);
                        end
                        
                        % add xtick labels, yaxis labels and sortName titles to first plot and remove tick label from other plots
                        if isFirstPlot
                            set(gca,'XTick',obj.XTick,'XTickLabel',obj.XTickLabel);
                            xh=xlabel(obj.XLabel);
                            xh.Position = [xh.Position(1) xh.Position(2)+obj.XLabelOffset];
                            if ~isempty(obj.YLabel)
                                text(obj.YLabelPosition(1),obj.YLabelPosition(2),obj.YLabel,'Rotation',90,...
                                    'FontName',obj.FontName,'Color',obj.FontColor,'FontSize',obj.FontSize,'Units','Normalized');
                            end
                            text(obj.sortNameLabelPosition(1),obj.sortNameLabelPosition(2),obj.sortName,'Rotation',0,...
                                'FontName',obj.FontName,'Color',obj.FontColor,'FontSize',obj.FontSize+1,'HorizontalAlignment','center');
                            text(obj.sortNameEqualPosition(1),obj.sortNameEqualPosition(2),'=','Rotation',0,...
                                'FontName',obj.FontName,'Color',obj.FontColor,'FontSize',obj.FontSize,'HorizontalAlignment','center');
                            isFirstPlot = false;
                        else
                            set(gca,'XTick',obj.XTick,'XTickLabel',[]);
                        end
                        
                        % do this to every plot
                        set(gca,'YTick',[],'YTickLabel',[]);box off;
                        setFontProperties(gca,'fontName',obj.FontName,'fontSize',obj.FontSize,'fontColor',obj.FontColor);
                        set(gca,'YColor','w');
                        text(obj.sortNameValuePosition(1),obj.sortNameValuePosition(2),[num2str(obj.data.binCenters(bindex)) '^\circ'],'FontWeight','normal','FontName',obj.FontName,'Color',obj.FontColor,'FontSize',obj.FontSize-1);
                        if ~isempty(obj.XLIM)
                            xlim(obj.XLIM);
                        end
                        if ~isempty(obj.YLIM)
                            ylim(obj.YLIM);
                        end
                    else
                        axis off
                    end
                end
                set(gcf,'PaperPosition',obj.paperPosition,'PaperSize',[11 11],'InvertHardcopy','off','Color',[1 1 1])
                
                % print and save
                obj.printFigure
            end
        end
    end
    methods (Static)
        function [Xbar,SEM]=avgSeries(X,indices,varargin)
            % plotBinnedPopAvgs.avgSeries(X,indices)
            % average samples in X given sample indices in indices.
            % also has options to return, standard error about the mean
            %
            % X is nxd where n is number of samples
            % indices is 1xnumBins or numBinsx1 cell array
            % whose values are integers from 1:n
            options = struct('numSampMin',0,'setMin',NaN,'binValue',[],'time',[],'ID',[],'saveSampleData',false,'figureName','');
            options = parseNameValueoptions(options,varargin{:});
            
            numBins = length(indices);
            D = size(X,2);
            Xbar = zeros(numBins,D);
            SEM = zeros(numBins,D);
            
            if options.numSampMin>0 && options.numSampMin<1
                % this is a interpretted as a fraction of all samples
                N = size(X,1);
                doNotShowIfNumSampLessThan = round(N*options.numSampMin);
            else
                doNotShowIfNumSampLessThan =  options.numSampMin;
            end
            for bindex = 1 : numBins
                nsamp = length(indices{bindex});
                if nsamp >= doNotShowIfNumSampLessThan
                    % select samples at peak
                    Xbar(bindex,:) = mean(X(indices{bindex},:));
                    SEM(bindex,:) = std(X(indices{bindex},:))./sqrt(nsamp);
                    
                    if ~isnan(options.setMin)
                        Xbar(bindex,:) = Xbar(bindex,:) - min(Xbar(bindex,:)) + options.setMin;
                    end
                    if options.saveSampleData
                        [~,~,fileDirs] = rootDirectories;
                        fileID = fopen([fileDirs.scDataCSV options.figureName],'a');
                        if bindex == 1
                            if strcmp(options.figureName,'Figure 3g.csv')
                                fprintf(fileID,'Panel\ng\n');
                            elseif strcmp(options.figureName,'Supplementary Figure 3.csv')
                                fprintf(fileID,'Panel\na\n');
                            end
                        end
                        fprintf(fileID,'Saccade-triggered deconvolved fluorescence responses (a.u) at phi=%0.0f',options.binValue(bindex));
                        fprintf(fileID,'\n,,,time around saccade(s)');
                        dlmwrite([fileDirs.scDataCSV options.figureName],options.time,'delimiter',',','-append','coffset',1);
                        
                        fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Within-Plane Cell ID,Sample Index\n');
                        dlmwrite([fileDirs.scDataCSV options.figureName],[options.ID(indices{bindex},:) (1:length(indices{bindex}))' X(indices{bindex},:)],'delimiter',',','-append');
                        fclose(fileID);
                    end
                else
                    Xbar(bindex,:) = NaN(1,D);
                    SEM(bindex,:) = NaN(1,D);
                end
            end
        end
        function [x,varargout]=matchNorm(x,y,varargin)
            % matchNorm(x,y)
            % set each of the n vectors in the nxd matrix x to have the same
            % norm as each vector in the nxd matrix y
            options = struct('alsoMatch',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            n = size(x,1);
            if isempty(options.alsoMatch)
                nAdditional = 0;
            else
                Z = options.alsoMatch;
                nAdditional = size(Z,1);
                if nAdditional~=n
                    error('additional matrix must have the same number of rows as input');
                end
            end
            
            for index = 1: n
                scaleFactor = norm(y(index,:),2)/norm(x(index,:),2);
                x(index,:) = x(index,:).*scaleFactor;
                Z(index,:) = Z(index,:).*scaleFactor;
            end
            if nAdditional>0
                varargout{1} = Z;
            end
        end
        function binColors = RGBGrad2Colors(CM,binCenters)
            numBins = length(binCenters);
            % treated as an image to extract colors from
            [cm,colorBinValue] = handpickedLUT('ROYGBIV',CM);
            binColors = zeros(numBins,3);
            for j=1:numBins
                [~,cmind] = min(abs(binCenters(j)-colorBinValue));
                binColors(j,:) = cm(cmind,:);
            end
        end
    end
end

