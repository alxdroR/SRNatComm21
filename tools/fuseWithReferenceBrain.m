function [Ifuse,minGlobalZ,maxGlobalZ,Itransformed] = fuseWithReferenceBrain(movingImage,fixedImage,registrationTransform,varargin)

[Hglobal,Wglobal,Nglobal]=size(fixedImage);

options = struct('registeredZ',1:length(registrationTransform),'zconstraint',Nglobal);
options = parseNameValueoptions(options,varargin{:});



% transform images to reference brain
Itransformed = transform(registrationTransform,'movingImage',movingImage, ...
    'fixedData',[Wglobal,Hglobal]);

% ----
% only keep relevant z-locations for this fish up to some value
minGlobalZ = max(1,min(options.registeredZ)-options.zconstraint);
maxGlobalZ = min(Nglobal,max(options.registeredZ)+options.zconstraint);


% ---
% fuse
Ifuse = zeros(Hglobal,Wglobal,3,Nglobal,'uint8');
for plane = minGlobalZ : maxGlobalZ
    zindex = plane == options.registeredZ;
    if sum(zindex)>1
        warning('two moving planes are mapped to the same reference brain image');
    end
    if any(zindex)
        Ifuse(:,:,:,plane) = imfuse(imadjust(fixedImage(:,:,plane),[0.01 0.99]),imadjust(Itransformed(:,:,find(zindex,1)),[0.01 0.7]));
    else
        Ifuse(:,:,:,plane) = imfuse(fixedImage(:,:,plane),zeros(Hglobal,Wglobal));
    end
end
Ifuse = Ifuse(:,:,:,minGlobalZ:maxGlobalZ);

end