function [lonShift,index] = shiftLongitude(lon,OFFCut,varargin)
options = struct('reorder',true);
options = parseNameValueoptions(options,varargin{:});


index2cut = lon<OFFCut;
if options.reorder
    lonShift = [lon(~index2cut);lon(index2cut)+360];
    index = [find(~index2cut);find(index2cut)];
else
    lonShift = lon;
    lonShift(index2cut) = lon(index2cut)+360;
    index = 1:length(lon);
end
end

