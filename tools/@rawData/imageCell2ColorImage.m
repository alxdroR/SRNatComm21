function I = imageCell2ColorImage(images,varargin)
options = struct('greenLimits',[0;1],'redLimits',[0;1]);
options = parseNameValueoptions(options,varargin{:});

imagesScaled = cellfun(@(x) ((x-min(x))./(max(x)-min(x))),images.channel,'UniformOutput',false);
[H,W] = size(imagesScaled{1});
I = zeros(H,W,3);
if ~isempty(imagesScaled{2})
    I(:,:,1) = imagesScaled{2};
end
I(:,:,2) = imagesScaled{1};

% could add contrast enhancing option list imadjust or brightner
end