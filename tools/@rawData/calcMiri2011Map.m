function [rawobj,fluorescence,localCoordinates,A] = calcMiri2011Map(rawobj,varargin)
options = struct('vpniObj',[],'channel',1,...
    'motionC',false,'useTwitchDetector',false,'tau',1.83,'midlineYLocation','centered',...
    'runMxCCCellExtraction',false,'preAverage',false,'exclusionDistMu',4,'exclusionDistPix',[],'minCCPix',0.2,'minCCAvg',0.2,'nucSize',3,'edgeExclusionPixels',13);
options = parseNameValueoptions(options,varargin{:});

% Data loading (dimensions are part of options)
rawobj = rawobj.updateMovies(varargin{:});
rawobj.ccMap =cell(1,1);
if options.motionC
    [H,W,T] = size(rawobj.moviesMC{1}.channel{options.channel}); % size of movies
else
    [H,W,T] = size(rawobj.movies{1}.channel{options.channel}); % size of movies
end

if ischar(options.midlineYLocation)
    if strcmp(options.midlineYLocation,'centered')
        options.midlineYLocation = H/2;
    elseif strcmp(options.midlineYLocation,'auto')
        options.midlineYLocation = rawobj.estimateMidlineLocation(varargin{:});
    end
end
% The miri map needs to know midline location to compute ipsiversive
% saccades
leftRightPixelCoordinates = repmat((1:H)',1,W);
if isnumeric(options.midlineYLocation)
    inLeftHemisphere = leftRightPixelCoordinates > options.midlineYLocation;
elseif isa(options.midlineYLocation,'function_handle')
    YHemiTh = options.midlineYLocation(1:W,rawobj.fileIndex);
    inLeftHemisphere = leftRightPixelCoordinates > YHemiTh;
end
inLeftHemisphere = inLeftHemisphere(:);
if isempty(options.vpniObj)
    error('vpniObj required')
else
    vpniObj = options.vpniObj;
    vpniObj.yIsInLeftHemi = inLeftHemisphere;
end
if isempty(options.exclusionDistPix)
    exclusionDistPix = rawobj.mic2pix(options.exclusionDistMu,rawobj.metaData{1});
else
    exclusionDistPix = options.exclusionDistPix;
end
if options.preAverage
    % spatially-average pixels before correlating with eye position
    %  [ctr,binsInAvg] = dsInput4nnaverage(H,W,exclusionDistPix,'computeBinsInAverage',true);
    ctr = 'all';
    boxRgnObj = rectImgRgns('length',exclusionDistPix,'width',exclusionDistPix,'imgSize',[H,W]);
    if options.motionC
        % spatially average movie
        Fmat=rawData.nnaverage(rawobj.moviesMC{1}.channel{options.channel},ctr,boxRgnObj);
        rawobj.moviesMC = [];
    else
        % spatially average movie
        Fmat=rawData.nnaverage(rawobj.movies{1}.channel{options.channel},...
            ctr,exclusionDistPix);
    end
    rawobj.moviesSA{1} = Fmat;
else
    if options.motionC
        Fmat = reshape(rawobj.moviesMC{1}.channel{options.channel},[H*W,T]);
    else
        Fmat = reshape(rawobj.movies{1}.channel{options.channel},[H*W,T]);
    end
    Fmat = Fmat';
    Fmat = single(Fmat);
end
vpniObj.y0 = single(Fmat);
if options.useTwitchDetector
    vpniObj.missingSamples = rawobj.twitchFrames;
end
[cc,pvals,Zscores] = vpniObj.Miri2011('indexOfLeftEye',1,'eye2Use','ipsi','computeZScores',true,'compCCPValTh',false,'removeMissingSamples',options.useTwitchDetector,'tau',options.tau);
cc = cc';
pvals = pvals';
p = size(cc,2);
ccFull = reshape(cc,[H,W,p]);
pvalFull = reshape(pvals,[H,W,p]);
ZscoreFull = reshape(Zscores',[H,W,p]);
fluorescence =  [];
localCoordinates =  [];
A  =[];
if options.runMxCCCellExtraction
    maxcc = max(abs(ccFull),[],3);
    numSizePix = rawobj.mic2pix(options.nucSize,rawobj.metaData{1});
    maxCCCoord=rawData.getCCIndices(maxcc,options.minCCPix,exclusionDistPix,options.edgeExclusionPixels,rawobj.images.channel{1},exclusionDistPix);
    if ~isempty(maxCCCoord)
        % find out which cells to keep
        fpCreator = circleImgRgns('radius',numSizePix,'imgSize',[H,W]);
        ccAvg = rawobj.nnaverage(maxcc,maxCCCoord,fpCreator);
        keepThisCell = ccAvg >= options.minCCAvg;
        numCells2Keep = sum(keepThisCell);
        if numCells2Keep > 0
            maxCCCoord = maxCCCoord(keepThisCell,:);
            ccAvg = ccAvg(keepThisCell);
            if options.preAverage
                [y,A] = rawobj.nnaverage(rawobj.moviesSA{1}.channel{options.channel},maxCCCoord,fpCreator,'chunkSize',numCells2Keep);
            else
                % average fluorescence within a box surronding the ROI
                if options.motionC
                    [y,A] = rawobj.nnaverage(rawobj.moviesMC{1}.channel{options.channel},maxCCCoord,fpCreator,'chunkSize',numCells2Keep);
                else
                    [y,A] = rawobj.nnaverage(rawobj.movies{1}.channel{options.channel},maxCCCoord,fpCreator,'chunkSize',numCells2Keep);
                end
            end
            % sort traces by correlations
            [~,srtind]=sort(ccAvg,'descend');
            fluorescence =  y(:,srtind);
            localCoordinates =  maxCCCoord(srtind,:);
            A = sparse(A(:,srtind));
        end
    end
end
rawobj.ccMap = ccFull;
rawobj.zScoreMap = ZscoreFull;
rawobj.ccPvals = pvalFull;
end % end correlation map
