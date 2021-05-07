function [movingPoints,fixedPoints]=registerImages(caobj,varargin)
options = struct('saveon',true,'fixedPoints',true,'fixedData',[]);
options = parseNameValueoptions(options,varargin{:});

fixedPoints = [];
movingPoints = [];
if options.fixedPoints
    % check and load fixed points if they exist
    % transformFilename = registrationTransformFilename(caobj.fishID,caobj.locationID,caobj.expCond);
    transformFilename = getFilenames(caobj.fishID,'expcond',caobj.expCond,'fileType','ImageCoordPoints');
    if exist(transformFilename,'file')==2
        load(transformFilename);
    end
end

[movingPoints,fixedPoints]=cpselect3D(caobj.images.channel{1},'fixedPoints',fixedPoints,'movingPoints',movingPoints,'fixedData',options.fixedData);

if options.saveon
    % get file name
    %      transformFilename = registrationTransformFilename(caobj.fishID,caobj.locationID,caobj.expCond);
    transformFilename = getFilenames(caobj.fishID,'expcond',caobj.expCond,'fileType','ImageCoordPoints');
    shouldSave = overwriteCheck(transformFilename);
    if shouldSave
        save(transformFilename,'movingPoints','fixedPoints');
    end
end
end