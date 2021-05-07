function varargout = avgImgsAllPlanes(rawobj,varargin)
% images = avgImgsAllPlanes(rawobj,varargin)
% Run through all raw videos for current fish and experimental condition and create a summary statistic of the movies across time
%
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
options = struct('fast',false,'motionC',false,'channel2motionC',1,'useTwitchDetector',false,'useImread',true,'saveFiles',false,'stat2use','median',...
    'statisticFnc',[],'correctiveMetaData',[],'singleCellAblations',false,'dir2Save',[],'dir2Load',[]);
options = parseNameValueoptions(options,varargin{:});

if strcmp(options.stat2use,'median')
    options.statisticFnc = @median;
elseif strcmp(options.stat2use,'mean')
    options.statisticFnc = @mean;
end

% load meta data if it exist
expdataFile = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','expMetaData','singleCellAblations',options.singleCellAblations,'dir',rawobj.dir);
if exist(expdataFile,'file')==2
    load(expdataFile,'expMetaData');
else
    expMetaData = makeMetaDataStruct;
end

filenames = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','raw','singleCellAblations',options.singleCellAblations,'dir',rawobj.dir);
narrays = length(filenames);
if narrays>0
    if options.motionC
        twitchFrames = cell(narrays,1);
        twitchTimes = cell(narrays,1);
        MCerror = cell(narrays,1);
    end
    for arrayInd = 1 : narrays
        rawobj = rawobj.timeAverage('fileNumber',arrayInd,'useImread',options.useImread,...
            'fast',options.fast,'motionC',options.motionC,'channel',options.channel2motionC,...
            'useTwitchDetector',options.useTwitchDetector,'statisticFnc',options.statisticFnc,...
            'singleCellAblations',options.singleCellAblations);
        % create structure of images that will be saved
        if arrayInd==1
            % given width, height, we can now intialize images assuming that width and height are constant across planes
            oneImage = zeros(rawobj.metaData{1}.acq.linesPerFrame,rawobj.metaData{1}.acq.pixelsPerLine,narrays,'single');
            images.channel = {oneImage,oneImage,oneImage};
        end
        % save images to structure
        for chNum=1:3
            images.channel{chNum}(:,:,arrayInd) = rawobj.images.channel{chNum};
        end
        % save motion correction parameters
        if options.motionC
            twitchFrames{arrayInd} = rawobj.twitchFrames;
            twitchTimes{arrayInd} = rawobj.twitchTimes;
            MCerror{arrayInd} = rawobj.MCError;
        end
        % save metadata
        expMetaData.scanParam{arrayInd} = rawobj.metaData{1};
    end
    need2split = spontDataSplitPlanes(rawobj.fishID);
    if need2split
        [~,~,I1] = spontDataSplitPlanes(rawobj.fishID,images.channel{1});
        [~,~,I2] = spontDataSplitPlanes(rawobj.fishID,images.channel{2});
        [~,~,I3] = spontDataSplitPlanes(rawobj.fishID,images.channel{3});
        image1.channel = {I1{1},I2{1},I3{1}};
        image2.channel = {I1{2},I2{2},I3{2}};
        images = {image1,image2};
    end
    if ~isempty(options.correctiveMetaData)
        if isstruct(options.correctiveMetaData)
            shiftStructure = options.correctiveMetaData;
        else
            if ~isempty(rawobj.file2Load)
                shiftStructure = rawData.constructShiftStruc(rawobj.file2Load);
            else
                error('filenames required to run shift corrections');
            end
        end
        [~,~,scaleX] = spontDataSplitPlanes(rawobj.fishID,shiftStructure.scaleX);
        [~,~,shiftX] = spontDataSplitPlanes(rawobj.fishID,shiftStructure.shiftX);
        if need2split
            for splitIndex = 1 : 2
                images{splitIndex}.channel{1} = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},images{splitIndex}.channel{1},true);
                images{splitIndex}.channel{2} = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},images{splitIndex}.channel{2},true);
                images{splitIndex}.channel{3} = rawobj.shiftDataWShiftStruct(shiftX{splitIndex},scaleX{splitIndex},images{splitIndex}.channel{3},true);
            end
        else
            images.channel{1} = rawobj.shiftDataWShiftStruct(shiftX,scaleX,images.channel{1},true);
            images.channel{2} = rawobj.shiftDataWShiftStruct(shiftX,scaleX,images.channel{2},true);
            images.channel{3} = rawobj.shiftDataWShiftStruct(shiftX,scaleX,images.channel{3},true);
        end
    end
end
varargout{1} = images;
if options.saveFiles
    if strcmp(options.stat2use,'median')
        saveWithThisFilename = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','medianImages','dir',options.dir2Save);
    elseif strcmp(options.stat2use,'mean')
        saveWithThisFilename = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','averageImages','dir',options.dir2Save);
    end
    % save results to a .MAT file
    cellSelectParam = options;
    if options.motionC
        save([saveWithThisFilename '.mat'],'images','cellSelectParam','twitchFrames','twitchTimes','MCerror','expMetaData')
    else
        save([saveWithThisFilename '.mat'],'images','cellSelectParam','expMetaData')
    end
    % save results to a .TIF file
    % this code assume that channel 1 is always recorded
    if need2split
        save2TIFF(images{1},[saveWithThisFilename '-1']);
        save2TIFF(images{2},[saveWithThisFilename '-2']);
    else
        save2TIFF(images,saveWithThisFilename);
    end
end
end
function save2TIFF(data2save,saveWithThisFilename)
T = size(data2save.channel{1},3);
imwrite(uint16(data2save.channel{1}(:,:,1)),[saveWithThisFilename '.tif']);
for chNum=2:3
    if ~isempty(data2save.channel{chNum}(:,:,1))
        imwrite(uint16(data2save.channel{chNum}(:,:,1)),[saveWithThisFilename '.tif'],'WriteMode','append');
    end
end
for i = 2:T
    for chNum=1:3
        if ~isempty(data2save.channel{chNum}(:,:,i))
            imwrite(uint16(data2save.channel{chNum}(:,:,i)),[saveWithThisFilename '.tif'],'WriteMode','append');
        end
    end
end
end