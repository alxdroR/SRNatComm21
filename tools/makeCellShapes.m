classdef makeCellShapes < rectImgRgns
    % makeCellShapes
    % extract cell shapes from sparse footprints of size dxN into an array
    % of boxes [options.boxHeight,options.boxWidth] where
    % options.boxWidth*options.boxHeight < d
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 -202x
    properties
        extractedShapes
        muPerPix = struct('X',0,'Y',0)
    end
    
    methods
        function obj = makeCellShapes(varargin)
            options = struct('fPrints',[],'fPrintCenters',[],'muPerPix',[]);
            options = parseNameValueoptions(options,varargin{:});
            rectOptions = obj.setOptions(varargin{:});
            options = obj.mergeStructs(options,rectOptions);
            obj = obj.setDefaults(options);
            obj.extractedShapes = options;
        end
        function obj = set.extractedShapes(obj,options)
            if ~isempty(options.fPrints)
                obj.extractedShapes = obj.extractCellShapesIntoBox(options.fPrints,'fPrintCenters',options.fPrintCenters);
            end
        end
        function extractedShapes = extractCellShapesIntoBox(obj,fPrints,varargin)
            options = struct('fPrintCenters',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.fPrintCenters)
                error('sorry code to determine center of footprint automatically not yet written.construct with fPrintCenters');
            end
            numSamplePrints = size(fPrints,2);
             extractedShapes = zeros(obj.numPixL,obj.numPixW,numSamplePrints);
            for index = 1 : numSamplePrints
                obj.center = fliplr(options.fPrintCenters(index,:));
                currentFootprint = reshape(fPrints(:,index),obj.imgSize(1),obj.imgSize(2));
                [~,~,extractedShapes(:,:,index)] = obj.makeBoxIndices(currentFootprint);
            end
        end
        function [resizedShapes,varargout] = reSizeShapes(obj,varargin)
            options = struct('newMuPerPix',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % current size of box in microns
            boxWidthMu = obj.width*obj.muPerPix.X;
            boxHeightMu = obj.length*obj.muPerPix.Y;
            
            newBoxWidth = boxWidthMu/options.newMuPerPix.X;
            newBoxHeight = boxHeightMu/options.newMuPerPix.Y;
            
            if obj.width > newBoxWidth
                subSampledIndsW = round(1 : (obj.width/newBoxWidth) : obj.numPixW);
            else
                error('reSizeShapes can only handle subsampling for now');
            end
            
            if obj.length > newBoxHeight
                subSampledIndsL =  round( 1 : (obj.length/newBoxHeight)  : obj.numPixL);
            else
                error('reSizeShapes can only handle subsampling for now');
            end
            
            numSamplePrints = size(obj.extractedShapes,3);
            resizedShapes = zeros(length(subSampledIndsL),length(subSampledIndsW),numSamplePrints);
            for sampInd = 1 : numSamplePrints
                resizedShapes(:,:,sampInd) = obj.extractedShapes(subSampledIndsL,subSampledIndsW,sampInd);
                % change values to zero or one
                resizedShapes(:,:,sampInd) = resizedShapes(:,:,sampInd)~=0;
            end
            varargout{1} = newBoxWidth;
        end
    end
    methods (Static)
        function [randSelection,varargout] = selectRndFPs(A,varargin)
            options = struct('numPlanes2Choose',6,'numCellPerPlane2Choose',10,'fPrintCenters',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if iscell(A)
                numPlanes = length(A);
                D = size(A{1},1);
                randomSelectedPlanes = randperm(numPlanes,options.numPlanes2Choose);
                randomSelectedCells = zeros(options.numPlanes2Choose,options.numCellPerPlane2Choose);
                randSelection = sparse(D,options.numPlanes2Choose*options.numCellPerPlane2Choose);
                if ~isempty(options.fPrintCenters)
                    randSelectedCenters = zeros(options.numPlanes2Choose*options.numCellPerPlane2Choose,2);
                end
                
                for i = 1 : options.numPlanes2Choose
                    planeIndex = randomSelectedPlanes(i);
                    numCellsInPlane = size(A{planeIndex},2);
                    randomSelectedCells(i,:) = randperm(numCellsInPlane,options.numCellPerPlane2Choose);
                    indices2StoreSelection = (1:options.numCellPerPlane2Choose) + (i-1)*options.numCellPerPlane2Choose;
                    randSelection(:,indices2StoreSelection) = A{planeIndex}(:,randomSelectedCells(i,:));
                    if ~isempty(options.fPrintCenters)
                        randSelectedCenters(indices2StoreSelection,:) = options.fPrintCenters{planeIndex}(randomSelectedCells(i,:),:);
                    end
                end
            elseif issparse(A)
                numCellsInPlane = size(A,2);
                randomSelectedCells = randperm(numCellsInPlane,options.numCellPerPlane2Choose);
                randSelection = A(:,randomSelectedCells);
            end
            varargout{1} = randomSelectedCells;
            if ~isempty(options.fPrintCenters)
                varargout{2} = randSelectedCenters;
            end
        end
        
        function indices = makeIndicesAroundZero(totalLength)
            if mod(totalLength,2)==1
                r = (totalLength-1)/2;
                indices= (-r:r);
            else
                r = totalLength/2;
                indices= [-r:-1,1:r]; % remove zero
            end
        end
    end
end

