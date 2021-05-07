function [FCh1,FCh2,FCh3] = loadTIFF(filename,varargin)
options = struct('fast',false,'useImread',true);
options = parseNameValueoptions(options,varargin{:});

% get information about the fname
finfo = imfinfo(filename);
numFrames = length(finfo);
% total number of frames recorded
if options.fast
    numFrames = min(numFrames,20);
end
T = numFrames;


% if pictures were averaged we don't load
% all frames

% load all data
Fmat = zeros(finfo(1).Height,finfo(1).Width,T,'uint16'); % calcium time-series
if options.useImread
    for i=1:T
        Fmat(:,:,i)=imread(filename,'Index',i,'PixelRegion',{[1 finfo(1).Height],[1 finfo(1).Width]});
    end
else
    TifLink = Tiff(filename,'r');
    for i = 1:T
        TifLink.setDirectory(i);
        Fmat(:,:,i) = TifLink.read();
    end
    TifLink.close();
end
FCh1 = Fmat;
FCh2 = []; FCh3 = [];
% save channels with appropriate labels

end % end loadTIFF
