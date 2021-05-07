function out = imadjust3d_stretch(I,tol)
% imadjust3d: run imadjust using stretchlim on all planes of an input stack
%out = imadjust3d(I,tol)
%   Use this when you want to loop over multiple planes in input image I 
% and use the stretchlim argument with input tol for each plane

% determine number of planes 
[M,N,d3,d4] = size(I);

% if double, imadjust requires the images to range from 0 to 1
cI = class(I);
slc = @(x) (x- min(x(:)))./(max(x(:))-min(x(:)));
% determine if I is a color image or greyscale 
if d3== 3
    nplanes = d4;
    out = zeros(M,N,d3,d4);
for i=1 : nplanes
    Iin = I(:,:,:,i);
    if isa(I,'double')  || isa(I,'single') 
        Iin = slc(Iin); % scale between 0 and 1 
    elseif  isa(I,'uint16')
        Iin = double(Iin);
        Iin = slc(Iin); % scale between 0 and 1 
    end
    out(:,:,:,i) = imadjust(Iin,stretchlim(Iin,tol));
end
    

else
    nplanes = d3;
     out = zeros(M,N,d3);
for i=1 : nplanes
    Iin = I(:,:,i);
    if isa(I,'double') || isa(I,'single') 
        Iin = slc(Iin); % scale between 0 and 1 
        elseif  isa(I,'uint16')
        Iin = double(Iin);
        Iin = slc(Iin); % scale between 0 and 1 
    end
    out(:,:,i) = imadjust(Iin,stretchlim(Iin,tol));
end
end

end

