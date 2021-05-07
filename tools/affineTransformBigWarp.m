function varargout = affineTransformBigWarp(U,movingPoints,fixedPoints,varargin)
options = struct('useMatrixMult',false,'onlyComputeTransform',false);
options = parseNameValueoptions(options,varargin{:});

movingDim = size(movingPoints,2);
fixedDim = size(fixedPoints,2);

movingPoints = [movingPoints, ones(size(movingPoints,1), 1)]; % coordinates in microns
fixedPoints =    [fixedPoints, ones(size(fixedPoints,1), 1)]; % coordinates in microns

t = movingPoints\fixedPoints;
t(:,fixedDim+1) = [zeros(movingDim,1);1];

if options.useMatrixMult
    if ~options.onlyComputeTransform
        X = [U ones(size(U,1),1)]*t;
        X = X(:,1:3);
        varargout{1} = X;
        varargout{2} = t;
    else
        varargout{1} = t;
    end
    
else
    if movingDim ~= fixedDim
        error('Moving and Fixed Points must be the same dimension to use transformPointsForward');
    else
        if movingDim == 2 
            tform = affine2d(t);
        elseif movingDim == 3  
            tform = affine3d(t);
        end
        if ~options.onlyComputeTransform
            X = transformPointsForward(tform,U);
            varargout{1} = X;
            varargout{2} = t;
            varargout{3} = tform;
        else
            varargout{1} = t;
            varargout{2} = tform;
        end
    end
end
end

