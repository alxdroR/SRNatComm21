function inMB = removeCellsRegistered2MB(Coordinates,varargin)
%removeCellsNotRegistered2HB - Given coordinates in the Z-Brain, return a
%    boolean variable telling which points are located in the midbrain
%
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
options = struct('demoAccuracy',false);
options = parseNameValueoptions(options,varargin{:});


[~,~,fileDirs] = rootDirectories;
load(fileDirs.ZBrainMasks,'MaskDatabase','height','width','Zs');

MesMaskIndex = 94;
mbOutline = reshape(full(MaskDatabase(:,MesMaskIndex)),height,width,Zs);
inMB = false(size(Coordinates,1),1);
for planeInd = 1 : Zs
    inThisPlane = abs(Coordinates(:,3)-planeInd)<=0.5;
    coorInThisPlane = Coordinates(inThisPlane,:);
    inMBInThisPlane = false(size(coorInThisPlane,1),1);
    maskInThisPlane = mbOutline(:,:,planeInd);
    for cellInd = 1 : size(coorInThisPlane,1)
        inMBInThisPlane(cellInd) = maskInThisPlane(round(coorInThisPlane(cellInd,1)),round(coorInThisPlane(cellInd,2)));
    end
    inMB(inThisPlane) = inMBInThisPlane;
end
if options.demoAccuracy
    planeInd = 93;
    maskInThisPlane = mbOutline(:,:,planeInd);
    inThisPlane = abs(Coordinates(:,3)-planeInd)<=0.5;
    coorInThisPlane = Coordinates(inThisPlane & inMB,:);
    figure;imagesc(maskInThisPlane);hold on;
    plot(coorInThisPlane(:,2),coorInThisPlane(:,1),'r.');
end

end

