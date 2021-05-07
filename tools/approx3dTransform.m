function [ cellTransform,transZ] = approx3dTransform(movingPoints,fixedPoints,ZsizeMovingImages,ZsizeFixedImages,varargin)
% approx3dTransform approximate 3d transform by multiple 2d transforms 
% [ cellTransform,transZ] = approx3dTransform(movingPoints,fixedPoints,ZsizeMovingImages,ZsizeFixedImages)
%
%  determine geometric transforms for control point pairs in each plane. 
% If control point pairs have not been chosen for each plane, this function will attempt to register the
% z-planes of the moving images to the fixed images based on a fixed
% spacing approximation.  

% 
%  INPUT:
%        movingPoints = Nx3 matrix of points on the moving image that 
%                       correspond to N points on the fixed image. 
%                       movingPoints(n,:) is a vector
%                       [u,j,k] of the u,j pixel location for plane number
%                       k in the moving image that corresponds to Nth
%                       row of the fixedPoints
%       fixedPoints = Nx3 matrix 
% 
%       ZsizeMovingImages = total number of frames in the moving images
%       
%       ZsizeFixedImages = total number of frames in the fixed images
%   


movPlnesWithCP = unique(movingPoints(:,3));
% create a table mapping fixed frame indices to moving frame indices.
zmap = zeros(length(movPlnesWithCP),2);
for i=1:length(movPlnesWithCP)
    localFixFrames = unique(fixedPoints(movingPoints(:,3)==movPlnesWithCP(i),3));
    if length(localFixFrames)>1
      error(['There is more than one fixed frame assigned to moving frame ' num2str(movPlnesWithCP(i))]) 
    else
        zmap(i,2) = localFixFrames;
        zmap(i,1) = movPlnesWithCP(i);
    end
end

numMovePlanesGiven = length(movPlnesWithCP);
edgesBtwnFitPlanes = [1; movPlnesWithCP(2:end); ZsizeMovingImages+1];

% loop through unique planes and calculate geometric transform to control
% point pairs for each plane
cellTransform = cell(ZsizeMovingImages,1);
for plane2fit=1:numMovePlanesGiven
    coordIndex2d = movingPoints(:,3) == movPlnesWithCP(plane2fit);
    transform2d= fitgeotrans(movingPoints(coordIndex2d,1:2),fixedPoints(coordIndex2d,1:2),'affine');
    for validPlanesForTrans = edgesBtwnFitPlanes(plane2fit) : edgesBtwnFitPlanes(plane2fit+1)-1
        cellTransform{validPlanesForTrans} = transform2d;
    end 
end

if ZsizeMovingImages==length(movPlnesWithCP)
    % every moving image has been assigned to a reference image
    % and there is no need to infer which planes correspond
    transZ = zmap(:,2);
else
    % calculate z spacing for ALL images
  %  moving2fixedzratio = 10/3; % use this for ablations 
    moving2fixedzratio = 5/3;  % use this for 
    transZ = calcZspacing(moving2fixedzratio,ZsizeFixedImages,ZsizeMovingImages,zmap(:,2),zmap(:,1));
end
end
function transZ = calcZspacing(moving2fixedzratio,NfixedPoints,NmovingPoints,fixedPoints,movingPoints)
% z-spacing assuming equal spacing with only the first point anchored.
transZ = findTransformedZ(moving2fixedzratio,NfixedPoints,NmovingPoints,fixedPoints(1),movingPoints(1));

% anchor all the other user-chosen points 
transZ(movingPoints) = fixedPoints;

% make sure that transZ is monotonically increasing
[transZ,fixend] = fixspacing(transZ,fixedPoints,movingPoints);
if fixend
   eqspace=findTransformedZ(moving2fixedzratio,NfixedPoints,NmovingPoints,fixedPoints(end),movingPoints(end));
    interval = movingPoints(end)+1:NmovingPoints;
    nonMonoPoints = interval(transZ(interval)<fixedPoints(end));
    transZ(nonMonoPoints) = eqspace(nonMonoPoints);

end
end


function transformedZ = findTransformedZ(moving2fixedzratio,NfixedPoints,NmovingPoints,fixedPoint,movingPoint)
% local function for solving the following problem: We have NmovingPoints
% number of moving frames and we need to find the frames from the
% reference brain to which they correspond. We know the reference brain frame 
% that corresponds to the fixedPoint frame from the set of moving frames. We need to 
% calculate the other corresponding frames.  We assume a fixed moving-frame
% to fixed frame ratio of moving2fixedzratio.
%
% Example: fixedPoint = 10; movingPoint = 1; NfixedPoints=76;
% NmovingPoints=8;
%           In this case we are registering the first moving frame. We know that 
% it should correspond to the tenth frame of the fixed movies.  Since we are registering 
% the first moving frame, there are no preceeding frames to register and transZBeforeStart 
% simply equals 10. The next 8 frames are registered as 
% 10 + round([1 2 3 4 5 6 7 8]*(moving spacing/ fixed spacing)).
%       
%

transZBeforeStart = [sort(fixedPoint-round([1:(movingPoint-1)]*moving2fixedzratio)) fixedPoint];
transZBeforeStart(transZBeforeStart<=0) = transZBeforeStart(find(transZBeforeStart>0,1));

transZAfterStart =  [fixedPoint round([1:(NmovingPoints-movingPoint)]*moving2fixedzratio)+fixedPoint];
transZAfterStart(transZAfterStart>NfixedPoints) = transZAfterStart(find(transZAfterStart<=NfixedPoints,1,'last'));


transformedZ = [transZBeforeStart(1:end-1) transZAfterStart];

end
function [transZ,fixend] = fixspacing(transZ,fixedIAnchor,movingIAnchor)

% checks that no points between the anchor points (inferred only using the
% first anchor point and equal spacing) are larger than the anchor points 
for j=1:length(movingIAnchor)-1
    interval = movingIAnchor(j)+1:movingIAnchor(j+1);
    nonMonoCond = transZ(interval)>fixedIAnchor(j+1);
    nonMonoPoints = interval(nonMonoCond);
    transZ(nonMonoPoints)=fixedIAnchor(j+1); 
end

% checks that last points are not smaller in magnitude than last anchor
% point
interval = movingIAnchor(end)+1:length(transZ);
nonMonoCond = transZ(interval)<fixedIAnchor(end);
fixend = false;
if any(nonMonoCond)
  fixend =true;
end
end
