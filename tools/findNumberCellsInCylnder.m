function numCells = findNumberCellsInCylnder(Coordinates,cylinder,varargin)
% findNumberCellsInCylnder(Coordinates,cylinder,varargin)
% Coordinates - Nxd array of cell positions. [rc axis, lm, dorsal-ventral]
% clyinder - struct('center',(x,y,z), 'radius', 1x1 array,'length',1x1
% array)

options = struct('weightRCAxis',false,'nSampleMap',[],'selector',[]);
options = parseNameValueoptions(options,varargin{:});


cylCenter = cylinder.center;
radius = cylinder.radius;
l = cylinder.length;

% check for dimension consistencies in inputs
[N,dc] = size(Coordinates);
[Nr,dr] = size(cylCenter);
if Nr>1
    error('findNumberCellsInCylnder only handles 1 cylinder center');
end
if dc ~= dr 
    error('dimension of cylinder center must equal the dimension of Coordinates')
end

if options.weightRCAxis
    [~,weightNorm] = sampleDensities1d(options.nSampleMap,'axis','rc','minRelDensity',0.05);
    Z = 1./weightNorm; 
    weightNorm= Z/sum(Z);
end

% detect if user entered a selector
if ~isempty(options.selector)
    if N ~= size(options.selector,1)
        error('`selector` must by an NxP array');
    end
    numCellTypes = size(options.selector,2);
else
    numCellTypes = 1;
    options.selector = true(N,1);
end
numCells = NaN(numCellTypes,1);

inCylinderBOOL = findPointsInCylinder(Coordinates,radius,l,cylCenter);
if options.weightRCAxis
    weightIndexL = round(Coordinates(inCylinderBOOL,1));
    weightIndexL(weightIndexL<1)=1;
    weightIndexL(weightIndexL>length(weightNorm))=length(weightNorm);
    weightingsL = weightNorm(weightIndexL);
    
    for countIndex = 1 : numCellTypes
        numCells(countIndex) = sum(options.selector(inCylinderBOOL,countIndex).*weightingsL');
    end
else
    for countIndex = 1 : numCellTypes
        numCells(countIndex) = sum(options.selector(inCylinderBOOL,countIndex));
    end
end

end

