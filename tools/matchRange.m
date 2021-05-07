function [yMatched,varargout] = matchRange(y,x,varargin)
%  matchRange(y,x)
% match the range in y to that of x
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2021
options = struct('matchFirstDataPoint',false);
options = parseNameValueoptions(options,varargin{:});

minX = min(x);
maxX = max(x);
minY = min(y);
maxY = max(y);

if options.matchFirstDataPoint
    % max(yMatched)=max(x); yMatched(1)=x(1);
    scale = (maxX-x(1))./(maxY-y(1));
    offset = x(1)-scale.*y(1);
else
    %
    % max(yMatched)=max(x); min(yMatched)=min(x);
    % The way to match is to first scale y to go from 0 to 1
    % y01scale = (y-minY)/(maxY-minY);
    % and then translate to match x
    % yMatched = y01scale*(maxX-minX) + minX;
    % this is equivalent to a location scale transformation that is
    scale = (maxX-minX)./(maxY-minY);
    offset = minX-scale.*minY;
end
yMatched = y.*scale + offset;
varargout{1} = scale;
varargout{2} = offset;
end

