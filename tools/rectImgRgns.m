classdef rectImgRgns<geometricImgRgns
    %rectImgRgns
    properties
        length = 1
        width = 1
    end
    properties (Dependent,Hidden)
        numPixL
        numPixW
    end
    properties (Constant)
        shape = 'rect'
    end
    
    methods
        function obj = rectImgRgns(varargin)
            options = rectImgRgns.setOptions(varargin{:});
            obj = obj.setDefaults(options);
        end
        function nl = get.numPixL(obj)
            % number of non-zero pixels to make this length
            if mod(obj.length,2)==0
                nl = obj.length + 1;
            else
                nl = obj.length;
            end
        end
        function nw = get.numPixW(obj)
            if mod(obj.length,2)==0
                nw = obj.length + 1;
            else
                nw = obj.length;
            end
        end
        function [x,y] = makeShape(obj,varargin)
            % diff(x), diff(y) made to equal length and width.
            % number of pixels in footprint equals side length with
            % odd otherwise equals side lenght+1
            % using 0.99 allows the round fnc to not add an additional pixel
            % when length is odd.
            x = obj.center(1) + [-0.9999 0.9999].*obj.width/2;
            y = obj.center(2) + [-0.9999 0.9999].*obj.length/2;
            % add all points to complete rectangle
            x = [x(1),x(1),x(2),x(2),x(1)];
            y = [y(1),y(2),y(2),y(1),y(1)];
        end
        function [rows,cols,varargout] = makeBoxIndices(obj,varargin)
            halfLength = makeProjections.pixelMiddle(obj.length);
            halfWidth = makeProjections.pixelMiddle(obj.width);
            x = obj.center(1) + [-1 1].*halfWidth;
            y = obj.center(2) + [-1 1].*halfLength;
            xyPixels = makeProjections.coor2pixels([(x(1):x(2))',(y(1):y(2))'],obj.imgSize);
            cols = xyPixels(:,1); rows = xyPixels(:,2);
            if ~isempty(varargin)
                image = varargin{1};
                imagePatch = image(rows,cols);
                varargout{1} = imagePatch;
            end
        end
    end
    methods (Static)
        function options = setOptions(varargin)
            options = struct('length',[],'width',[]);
            options = parseNameValueoptions(options,varargin{:});
            geoOptions = geometricImgRgns.setOptions(varargin{:});
            options = parseNameValuePropertySet.mergeStructs(options,geoOptions);
        end
    end
end


