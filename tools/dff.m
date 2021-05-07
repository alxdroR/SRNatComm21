function [Fnormalized] = dff(F)
%DFF computes delta F over F for the Nxp matrix F
%   [Fnormalized] = dff(F)
%  computes delta F over F for the Nxp matrix F
%  average F is computed across rows
mu = nanmean(F,1);
Fnormalized = bsxfun(@(x,y) (x-y)./y,F,mu);
% set NaN's to 0 
Fnormalized(:,mu==0) = 0;
end

