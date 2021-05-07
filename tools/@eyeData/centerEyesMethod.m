function [centeredPositionOut,eyeobj] = centerEyesMethod(eyeobj,varargin)
% options = struct('planeIndex',1,'eye','both');
options = struct('planeIndex',1,'eye','both');
options = parseNameValueoptions(options,varargin{:});

positionMean = nanmean(eyeobj.position{options.planeIndex});
centeredPosition = bsxfun(@minus,eyeobj.position{options.planeIndex},positionMean);
switch options.eye
    case 'both'
        centeredPositionOut = centeredPosition;
    case 'left'
        centeredPositionOut = centeredPosition(:,1);
    case 'right'
        centeredPositionOut = centeredPosition(:,2);
end
end
