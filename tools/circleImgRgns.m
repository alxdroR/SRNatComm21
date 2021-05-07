classdef circleImgRgns<geometricImgRgns
    %circleImgRgns
    
    properties
        radius = 1
    end
    properties (Hidden)
        cosphi
        sinphi
    end
     properties (Constant)
        shape = 'circle'
    end
    methods
        function obj = circleImgRgns(varargin)
            options = struct('radius',[],'spacing',20);
            options = parseNameValueoptions(options,varargin{:});
            geoOptions = geometricImgRgns.setOptions(varargin{:});
            options = obj.mergeStructs(options,geoOptions);
            obj = obj.setDefaults(options);
            phi = (0:options.spacing:360).*(pi/180);
            obj.cosphi = cos(phi);
            obj.sinphi = sin(phi);
        end
        
        function [x,y] = makeShape(obj,varargin)
            x = obj.radius*obj.cosphi + obj.center(1);
            y = obj.radius*obj.sinphi + obj.center(2);
        end
    end
end


