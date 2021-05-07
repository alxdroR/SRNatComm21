function [xpixels,pixPerMicron,varargout]=mic2pix(xmicrons,metaData)
%  function xpixels=mic2pix(xmicrons,metaData)
% given a cell size, xmicrons, in microns, convert to number of pixels
% based on information stored in metadata
% The metadata structure is given by
% rawData.metaData{arrayInd} or
% caData.metaData.scanParam{arrayInd}


% Scope calibration table (microns to pixel at different zooms @ 40x)
cv512=[548.8200  275.8785  184.4941  138.6774  111.1327   92.7407   79.5865   69.7098   62.0205   55.8637   50.8225   46.6185   43.0590   40.0062   37.3589 ...
    35.0414   32.9956   31.1762   29.5476   28.0813   26.7542   25.5472   24.4449   23.4340   22.5037   21.6447   20.8491   20.1101   19.4219   18.7794];
cv = cv512/512;  % microns per pixel;

if ~isempty(metaData)
    if metaData.acq.scanAmplitudeX ~= 2.5 || metaData.acq.scanAmplitudeY ~= 2.5
        fprintf('acq.scanAmplitudeX = %0.2f\n',metaData.acq.scanAmplitudeX);
        fprintf('acq.scanAmplitudeY = %0.2f\n',metaData.acq.scanAmplitudeY);
        error('The scale saved here is only valid for scanAmplitudeX=scanAmplitudeY=2.5');
    end
    
    % get zoom factor and conversion factor based on that zoom
    zoomfac= metaData.acq.zoomtens*10 + metaData.acq.zoomones;
    xpixels = round(xmicrons./cv(zoomfac));
    
    % pixel size cannot be even
    for i=1:length(xmicrons)
        if mod(xpixels(i),2)==0
            xpixels(i) = xpixels(i)-1;
        end
    end
    pixPerMicron = 1/cv(zoomfac);
    varargout{1} = cv(zoomfac);
else
    warning('metaData is empty. Using default 3x magnification with 40X objective');
    xpixels = round(xmicrons./cv(3));
    pixPerMicron = 1/cv(3);
    varargout{1} = cv(3);
end
end
