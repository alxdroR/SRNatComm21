function [relativeShiftX,extraSpace] = preRegShift(regShift,varargin)
options = struct('shiftX',[],'scaleX',[]);
options = parseNameValueoptions(options,varargin{:});

if isstruct(regShift)
    shiftX = regShift.shiftX;
    scaleX = regShift.scaleX;
elseif isnumeric(regShift) && ~isempty(regShift)
    shiftX = regShift(:,1);
    scaleX = regShift(:,2);
elseif isempty(regShift)
    if ~isempty(options.shiftX)
        shiftX = options.shiftX;
    else
        error('Shift and Scale variables must be supplied');
    end
    if ~isempty(options.scaleX)
        scaleX = options.scaleX;
    else
        error('Shift and Scale variables must be supplied');
    end
end
extraSpace = round((min(shiftX) - shiftX(1))*scaleX(1)*1.5);
numPlanes = length(shiftX);

relativeShiftX = zeros(numPlanes,1);
for j = 1 : numPlanes
    relativeShiftX(j) = -extraSpace + round( (shiftX(j)-shiftX(1))*scaleX(j)*1.5 );
end
end

