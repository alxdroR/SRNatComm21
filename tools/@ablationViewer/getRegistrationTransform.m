function abobj=getRegistrationTransform(abobj,varargin)
options = struct('method','2dstitch');
options = parseNameValueoptions(options,varargin{:});
transformFileName = getFilenames(abobj.fishID(2:end),'expcond',['-' abobj.expcond 'CP.mat'],'fileType','damageCoordPoints');
if exist(transformFileName,'file')==2
    %load(transformFileName,'fixedPoints','movingPoints','offsetc')
    load(transformFileName)
    if exist('offsetc','var')~=0
        % old method
        Nlocal=size(offsetc,1);
        for plane = 1 : Nlocal
            translation2d = [eye(2,3);[offsetc(plane,1) offsetc(plane,2) 1]];
            abobj.regTransform{plane} = maketform('affine',translation2d);
        end
        abobj.transformedZ = offsetc(:,3);
    else
        abobj.regMethod = options.method;
        switch options.method
            case '2dstitch'
                [abobj.regTransform,abobj.transformedZ] = approx3dTransform(movingPoints,fixedPoints,abobj.nImages,abobj.refSize(3));
            case '3daffine'
                error('in progress')
        end
    end
end
end