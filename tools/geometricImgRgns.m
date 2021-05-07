classdef geometricImgRgns < parseNameValuePropertySet & imageConventions
    %geometricImgRgns
    
    properties
        center = [0,0] %[x,y]
        imgSize % [height,width]
    end
    properties (Abstract,Constant)
        shape
    end
    methods (Abstract)
        [x,y] = makeShape(obj)
        % return coordinates in [x,y] of 2D shape specific to each subclass
        % of geometricImgRgns
    end
    methods
        function obj = geometricImgRgns(varargin)
        end
        function A = makeFootprint(obj,varargin)
            if isempty(obj.imgSize)
                error('imgSize property must be set to return a footprint');
            end
            if strcmp(obj.shape,'rect')
                A = zeros(obj.imgSize);
                [indI,indJ] = obj.makeBoxIndices;
                A(indI,indJ) = 1;
            else
                [x,y] = obj.makeShape(varargin{:});
                pixelIndices = makeProjections.coor2pixels([x(:),y(:)],obj.imgSize);
                % fill
                A = obj.fillRegion(pixelIndices);
            end
        end
        function I = fillRegion(obj,pixelIndices)
            I = zeros(obj.imgSize);
            startCol = min(pixelIndices(:,1));
            stopCol = max(pixelIndices(:,1));
            
            % interpolate indices
            kOrdered=boundary(pixelIndices(:,1),pixelIndices(:,2));
            if isempty(kOrdered)
                % this can happen if a row or column has the same value
                % like a rectangle of pixel width 1
                miny = min(pixelIndices(:,2));
                maxy = max(pixelIndices(:,2));
                if (stopCol - startCol) == 0
                    piInterpTop = [ones(maxy-miny+1,1)*startCol,(miny:maxy)'];
                elseif (maxy -miny)==0
                    piInterpTop = [(startCol:stopCol)',ones(stopCol-startCol+1,1)*maxy];
                end
            else
                x1 = pixelIndices(kOrdered(1),1);
                y1 = pixelIndices(kOrdered(1),2);
                piInterpTop = NaN(length(kOrdered)*10,2);
                count = 1;
                piInterpTop(count,:) = round([x1,y1]);
                for kOrderedIndex = 2 : length(kOrdered)
                    k = kOrdered(kOrderedIndex);
                    
                    x2 = pixelIndices(k,1);
                    y2 = pixelIndices(k,2);
                    interpSlope = (y2-y1)/(x2-x1);
                    interpOffset = y1 - interpSlope*x1;
                    interpDir = sign(x2-x1);
                    for x = x1:interpDir:x2
                        y = interpSlope*x + interpOffset;
                        piInterpTop(count,:) = round([x,y]);
                        count = count + 1;
                    end
                    x1 = x2;
                    y1 = y2;
                end
                piInterpTop = piInterpTop(~isnan(piInterpTop(:,1)),:);
            end
            % fill between interpolated values
            for c = startCol:stopCol
                selectInterpRows = piInterpTop(:,1)==c;
                start = min(piInterpTop(selectInterpRows,2));
                stop = max(piInterpTop(selectInterpRows,2));
                I(start:stop,c) = 1;
            end
        end
    end
    methods (Static)
        function options = setOptions(varargin)
            options = struct('center',[],'imgSize',[]);
            options = parseNameValueoptions(options,varargin{:});
        end
    end
end


