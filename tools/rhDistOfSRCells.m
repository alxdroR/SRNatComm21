function rhDistOfSRCells(varargin)
% rhDistOfSRCells - find the distribution of SR cells across rhombomeres
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

options = struct('sigLeft',[],'sigRight',[],'Coordinates',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.sigLeft) || isempty(options.sigRight) || isempty(options.Coordinates)
   loadAnticipatorySelectionCriteria
else
    sigRight = options.sigRight;
    sigLeft = options.sigLeft;
    Coordinates = options.Coordinates;
end

CAntic = Coordinates(sigLeft|sigRight,:);
CAnticPixels = round(CAntic);
nCells = size(CAntic,1);

[~,~,fileDirs] = rootDirectories;
load(fileDirs.ZBrainMasks,'MaskDatabase','height','width','Zs');

% make a mask for all rhombomeres 
rh1MaskIndex = 219;
rh78MaskIndex = 225;
rhMask = MaskDatabase(:,rh1MaskIndex)*1;
for rhMaskIndex = rh1MaskIndex+1:rh78MaskIndex
    rhMask = rhMask + MaskDatabase(:,rhMaskIndex)*(rhMaskIndex-rh1MaskIndex+1);
end
%cbMaskIndex = 131;
%rhMask = rhMask + MaskDatabase(:,cbMaskIndex)*8; 
mask = reshape(full(rhMask),height,width,Zs);  

CAnticLocation = false(nCells,8);
for cellIndex = 1 : nCells
    cellLocation = mask(CAnticPixels(cellIndex,1),CAnticPixels(cellIndex,2),CAnticPixels(cellIndex,3));
    
    if cellLocation ~= 0 
        CAnticLocation(cellIndex,cellLocation)=true;
    else
        % at the dorsal planes (~30% of cells), the masks seem less accurate so we will
        % register using the plane at the MC
        cellLocation = mask(CAnticPixels(cellIndex,1),CAnticPixels(cellIndex,2),66);
        if cellLocation ~= 0 
            CAnticLocation(cellIndex,cellLocation)=true;
        else
            % If things still don't register ... 
             CAnticLocation(cellIndex,8)=true;
        end
    end
end
numCellAtRh = sum(CAnticLocation);
Nregistered = sum(numCellAtRh(1:7));
numR1 = numCellAtRh(1)/Nregistered;
numR26 = sum(numCellAtRh(2:6))/Nregistered;
numR78 = numCellAtRh(7)/Nregistered;
fprintf('\n and rh1 (%0.3f), the majority between r2-6 (%0.3f), and a modest representation in r7-8 (%0.3f)\n',numR1,numR26,numR78)


