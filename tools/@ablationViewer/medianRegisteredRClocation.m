function [medianRC,medianLength,registeredPoints]=medianRegisteredRClocation(abobj)
% medianLength gives the extent of the damage on the registered
% brain.  If there is no scaling, this simply equals the radius
% of the damage.
%

% register points
registeredPoints = transform(abobj.regTransform,'points',abobj.offset,...
    'registeredz',abobj.transformedZ);
% calculate median
medianOffset = median(registeredPoints,1);
medianRC = medianOffset(1);

% need to fix this
medianLength = 2*max(abobj.radius);
%  the answer is what are the extremum of
% sqrt(qA*A'q'), when q is constrained to lie on
% a circle of radius R.  Solve this problem for each plane
% then take median (todo)
%
%           % brute force way (todo)
%           %for plane = 1:length(abobj.regTransform)
%
%           % make a circle with the right radius
%           x = [-1:0.001:1];
%           y = sqrt(radius(sampleIndex)^2-x.^2);
%           x = [x x];
%           y = [y -y];
%           % transform these points, find minium
%           % end
%
%
end