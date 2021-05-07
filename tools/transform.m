function registeredOut = transform(tformStruct,varargin)
options = struct('points',[],'movingImage',[],'fixedData',[],'registeredz',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.points) % default case is to transform damage images to reference brain size
    if isempty(options.movingImage)
        error('Points or a moving Image must be entered');
    end
    if isempty(options.fixedData)
        refbrainFile = refbrainFilename('fileFormat','tiff');
        refHeader = imfinfo(refbrainFile);
        Hglobal = refHeader.Height;
        Wglobal = refHeader.Width;
    else
        Hglobal = options.fixedData(2);
        Wglobal = options.fixedData(1);
    end
    
    [Hlocal,Wlocal,Nlocal]=size(options.movingImage);
    Itransformed = zeros(Hglobal,Wglobal,Nlocal);
    for plane = 1 : Nlocal
        Itransformed(1:Hlocal,1:Wlocal,plane)=options.movingImage(:,:,plane);
        if isa(tformStruct{plane},'affine2d')
            Itransformed(:,:,plane) = imwarp(Itransformed(:,:,plane),tformStruct{plane},'OutputView',imref2d([Hglobal,Wglobal]));
        else
            Itransformed(:,:,plane) = imtransform(Itransformed(:,:,plane),tformStruct{plane}, ...
                'XData',[1 Wglobal],'YData',[1 Hglobal]);
        end
    end
    registeredOut  = Itransformed;
else
    % handle cell or matrix format for points ... z options must match
    try
        Npoints = size(options.points,1);
        registeredPoints = zeros(Npoints,3);
        uniquePlanes = unique(options.points(:,3));
        for plane = uniquePlanes'
            subindex = options.points(:,3)==plane;
            registeredPoints(subindex,1:2) = transformPointsForward(tformStruct{plane},options.points(subindex,1:2));
            
            if ~isempty(options.registeredz)
                registeredPoints(subindex,3) = options.registeredz(plane);
            else
                registeredPoints(subindex,3) = plane;
            end
        end
        registeredOut = registeredPoints;
    catch me
        me
        %  throw(me)
        keyboard
    end
end

end