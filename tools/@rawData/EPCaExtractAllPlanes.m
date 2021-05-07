function EPCaExtractAllPlanes(rawobj,varargin)
% save traces and images from all Planes
options = struct('motionC',false,'useTwitchDetector',false,'channel2Correct',1,...
    'merge_thr',0.95,'tau',5,'K',250,'p',0,'tauGCaMP',1.3,'initialFootprints',[],...
    'useImread',true,'singleCellAblations',false,'verbose',false,...
    'saveFiles',true,'saveFileAs',[],'dir2Save',[],'saveID',[],'saveExpTag',[],'saveOneBatchFileForAllFiles',true,...
    'eyeCaSynced',false,'laserStartTimeFile',[],'laserStartDir',[],'laserID',[],'laserExpTag',[],...
    'behaviorStartTimeFile',[],'behaviorStartDir',[],'behaviorID',[],'behaviorExpTag',[]);
options = parseNameValueoptions(options,varargin{:});

if ~options.saveFiles
    warning('EPCaExtractAllPlanes does not output anything. Set saveFiles to true to save output') 
end
% until legacy code is fixed
if isfield(options,'channel')
    options.channel2Correct = options.channel;
end
% load meta data if it exist
expMetaData = rawobj.loadOrCreateExpMetaData(varargin{:});
[numFiles2Load,analyzedFiles]=rawobj.determineNumberOfFiles2Load('singleCellAblations',options.singleCellAblations);
if options.saveFiles
    saveTraceName = rawobj.loadOrCreateName2SaveFile('catraces','caTraceType','NMF','saveFileAs',options.saveFileAs,'dir2Save',options.dir2Save,...
        'saveID',options.saveID,'saveExpTag',options.saveExpTag,'appendFileType',false);
    cellSelectParam = options;
end
if numFiles2Load>0
    if options.saveOneBatchFileForAllFiles
        fluorescence = cell(numFiles2Load,1);filtFl = fluorescence;frate =fluorescence;Por = fluorescence; b2 = fluorescence;f2 = fluorescence;localCoordinates = cell(numFiles2Load,1);...
            A = cell(numFiles2Load,1); twitchFrames = cell(numFiles2Load,1);twitchTimes = cell(numFiles2Load,1);MCerror = cell(numFiles2Load,1);syncOffset = zeros(numFiles2Load,1);
    else
        fluorescence = cell(1,1);filtFl = fluorescence;frate =fluorescence;Por = fluorescence; b2 = fluorescence;f2 = fluorescence;localCoordinates = cell(1,1);...
            A = cell(1,1); twitchFrames = cell(1,1);twitchTimes = cell(1,1);MCerror = cell(1,1);syncOffset = zeros(1,1);
    end
    for arrayInd = 1 : numFiles2Load
        if ~isempty(options.initialFootprints)
            initialFP = options.initialFootprints{arrayInd};
        else
            initialFP = [];
        end
        [f1plane,c1plane,a1plane,Cafilt1plane,S1plane,Por1plane,b21plane,f21plane,rawobj] = ...
            rawobj.EPCaExtract('fileNumber',arrayInd,'channel',options.channel2Correct,...
            'motionC',options.motionC,'merge_thr',options.merge_thr,'tau',options.tau,...
            'K',options.K,'p',options.p,'useTwitchDetector',options.useTwitchDetector,'tauGCaMP',options.tauGCaMP,...
            'useImread',options.useImread,'singleCellAblations',options.singleCellAblations,...
            'initialFootprints',initialFP,'verbose',options.verbose);
        if options.eyeCaSynced
            lagBetweenBehCa = 0;
        else
            lagBetweenBehCa = rawobj.loadBehCaStartOffset(varargin{:});
        end
        if options.saveOneBatchFileForAllFiles
            fluorescence{arrayInd} = f1plane{1};localCoordinates{arrayInd} = c1plane{1};A{arrayInd} = a1plane; filtFl{arrayInd} = Cafilt1plane;frate{arrayInd} = S1plane;...
                Por{arrayInd} = Por1plane;b2{arrayInd} = b21plane;f2{arrayInd} = f21plane;twitchFrames{arrayInd} = rawobj.twitchFrames;twitchTimes{arrayInd} = rawobj.twitchTimes;...
                MCerror{arrayInd} = rawobj.MCError;expMetaData.scanParam{arrayInd} = rawobj.metaData{1};
            syncOffset(arrayInd) = lagBetweenBehCa;
        elseif options.saveFiles
            fluorescence{1} = f1plane{1};localCoordinates{1} = c1plane{1};A{1} = a1plane; filtFl{1} = Cafilt1plane;frate{1} = S1plane;...
                Por{1} = Por1plane;b2{1} = b21plane;f2{1} = f21plane;twitchFrames{1} = rawobj.twitchFrames;twitchTimes{1} = rawobj.twitchTimes;...
                MCerror{1} = rawobj.MCError;expMetaData.scanParam{1} = rawobj.metaData{1};
            syncOffset(1) = lagBetweenBehCa;
            analyzedFile = analyzedFiles{arrayInd};
            fullSaveName = [saveTraceName num2str(rawobj.fileIndex) '.mat'];
            if options.verbose
                fprintf('----------saving NMF output as -----------\n%s\n',fullSaveName);
            end
            save(fullSaveName,'fluorescence','localCoordinates','A','filtFl','frate','Por','b2','f2','cellSelectParam',...
                'expMetaData','twitchFrames','twitchTimes','MCerror','syncOffset','analyzedFile')
        end
    end
    if options.saveOneBatchFileForAllFiles && options.saveFiles
        save([saveTraceName '.mat'],'fluorescence','localCoordinates','A','filtFl','frate','Por','b2','f2','cellSelectParam',...
            'expMetaData','twitchFrames','twitchTimes','MCerror','syncOffset','analyzedFiles')
    end
end
end % end EPCaExtractAllPlanes
