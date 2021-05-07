function [inIndex] = findPointsInCylinder(X,cr,cl,c)
% findPointsInCylinder - finds which user-specified points fall within a
% cylinder of user-specified dimensions. 
% 
% [inIndex] = findPointsInCylinder(X,cr,cl,c)
% Returns a vector, inIndex, containing the row indices of X that
% correspond to points within a cylinder (radius cr, length cl) centered 
% about c. 
%
% INPUT 
% X -  N x 3 matrix. X(i,:) = [x,y,z]. z is the dimension of cylinder
% height. The radius of the cylinder is in the x-y plane
% cr - radius (scalar)
% cl - length (scalar)
% c  - 3x1 vector of cylinder center c
% OUTPUT 
% inIndex - Nx1 boolean vector. inIndex(i) = true if X(i,:) is within the
% cylinder
%
% Example: 
% create a 3D grid
% [x,y,z] = meshgrid(-2:.2:2);
% X = [x(:) y(:) z(:)];
% plot 
% plot3(X(:,1),X(:,2),X(:,3),'.');xlabel('x');ylabel('y');
% find points in cylinder of radius 0.5, length 3 centered at [1,1,0]
% inIndex = findPointsInCylinder(X,0.5,3,[1,1,0]);
% plot the points found within the cylinder in red. 
% hold on;plot3(X(inIndex,1),X(inIndex,2),X(inIndex,3),'r.')
% by examining the plot at various angles one can verify that the proper 
% points are included in the clyinder.
%
% adr 
% June 23 2018


% find bounding region for x 
withinx = X(:,1) <= c(1) + cr & X(:,1) >= c(1) - cr;

% find bounding region for y
%1 ) convert each points x-value into a constraint for y determined by 
%  the equation of a circle centered at zeros

outsideRegion = (X(:,1)-c(1)).^2 > cr^2;
yconstraint = -inf(size(X,1),1);
yconstraint(~outsideRegion) = sqrt(cr^2 - (X(~outsideRegion,1)-c(1)).^2);
% 2) determine which points have y within the constraint
withiny = X(:,2) <=  c(2) + yconstraint & X(:,2) >= c(2) - yconstraint;

%withiny = X(:,2) <=  c(2) + cr & X(:,2) >= c(2) - cr;

% find bounding region for z 
withinz = X(:,3) <= c(3) + cl/2 & X(:,3) >= c(3) - cl/2;

inIndex = withinx & withiny & withinz;
end

