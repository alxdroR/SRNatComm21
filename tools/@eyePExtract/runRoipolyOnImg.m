function [varargout] = runRoipolyOnImg(I,varargin)
%[ROILeft,varargout] = runRoipolyOnImg(I)
% run roipoly on input image
% options = struct('numROIs',2,'dispText',{{'please circle Left Eye','please circle the right eye'}});
% options = parseNameValueoptions(options,varargin{:});
% adr
% ea lab
% weill cornell medicine
% 10/2012 -202x
options = struct('numROIs',2,'dispText',{{'please circle Left Eye','please circle the right eye'}});
options = parseNameValueoptions(options,varargin{:});

figure;
imagesc(I);colormap('gray'); hold on;

varargout = cell(options.numROIs,1);
for index = 1 : options.numROIs
    if ~isempty(options.dispText)
        set(gcf,'Name',options.dispText{1}{index});
        fprintf('%s\n',options.dispText{1}{index});
    end
    [ROIOut,xi,yi] = roipoly(I);
    plot(xi,yi,'r');
    varargout{index} = ROIOut;
end
end