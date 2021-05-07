classdef caData
    % caData - class for dealing with single-cell time-series data
    %options = struct('fluorescence',[],'time',[],'fishid',[],'expcond',[],...
    %            'loadImages',false,'imageStat','averageImages','sameCells',false,'NMF',false,'EPSelectedCells',false,'MO',false,'CCEyes',false,'normalizeImages',false,...
    %            'loadCCMap',false,'fluoFile',[],'ccMAPFile',[],'imageFile',[]);
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    properties
        fishID % see constructor for identification information
        expCond
        fluorescence
        nmfDeconvF
        nmfDenoiseF
        FStdBasedROI
        time
        images
        roiBoxSize
        stAverage
        stBinTime
        stValidStartInd
        stValidStopInd
        stExist
        classParam
        cellTypes
        stResp
        stTime
        stAbsTime
        stPass
        stDirection
        localCoordinates
        footprints
        CoordStdBasedROI
        transformedZ
        regTransform
        corrWithEye
        metaData
        cellSelectOptions
        matchedAblImgData
        selectedPlanes
        twitchFrames
        twitchTimes
        MCError
        syncOffset
    end
    properties (Hidden)
        extractionMethod
    end
    properties (Dependent)
        numPlanes
        imgSize
    end
    methods
        function caobj = caData(varargin)
            options = struct('fluoFile',[],'fluorescence',[],'loadfluorescence',true,...
                'nmfDeconvF',[],'loadnmfDeconvF',true,...
                'nmfDenoiseF',[],'loadnmfDenoiseF',true,...
                'localCoordinates',[],'loadlocalCoordinates',true,...
                'metaDataFile',[],'metaData',[],'loadmetaData',true,...
                'cellSelectOptions',[],'loadcellSelectOptions',true,...
                'twitchFrames',[],'loadtwitchFrames',true,...
                'twitchTimes',[],'loadtwitchTimes',true,...
                'MCError',[],'loadMCError',true,...
                'syncOffset',[],'loadsyncOffset',true,'time',[],'fishid',[],'expcond',[],'dir',[],'sameCells',false,...
                'loadImages',false,'imageFile',[],'imageDir',[],'imageStat','averageImages',...
                'NMF',false,'NMFFile',[],'NMFDir',[],'EPSelectedCells',false,'MO',false,'CCEyes',false,'normalizeImages',false,...
                'loadCCMap',false,'ccMAPFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if ~isempty(options.fishid)
                caobj.fishID = options.fishid;
            end
            if ~isempty(options.expcond)
                caobj.expCond = options.expcond;
            end
            if options.EPSelectedCells
                % old name for NMF option was EPSelectedCells
                options.NMF = true;
            end
            [caobj,var2load,prop2set] = loadDataOrFiles2Load(caobj,varargin{:});
            loadFData = ~isempty(var2load);
            if loadFData
                if isempty(options.fluoFile)
                    options.fluoFile = caobj.getFile2Load(varargin{:});
                end
                varStructure = load(options.fluoFile,var2load{:});
                caobj = caobj.setFRelatedProperties(varStructure,var2load,prop2set);
            end
            if isempty(caobj.metaData)
                if isempty(options.metaDataFile)
                    options.metaDataFile = caobj.getFile2Load(caobj,'NMF',true,'NMFDir',options.NMFDir);
                end
                load(options.metaDataFile,'expMetaData');
                caobj.metaData = expMetaData;
            end
            if options.loadCCMap
                if isempty(options.ccMAPFile)
                    ccEyesFilename = getFilenames(caobj.fishID,'expcond',caobj.expCond,'fileType','catraces','caTraceType','CCEyes');
                    load(ccEyesFilename,'ccMap')
                else
                    load(options.ccMAPFile,'ccMap');
                end
            end
            if options.loadCCMap
                caobj.corrWithEye = ccMap;
            end
            if ~isempty(caobj.cellSelectOptions)
                if isfield(caobj.cellSelectOptions,'cellsize')
                    caobj.roiBoxSize = caobj.cellSelectOptions.cellsize;
                end
            end
            if exist('FStdBasedROI','var')==1
                caobj.FStdBasedROI = FStdBasedROI;
                caobj.CoordStdBasedROI = CoordStdBasedROI;
            end
            if options.loadImages
                if isempty(options.imageFile)
                    imageFilename = getFilenames(options.fishid,'expcond',options.expcond,'fileType',options.imageStat);
                    if ~options.sameCells
                        load([imageFilename '.mat'],'images');
                        caobj.images = images;
                    else
                        load([roiFilename '-BA.mat'],'I')
                        caobj.images = I;
                    end
                else
                    load(options.imageFile);
                    caobj.images = images;
                end
                if options.normalizeImages
                    for i=1:3
                        if sum(caobj.images.channel{i}(:))~=0
                            caobj.images.channel{i}= imadjust3d_stretch(caobj.images.channel{i},[0.01 0.95]);
                        end
                    end
                end
            end
            caobj = caobj.standardizeProps(varargin{:});
            caobj = caobj.computeTime;
        end
        function numPlanes = get.numPlanes(obj)
            numPlanes = length(obj.fluorescence);
        end
        function caobj = standardizeProps(caobj,varargin)
            options = struct('NMF',false,'MO',false);
            options = parseNameValueoptions(options,varargin{:});
            numberPlanes = length(caobj.fluorescence);
            
            lcLongVector = [];
            for plne = 1 : numberPlanes
                [fr,fc] = size(caobj.fluorescence{plne});
                if ~isempty(caobj.metaData)
                    NFrames = caobj.metaData.scanParam{plne}.acq.numberOfFrames;
                    if fc == NFrames
                        N = fr;
                        caobj.fluorescence{plne} = caobj.fluorescence{plne}';
                        if ~isempty(caobj.nmfDeconvF)
                            caobj.nmfDeconvF{plne} = caobj.nmfDeconvF{plne}';
                        end
                        if ~isempty(caobj.nmfDenoiseF)
                            caobj.nmfDenoiseF{plne} = caobj.nmfDenoiseF{plne}';
                        end
                    else
                        N = fc;
                    end
                else
                    N = fc;
                end
                if iscell(caobj.localCoordinates)
                    if options.NMF
                        lcLongVector = [lcLongVector;[caobj.localCoordinates{plne}(:,2) caobj.localCoordinates{plne}(:,1) ones(size(caobj.localCoordinates{plne},1),1)*plne]];
                    elseif options.MO
                        if N < size(caobj.localCoordinates{plne},1)
                            numMissing = size(caobj.localCoordinates{plne},1)-N;
                            lcLongVector = [lcLongVector;[[caobj.fluorescence{plne} NaN(T,numMissing)] ones(size(caobj.localCoordinates{plne},1),1)*plne]];
                        else
                            lcLongVector = [lcLongVector;[caobj.localCoordinates{plne} ones(size(caobj.localCoordinates{plne},1),1)*plne]];
                        end
                    end
                end
            end
            if iscell(caobj.localCoordinates)
                caobj.localCoordinates = lcLongVector;
            end
        end
        function caobj = computeTime(caobj)
            numberPlanes = length(caobj.fluorescence);
            caobj.time = cell(numberPlanes,1);
            for plne = 1 : numberPlanes
                [T,N] = size(caobj.fluorescence{plne});
                if ~isempty(caobj.metaData)
                    H = caobj.metaData.scanParam{plne}.acq.linesPerFrame;
                    Ts = caobj.metaData.scanParam{plne}.acq.msPerLine*H;
                else
                    Ts = 1;
                end
                if ~isempty(caobj.localCoordinates) &&  ~isempty(caobj.metaData)
                    W = caobj.metaData.scanParam{plne}.acq.pixelsPerLine;
                    timePerPixel = caobj.metaData.scanParam{plne}.acq.msPerLine/W;
                    cellIndex = caobj.plane2ind('all',plne);
                    ctrOffset = caobj.coor2TimeInPlane(caobj.localCoordinates(cellIndex,1:2),W,timePerPixel);
                    if ~isempty(caobj.syncOffset)
                        ctrOffset = ctrOffset + caobj.syncOffset(plne);
                    end
                else
                    ctrOffset = 0;
                    N = 1;
                end
                caobj.time{plne} = Ts*(0:T-1)'*ones(1,N) + ones(T,1)*ctrOffset';
            end
        end
        function imgSize = get.imgSize(obj)
            if ~isempty(obj.metaData)
                H = obj.metaData.scanParam{1}.acq.linesPerFrame;
                W = obj.metaData.scanParam{1}.acq.pixelsPerLine;
                imgSize = [H,W];
            end
        end
        function  obj = set.fluorescence(obj,value)
            if isnumeric(value)
                obj.fluorescence = {value};
            else
                obj.fluorescence = value;
            end
        end
        function [obj,var2load,properties2check] = loadDataOrFiles2Load(obj,varargin)
            options = struct('fluorescence',[],'loadfluorescence',true,...
                'nmfDeconvF',[],'loadnmfDeconvF',true,...
                'nmfDenoiseF',[],'loadnmfDenoiseF',true,...
                'localCoordinates',[],'loadlocalCoordinates',true,...
                'footprints',[],'loadfootprints',true,...
                'metaData',[],'loadmetaData',true,...
                'cellSelectOptions',[],'loadcellSelectOptions',true,...
                'twitchFrames',[],'loadtwitchFrames',true,...
                'twitchTimes',[],'loadtwitchTimes',true,...
                'MCError',[],'loadMCError',true,...
                'syncOffset',[],'loadsyncOffset',true,...
                'NMF',false,'MO',false,'CCEyes',false);
            options = parseNameValueoptions(options,varargin{:});
            
            if options.NMF
                obj.extractionMethod = 'NMF';
                properties2check = {'fluorescence','nmfDeconvF','nmfDenoiseF','localCoordinates','footprints',...
                    'metaData','cellSelectOptions','twitchFrames','twitchTimes','MCError','syncOffset'};
                allVarNames = {'fluorescence','frate','filtFl','localCoordinates','A','expMetaData','cellSelectParam','twitchFrames','twitchTimes','MCerror','syncOffset'};
            elseif options.MO
                obj.extractionMethod = 'MO';
                properties2check = {'fluorescence','localCoordinates','footprints'};
                allVarNames = {'fluorescence','localCoordinates','A'};
            elseif options.CCEyes
                obj.extractionMethod = 'CCEyes';
                properties2check = {'fluorescence','localCoordinates',...
                    'metaData','cellSelectOptions','twitchFrames','twitchTimes','MCError','syncOffset'};
                allVarNames = {'fluorescence','localCoordinates','expMetaData','cellSelectParam','twitchFrames','twitchTimes','MCerror','syncOffset'};
            else
                error('Please set at least one ca extraction method to true {NMF,MO,CCEyes}');
            end
            var2load = cell(length(allVarNames),1);
            for k  = 1 : length(properties2check)
                if isempty(options.(properties2check{k}))
                    if options.(['load' properties2check{k}])
                        var2load{k} = allVarNames{k};
                    end
                else
                    obj.(properties2check{k}) = options.(properties2check{k});
                end
            end
            doNotLoad = cellfun(@isempty,var2load);
            var2load = var2load(~doNotLoad);
            properties2check = properties2check(~doNotLoad);
        end
        function obj = setFRelatedProperties(obj,varStructure,varNames,properties2set)
            for k  = 1 : length(properties2set)
                obj.(properties2set{k}) = varStructure.(varNames{k});
            end
        end
        function name2load = getFile2Load(caobj,varargin)
            options = struct('NMF',false,'MO',false,'CCEyes',false,'NMFDir',[],'MODir',[]);
            options = parseNameValueoptions(options,varargin{:});
            if isempty(caobj.fishID)
                error('need to specify a fish ID number if position is not specified');
            end
            if options.CCEyes
                name2load = getFilenames(caobj.fishID,'expcond',caobj.expCond,'fileType','catraces','caTraceType','CCEyes');
            elseif options.NMF
                name2load = getFilenames(caobj.fishID,'expcond',caobj.expCond,'fileType','catraces','caTraceType','NMF','dir',options.NMFDir);
            elseif options.MO
                name2load = getFilenames(caobj.fishID,'expcond',caobj.expCond,'fileType','catraces','caTraceType','MO','dir',options.MODir);
            else
                error('Please set at least one ca extraction method to true {NMF,MO,CCEyes}');
            end
        end
        function fpContour = computefpContours(obj)
            fpContour = cell(obj.numPlanes,1);
            if strcmp(obj.extractionMethod,'CCEyes')
                numSizePix = rawData.mic2pix(obj.cellSelectOptions.nucSize,obj.metaData.scanParam{1});
                fpCreator = circleImgRgns('radius',numSizePix,'imgSize',[H,W]);
            end
            for planeIndex = 1 : obj.numPlanes
                numCells = size(obj.fluorescence{planeIndex},2);
                if strcmp(obj.extractionMethod,'CCEyes')
                    fpContour{planeIndex} = cell(numCells,1);
                    for cellIndex = 1 : numCells
                        fpCreator.center = caobj.localCoordinates(caobj.plane2ind(planeIndex,cellindex),:);
                        [x,y] = fpCreator.makeShape;
                        fpContour{planeIndex}{cellIndex} = [x,y];
                    end
                else
                    fpContour{planeIndex} = footprint2Contour(obj.footprints{planeIndex},obj.imgSize(1),obj.imgSize(2));
                end
            end
        end
        caobj=getRegistrationTransform(caobj,varargin)
        plotEyeOverCell(caobj,varargin)
        titleStr = generateTitle(caobj)
        [movingPoints,fixedPoints]=registerImages(caobj,varargin);
        cellIndex=plane2ind(caobj,subIndex,plane)
    end
    methods (Static)
        function ctrOffset = coor2TimeInPlane(x,W,timePerPixel)
            timeSpentOnPreviousLines = timePerPixel*W*(x(:,2)-1);
            timeSpentOnCurrentLine = timePerPixel*x(:,1);
            ctrOffset = (timeSpentOnPreviousLines + timeSpentOnCurrentLine);
        end
    end
end

