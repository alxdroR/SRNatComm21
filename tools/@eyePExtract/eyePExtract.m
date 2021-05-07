classdef eyePExtract
% classdef eyePExtract - extract eye positions from raw behavior videos
% adr
% ea lab
% weill cornell medicine
% 10/2012 -202x

    properties
        video2AngleParameters
        fileName
        fileType
        currentFileNumber
        offsetFile
        offsetFileIndex 
        vrObj
        leftEye
        rightEye
        bodyCentroid
        fitProps
        laserStartTime
        laserStartTimeEvidence
        laserStartFrame
        movieStartDateTime
    end
    
    methods
        function obj = eyePExtract(varargin)
            options = struct('fileName',[],'dir',[],'fileType','.avi','video2AngleParameters',[],'checkParameter',false,...
                'offsetFileName',[],'offsetDir',[],'manualOffsetSelect',false);
            options = parseNameValueoptions(options,varargin{:});
            obj.fileType = options.fileType;
            % Setting Filename or names ---------------------
            if ~isempty(options.fileName)
                if ~iscell(options.fileName)
                % add .avi if it was not included
                if strcmp(options.fileName(end-3:end),options.fileType)
                    obj.fileName = {options.fileName};
                else
                    obj.fileName = {[options.fileName options.fileType]};
                end
                end
                for findex = 1 : length(obj.fileName)
                    if exist(obj.fileName{findex},'File')~=2
                        error('%s does not exist. do you have the full path? is options.fileType correct?\n',obj.fileName{findex});
                    end
                end
            elseif ~isempty(options.dir)
                if ispc
                    D = dir([options.dir '\*' options.fileType]);
                else
                    D = dir([options.dir '/*' options.fileType]);
                end
                obj.fileName = arrayfun(@(x) [x.folder '/' x.name],D,'uniformOutput',false);
            else
                fprintf('Select the AVI file\n');
                [FullFilename,pathname]=uigetfile('*.avi','Select the AVI file');
                obj.fileName = {[pathname FullFilename]};
            end
            % ----------------------
            obj.currentFileNumber = obj.getFileNumber([obj.fileName{1} obj.fileType],obj.fileType);
            
            if ~isempty(options.video2AngleParameters)
                obj.video2AngleParameters = options.video2AngleParameters;
            end
            % -------- offset file or files
            if ~isempty(options.offsetFileName)
                obj.offsetFile = {options.offsetFileName};
            elseif ~isempty(options.offsetDir)
                if ispc
                    D = dir([options.offsetDir '\*offset.mat']);
                else
                    D = dir([options.offsetDir '/*offset.mat']);
                end
                 obj.offsetFile = arrayfun(@(x) [x.folder '/' x.name],D,'uniformOutput',false);
            elseif options.manualOffsetSelect
                fprintf('Select the offset file\n');
                [FullFilename,pathname]=uigetfile('*.mat','Select the offset file');
                obj.offsetFile = {[pathname FullFilename]};
            end
            % ---------------------
            obj.vrObj = VideoReader(obj.fileName{1});
        end
        
        function I = fillInImage(obj,I)
            I(obj.video2AngleParameters.ROIInLeftEye)=0;
            I(obj.video2AngleParameters.ROIInRightEye)=0;
        end
        function [imageStart,obj] = loadLaserStartTime(obj)
            if isempty(obj.offsetFile)
                error('You need to specify a file or list of files with laser start time');
            end
            % search for the appropriate file 
            currentFileSelectorBOOL = cellfun(@(x) obj.currentFileNumber==eyePExtract.getFileNumber(x,'offset.mat'),obj.offsetFile);
            if any(currentFileSelectorBOOL)
                obj.offsetFileIndex = find(currentFileSelectorBOOL);
                currentOffsetFile = obj.offsetFile{currentFileSelectorBOOL};
                load(currentOffsetFile,'imageStart');
            else
                error('offset file for fileNumber %d is missing\n',obj.currentFileNumber);
            end
        end
        function saveData(obj,varargin)
            options = struct('dir2Save',[]);
            options = parseNameValueoptions(options,varargin{:});
            if isempty(options.dir2Save)
                options.dir2Save = obj.vrObj.Path;
            end
            [~,indexEndingStart]=obj.getFileNumber(obj.vrObj.Name,'.avi');
            if ispc
                name2save = [options.dir2Save '\' obj.vrObj.Name(1:indexEndingStart) 'E_' num2str(obj.currentFileNumber) '.mat'];  
            else
                name2save = [options.dir2Save '/' obj.vrObj.Name(1:indexEndingStart) 'E_' num2str(obj.currentFileNumber) '.mat'];  
            end
            % extract
            [t,rpMatrix,rpColumnNames] = obj.reformatData;
          %  leye_position = obj.leftEye;
          %  reye_position = obj.rightEye;
            video2AngleParameters = obj.video2AngleParameters;
            bodyCentroid = obj.bodyCentroid;
           % epropDisp = obj.fitProps;
            fileName = obj.vrObj.Name;
            timeRelMovieStart = obj.laserStartTime;
            frameStart = obj.laserStartFrame;
            beg_time = obj.movieStartDateTime;
            laserStartTimeEvidence = obj.laserStartTimeEvidence;
            offsetFileName = [];
            if ~isempty(obj.offsetFile)
                if ~isempty(obj.offsetFileIndex)
                    offsetFileName = obj.offsetFile{obj.offsetFileIndex};
                end
            end
            save(name2save,'t','rpMatrix','rpColumnNames','bodyCentroid','beg_time','fileName','frameStart','laserStartTimeEvidence','offsetFileName','timeRelMovieStart','video2AngleParameters');
           % save(name2save,'leye_position','reye_position','video2AngleParameters','epropDisp','fileName','timeRelMovieStart','frameStart','beg_time','offsetFileName','laserStartTimeEvidence');
        end
        function [t,rpMatrix,rpColumnNames] = reformatData(obj)
            % extract
            leye_position = obj.leftEye;
            epropDisp = obj.fitProps;
            [d1e,d2e] = size(epropDisp);
            if d2e > d1e
                epropDisp=epropDisp';
            end
          
            rpColumnNames = {'Left Eye Orientation','Right Eye Orientation','Left Eye CentroidX','Right Eye CentroidX',...
                'Left Eye CentroidY','Right Eye CentroidY',...
                'Left Eye MajorAxisLength','Right Eye MajorAxisLength','Left Eye MinorAxisLength','Right Eye MinorAxisLength',...
                'Left Eye Area','Right Eye Area'};
            rpMatrix = [cellfun(@(s) s(1).Orientation,epropDisp),...
                cellfun(@(s) s(2).Orientation,epropDisp),...
                cellfun(@(s) s(1).Centroid(1),epropDisp),...
                cellfun(@(s) s(2).Centroid(1),epropDisp),...
                cellfun(@(s) s(1).Centroid(2),epropDisp),...
                cellfun(@(s) s(2).Centroid(2),epropDisp),...
                cellfun(@(s) s(1).MajorAxisLength,epropDisp),...
                cellfun(@(s) s(2).MajorAxisLength,epropDisp),...
                cellfun(@(s) s(1).MinorAxisLength,epropDisp),...
                cellfun(@(s) s(2).MinorAxisLength,epropDisp),...
                cellfun(@(s) s(1).Area,epropDisp),...
                cellfun(@(s) s(2).Area,epropDisp),...
                ];
            t = leye_position(1,:)';
        end
        function obj = demoUsage(obj)
            obj = obj.setVideoParameters('checkParameter',false); % checkParameter matters if video2AngleParameters are already set and you want t ocheck
            obj = obj.convertVideo2AnglesIDSCamera('frameRate',1/10,'plotEllipse',true,'plotPeriod',50,'verbose',true,'progRate',0.5);
            obj = obj.identifyCaOnset('startTime','load','checkUptoTime',6,'manual',false,'semiAutoThr',0.1,'verbose',true,'progRate',0.5);
            figure; plot(obj.leftEye(1,:),obj.leftEye(2,:),':.'); hold on;plot(obj.rightEye(1,:),obj.rightEye(2,:),':.')
        end
        function analyzeAndSaveAllData(obj,varargin)
            options = struct('dir2Save',[],'frameRate',15,'maxTimeFromEyeRecStart2LaserOnset',7,'manualCheckForLaserFrameStart',false);
            options = parseNameValueoptions(options,varargin{:});
            for k = 1 : length(obj.fileName)
                fprintf('Begin analyzing: %s\n',obj.fileName{k})
                startTime = tic;
                if k == 1 
                    obj = obj.setVideoParameters('checkParameter',false);
                else
                    delete(obj.vrObj)
                    obj.vrObj = VideoReader(obj.fileName{k});
                    obj.currentFileNumber = obj.getFileNumber([obj.fileName{k} obj.fileType],obj.fileType);
                end
               obj = obj.convertVideo2AnglesIDSCamera('frameRate',options.frameRate,'plotEllipse',false,'plotPeriod',50,'verbose',true,'progRate',0.5);
               obj = obj.identifyCaOnset('startTime','load','checkUptoTime',options.maxTimeFromEyeRecStart2LaserOnset,'manual',options.manualCheckForLaserFrameStart,...
                   'semiAutoThr',0.1,'verbose',true,'progRate',0.5);
               obj.saveData('dir2Save',options.dir2Save);
               analysisTime = toc(startTime);
               fprintf('offset file: %s\n analysis time %0.3f\n',obj.offsetFile{obj.offsetFileIndex},analysisTime)
            end
        end
        
        obj = convertVideo2AnglesIDSCamera(obj,varargin)
        obj = setVideoParameters(obj,varargin)
        [beg_time,obj,varargout] = identifyCaOnset(obj,varargin)
    end
    methods (Static)
         [varargout] = runRoipolyOnImg(I,varargin)
         [thresholdL,thresholdR] = determineThresholdLESeperate(I,varargin)
         [x,y,ph,phMA] = visualize_ellipse(s,fig,varargin)
         function [fileNumber,start,stop] = getFileNumber(fileName,endingAfterNumber)
             startPattern = ['_\d*' endingAfterNumber]; % example REGION_A_01012020_EXPERIMENT_B_1.mat
             stopPattern = endingAfterNumber;
             start = regexp(fileName,startPattern);
             stop  = regexp(fileName,stopPattern);
             fileNumber = str2double(fileName(start+1:stop-1));
         end
    end
end

