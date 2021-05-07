function syncOffset = calcSyncOffset(varargin)
% calculate the difference between
% when the TTL pulse is recieved by the eye-tracking computer
% and when the recording loop begins or when the first
% image is taken with the camera.
%
% a return of 0 could mean 0 offset but likely means
% the required files don't exist

% filename used for syncing imaging with eye recordings (I
% haven't hardcoded this offset into getFilenames yet.
% adr-2/3/2017
options = struct('singleCellAblations',false,'laserStartTimeFile',[],'laserStartDir',[],'laserID',[],'laserExpTag',[],...
    'behaviorStartTimeFile',[],'behaviorStartDir',[],'behaviorID',[],'behaviorExpTag',[],'fileIndex',[],'verbose',false);
options = parseNameValueoptions(options,varargin{:});


if ~isempty(options.laserStartTimeFile)
    laserStartTimeFile = options.laserStartTimeFile;
else
    allOffsetFiles = getFilenames(options.laserID,'expcond',options.laserExpTag,'fileType','laserStartTimes','dir',options.laserStartDir);
    if isempty(allOffsetFiles)
        error('data load failure: if a specific file is not indicated : laserID,  laserIndexFromAllMatchingFiles all required to find a file to load');
    end
    laserFileNumber = dataNameConventions.identifyFileNumber(num2str(options.fileIndex),allOffsetFiles,'offset.mat');
    if isempty(laserFileNumber)
        if options.verbose
            fprintf('-----------NO LASER START TIME FILEs-----------\n');
        end
        laserStartTimeFile = 'NaN';
    else
        laserStartTimeFile = allOffsetFiles{laserFileNumber};
    end
end
if ~isempty(options.behaviorStartTimeFile)
    behaviorStartTimeFile= options.behaviorStartTimeFile;
else
    allEyePositionFiles = getFilenames(options.behaviorID,'expcond',options.behaviorExpTag,'fileType','eye','dir',options.behaviorStartDir);
    if isempty(allEyePositionFiles)
        error('data load failure: if a specific file is not indicated : behaviorID, behaviorIndexFromAllMatchingFiles all required to find a file to load');
    end
    behaviorFileNumber = dataNameConventions.identifyFileNumber(num2str(options.fileIndex),allEyePositionFiles,'.mat');
    if isempty(behaviorFileNumber)
        if options.verbose
            fprintf('-----------NO EYE RECORDING START TIME FILEs-----------\n');
        end
        behaviorStartTimeFile = 'NaN'; 
    else
        behaviorStartTimeFile = allEyePositionFiles{behaviorFileNumber};
    end
end
syncOffset = 0;
if exist(behaviorStartTimeFile,'File') == 2
    if  exist(laserStartTimeFile,'file')==2
        if options.verbose
            fprintf('-----------offset files-----------\n%s\n%s\n',laserStartTimeFile,behaviorStartTimeFile);
        end
        load(laserStartTimeFile,'imageStart');
        load(behaviorStartTimeFile,'beg_time');
        if exist('beg_time','var')
            syncOffset = etime(imageStart,beg_time);
        end
        if isempty(syncOffset)
            syncOffset = NaN;
        end
    end
end
end

