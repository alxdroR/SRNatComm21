classdef eyeData
    
    
    properties
        position% position{i}(n,p) yields the nth sample of position for the pth variable. p generally equals to 2, the number of  eye traces. position can be set by the user to an Nxp matrix.
        time % time has the same dimensions as position and represents the times at which sample points were taken(usually in seconds)
        fishID % see constructor for identification information
        eyeFilesLoaded
        expCond
        saccadeTimes % times at which saccades occur.  This is specified as a public property since getting all saccades can take many many hours or since this is known for simulated data.
        saccadeTimeFilePath
        saccadeDirection
        saccadeVelocity
        saccadeAmplitude
        saccadeIndex
        conjugateSaccade % change: simultaneous saccades but not necessarily conjugate (todo)
        saccadeDetectionAlgorithm
        saccadeDetectionParamters
        stim
        stimTime
        stimFilesLoaded
    end
    
    methods
        function eyeObj=eyeData(varargin)
            options = struct('position',[],'time',[],'fishid',[],'expcond',[],'PFile2Load',[],'PDir',[],'StimFile2Load',[],'StimDir',[]);
            options = parseNameValueoptions(options,varargin{:});
            loadData = true;
            if ~isempty(options.position)
                loadData = false;
                if isempty(options.time)
                    error('time property must be specified when position is given')
                end
            end
            
            % -- load the data if this is required
            if loadData
                if isempty(options.PFile2Load)
                    if isempty(options.fishid)
                        error('need to specify a fish ID number if position is not specified');
                    end
                    eyeFilePath = getFilenames(options.fishid,'expcond',options.expcond,'fileType','eye','dir',options.PDir);
                else
                    if iscell(options.PFile2Load)
                        eyeFilePath = options.PFile2Load;
                    else
                        eyeFilePath = {options.PFile2Load};
                    end
                end
                eyeObj.eyeFilesLoaded = eyeFilePath;
                numEyeFiles2Load = length(eyeFilePath);
                eyeObj.position = cell(numEyeFiles2Load,1);
                eyeObj.time = cell(numEyeFiles2Load,1);
                for arrayInd = 1 : numEyeFiles2Load
                    load(eyeFilePath{arrayInd},'leye_position','reye_position');
                    timeMatrix = [leye_position(1,:)' reye_position(1,:)'];
                    % in all the experiments the eyes are recorded
                    % simultaneously. They just aren't processed on or
                    % offline simultaneously
                    timeMatrix = min(timeMatrix,[],2)*ones(1,2);
                    allPositions = [leye_position(2,:)' reye_position(2,:)'];
                    eyeObj.time{arrayInd} = timeMatrix;
                    eyeObj.position{arrayInd} = allPositions;
                    
                    clear leye_position reye_position allPositions
                end
                eyeObj.saccadeTimes = cell(numEyeFiles2Load,1);
                eyeObj.saccadeDirection = cell(numEyeFiles2Load,1);
                eyeObj.saccadeVelocity = cell(numEyeFiles2Load,1);
                eyeObj.saccadeAmplitude = cell(numEyeFiles2Load,1);
                eyeObj.conjugateSaccade = cell(numEyeFiles2Load,1);
                eyeObj.saccadeIndex = cell(numEyeFiles2Load,1);
                eyeObj.fishID = options.fishid;
                
                if ~isempty(options.expcond)
                    eyeObj.expCond = options.expcond;
                end
                
                % load stimulus if there is any
                if isempty(options.StimFile2Load)
                    stimFilePath = getFilenames(options.fishid,'fileType','OKRstim','dir',options.StimDir);
                    eyeObj.stimFilesLoaded = stimFilePath;
                else
                    stimFilePath = {options.StimFile2Load};
                    eyeObj.stimFilesLoaded = options.StimFile2Load;
                end
                numStimFiles = length(stimFilePath);
                eyeObj.stim = cell(numEyeFiles2Load,1);
                eyeObj.stimTime = cell(numEyeFiles2Load,1);
                if numStimFiles ~= numEyeFiles2Load && numStimFiles~=0
                    error('You forgot to save a stimulus for an eye position recording');
                end
                for arrayInd = 1 : numStimFiles
                    load(stimFilePath{arrayInd},'beg_time','X','loopt');
                    eyeBegTime =  load(eyeFilePath{arrayInd},'beg_time');
                    tempOffset = etime(eyeBegTime.beg_time,beg_time);
                    eyeObj.stimTime{arrayInd} = loopt(1,:)-tempOffset;
                    eyeObj.stim{arrayInd} = X;
                    clear loopt X beg_time
                end
            else
                if iscell(options.position)
                    eyeObj.position = options.position;
                    eyeObj.time = options.time;
                    narrays = length(options.position);
                else
                    narrays = 1;
                    eyeObj.position{1} = options.position;
                    eyeObj.time{1} = options.time;
                    clear position time
                end
                eyeObj.saccadeTimes = cell(narrays,1);
                eyeObj.saccadeDirection = cell(narrays,1);
                eyeObj.saccadeVelocity = cell(narrays,1);
                eyeObj.saccadeAmplitude = cell(narrays,1);
                eyeObj.conjugateSaccade = cell(narrays,1);
                eyeObj.saccadeIndex = cell(narrays,1);
            end
        end
        [centeredPositionOut,eyeobj] = centerEyesMethod(eyeobj,varargin);
        eyeobj = saccadeDetection(eyeobj,varargin);
        options=plot(eyeobj,varargin);
        [dur,eyeobj,ISIAllPlanes] = calcMedDur2(eyeobj,varargin);
        [num,eyeobj] = calcNumSac(eyeobj,varargin);
        [pvRegresionCoef,segmentedPosition,segmentedVelocity,segmentedTime,...
            segmentedPositionArray,segmentedTimeArray,pvRegresionCoefExtra,...
            segmentedAbsTime,segmentedPositionNobin,segmentedPositionArray2,segmentedTimeArray2,...
            segmentedAbsTimeArray] = pvregression(eyeobj,varargin);
    end
end

