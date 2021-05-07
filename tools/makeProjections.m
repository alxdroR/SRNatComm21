classdef makeProjections
    % makeProjections
    % under construction
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 202x
    
    properties
        coor = [0,0,0]% registered coordinates
        brainSize = struct('Width',512,'Height',512,'nSlice',1) % size of registered brain [Width,Height,Num Slices]
        brainScale = struct('XMicPerPix',1,'YMicPerPix',1,'ZMicPerPlane',1);
        binSizeMicrons = struct('xWidth',1,'yHeight',1,'zLength',1)
        gridSpacingMicrons = struct('xWidth',1,'yHeight',1,'zLength',1)
        interpZ2XScale = true
        minNumCellPerBin % minimum number of cells required in any given projection to make it into a map
        cellValues
        cellValueBinEdges % for mode values projections
        scaleShift % for average
        projType = 'numCellsPerBin' % see get.projComputation
        weightPerCell = 1
        cellShapes = 1
        varyBinWithProjection = false
        %spSizeData = 2 % scatter plot size data
        spSizeData = [(1:5);[0.1 0.5 1 1.5 2]] 
        spSizeOpacity = [(1:5);(1:5)/5]; % table of n values and associated opacity
        spConstOpacity = 0.8
        spValueColor
        spLineWidth = 0.1;
        scatterPlot = false
    end
    properties(Dependent)
        binSizePixels
        gridSpacingPixels
        numCells
        projComputation
        numZSliceInProjection
        numProjections2Make
    end
    properties (SetAccess = private)
        projMapRatio
    end
    methods
        function obj = makeProjections(varargin)
            options = struct('coor',[0,0,0],'brainSize',[800,800,60],'minNumCellPerBin',0,'brainScale',[1,1,1],...
                'cellValues',[],'projType',[],'binSizeMicrons',[],'gridSpacingMicrons',[],'valueBins',[],...
                'cellShapes',[],'weights',[],'scaleShift',[],'runDemo',false,'spValueColor',[]);
            options = parseNameValueoptions(options,varargin{:});
            if options.runDemo
                % run demo is a special command
                obj.demoMakeProjectionsClass
            else
                obj.brainSize.Width = options.brainSize(1);
                obj.brainSize.Height = options.brainSize(2);
                obj.brainSize.nSlice = options.brainSize(3);
                obj.brainScale.XMicPerPix = options.brainScale(1);
                obj.brainScale.YMicPerPix = options.brainScale(2);
                obj.brainScale.ZMicPerPlane = options.brainScale(3);
                obj.minNumCellPerBin = max(1,options.minNumCellPerBin);
                obj.coor = options.coor;
                if ~isempty(options.cellValues)
                    obj.cellValues = options.cellValues;
                    obj.cellValueBinEdges = options.valueBins;
                    obj.scaleShift = options.scaleShift;
                end
                if ~isempty(options.spValueColor)
                    obj.spValueColor = options.spValueColor;
                end
                if ~isempty(options.cellShapes)
                    obj.cellShapes = options.cellShapes;
                end
                if ~isempty(options.projType)
                    obj.projType = options.projType;
                    if strcmp(options.projType,'weightedNumCellsPerBin') && isempty(options.weights)
                        warning('No weights given but weighted projection desired');
                    end
                end
                if ~isempty(options.weights)
                    obj.weightPerCell = options.weights;
                end
                if ~isempty(options.binSizeMicrons)
                    if ischar(options.binSizeMicrons) && strcmp(options.binSizeMicrons,'noOverlappingTiles')
                        obj.varyBinWithProjection = true;
                        [cellShapeHeight,cellShapeWidth,~] = size(obj.cellShapes);
                        cellShapeWMu = cellShapeWidth*obj.brainScale.XMicPerPix;
                        cellShapeHMu = cellShapeHeight*obj.brainScale.YMicPerPix;
                        obj.binSizeMicrons = struct('xWidth',cellShapeWMu,'yHeight',cellShapeHMu,'zLength',NaN);
                    else
                        obj.binSizeMicrons = options.binSizeMicrons;
                    end
                end
                if isempty(options.gridSpacingMicrons)
                    obj.gridSpacingMicrons = 'match2BinSize';
                else
                    obj.gridSpacingMicrons = options.gridSpacingMicrons;
                end
            end
        end
        
        function numProj = get.numProjections2Make(obj)
            switch obj.projType
                case 'numCellsPerBin'
                    numProj = 1;
                case 'fracTotalCellsPerBin'
                    numProj = 1;
                case 'weightedNumCellsPerBin'
                    numProj = 1;
                case 'avgValuesPerBin'
                    numProj = size(obj.cellValues,2);
                case 'modeValues'
                    numProj = size(obj.cellValues,2);
            end
        end
        function compHandle = get.projComputation(obj)
            switch obj.projType
                case 'numCellsPerBin'
                    compHandle = @(x,dummyInd) sum(x);
                case 'fracTotalCellsPerBin'
                    compHandle = @(x,dummyInd) sum(x)/obj.numCells;
                case 'weightedNumCellsPerBin'
                    compHandle = @(x,dummyInd) sum(x.*obj.weightPerCell);
                case 'avgValuesPerBin'
                    if isempty(obj.scaleShift)
                        compHandle = @(x,ind) mean(obj.cellValues(x,ind));
                    else
                        compHandle = @(x,ind) obj.scaleShift(1)*mean(obj.cellValues(x,ind)) + obj.scaleShift(2);
                    end
                case 'modeValues'
                    if isempty(obj.cellValueBinEdges)
                        error('computing the mode requires the user to enter a grid to first histogram values and then choose mode of this histogram');
                    else
                        compHandle = @(x,ind) obj.findModeAfterBinning(obj.cellValues(:,ind),x,obj.cellValueBinEdges);
                    end
            end
        end
        function numCells = get.numCells(obj)
            numCells = size(obj.coor,1);
        end
        function nSlice = get.numZSliceInProjection(obj)
            if obj.interpZ2XScale
                nSlice = floor(obj.brainSize.nSlice*obj.projMapRatio);
            else
                nSlice = obj.brainSize.nSlice;
            end
        end
        function binSizePixels = get.binSizePixels(obj)
            if ~isstruct(obj.binSizeMicrons)
                error('binSizeMicrons property must be a structure with fields: xWidth,yHeight,zLength');
            end
            binSzPix = obj.microns2pixels([obj.binSizeMicrons.xWidth,obj.binSizeMicrons.yHeight,obj.binSizeMicrons.zLength],...
                [obj.brainScale.XMicPerPix,obj.brainScale.YMicPerPix,obj.brainScale.ZMicPerPlane],...
                [obj.brainSize.Width,obj.brainSize.Height,obj.brainSize.nSlice]);
            binSizePixels = struct('xWidth',binSzPix(1),...
                'yHeight',binSzPix(2),...
                'zLength',binSzPix(3));
        end
        function gridSpacingPixels = get.gridSpacingPixels(obj)
            if ischar(obj.gridSpacingMicrons)
                if strcmp('match2BinSize',obj.gridSpacingMicrons)
                    obj.gridSpacingMicrons = obj.binSizeMicrons;
                end
            end
            if ~isstruct(obj.gridSpacingMicrons)
                error('gridSpacingMicrons property must be a structure with fields: xWidth,yHeight,zLength');
            end
            binSzPix = obj.microns2pixels([obj.gridSpacingMicrons.xWidth,obj.gridSpacingMicrons.yHeight,obj.gridSpacingMicrons.zLength],...
                [obj.brainScale.XMicPerPix,obj.brainScale.YMicPerPix,obj.brainScale.ZMicPerPlane],...
                [obj.brainSize.Width,obj.brainSize.Height,obj.brainSize.nSlice]);
            gridSpacingPixels = struct('xWidth',binSzPix(1),...
                'yHeight',binSzPix(2),...
                'zLength',binSzPix(3));
        end
        function [coorOut,obj] = parseCellRestrictions(obj,rStruct)
            coorOut = obj.coor;
            if ~isempty(rStruct)
                if isfield(rStruct,'x')
                    xTh = rStruct.x;
                else
                    xTh = [-inf,inf];
                end
                if isfield(rStruct,'y')
                    yTh = rStruct.y;
                else
                    yTh = [-inf,inf];
                end
                if isfield(rStruct,'z')
                    zTh = rStruct.z;
                else
                    zTh = [-inf,inf];
                end
                
                xCellsPassingTh = obj.findCellsInBin(coorOut(:,1),xTh);
                yCellsPassingTh = obj.findCellsInBin(coorOut(:,2),yTh);
                zCellsPassingTh = obj.findCellsInBin(coorOut(:,3),zTh);
                cellLocRestriction = xCellsPassingTh & yCellsPassingTh & zCellsPassingTh;
                coorOut = coorOut(cellLocRestriction,:);
                if ~isempty(obj.cellValues)
                    obj.cellValues = obj.cellValues(cellLocRestriction,:);
                end
            end
        end
        function [xGrid,yGrid,zGrid]=makeGrid(obj,varargin)
            if nargin == 2
                coorOut = varargin{1};
            else
                coorOut = obj.coor;
            end
            xGrid = min(coorOut(:,1)) : obj.gridSpacingPixels.xWidth: max(coorOut(:,1)) + obj.binSizePixels.xWidth/2;
            xGrid = obj.coor2pixels(xGrid,obj.brainSize.Width)';
            yGrid = min(coorOut(:,2)) : obj.gridSpacingPixels.yHeight: max(coorOut(:,2)) + obj.binSizePixels.yHeight/2;
            yGrid = obj.coor2pixels(yGrid,obj.brainSize.Height)';
            zGrid = min(coorOut(:,3)) : obj.gridSpacingPixels.zLength: max(coorOut(:,3)) + obj.binSizePixels.zLength/2;
            zGrid = obj.coor2pixels(zGrid,obj.brainSize.nSlice)';
        end
        function horzProj = horzProjection(obj,varargin)
            options = struct('cellRestrictionTholds',[],'horzMap',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.horzMap)
                horzProj = NaN(obj.brainSize.Height,obj.brainSize.Width,obj.numProjections2Make);
            end
            [coorOut,obj] = obj.parseCellRestrictions(options.cellRestrictionTholds);
            if ~isempty(coorOut)
                % construct grid we will loop through
                [xGrid,yGrid] = obj.makeGrid(coorOut);
                if obj.scatterPlot
                    sxsy = NaN(length(xGrid)*length(yGrid),2,obj.numProjections2Make);
                    sAlpha = NaN(length(xGrid)*length(yGrid),obj.numProjections2Make);
                    sVCIndex = NaN(length(xGrid)*length(yGrid),obj.numProjections2Make);
                    count = 1;
                end
                [cellShapeHeight,cellShapeWidth,numCellShapes] = size(obj.cellShapes);
                for w = xGrid
                    for h = yGrid
                        cellsInProjBool = coorOut(:,1)>= w - obj.binSizePixels.xWidth/2 & coorOut(:,1)<= w + obj.binSizePixels.xWidth/2 ...
                            & coorOut(:,2) >= h-obj.binSizePixels.yHeight/2 & coorOut(:,2) <= h+obj.binSizePixels.yHeight/2;
                        
                        numCellsNCurrentProjection = sum(cellsInProjBool);
                        if numCellsNCurrentProjection >= obj.minNumCellPerBin
                            if numCellShapes > 1
                                % randomly choose a cell out of our samples to use
                                sampleIndex =  randperm(numCellShapes,1);
                            else
                                sampleIndex = 1;
                            end
                            [pixelInMapX1,cellShapeCols] = obj.expandPoint(w,cellShapeWidth,obj.brainSize.Width);
                            [pixelInMapX2,cellShapeRows] = obj.expandPoint(h,cellShapeHeight,obj.brainSize.Height);
                            shape2Display = obj.cellShapes(cellShapeRows,cellShapeCols,sampleIndex);
                            for projIndex = 1 : obj.numProjections2Make
                                projValue = obj.projComputation(cellsInProjBool,projIndex);
                                if obj.scatterPlot
                                   % opIndex = max(obj.spSizeData(1,end),numCellsNCurrentProjection);
                                    opIndex = numCellsNCurrentProjection;
                                    valueColorIndex = find(obj.spValueColor(:,1)==projValue);
                                    sxsy(count,1,projIndex) = w;
                                    sxsy(count,2,projIndex) = h;
                                    sAlpha(count,projIndex) = opIndex;
                                    sVCIndex(count,projIndex) = valueColorIndex;
                                else
                                    horzProj(pixelInMapX2,pixelInMapX1,projIndex) = projValue*shape2Display;
                                end
                            end
                            if obj.scatterPlot
                                count = count + 1;
                            end
                        end
                    end
                end
            end
            if obj.scatterPlot
                sxsy=sxsy(1:count-1,:,:);
                sAlpha = sAlpha(1:count-1,:);
                sVCIndex = sVCIndex(1:count-1,:);
                
                for projIndex = 1 : obj.numProjections2Make
                    if isempty(options.horzMap)
                        horzProj(projIndex) = figure; hold on;
                    else
                        horzProj(projIndex) = figure; imagesc(options.horzMap(:,:,projIndex)); colormap('gray'); hold on;
                    end
                    
                    for numSampInd = 1 : length(obj.spSizeData(1,:))
                        for colIndex = 1 : length(obj.spValueColor(:,1))
                            samps2use = sVCIndex(:,projIndex) == colIndex & sAlpha(:,projIndex) == numSampInd;
                            if sum(samps2use)>0
                                color2show = obj.spValueColor(colIndex,2:end);
                                sz = obj.spSizeData(2,numSampInd);
                               
                                scatter(squeeze(sxsy(samps2use,1,projIndex)),squeeze(sxsy(samps2use,2,projIndex)),sz,'MarkerFaceColor',color2show,'MarkerEdgeColor','none',...
                                    'MarkerFaceAlpha',obj.spConstOpacity,'MarkerEdgeAlpha',1,'LineWidth',obj.spLineWidth)
                            end
                        end
                    end
                    hold off
                    set(gca,'View',[90 90])
                end
                hold on;
                for numSampInd = 1 : length(obj.spSizeData(1,:))
                    sz = obj.spSizeData(2,numSampInd);
                    scatter(1322,(max(obj.spSizeData(2,:))+5)*(numSampInd-1)+500,sz,'MarkerFaceColor','w','MarkerEdgeColor','none','MarkerFaceAlpha',obj.spConstOpacity,'MarkerEdgeAlpha',1,'LineWidth',obj.spLineWidth);
                end
                numPixIn50Mic=round(50/obj.brainScale.XMicPerPix);
                plot(1322*ones(numPixIn50Mic,1),390+(1:numPixIn50Mic),'w','LineWidth',1);
                
                plot(1222*ones(obj.binSizePixels.xWidth,1),390+(1:obj.binSizePixels.xWidth),'w','LineWidth',1);
                hold off
                %obj.printMap(horzProj,obj.names2Save);
            end
        end
        function saggProj = saggProjection(obj,varargin)
            options = struct('cellRestrictionTholds',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            [cellShapeHeight,cellShapeWidth,numCellShapes] = size(obj.cellShapes);
            if obj.varyBinWithProjection
                obj.binSizeMicrons.zLength = obj.binSizeMicrons.yHeight;
                obj.projMapRatio = (obj.brainScale.ZMicPerPlane/obj.brainScale.YMicPerPix);
            end
            saggProj = NaN(obj.numZSliceInProjection,obj.brainSize.Width,obj.numProjections2Make);
            [coorOut,obj] = obj.parseCellRestrictions(options.cellRestrictionTholds);
            if ~isempty(coorOut)
                % construct grid we will loop through
                [xGrid,~,zGrid] = obj.makeGrid(coorOut);
                
                if obj.interpZ2XScale
                    zSpaceHighResMu = (0:obj.numZSliceInProjection-1)*obj.brainScale.YMicPerPix;
                end
                
                for w = xGrid
                    for L = zGrid
                        cellsInProjBool = coorOut(:,1)>= w - obj.binSizePixels.xWidth/2 & coorOut(:,1)<= w + obj.binSizePixels.xWidth/2 ...
                            & coorOut(:,3) >= L-obj.binSizePixels.zLength/2 & coorOut(:,3) <= L+obj.binSizePixels.zLength/2;
                        
                        numCellsNCurrentProjection = sum(cellsInProjBool);
                        if numCellsNCurrentProjection >= obj.minNumCellPerBin
                            if numCellShapes > 1
                                % randomly choose a cell out of our samples to use
                                sampleIndex =  randperm(numCellShapes,1);
                            else
                                sampleIndex = 1;
                            end
                            
                            if obj.interpZ2XScale
                                [pixelInMapX1,cellShapeCols] = obj.expandPoint(w,cellShapeWidth,obj.brainSize.Width);
                                LHR = find(abs(zSpaceHighResMu - (L-1)*obj.brainScale.ZMicPerPlane)<obj.brainScale.YMicPerPix/2);
                                [pixelInMapX2,cellShapeRows] = obj.expandPoint(LHR,cellShapeHeight,obj.numZSliceInProjection);
                            else
                                [pixelInMapX1,cellShapeCols] = obj.expandPoint(w,cellShapeWidth,obj.brainSize.Width);
                                [pixelInMapX2,cellShapeRows] = obj.expandPoint(L,cellShapeHeight,obj.brainSize.Height);
                            end
                            if isempty(cellShapeRows)
                                shape2Display = ones(1,length(cellShapeCols));
                            else
                                shape2Display = obj.cellShapes(cellShapeRows,cellShapeCols,sampleIndex);
                            end
                            for projIndex = 1 : obj.numProjections2Make
                                projValue = obj.projComputation(cellsInProjBool,projIndex);
                                saggProj(pixelInMapX2,pixelInMapX1,projIndex) = projValue*shape2Display;
                            end
                        end
                    end
                end
            end
        end
        function corrProj = corrProjection(obj,varargin)
            options = struct('cellRestrictionTholds',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            [cellShapeHeight,cellShapeWidth,numCellShapes] = size(obj.cellShapes);
            if obj.varyBinWithProjection
                obj.projMapRatio = (obj.brainScale.ZMicPerPlane/obj.brainScale.XMicPerPix);
                obj.binSizeMicrons.zLength = obj.binSizeMicrons.xWidth;
            end
            corrProj = NaN(obj.numZSliceInProjection,obj.brainSize.Height,obj.numProjections2Make);
            [coorOut,obj] = obj.parseCellRestrictions(options.cellRestrictionTholds);
            if ~isempty(coorOut)
                % construct grid we will loop through
                [~,yGrid,zGrid] = obj.makeGrid(coorOut);
                if obj.interpZ2XScale
                    zSpaceHighResMu = (0:obj.numZSliceInProjection-1)*obj.brainScale.XMicPerPix;
                end
                
                for h = yGrid
                    for L = zGrid
                        cellsInProjBool = coorOut(:,2) >= h-obj.binSizePixels.yHeight/2 & coorOut(:,2) <= h+obj.binSizePixels.yHeight/2 ...
                            & coorOut(:,3) >= L-obj.binSizePixels.zLength/2 & coorOut(:,3) <= L+obj.binSizePixels.zLength/2;
                        
                        numCellsNCurrentProjection = sum(cellsInProjBool);
                        if numCellsNCurrentProjection >= obj.minNumCellPerBin
                            if numCellShapes > 1
                                % randomly choose a cell out of our samples to use
                                sampleIndex =  randperm(numCellShapes,1);
                            else
                                sampleIndex = 1;
                            end
                            
                            if obj.interpZ2XScale
                                [pixelInMapX1,cellShapeRows] = obj.expandPoint(h,cellShapeHeight,obj.brainSize.Height);
                                LHR = find(abs(zSpaceHighResMu - (L-1)*obj.brainScale.ZMicPerPlane)<obj.brainScale.XMicPerPix/2);
                                [pixelInMapX2,cellShapeCols] = obj.expandPoint(LHR,cellShapeWidth,obj.numZSliceInProjection);
                            else
                                [pixelInMapX1,cellShapeCols] = obj.expandPoint(h,cellShapeWidth,obj.brainSize.Height);
                                [pixelInMapX2,cellShapeRows] = obj.expandPoint(L,cellShapeHeight,obj.brainSize.Height);
                            end
                            if isempty(cellShapeRows)
                                shape2Display = ones(1,length(cellShapeCols));
                            else
                                shape2Display = obj.cellShapes(cellShapeRows,cellShapeCols,sampleIndex);
                            end
                            for projIndex = 1 : obj.numProjections2Make
                                projValue = obj.projComputation(cellsInProjBool,projIndex);
                                corrProj(pixelInMapX2,pixelInMapX1,projIndex) = projValue*shape2Display';
                            end
                        end
                    end
                end
            end
        end
    end
    methods (Static)
        function options = setOptions(varargin)
            options = struct('coor',[],'brainSize',[],'minNumCellPerBin',[],'brainScale',[],...
                'cellValues',[],'projType',[],'binSizeMicrons',[],'gridSpacingMicrons',[],'valueBins',[],'cellShapes',[],'weights',[],'scaleShift',[],'runDemo',[]);
            options = parseNameValueoptions(options,varargin{:});
        end
        function pixelIndices = coor2pixels(coor,brainSize,varargin)
            % coordinates are floating values (in units of pixels)
            % pixelIndices are closest integers constrained to lie within
            % brainSize
            if ~isempty(varargin)
                options = struct('alarmDistance',10);
                options = parseNameValueoptions(options,varargin{:});
                alarmDistance = options.alarmDistance;
            else
                alarmDistance = 10;
            end
            D = length(brainSize);
            if size(coor,2) ~= D
                coor = coor';
            end
            % round coordinates to obtain pixels
            pixelIndices = round(coor);
            
            % fix the edge cases
            %pixelIndices(pixelIndices<=1)=1;
            pixelIndices = max(pixelIndices,1);
            for d = 1 : D
                dimSize = brainSize(d);
                pixelIndices(:,d) = min(pixelIndices(:,d),dimSize);
                %    pointsOutsideImage = pixelIndices(:,d)>dimSize;
                %    pixelIndices(pointsOutsideImage,d) = dimSize;
            end
            % warn the user of any major changes
            diffIndexFloat = abs(coor - pixelIndices);
            cause4Concern = any(diffIndexFloat > alarmDistance);
            if cause4Concern
                warning('mismatch between index and coordinate exceeds %0.2f\n',alarmDistance)
                keyboard
            end
        end
        function coorPixels = microns2pixels(coorMu,scaleMicPerPix,imgSize,varargin)
            D = length(imgSize);
            if size(coorMu,2) ~= D
                coorMu = coorMu';
            end
            if length(scaleMicPerPix) ~= size(coorMu,2)
                error('every dimension of coordinates requires a mic/pixel scale factor');
            end
            coorPixelFractions = coorMu./scaleMicPerPix;
            coorPixels = makeProjections.coor2pixels(coorPixelFractions,imgSize,varargin{:});
        end
        function [expandedPixels,shapePixels] = expandPoint(point,expanBreadth,expanLimit)
            expandedPoints = (-(expanBreadth-1)/2:(expanBreadth-1)/2)'+point;
            
            expandedPixels = makeProjections.coor2pixels(expandedPoints,expanLimit);
            if isempty(expandedPixels)
                expandedPixels = NaN;
            end
            shapePixels = makeProjections.indicesInShape2Use(length(expandedPixels),expanBreadth);
        end
        function shapePixels = indicesInShape2Use(numPixels,shape1DSize)
            
            shapePixels = 1:shape1DSize;
            % cut shape if necessary
            if numPixels < shape1DSize
                offset = makeProjections.pixelMiddle(shape1DSize);
                shapePixels = makeCellShapes.makeIndicesAroundZero(numPixels) + offset;
            end
        end
        function mid = pixelMiddle(L)
            if mod(L,2)==1
                mid = (L-1)/2;
            else
                mid = L/2;
            end
        end
        function modeOut= findModeAfterBinning(values,limitingCondition,binEdges)
            binSize = binEdges(2)-binEdges(1);
            valuesInProj = values(limitingCondition);
            [cnts,edges]=histcounts(valuesInProj,binEdges);
            [mxval,mxind]=max(cnts);  % max returns first occurence when there are ties. since cnts are orderd, will return the lowest phi value when there are ties
            modeIndices = find(cnts==mxval);
            if length(modeIndices)>1
                % there are ties. randomly choose what to display
                mxind = modeIndices(randi(length(modeIndices),1));
            end
            modeOut = edges(mxind) + binSize/2;
        end
        function cellsInBin = findCellsInBin(x,bin)
            cellsInBin = x >= bin(1) & x< bin(2);
        end
        function demoMakeProjectionsClass
            brainSize = [100,50,20];
            brainScale = [1,2,3];
            numCellLowerLim = 0;
            shapes = ones(5,10,3); %shapes(1,:,1)=zeros(1,5);shapes(2,:,2)=zeros(1,5);shapes(3,:,3)=zeros(1,5);
            
            coor = [[80.1,30.89,1.2];...
                [80.1,30.89,17.2];...
                [80.1,30.89,5.8]];
            lon = [[15,1];...
                [11,3];...
                [35,22]];
            lonBinEdges = [0,10,20,30,40];
            % expected result:
            % 1 randomly selected shape at pixel
            % Horz: [80,31] (3 cells, mode values are 15 and 5); Sag:
            % [80,1->0*(2/1) (nearest bin 1)] (value is 15,5) ,[80,17->16*(2/1)
            % ->nearest center] (value is 15,5); etc
            % Cor: [31,1->0*(1/1) (nearest bin 1)], [301,17->16*(1/1) ->nearest
            % center], etc
            projObj = makeProjections('coor',coor,...
                'brainSize',brainSize,...
                'brainScale',brainScale,...
                'minNumCellPerBin',numCellLowerLim,...
                'cellValues',lon,...
                'projType','modeValues',...
                'valueBins',lonBinEdges,...
                'binSizeMicrons','noOverlappingTiles'...
                , 'cellShapes',shapes);
            
            horzMap= projObj.horzProjection;
            sagMap = projObj.saggProjection;
            corMap = projObj.corrProjection;
            figure;subplot(3,2,1);imagesc(horzMap(:,:,1),[0 40]);title('H1');colorbar;subplot(3,2,2);imagesc(horzMap(:,:,2),[0 40]);title('H2');colorbar;
            subplot(3,2,3);imagesc(sagMap(:,:,1),[0 40]);title('S1');colorbar;subplot(3,2,4);imagesc(sagMap(:,:,2),[0 40]);title('S2');colorbar;
            subplot(3,2,5);imagesc(corMap(:,:,1),[0 40]);colorbar;subplot(3,2,6);imagesc(corMap(:,:,2),[0 40]);colorbar;
            projObj = makeProjections('coor',coor,...
                'brainSize',brainSize,...
                'brainScale',brainScale,...
                'minNumCellPerBin',numCellLowerLim,...
                'cellValues',lon,...
                'projType','fracTotalCellsPerBin',...
                'valueBins',lonBinEdges,...
                'binSizeMicrons','noOverlappingTiles'...
                , 'cellShapes',shapes);
            
            horzMap= projObj.horzProjection;
            sagMap = projObj.saggProjection;
            corMap = projObj.corrProjection('cellRestrictionTholds',struct('x',[-inf inf]));
            figure;subplot(3,2,1);imagesc(horzMap(:,:,1),[0 1]);title('H1');colorbar;subplot(3,2,2);imagesc(horzMap(:,:,2),[0 1]);title('H2');colorbar;
            subplot(3,2,3);imagesc(sagMap(:,:,1),[0 1]);title('S1');colorbar;subplot(3,2,4);imagesc(sagMap(:,:,2),[0 1]);title('S2');colorbar;
            subplot(3,2,5);imagesc(corMap(:,:,1),[0 1]);colorbar;subplot(3,2,6);imagesc(corMap(:,:,2),[0 1]);colorbar;
        end
    end
end

