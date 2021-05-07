function [y,imageTime,saccadeTimes,saccadeDirection,varargout] = loadDataForSNR(ID,cellFinderMethod,varargin)

options = struct('useTwitches',true,'expcond','before','eyeIndex',1,'useDeconvF',false,'useDeNoiseF',false,'normFunction','dff','NMFDir',[],'PDir',[]);
options = parseNameValueoptions(options,varargin{:});

if size(ID,2) == 1 
    planeIndex = 'all';
elseif size(ID,2) == 2 
    planeIndex = ID(1,2);
end
expIndex = ID(1,1);

if strcmp(cellFinderMethod,'BASet')
    fid = {'H','X','K','C','D','E'};
else
    [fid,expCond] = listAnimalsWithImaging(varargin{:});
end
eyeobj = eyeData('fishid',fid{expIndex},'expcond',expCond{expIndex},'PDir',options.PDir);
if strcmp(cellFinderMethod,'NMF')
    caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'NMF',true,'loadImages',false,'loadCCMap',false,'NMFDir',options.NMFDir);
elseif strcmp(cellFinderMethod,'CCEyes')
    caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'EPSelectedCells',false,'loadImages',false,'loadCCMap',false);
elseif strcmp(cellFinderMethod,'BASet')
    caFileName = getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','catraces');
    caFileNameBAR = [caFileName 'BARedux'];
    load(caFileNameBAR)
    load([caFileNameBAR(1:end-13) 'matchPoints.mat'])
    if strcmp(expCond{expIndex},'before')
        F = yB;
        ctr = mpB;
    elseif strcmp(expCond{expIndex},'after')
        F = yA;
        ctr = mpA;
        caFileNameB = getFilenames(fid{expIndex},'expcond','before','fileType','catraces');
        caFileNameB = [caFileNameB 'BARedux'];
        load([caFileNameB(1:end-13) 'matchPoints.mat'])
    end
    Tv = cellfun(@(x) size(x,1),F);
    imageTime = recordingTimeEstimate(ctr,Tv,'expFilename',caFileName);
    imageTime = imageTime{planeIndex};
    
    load([caFileName '_EPSelect'],'twitchFrames')
end
eyeobj = eyeobj.saccadeDetection;

if ~strcmp(cellFinderMethod,'BASet')
    if options.useDeconvF
        F=caobj.nmfDeconvF;
    elseif options.useDeNoiseF
        F=caobj.nmfDenoiseF;
    else
        F = caobj.fluorescence;
    end
    if ischar(planeIndex)
        twitchFrames = caobj.twitchFrames;
        imageTime = caobj.time;
    else
        twitchFrames = caobj.twitchFrames{planeIndex};
        imageTime = caobj.time{planeIndex};
        F = F{planeIndex};
    end
end

if ~options.useTwitches
    F = replaceTwitchSamplesWithNaN(F,twitchFrames);
end
if strcmp(options.normFunction,'dff')
    normFnc = @dff;
elseif strcmp(options.normFunction,'zscore')
    normFnc = @(x) (x - nanmean(x))./nanstd(x);
else
    normFnc = @(x) x;
end
if ischar(planeIndex)
    y = cell(length(F),1);
    for k = 1 : length(F)
        y{k} = normFnc(F{k});
    end
else
    y = normFnc(F);
end

if length(ID)>2
    cellIndex = ID(:,3);
    y = y(:,cellIndex);
    imageTime = imageTime(:,cellIndex);
end
if ischar(planeIndex)
    saccadeTimes = eyeobj.saccadeTimes;
    saccadeDirection = eyeobj.saccadeDirection;
else
    saccadeTimes = eyeobj.saccadeTimes{planeIndex}{options.eyeIndex};
    saccadeDirection = eyeobj.saccadeDirection{planeIndex}{options.eyeIndex};
end
varargout{1}=eyeobj;
if ~strcmp(cellFinderMethod,'BASet')
    varargout{2}=caobj;
end
end

