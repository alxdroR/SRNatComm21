function [rawobj,varargout] = extractSingleCellTraces(rawobj,extractionMethod,varargin)
% save traces and images from all Planes
options = struct('motionC',false,'removeTwitches',false,'channel2Correct',1,...
    'useImread',true,'singleCellAblations',false,'verbose',false,...
    'eyeCaSynced',false,'laserStartTimeFile',[],'laserStartDir',[],'laserID',[],'laserExpTag',[],...
    'behaviorStartTimeFile',[],'behaviorStartDir',[],'behaviorID',[],'behaviorExpTag',[],...
    'analyzeAllPlanes',true,'saveFiles',true,'saveTraceFileAs',[],'saveMapFileAs',[],'dir2Save',[],'saveID',[],'saveExpTag',[],'saveOneBatchFileForAllFiles',true,...
    'merge_thr',0.95,'tau',5,'K',250,'p',0,'initialFootprints',[],'min_size',16,'space_thresh',0.05,'time_thresh',0.05,'max_size',320,... % NMF specific parameters
    'midlineYLocation','centered','calcMidlineFnc',false,'eyeFiles2Load',[],'eyeDir',[],'eyeID',[],'eyeExpTag',[],'StimFile2Load',[],'StimDir',[],'printTIFFMaps',false,... % params specific to Miri 2011 method
    'tauGCaMP',1.3,... % parameter used by both NMF and Miri methods
    'correctShiftsInMap',false,'split',[],...
    'runMxCCCellExtraction',false,'preAverage',false,'exclusionDistMu',4,'exclusionDistPix',[],'minCCPix',0.2,'minCCAvg',0.2,'nucSize',3,'edgeExclusionPixels',13 ... % additional params for tweaks I made to extraction of cells using Miri CC maps
    );
options = parseNameValueoptions(options,varargin{:});
warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
properName = strcmp(extractionMethod,'NMF') || strcmp(extractionMethod,'miri2011');
if ~properName
    error('extractionMethod must be : NMF, miri2011');
end

% load meta data if it exist
expMetaData = rawobj.loadOrCreateExpMetaData(varargin{:});
[rawobj,numFiles2Load]=rawobj.setFiles2Load(varargin{:});
if options.saveFiles
    switch extractionMethod
        case 'NMF'
            fileType = 'catraces';
            caTraceType = 'NMF';
        case 'miri2011'
            saveMapName = rawobj.loadOrCreateName2SaveFile('regressionMaps','saveFileAs',options.saveMapFileAs,'dir2Save',options.dir2Save,...
                'saveID',options.saveID,'saveExpTag',options.saveExpTag,'appendFileType',false);
            fileType = 'catraces';
            caTraceType = 'CCEyes';
    end
    saveTraceName = rawobj.loadOrCreateName2SaveFile(fileType,'caTraceType',caTraceType,'saveFileAs',options.saveTraceFileAs,'dir2Save',options.dir2Save,...
        'saveID',options.saveID,'saveExpTag',options.saveExpTag,'appendFileType',false);
    cellSelectParam = options;
    % forbid user from analyzing a single-plane and saving as a batch file
    if options.saveOneBatchFileForAllFiles && ~options.analyzeAllPlanes
        options.saveOneBatchFileForAllFiles = false;
    end
end
if strcmp(extractionMethod,'miri2011')
    eyeobj = rawobj.loadEyeDataObj(varargin{:});
end
if options.printTIFFMaps
    dec2IntFnc = @(x) x*1000;
    negLogFnc = @(x) -log(x);
end
if numFiles2Load>0
    if options.saveOneBatchFileForAllFiles
        numCombinedFiles = numFiles2Load;
    else
        numCombinedFiles = 1;
    end
    twitchFrames = cell(numCombinedFiles,1);twitchTimes = cell(numCombinedFiles,1);MCerror = cell(numCombinedFiles,1);syncOffset = zeros(numCombinedFiles,1);
    
    % initialize
    fluorescence = cell(numCombinedFiles,1);localCoordinates = fluorescence;A = fluorescence;
    switch extractionMethod
        case 'NMF'
           filtFl = fluorescence;frate =fluorescence;Por = fluorescence; b2 = fluorescence;f2 = fluorescence;
        case 'miri2011'
            ccMap = struct('pos',[],'vel',[]);ccPvalMap = struct('pos',[],'vel',[]); zscoreMap = struct('pos',[],'vel',[]);
    end
    if options.correctShiftsInMap && numFiles2Load>1
        registrationShifts = struct('shiftX',zeros(numFiles2Load,1),'shiftY',zeros(numFiles2Load,1),...
            'scaleX',zeros(numFiles2Load,1),'scaleY',zeros(numFiles2Load,1),'changesInScale',false,'changesInShift',false,'split',options.split);
    end
    for arrayInd = 1 : numFiles2Load
        if options.analyzeAllPlanes
            rawobj.fileNumber = arrayInd;
            saveDataCellIndex = arrayInd;
        else
             saveDataCellIndex = 1;
        end
        rawobj = rawobj.updateMovies('motionC',options.motionC,'channel2Correct',options.channel2Correct,'useImread',options.useImread,'singleCellAblations',options.singleCellAblations,'verbose',options.verbose);
        expMetaData.scanParam{arrayInd} = rawobj.metaData{1};
        if options.correctShiftsInMap && numFiles2Load>1
            [registrationShifts.shiftX(arrayInd),registrationShifts.shiftY(arrayInd),registrationShifts.scaleX(arrayInd),registrationShifts.scaleY(arrayInd)] = rawobj.constructShiftStruc(rawobj.metaData{1});
        end
        if options.eyeCaSynced
            lagBetweenBehCa = 0;
        else
            lagBetweenBehCa = rawobj.loadBehCaStartOffset(varargin{:});
        end
        
        switch extractionMethod
            case 'NMF'
                if ~isempty(options.initialFootprints)
                    initialFP = options.initialFootprints{arrayInd};
                else
                    initialFP = [];
                end
                [f1plane,c1plane,a1plane,Cafilt1plane,S1plane,Por1plane,b21plane,f21plane,rawobj] = ...
                    rawobj.EPCaExtract('channel',options.channel2Correct,...
                    'motionC',options.motionC,'merge_thr',options.merge_thr,'tau',options.tau,...
                    'K',options.K,'p',options.p,'useTwitchDetector',options.removeTwitches,'tauGCaMP',options.tauGCaMP,...
                    'useImread',options.useImread,'singleCellAblations',options.singleCellAblations,...
                    'initialFootprints',initialFP,'verbose',options.verbose,'min_size_thr_postWarmup',options.min_size,'space_thresh_postWarmup',options.space_thresh,...
                    'time_thresh_postWarmup',options.time_thresh,'max_size_thr',options.max_size);
               
                fluorescence{saveDataCellIndex} = f1plane{1};localCoordinates{saveDataCellIndex} = c1plane{1};A{saveDataCellIndex} = a1plane; filtFl{saveDataCellIndex} = Cafilt1plane;frate{saveDataCellIndex} = S1plane;...
                    Por{saveDataCellIndex} = Por1plane;b2{saveDataCellIndex} = b21plane;f2{saveDataCellIndex} = f21plane;
            case 'miri2011'
                % prepare regression object
                avgCaTimeOffset = caData.coor2TimeInPlane([expMetaData.scanParam{arrayInd}.Width/2,expMetaData.scanParam{arrayInd}.Height/2],...
                    expMetaData.scanParam{arrayInd}.Width,...
                    expMetaData.scanParam{arrayInd}.avgPixelTime);
                avgCaTime = expMetaData.scanParam{arrayInd}.imagingPeriod*(0:expMetaData.scanParam{arrayInd}.numSlices-1)' + avgCaTimeOffset + lagBetweenBehCa;
                eyeFileNumber = dataNameConventions.identifyFileNumber(num2str(rawobj.fileIndex),eyeobj.eyeFilesLoaded,'.mat');
                E = eyeobj.centerEyesMethod('planeIndex',eyeFileNumber);
                vpniObj = VPNISelection('ty0',avgCaTime,'tx0',eyeobj.time{eyeFileNumber},'X0',E,...
                    'stim',eyeobj.stim{eyeFileNumber}(:)-nanmean(eyeobj.stim{eyeFileNumber}(:)),'stimTime',eyeobj.stimTime{eyeFileNumber}(:));
                [rawobj,f1plane,c1plane,a1plane]=rawobj.calcMiri2011Map('vpniObj',vpniObj,'motionC',options.motionC,'channel',options.channel2Correct,...
                    'useTwitchDetector',options.removeTwitches,'eyeobj',eyeobj,'tau',options.tauGCaMP,...
                    'midlineYLocation',options.midlineYLocation,'calcMidlineFnc',options.calcMidlineFnc,...
                    'runMxCCCellExtraction',options.runMxCCCellExtraction,'preAverage',options.preAverage,'exclusionDistMu',options.exclusionDistMu,...
                    'exclusionDistPix',options.exclusionDistPix,'minCCPix',options.minCCPix,'minCCAvg',options.minCCAvg,'nucSize',options.nucSize,'edgeExclusionPixels',options.edgeExclusionPixels);
                fluorescence{saveDataCellIndex} = f1plane;localCoordinates{saveDataCellIndex} = c1plane;A{saveDataCellIndex} = a1plane;
                if saveDataCellIndex == 1
                    [H,W,~] = size(rawobj.ccMap);
                    ccMap.pos = zeros(H,W,numCombinedFiles); ccMap.vel = zeros(H,W,numCombinedFiles);
                    ccPvalMap.pos = zeros(H,W,numCombinedFiles); ccPvalMap.vel = zeros(H,W,numCombinedFiles);
                    zscoreMap.pos = zeros(H,W,numCombinedFiles);zscoreMap.vel = zeros(H,W,numCombinedFiles);
                end
                ccMap.pos(:,:,saveDataCellIndex) = rawobj.ccMap(:,:,1); ccMap.vel(:,:,saveDataCellIndex) = rawobj.ccMap(:,:,2);
                ccPvalMap.pos(:,:,saveDataCellIndex) = rawobj.ccPvals(:,:,1); ccPvalMap.vel(:,:,saveDataCellIndex) = rawobj.ccPvals(:,:,2);
                zscoreMap.pos(:,:,saveDataCellIndex) = rawobj.zScoreMap(:,:,1);zscoreMap.vel(:,:,saveDataCellIndex) = rawobj.zScoreMap(:,:,2);
        end
        twitchFrames{saveDataCellIndex} = rawobj.twitchFrames;twitchTimes{saveDataCellIndex} = rawobj.twitchTimes;MCerror{saveDataCellIndex} = rawobj.MCError;syncOffset(saveDataCellIndex) = lagBetweenBehCa;
        if options.saveFiles && ~options.saveOneBatchFileForAllFiles
            analyzedFile = rawobj.file2Load{arrayInd};
            if options.verbose
                fullSaveName = [saveTraceName num2str(rawobj.fileIndex) '.mat'];
                fprintf('----------saving NMF output as -----------\n%s\n',fullSaveName);
            end
            switch extractionMethod
                case 'NMF'
                    save([saveTraceName num2str(rawobj.fileIndex) '.mat'],'fluorescence','localCoordinates','A','filtFl','frate','Por','b2','f2','cellSelectParam',...
                        'expMetaData','twitchFrames','twitchTimes','MCerror','syncOffset','analyzedFile')
                case 'miri2011'
                    save([saveMapName num2str(rawobj.fileIndex) '.mat'],'ccMap','zscoreMap','analyzedFile','cellSelectParam')
                    save([saveTraceName num2str(rawobj.fileIndex) '.mat'],'fluorescence','localCoordinates','A','cellSelectParam',...
                        'twitchFrames','twitchTimes','MCerror','syncOffset','analyzedFile','expMetaData')
                    if options.printTIFFMaps
                        if options.printTIFFMaps
                            printTiff(zscoreMap,dec2IntFnc,[saveMapName num2str(rawobj.fileIndex) '_ZScore' '.tif'])
                            printTiff(ccMap,dec2IntFnc,[saveMapName num2str(rawobj.fileIndex) '_CC' '.tif'])
                            printTiff(ccPvalMap,negLogFnc,[saveMapName num2str(rawobj.fileIndex) '_CCPval' '.tif'])
                        end
                    end
            end
        end
    end
    if strcmp(extractionMethod,'miri2011') && numFiles2Load>1
        need2split = spontDataSplitPlanes(rawobj.fishID);
        if need2split
            [~,~,p1] = spontDataSplitPlanes(rawobj.fishID,ccMap.pos);[~,~,v1] = spontDataSplitPlanes(rawobj.fishID,ccMap.vel);
            ccMap = {struct('pos',p1{1},'vel',v1{1}),struct('pos',p1{2},'vel',v1{2})};
            [~,~,p1] = spontDataSplitPlanes(rawobj.fishID,ccPvalMap.pos);[~,~,v1] = spontDataSplitPlanes(rawobj.fishID,ccPvalMap.vel);
            ccPvalMap = {struct('pos',p1{1},'vel',v1{1}),struct('pos',p1{2},'vel',v1{2})};
            [~,~,p1] = spontDataSplitPlanes(rawobj.fishID,zscoreMap.pos);[~,~,v1] = spontDataSplitPlanes(rawobj.fishID,zscoreMap.vel);
            zscoreMap = {struct('pos',p1{1},'vel',v1{1}),struct('pos',p1{2},'vel',v1{2})};
        end
        if options.correctShiftsInMap
            registrationShifts.changesInShift = any((registrationShifts.shiftX -registrationShifts.shiftX(1))~=0) || ...
                any((registrationShifts.shiftY -registrationShifts.shiftY(1))~=0);
            registrationShifts.changesInScale = any((registrationShifts.scaleX -registrationShifts.scaleX(1))~=0) || ...
                any((registrationShifts.scaleY -registrationShifts.scaleY(1))~=0);
            
            [~,~,scaleX] = spontDataSplitPlanes(rawobj.fishID,registrationShifts.scaleX);
            [~,~,shiftX] = spontDataSplitPlanes(rawobj.fishID,registrationShifts.shiftX);
            if need2split
                ccMapShift = cell(2,1); ccPvalMapShift = cell(2,1); zscoreMapShift = cell(2,1);
                for splitIndex = 1 : 2
                    PShift = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},ccMap{splitIndex}.pos,true);
                    VShift = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},ccMap{splitIndex}.vel,true);
                    ccMapShift{splitIndex} = struct('pos',PShift,'vel',VShift);
                    PShift = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},ccPvalMap{splitIndex}.pos,true);
                    VShift = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},ccPvalMap{splitIndex}.vel,true);
                    ccPvalMapShift{splitIndex} = struct('pos',PShift,'vel',VShift);
                    PShift = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},zscoreMap{splitIndex}.pos,true);
                    VShift = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},zscoreMap{splitIndex}.vel,true);
                    zscoreMapShift{splitIndex} = struct('pos',PShift,'vel',VShift);
                end
                ccMap = ccMapShift; ccPvalMap = ccPvalMapShift; zscoreMap = zscoreMapShift;
            else
                PShift = rawobj.shiftDataWShiftStruct(shiftX,scaleX,ccMap.pos,true);VShift = rawobj.shiftDataWShiftStruct(shiftX,scaleX,ccMap.vel,true);
                ccMap = struct('pos',PShift,'vel',VShift);
                PShift = rawobj.shiftDataWShiftStruct(shiftX,scaleX,ccPvalMap.pos,true);VShift = rawobj.shiftDataWShiftStruct(shiftX,scaleX,ccPvalMap.vel,true);
                ccPvalMap = struct('pos',PShift,'vel',VShift);
                PShift = rawobj.shiftDataWShiftStruct(shiftX,scaleX,zscoreMap.pos,true);VShift = rawobj.shiftDataWShiftStruct(shiftX,scaleX,zscoreMap.vel,true);
                zscoreMap = struct('pos',PShift,'vel',VShift);
            end
        end
    end
    switch extractionMethod
        case 'NMF'
            if 0 
            varargout{1} = caData('NMF',true,'fluorescence',fluorescence,'nmfDeconvF',frate,'nmfDenoiseF',filtFl,...
                'localCoordinates',localCoordinates,'metaData',expMetaData,'twitchFrames',twitchFrames,'twitchTimes',twitchTimes,'MCError',MCerror,'syncOffset',syncOffset,'cellSelectOptions',options);
            varargout{2} = 'A';
            varargout{3} = 'b2';
            varargout{4} = 'f2';
            varargout{5} = 'Por';
            end
        case 'miri2011'
             varargout{1} = caData('CCEyes',true,'fluorescence',fluorescence,'localCoordinates',localCoordinates,'metaData',expMetaData,...
                 'twitchFrames',twitchFrames,'twitchTimes',twitchTimes,'MCError',MCerror,'syncOffset',syncOffset,'cellSelectOptions',options);
            voutStart = 1;
            varargout{voutStart+1} = ccMap;
            varargout{voutStart+2} = ccPvalMap;
            varargout{voutStart+3} = zscoreMap;
            varargout{voutStart+4} = 'A';
    end
end
if options.saveOneBatchFileForAllFiles && options.saveFiles
    analyzedFiles = rawobj.file2Load;
    switch extractionMethod
        case 'NMF'
            save([saveTraceName '.mat'],'fluorescence','localCoordinates','A','filtFl','frate','Por','b2','f2','cellSelectParam',...
                'expMetaData','twitchFrames','twitchTimes','MCerror','syncOffset','analyzedFiles')
        case 'miri2011'
            save([saveMapName '.mat'],'ccMap','zscoreMap','ccPvalMap','cellSelectParam','analyzedFiles')
            save([saveTraceName '.mat'],'fluorescence','localCoordinates','cellSelectParam','twitchFrames','twitchTimes','MCerror','syncOffset','analyzedFiles','expMetaData')
            if options.printTIFFMaps
                if need2split
                    printTiff(zscoreMap{1},dec2IntFnc,[saveMapName '_ZScore-1' '.tif'])
                    printTiff(zscoreMap{2},dec2IntFnc,[saveMapName '_ZScore-2' '.tif'])
                    printTiff(ccMap{1},dec2IntFnc,[saveMapName '_CC-1' '.tif'])
                    printTiff(ccMap{2},dec2IntFnc,[saveMapName '_CC-2' '.tif'])
                    printTiff(ccPvalMap{1},negLogFnc,[saveMapName '_CCPval-1' '.tif'])
                    printTiff(ccPvalMap{2},negLogFnc,[saveMapName '_CCPval-2' '.tif'])
                else
                    printTiff(zscoreMap,dec2IntFnc,[saveMapName '_ZScore' '.tif'])
                    printTiff(ccMap,dec2IntFnc,[saveMapName '_CC' '.tif'])
                    printTiff(ccPvalMap,negLogFnc,[saveMapName '_CCPval' '.tif'])
                end
            end
    end
end
warning('on','MATLAB:imagesci:tiffmexutils:libtiffWarning');
end
function printTiff(mapStructWPosVelFields,f,saveWithThisFileName)
overwrite = true;
for planeIndex = 1 : size(mapStructWPosVelFields.pos,3)
    % write with precision of zscores up to 3 decimals
    if overwrite
        imwrite(uint16(f(mapStructWPosVelFields.pos(:,:,planeIndex))),saveWithThisFileName,'writemode','overwrite');
        imwrite(uint16(f(mapStructWPosVelFields.vel(:,:,planeIndex))),saveWithThisFileName,'writemode','append');
        overwrite = false;
    else
        imwrite(uint16(f(mapStructWPosVelFields.pos(:,:,planeIndex))),saveWithThisFileName,'writemode','append');
        imwrite(uint16(f(mapStructWPosVelFields.vel(:,:,planeIndex))),saveWithThisFileName,'writemode','append');
    end
end
end