function cc = nancorr(x,y)
% cc = nancorr(x,y) - ignore NaNs when computing Pearson Correlation
% Coefficient of x and y. Matlab's corr function would return NaN if X or Y
% have a NaN
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

[Nx,dimx]=size(x);
[Ny,dimy] = size(y);
if Nx==1 && dimx>1
    % unidimensional case where x was incorrectly inputed
    x = x(:);
    Nx = length(x);
end
if Ny==1 && dimy>1
    y = y(:);
    Ny = length(y);
end

if Nx ~= Ny
    error('x and y must be the same length');
end

dx = x-nanmean(x);
dy = y - nanmean(y);

sx = sqrt(nansum(dx.^2));
sy = sqrt(nansum(dy.^2));
if ~any(any(isnan(x))) && ~any(any(isnan(y)))
    % no nans
    cc=(dx./sx)'*(dy./sy);
else
    cc = NaN(dimy,dimx);
    for yind = 1 : dimy
        dxy = dx.*dy(:,yind);
        dotProd = nansum(dxy);
        cc(yind,:) = dotProd./(sx.*sy(yind));
    end
end
end

