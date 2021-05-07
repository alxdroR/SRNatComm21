% calculate a box about ctr, taking into account bndry effects
function [indI,indJ]=localBoxInd(ctr,boxsize,imgSize)
% [indI,indJ]=localBoxInd(ctr,imgSize)
% Input :
%  ctr -- 1x2 or 2x1 vector (x,y) points of 2d image plane
%
%  boxsize -- scalar - box length in pixels
%
%  imgSize -- size of Image. imgSize(1) is width
%            imgSize(2) is height.

% thresholds take into account bndry effects
topRowBorder = max(1,ctr(2)-(boxsize-1)/2);
bottomRowBorder = min(ctr(2)+(boxsize-1)/2,imgSize(2));
leftColBorder = max(1,ctr(1)-(boxsize-1)/2);
rightColBorder = min(imgSize(1),ctr(1)+(boxsize-1)/2);

indI = topRowBorder:bottomRowBorder;
indJ = leftColBorder:rightColBorder;
end % end local box calculation
