function [STA,STS,bt,nTrialsL,nTrialsR,STCIL,STCIU,anovaPvals,varargout] = calcSTA2(cellFinderMethod,Ta,Tb,minNumFixations,varargin)
options = struct('noiseControl',false,'useTwitches',true,'runSTACIcalc',false,'runAnova1',false,...
    'expcond','before','useDeconvF',false,'useDeNoiseF',false,'normFunction','dff','singleCellAblationsFULL',false,...
    'NMFDir',[],'PDir',[],'eyeIndex',1);
options = parseNameValueoptions(options,varargin{:});
options.dir = options.NMFDir; % for totalNumberCells
if strcmp(cellFinderMethod,'BASet')
    [~,~,ID] = totalNumberCellsBASet(options.expcond);
    fid = {'H','X','K','C','D','E'};
else
    [~,numPlanesV] = totalNumberCells(cellFinderMethod,varargin{:});
    fid = listAnimalsWithImaging(varargin{:});
end
STA = [];STS=[];
nTrialsL = []; nTrialsR = [];
STCIL = []; STCIU = [];
anovaPvals = [];
PSIGN = cell(length(fid),1);
numCompPSign = cell(length(fid),1);
for expIndex =1 : length(fid)
    if strcmp(cellFinderMethod,'BASet')
        planeIndices = unique(ID(ID(:,1)==expIndex,2))';
    else
        planeIndices = 1 : numPlanesV(expIndex);
    end
    PSIGN{expIndex} = cell(max(planeIndices),1);
    numCompPSign{expIndex} = cell(max(planeIndices),1);
    [DFF,imageTime,saccadeTimes,saccadeDirection] = loadDataForSNR(expIndex,cellFinderMethod,...
            'useTwitches',options.useTwitches,'useDeconvF',options.useDeconvF,'useDeNoiseF',options.useDeNoiseF,'normFunction',options.normFunction...
            ,'singleCellAblationsFULL',options.singleCellAblationsFULL,'NMFDir',options.NMFDir,'PDir',options.PDir);
    for planeIndex = planeIndices
        [sta,sts,bt,nTL,nTR,CIL,CIU,pvals,psign,numComp]=calcSTASTSSinglePlane(DFF{planeIndex},imageTime{planeIndex},...
            saccadeTimes{planeIndex}{options.eyeIndex},saccadeDirection{planeIndex}{options.eyeIndex},Tb,Ta,minNumFixations,...
            'runSTACIcalc',options.runSTACIcalc,'runAnova1',options.runAnova1);
        STA = [STA;sta];
        STS = [STS;sts];
        nTrialsL = [nTrialsL;nTL];
        nTrialsR = [nTrialsR;nTR];
        STCIL = [STCIL;CIL];
        STCIU = [STCIU;CIU];
        anovaPvals = [anovaPvals;pvals];
        PSIGN{expIndex}{planeIndex} = psign;
        numCompPSign{expIndex}{planeIndex} = numComp;
    end
end
varargout{1} = PSIGN;
varargout{2} = numCompPSign;
end

