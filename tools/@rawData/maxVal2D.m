function [I1a,J1a] = maxVal2D(scalarMap,boxRgnObj)
% indices for local box about the point ctr
[indI,indJ,ypatch]=boxRgnObj.makeBoxIndices(scalarMap);
[~,maxLinearInd]=max(ypatch(:));

% convert linear index of local patch to sub index of global
% patch
[maxSubI,maxSubJ] = ind2sub(size(ypatch),maxLinearInd);
I1a=indI(maxSubI);
J1a=indJ(maxSubJ);
end
