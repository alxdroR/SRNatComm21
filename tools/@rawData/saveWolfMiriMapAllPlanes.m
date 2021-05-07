function saveWolfMiriMapAllPlanes(rawobj,varargin)
% save traces and images from all Planes
options = struct('voxelsize',1,'channel2Correct',1,'motionC',false,'preAverage',false,'useTwitchDetector',false,...
    'eyeFiles2Load',[],'eyeDir',[],'eyeID',[],'eyeExpTag',[],'StimFile2Load',[],'StimDir',[],...
    'eyeCaSynced',false,'useImread',true,'singleCellAblations',false,...
    'saveFiles',false,'printTIFFMaps',false);
options = parseNameValueoptions(options,varargin{:});

% until legacy code is fixed
if isfield(options,'channel')
    options.channel2Correct = options.channel;
end

% load meta data if it exist
expdataFile = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','expMetaData','singleCellAblations',options.singleCellAblations,'dir',rawobj.dir);
if exist(expdataFile,'file')==2
    load(expdataFile,'expMetaData');
else
    expMetaData = makeMetaDataStruct;
end
if options.saveFiles
    if ~isempty(options.saveFileAs)
        saveTraceName = options.saveFileAs;
    else
        saveTraceName = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','regressionMaps','dir',options.dir2Save);
    end
end
eyeobj = rawobj.loadEyeDataObj(varargin{:});
[numFiles2Load,files2Analyze]=rawobj.determineNumberOfFiles2Load('singleCellAblations',options.singleCellAblations);
if numFiles2Load>0
    ccMap = cell(numFiles2Load,1);
    zscoreMap = cell(numFiles2Load,1);
    twitchFrames = cell(numFiles2Load,1);
    twitchTimes = cell(numFiles2Load,1);
    MCerror = cell(numFiles2Load,1);
    syncOffset = zeros(numFiles2Load,1);
    
    for arrayInd = 1 : numFiles2Load
        % load and update fileNumber and fileIndex to properly find
        % lagBetweenBehCa
        rawobj = rawobj.updateMovies(arrayInd,...
            'motionC',options.motionC,'channel2Correct',options.channel2Correct,'useImread',options.useImread,'singleCellAblations',options.singleCellAblations);
        % prepare regression object
        expMetaData.scanParam{arrayInd} = rawobj.grabMetaData(files2Analyze{arrayInd});
        avgCaTimeOffset = caData.coor2TimeInPlane([expMetaData.scanParam{arrayInd}.Width/2,expMetaData.scanParam{arrayInd}.Height/2],...
            expMetaData.scanParam{arrayInd}.Width,...
            expMetaData.scanParam{arrayInd}.avgPixelTime);
        if options.eyeCaSynced
            lagBetweenBehCa = 0;
        else
            lagBetweenBehCa = rawobj.loadBehCaStartOffset(varargin{:});
        end
        avgCaTime = expMetaData.scanParam{arrayInd}.imagingPeriod*(0:expMetaData.scanParam{arrayInd}.numSlices-1)' + avgCaTimeOffset + lagBetweenBehCa;
        eyeFileNumber = dataNameConventions.identifyFileNumber(num2str(rawobj.fileIndex),eyeobj.eyeFilesLoaded,'.mat');
        E = eyeobj.centerEyesMethod('planeIndex',eyeFileNumber); 
        vpniObj = VPNISelection('ty0',avgCaTime,'tx0',eyeobj.time{eyeFileNumber},'X0',E,...
            'stim',eyeobj.stim{eyeFileNumber}(:)-nanmean(eyeobj.stim{eyeFileNumber}(:)),'stimTime',eyeobj.stimTime{eyeFileNumber}(:));
        
        % compute map for this plane
        rawobj=rawobj.calcWolfMiriMap('fileNumber',arrayInd,'vpniObj',vpniObj,'cellsize',options.voxelsize,'channel',options.channel2Correct,...
            'motionC',options.motionC,'preAverage',options.preAverage,'useTwitchDetector',options.useTwitchDetector,'eyeobj',eyeobj);
        
        % combine other files into a matrix for future analysis in matlab
        if options.preAverage
            ccMap{arrayInd} =rawobj.ccMapSA{1}.channel{1};
        else
            ccMap{arrayInd} =rawobj.ccMap{1}.channel{1};
        end
        zscoreMap{arrayInd} = rawobj.zScoreMap;
        twitchFrames{arrayInd} = rawobj.twitchFrames;
        twitchTimes{arrayInd} = rawobj.twitchTimes;
        MCerror{arrayInd} = rawobj.MCError;
        syncOffset(arrayInd) = lagBetweenBehCa;
    end
    if options.saveFiles
        cellSelectParam = options;
        save([saveTraceName '.mat'],'ccMap','zscoreMap','cellSelectParam','twitchFrames','twitchTimes','MCerror','syncOffset','files2Analyze','expMetaData')
    end
    if options.printTIFFMaps
        if options.saveFiles
            % write the files to .tiff file
            imwrite(uint16(rawobj.images.channel{1}),[saveTraceName '_ZScore' '.tif'],'writemode','append')
            for i = 1 : size(rawobj.zScoreMap,3)
                % write with precision of zscores up to 3 decimals
                imwrite(uint16(rawobj.zScoreMap(:,:,i)*1000),[saveTraceName '_ZScore' '.tif'],'writemode','append')
            end
            
            imwrite(uint16(rawobj.images.channel{1}),[saveTraceName '_CC' '.tif'],'writemode','append')
            for i = 1 : size(rawobj.zScoreMap,3)
                if options.preAverage
                    % write with precision of zscores up to 3 decimals
                    imwrite(uint16(rawobj.ccMapSA{1}.channel{1}(:,:,i)*1000),[saveTraceName '_CC' '.tif'],'writemode','append')
                else
                    % write with precision of zscores up to 3 decimals
                    imwrite(uint16(rawobj.ccMap{1}.channel{1}(:,:,i)*1000),[saveTraceName '_CC' '.tif'],'writemode','append')
                end
            end
        end
    end
end
end