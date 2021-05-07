function [coef,score,expl,mu,lon,lat,varargout] = calcSTA2runPCA(varargin)
options = struct('STA',[],'STATime',[],'dirName',[],'filename','calcSTA2NMFOutput',...
    'timeBeforeSaccade',-5,'timeAfterSaccade',5,'selectionCriteria',[],'pc1PostSTAPos',true,'normalizeSTABeforePCA',false,...
    'deconvolve',false,'pcaOnDeconv',false,'numPCCoefForDeconvFilter',10,'tauGCaMP',2,'initCondBurnTime',1000);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.STA)
    if isempty(options.dirName)
        [~,~,fileDirs] = rootDirectories;
        options.dirName = fileDirs.sta;
    end
    load([options.dirName options.filename],'STA','bt');
    STATime = bt;
else
    if isempty(options.STATime)
        error('provide an accompanying time vector for the STA that was provided');
    else
        STA = options.STA;
        STATime = options.STATime;
    end
end

% determine the sta range that will be used in the PCA analysis
[TaIndex,TbIndex]=calcSTA2Time2TimeIndex(STATime,[options.timeBeforeSaccade,options.timeAfterSaccade]);
% concatenate STAs to the left and to the right
[STA4PCAL,STA4PCAR,STACAT,tauPCA] = calcSTA2SplitSTOutput(STA,'timeAIndex',TaIndex,...
    'timeBIndex',TbIndex,'selectionCriteria',options.selectionCriteria,'STTime',STATime);
varargout{1} = STACAT;
varargout{2} = tauPCA;
varargout{3} = STA4PCAL;
varargout{4} = STA4PCAR;

if options.normalizeSTABeforePCA
    % now add normalization before pca
    STANormValues = sum(STACAT.^2,2);
    STANormValues(STANormValues==0) = 1; % completely sparse would divide by 0 otherwise
    STACATNormed=STACAT./(sqrt(STANormValues)*ones(1,size(STACAT,2)));
    [coef,score,~,~,expl,mu]=pca(STACATNormed);
else
    [coef,score,~,~,expl,mu]=pca(STACAT);
end

if options.pc1PostSTAPos
    % determine a time after saccade where PC 1 should be positive
    [posTimeIndex]=calcSTA2Time2TimeIndex(tauPCA,1);
    if coef(posTimeIndex,1)<0
        coef(:,1)=-1*coef(:,1);
        score(:,1) = -1*score(:,1);
    end
end

if options.deconvolve
    % filter data first with PCA
    if ischar(options.numPCCoefForDeconvFilter)
        options.numPCCoefForDeconvFilter = size(score,2);
    end
    STACATFiltered = ones(size(STACAT,1),1)*mu + score(:,1:options.numPCCoefForDeconvFilter)*coef(:,1:options.numPCCoefForDeconvFilter)';
    STACATD = linearDeconvolution(STACATFiltered,'tauGCaMP',options.tauGCaMP,'time',tauPCA,'initCondBurnTime',options.initCondBurnTime);
    if options.pcaOnDeconv
        % overwrite PCA output with linearly deconvolved STA
        [coef,score,~,~,expl,mu]=pca(STACATD);
    end
end
[lon,lat,scoreNormed,snorms,S,h] = normedScoresSpherCoord(score);
varargout{5} = scoreNormed;
varargout{6} = snorms;
varargout{7} = S;
varargout{8} = h;
if options.deconvolve
    varargout{9} = STACATD;
    varargout{10} = STACATFiltered;
    if options.normalizeSTABeforePCA
        varargout{11} = STACATNormed;
    end
elseif options.normalizeSTABeforePCA
    varargout{9} = STACATNormed;
end

end

