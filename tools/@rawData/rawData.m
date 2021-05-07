classdef rawData
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 202x
    properties
        fishID % id of fish being analyzed
        expCond % ablation data sets require a before, after, or damage to properly identify the file
        currentFile % name of file currently loaded
        file2Load % if empty rawData will attempt to look for all files that match a pattern in the specified directory or in rootDirectories
        dir
        fileNumber % file number of movie that will be or is stored in the object
        metaData % metaData stored in .tiff file
        movies % movie of activity in plane object.fileNumber
        moviesMC % motion corrected movies
        moviesSA % spatially averaged movies
        images % object.images.channel{i}(:,:,k) gives the time-averaged image from channel i at frame k
        ccMap % correlation coefficient maps
        ccPvals
        zScoreMap % map of multivariate regression zscores
        twitchFrames % frames detected as having twitches by motion correction algorithm
        twitchTimes % frames converted to time windows
        MCError % error in motion correction
    end
    properties (Dependent)
        fileIndex
        movieUpdateRequired
    end
    
    methods
        function rawobj = rawData(varargin)
            % rawobj = rawData(varargin) -- constructor for rawData class
            % Name-value pairs:
            %
            options = struct('fishid',[],'expcond',[],'fileNumber',1,'dir2Load',[],'file2Load',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % check for valid inputs
            if isempty(options.fishid)
                %error('fishid property is empty: need to specify a fish id');
            else
                rawobj.fishID = options.fishid;
            end
            if ~isempty(options.expcond)
                rawobj.expCond = options.expcond;
            end
            if ~isempty(options.file2Load)
                rawobj.file2Load = options.file2Load;
            end
            if ~isempty(options.dir2Load)
                rawobj.dir = options.dir2Load;
            end
            rawobj.fileNumber = options.fileNumber;
        end % end constructor
        function movieUpdateRequired = get.movieUpdateRequired(rawobj)
            movieUpdateRequired = false;
            if isempty(rawobj.currentFile)
                movieUpdateRequired = true;
            elseif ~strcmp(rawobj.currentFile,rawobj.file2Load{rawobj.fileNumber})
                movieUpdateRequired = true;
            end
        end
        function fileIndex = get.fileIndex(rawobj)
            fileIndex = dataNameConventions.identifyFileIndex(rawobj.file2Load{rawobj.fileNumber},'.');
        end
        function rawobj = updateMovies(rawobj,varargin)
            options = struct('motionC',false,'channel2Correct',1,'useImread',true,'singleCellAblations',false,'verbose',false);
            options = parseNameValueoptions(options,varargin{:});
            
            if rawobj.movieUpdateRequired
                if options.motionC
                    rawobj = rawobj.motionCorrect('channel',options.channel2Correct,'useImread',options.useImread,'singleCellAblations',options.singleCellAblations,'verbose',options.verbose);
                else
                    rawobj = rawobj.load('useImread',options.useImread,'singleCellAblations',options.singleCellAblations,'verbose',options.verbose);
                end
            elseif options.motionC && isempty(rawobj.moviesMC)
                % the correct movie is loaded but it has not been motion corrected
                rawobj = rawobj.motionCorrect('channel',options.channel2Correct,'useImread',options.useImread,'singleCellAblations',options.singleCellAblations,'verbose',options.verbose);
            end
        end
        function options = setDefaultFileInfo(rawobj,options,fieldnames)
            if isempty(options.(fieldnames{1}))
                options.(fieldnames{1}) = rawobj.fishID;
            end
            if isempty(options.(fieldnames{2}))
                options.(fieldnames{2}) = rawobj.expCond;
            end
            if isempty(options.(fieldnames{3}))
                options.(fieldnames{3}) = rawobj.dir;
            end
        end
        function eyeobj = loadEyeDataObj(rawobj,varargin)
            options = struct('eyeFiles2Load',[],'eyeDir',[],'eyeID',[],'eyeExpTag',[],'StimFile2Load',[],'StimDir',[]);
            options = parseNameValueoptions(options,varargin{:});
            if isempty(options.eyeFiles2Load)
                options = rawobj.setDefaultFileInfo(options,{'eyeID','eyeExpTag','eyeDir'});
            end
            if isempty(options.StimFile2Load)
                if isempty(options.StimDir)
                    options.StimDir = options.eyeDir;
                end
            end
            eyeobj = eyeData('fishid',options.eyeID,'expcond',options.eyeExpTag,...
                'PFile2Load',options.eyeFiles2Load,'PDir',options.eyeDir,...
                'StimFile2Load',options.StimFile2Load,'StimDir',options.StimDir);
            eyeobj = eyeobj.saccadeDetection;
        end
        function saveTraceName = loadOrCreateName2SaveFile(rawobj,getFilenameFileType,varargin)
            options = struct('saveFileAs',[],'dir2Save',[],'saveID',[],'saveExpTag',[],'caTraceType',[],'appendFileType',true);
            options = parseNameValueoptions(options,varargin{:});
            
            if ~isempty(options.saveFileAs)
                saveTraceName = options.saveFileAs;
            else
                options = rawobj.setDefaultFileInfo(options,{'saveID','saveExpTag','dir2Save'});
                saveTraceName = getFilenames(options.saveID,'fileType',getFilenameFileType,'dir',options.dir2Save,'expcond',options.saveExpTag,...
                    'caTraceType',options.caTraceType,'appendFileType',options.appendFileType);
            end
        end
        function expMetaData = loadOrCreateExpMetaData(rawobj,varargin)
            options = struct('singleCellAblations',false,'expDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if ~isempty(options.expDataFile)
                expDataFile = options.expDataFile;
            else
                expDataFile = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','expMetaData','singleCellAblations',options.singleCellAblations,'dir',rawobj.dir);
            end
            if exist(expDataFile,'file')==2
                load(expDataFile,'expMetaData');
            else
                expMetaData = makeMetaDataStruct;
            end
        end
        function offset = loadBehCaStartOffset(rawobj,varargin)
            options = struct('singleCellAblations',false,'laserStartTimeFile',[],'laserStartDir',[],'laserID',[],'laserExpTag',[],...
                'behaviorStartTimeFile',[],'behaviorStartDir',[],'behaviorID',[],'behaviorExpTag',[],'fileIndex',[],'verbose',false);
            options = parseNameValueoptions(options,varargin{:});
            % ------------default options
            if isempty(options.laserStartTimeFile)
                options = rawobj.setDefaultFileInfo(options,{'laserID','laserExpTag','laserStartDir'});
            end
            if isempty(options.behaviorStartTimeFile)
                options = rawobj.setDefaultFileInfo(options,{'behaviorID','behaviorExpTag','behaviorStartDir'});
            end
            offset = rawData.calcSyncOffset('laserStartTimeFile',options.laserStartTimeFile,'laserStartDir',options.laserStartDir,...
                'laserID',options.laserID,'laserExpTag',options.laserExpTag,...
                'behaviorStartTimeFile',options.behaviorStartTimeFile,'behaviorStartDir',options.behaviorStartDir,...
                'behaviorID',options.behaviorID,'behaviorExpTag',options.behaviorExpTag,'fileIndex',rawobj.fileIndex,'verbose',options.verbose);
        end
        function [rawobj,numFiles2Load] = setFiles2Load(rawobj,varargin)
            options = struct('singleCellAblations',false,'analyzeAllPlanes',true);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(rawobj.file2Load)
                % getFilenames will look in rawobj.dir if not empty
                allFiles = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','raw','singleCellAblations',options.singleCellAblations,'dir',rawobj.dir);
                rawobj.file2Load = allFiles;
            else
                if ischar(rawobj.file2Load)
                    rawobj.file2Load = {rawobj.file2Load};
                end
            end
            if options.analyzeAllPlanes
                numFiles2Load = length(rawobj.file2Load);
            else
                numFiles2Load = 1;
            end
        end
        function getMidline(rawobj,varargin)
            % add an output! 
            options = struct('plotResult',false,'channel2fit',1,'calcMidlineFnc',false,'avgImages',[],'weightDecay',0.01,'compareWith',[]);
            options = parseNameValueoptions(options,varargin{:});
            if isempty(options.avgImages)
                if isempty(rawobj.images)
                    rawobj = rawobj.timeAverage(varargin{:});
                end
                I =rawobj.images.channel{options.channel2fit};
            elseif ischar(options.avgImages)
                I = rawData.loadTIFF(options.avgImages,'useImread',false);
            elseif isnumeric(options.avgImages)
                I = options.avgImages;
            end
            obj.estimateMidlineLocation(I,varargin{:});
        end
        function saveDmgImgAllPlanes(rawobj,varargin)
            % save traces and images from all Planes
            options = struct('fast',false);
            options = parseNameValueoptions(options,varargin{:});
            filenames = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','raw');
            narrays = length(filenames);
            if narrays>0
                for arrayInd = 1 : narrays
                    % select cells for this plane
                    rawobj = rawobj.timeAverage('fileNumber',arrayInd,'fast',options.fast);
                    if arrayInd==1
                        % given width, height, we can now intialize images
                        % assuming that width and height are constant across
                        % planes
                        oneImage = zeros(rawobj.metaData{1}.acq.linesPerFrame,rawobj.metaData{1}.acq.pixelsPerLine,narrays,'single');
                        images.channel = {oneImage,oneImage,oneImage};
                        for chNum=1:3
                            images.channel{chNum}(:,:,arrayInd) = rawobj.images.channel{chNum};
                        end
                    else
                        for chNum=1:3
                            images.channel{chNum}(:,:,arrayInd) = rawobj.images.channel{chNum};
                        end
                    end
                end
                
                saveImgName = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','damageImages');
                save(saveImgName,'images')
            end
        end % end save damage image all planes
        [rawobj,varargout] = extractSingleCellTraces(rawobj,extractionMethod,varargin)
        [rawobj,fluorescence,localCoordinates,ABinary] = calcMiri2011Map(rawobj,varargin)
        [fluorescence,localCoordinates,ABinary,C,S,Por,b2,f2,rawobj] = EPCaExtract(rawobj,varargin)
        [fluorescence,A,rawobj]=handSelectCaExtract(rawobj,varargin)
        rawobj = load(rawobj,varargin)
        rawobj = timeAverage(rawobj,varargin)
        [rawobj,twitchFrames] = motionCorrect(rawobj,varargin)
        images = avgImgsAllPlanes(rawobj,varargin)
        [roiboxsize,temp,rawobj] = micron2pixel(rawobj,x)
    end
    methods (Static)
        [meta,hinfo] = grabMetaData(filename,varargin)
        [xpixels,temp,xymicperpix]=mic2pix(xmicrons,metaData)
        A = handselect(varargin);
        I = imageCell2ColorImage(images,varargin)
        [FCh1,FCh2,FCh3] = loadTIFF(filename,varargin)
        [FCh1,FCh2,FCh3] = loadScanImageTIFF(filename,varargin)
        varargout = constructShiftStruc(varargin)
        shiftedData = shiftDataWShiftStruct(shiftX,scaleX,data,isImage)
        syncOffset = calcSyncOffset(varargin)
        [y,A]=nnaverage(F,ctrin,shapeObj,varargin)
        [indI,indJ]=localBoxInd(ctr,boxsize,imgSize)
        rsave=getCCIndices(maxcp,minCC,minDist,edgeExclusionSize,Iflt,maxIntWindow)
        [I1a,J1a] = maxVal2D(scalarMap,boxRgnObj)
        function [scaleOut,hasZInfo] = extractScaleFromMetaDataStruct(metaDataStruct)
            badFile = false; hasZInfo = true;
            if ~isfield(metaDataStruct,'zspacing')
                hasZInfo = false;
            elseif ~isfield(metaDataStruct,'scanParam')
                badFile = true;
            elseif strcmp(metaDataStruct.zspacing,'not specified')
                hasZInfo = false;
            end
            if badFile
                error('Improper MetaData File. Must be created as in makeMetaDataStruct.m. See rawData.loadOrCreateExpMetaData for an example');
            end
            if hasZInfo
                if isnumeric(metaDataStruct.zspacing)
                    ZMicPerPlane = metaDataStruct.zspacing;
                elseif ~isempty(regexp(metaDataStruct.zspacing,'\dmu', 'once'))
                    % this will break with say 10mu or 100mu
                    ZMicPerPlane = str2double(metaDataStruct.zspacing(1));
                elseif ischar(metaDataStruct.zspacing)
                    ZMicPerPlane = str2double(metaDataStruct.zspacing);
                else
                    ZMicPerPlane = NaN;
                    warning('can not decipher z-info. best format is just to store a number of a string of a number, for example `10` in this field');
                end
            end
            if iscell(metaDataStruct.scanParam)
                [~,~,XMicPerPix] = rawData.mic2pix(1,metaDataStruct.scanParam{1});
            elseif isstruct(metaDataStruct.scanParam)
                [~,~,XMicPerPix] = rawData.mic2pix(1,metaDataStruct.scanParam);
            end
            if hasZInfo
                scaleOut = [XMicPerPix,XMicPerPix,ZMicPerPlane];
            else
                scaleOut = [XMicPerPix,XMicPerPix];
            end
        end
        function mdFnc = midLFncHandleZBrainRegBased(bridge2ZBrain,fish2Bridge,scaleInfo,varargin)
            % midline estimation method based on registration to z-brain
            % re-write the equation below into a line that returns
            % the y(U_2) coordinate given an x (U_1) in the image
            % and a plane (U_3)
            % zBrainMidline = \sum_j (\sum_k U_k T1_{k,j}) T_{j,2}
            %
            % see also
            % rawData.estimateMidlineLocation
            
            options = struct('resetFrame',[],'zBrainMidline',247.38);
            options = parseNameValueoptions(options,varargin{:});
            % input - landmarks or files to 2 landmarks
            if ischar(bridge2ZBrain)
                bridge2ZBrainLandmarks = dlmread(bridge2ZBrain,',');
            elseif isnumeric(bridge2ZBrain)
                bridge2ZBrainLandmarks = bridge2ZBrain;
            end
            need2split = false;
            if iscell(fish2Bridge)
                need2split = true;
                if isempty(options.resetFrame)
                    error('multiple landmark info given but no indication of which frames go with which landmark');
                end
                if ischar(fish2Bridge{1})
                    fish2BridgeLandmarks = {dlmread(fish2Bridge{1},','),dlmread(fish2Bridge{2},',')};
                elseif isnumeric(fish2Bridge{1})
                    fish2BridgeLandmarks = fish2Bridge;
                end
            elseif ischar(fish2Bridge)
                fish2BridgeLandmarks = dlmread(fish2Bridge,',');
            elseif isnumeric(fish2Bridge)
                fish2BridgeLandmarks = fish2Bridge;
            end
            if isstruct(scaleInfo)
                scaleOut = rawData.extractScaleFromMetaDataStruct(scaleInfo);
            elseif isnumeric(scaleInfo)
                scaleOut = scaleInfo;
            end
            
            T2 = affineTransformBigWarp([1 1 0],bridge2ZBrainLandmarks(:,1:3),bridge2ZBrainLandmarks(:,4:6),'onlyComputeTransform',true); % brdige 2 zbrain
            if need2split
                T1a = affineTransformBigWarp([1 1 0],fish2BridgeLandmarks{1}(:,1:3),fish2BridgeLandmarks{1}(:,4:6),'onlyComputeTransform',true);
                T1b = affineTransformBigWarp([1 1 0],fish2BridgeLandmarks{2}(:,1:3),fish2BridgeLandmarks{2}(:,4:6),'onlyComputeTransform',true);
                
                T = {T1a*T2,T1b*T2};
                slope = {-T{1}(1,2)/T{1}(2,2),-T{2}(1,2)/T{2}(2,2)};
                offset = {(options.zBrainMidline-T{1}(4,2))/T{1}(2,2),(options.zBrainMidline-T{2}(4,2))/T{2}(2,2)};
                zDimWeight = {T{1}(3,2)/T{1}(2,2),T{2}(3,2)/T{2}(2,2)};
            else
                T1 = affineTransformBigWarp([1 1 0],fish2BridgeLandmarks(:,1:3),fish2BridgeLandmarks(:,4:6),'onlyComputeTransform',true);
                T = T1*T2;
                slope =-T(1,2)/T(2,2);
                offset = (options.zBrainMidline-T(4,2))/T(2,2);
                zDimWeight = T(3,2)/T(2,2);
            end
            mdFnc = @(x,plane) rawData.midLFncZBrainRegBased(x,plane,slope,offset,zDimWeight,scaleOut,'resetFrame',options.resetFrame);
        end
        function y = midLFncZBrainRegBased(xPix,plane,slope,offset,zDimWeight,scaleOut,varargin)
            options = struct('resetFrame',[],'units','pixels');
            options = parseNameValueoptions(options,varargin{:});
            
            z = (plane-1)*scaleOut(3); % convert plane 2 z in microns
            x = xPix*scaleOut(1);
            if isempty(options.resetFrame) || isnan(options.resetFrame)
                yMu = (x*slope + offset - z*zDimWeight);
            else
                if plane <= options.resetFrame
                    yMu = (x*slope{1} + offset{1} - z*zDimWeight{1});
                else
                    z = z + (1-options.resetFrame)*scaleOut(3);
                    yMu = (x*slope{2} + offset{2} - z*zDimWeight{2});
                end
            end
            switch options.units
                case 'pixels'
                    y = yMu/scaleOut(2);
                case 'microns'
                    y = yMu;
            end
        end
         function varargout = estimateMidlineLocation(I,varargin)
            options = struct('plotResult',false,'channel2fit',1,'calcMidlineFnc',false,'weightDecay',0.01,'compareWith',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if ischar(I)
                I = rawData.loadTIFF(I,'useImread',false);
            elseif ~isnumeric(I)
                error('I must be a filename or a matrix');
            end
            [H,W,N]=size(I);
            output = cell(N,1);
            
            for n = 1 : N
                ISingleImage = double(I(:,:,n));
                w = exp(-options.weightDecay*abs((1:H)-H/2)); % place the most weight around the middle of the image and downplay regions outside of the brain
                Iwinv = (1./w)'.*ISingleImage;
                q10=quantile(Iwinv(Iwinv~=0),0.1);
                Iw = w'.*(Iwinv<=q10);
                weightedImage = Iw>0.5;
                if options.calcMidlineFnc
                    [IJ,JJ]=find(weightedImage);
                    midlineParams = [JJ ones(size(JJ))]\IJ;
                    output{n} = @(x,planeIndex) x*midlineParams(1) + midlineParams(2);
                else
                    IJ=find(weightedImage);
                    output{n} =  median(IJ);
                end
                if options.plotResult
                    figure;subplot(121);imagesc(ISingleImage); hold on;
                    if options.calcMidlineFnc
                        plot(1:W,output{n}(1:W),'r')
                    else
                        plot([1 W],[1 1]*output{n})
                    end
                    plot([1 W],[1 1]*H/2,'g--')
                    if ~isempty(options.compareWith)
                        plot(1:W,options.compareWith(1:W,n),'k--');
                    end
                    subplot(122);imagesc(weightedImage)
                    if N > 10
                        keyboard
                    end
                end
            end
            if N > 1
                varargout{1} = output;
            end
        end
    end
end

