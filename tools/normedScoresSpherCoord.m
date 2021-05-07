function [lon,lat,varargout] = normedScoresSpherCoord(score)
% normalize scores and change to spherical coordinates

% normalize the scores to have unit norm--------------
snorms = sum(score(:,1:3).^2,2);
scoreNormed = score./(sqrt(snorms)*ones(1,size(score,2)));

% convert scores to spherical (longitude and lattitude) coordinates; 0/180
% is all +/- PC 1 and 90/-90 is all +/- PC 2
S = referenceSphere;
[lat,lon,h] = ecef2geodetic(S,scoreNormed(:,1),scoreNormed(:,2),scoreNormed(:,3));
% equivalent computation is 
% h=0
% lat = 90 - acos(scoreNormed(:,3))
% lon must be computed in sections for the conventional definition of a
% longitudinal angle
% xPositiveRegion = scoreNormed(:,1) >=0;
% phi1 = atan(scoreNormed(xPositiveRegion,2)./scoreNormed(xPositiveRegion,1))*(180/pi);
% region2 = scoreNormed(:,2) >= 0 & scoreNormed(:,1) <=0;
% phi2 = atan(scoreNormed(region2,2)./scoreNormed(region2,1))*(180/pi) + 180;
% region3 = scoreNormed(:,2) <= 0 & scoreNormed(:,1) <=0;
% phi3 = atan(scoreNormed(region3,2)./scoreNormed(region3,1))*(180/pi)-180;

varargout{1} = scoreNormed; 
varargout{2} = snorms;
varargout{3} = S;
varargout{4} = h;
end

