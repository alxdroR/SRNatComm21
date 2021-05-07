function [Ifuse,fh] = fuseAndView(movingImages0,fixedImages0,transform3d,varargin)
[Href,Wref,Nref]=size(fixedImages0);

options = struct('registeredZ',1:length(transform3d),'zconstraint',Nref,'userInteract',false);
options = parseNameValueoptions(options,varargin{:});

stretchParamF = [0.05 0.99];
stretchParamM = [0.01 0.45];

fixedImages = imadjust3d_stretch(fixedImages0,stretchParamF);
movingImages = imadjust3d_stretch(movingImages0,stretchParamM);
if options.userInteract
    continueResponse = input('adjust intensity? Y/N : ','s');
else
    continueResponse = 'n';
end
if strcmpi(continueResponse,'y')
    while strcmpi(continueResponse,'y')
        stretchParamF = input('please adjust stretch parameter settings for reference brain: example [0.2 0.9]\n');
        stretchParamM = input('please adjust stretch parameter settings for moving images: example [0.2 0.9]\n');
        fixedAdjust=imadjust(fixedImages0(:,:,options.registeredZ(1)),stretchlim(fixedImages0(:,:,options.registeredZ(1)),stretchParamF));
        movingAdjust=imadjust(movingImages0(:,:,1),stretchlim(movingImages0(:,:,1),stretchParamM));
        Itrans = imwarp(movingAdjust,transform3d{1},'OutputView',imref2d([Href,Wref]));
        
        fh=figure;
        imshowpair(fixedAdjust,Itrans)
        continueResponse = input('adjust intensity? Y/N : ','s');
        close(fh)
    end
    fixedImages = imadjust3d_stretch(fixedImages0,stretchParamF);
    movingImages = imadjust3d_stretch(movingImages0,stretchParamM);
end

Ifuse = fuseWithReferenceBrain(movingImages,fixedImages,transform3d,'registeredZ',options.registeredZ,'zconstraint',options.zconstraint);
fh=figure;
montage(Ifuse);
end

