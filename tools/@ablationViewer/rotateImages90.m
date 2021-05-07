function abobj = rotateImages90(abobj)
nchannels = length(abobj.images.channel);
for chIndex = 1 :nchannels
    images = abobj.images.channel{chIndex};
    if ~isempty(images)
        nplanes = size(images,3);
        for pIndex =1:nplanes
            abobj.images.channel{chIndex}(:,:,pIndex) = images(:,:,pIndex)';
        end
    end
end
end