function [sigLeft,sigRight,varargout] = createSRCellSelector(varargin)
options = struct('dirName',[],'filename','calcAnticCorrAllCellsOutput','level',1e-2,'selectionCriteria',[],'useShuffledMethod',false,'anticCC',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.dirName)
    [~,~,fileDirs] = rootDirectories;
    options.dirName = fileDirs.ccTimeBeforeSaccade;
end

if isempty(options.anticCC)
    anticCC = calcAnticCorrAllCellsloadSavedResults('dirName',options.dirName,'filename',options.filename,'useShuffledMethod',false);
else
    anticCC = options.anticCC;
end
if options.useShuffledMethod
    % This was an alternate approach for SR cell selection proposed by a
    % reviewer. The threshold for selection is based on a fixed threshold calculated from a suffled distribution.
    % Since the shuffled distribution only needs to be computed for one
    % large data set, this approach has the benefit of having a fixed
    % threshold for all fish. 
    anticCCControl = calcAnticCorrAllCellsloadSavedResults('dirName',options.dirName,'filename','calcAnticCorrAllCellsShuffledOutput','useShuffledMethod',options.useShuffledMethod);
    ccvalues = anticCC(:,1:2);
    ccvaluesControl = anticCCControl(:,1:2);
    sigThreshold = quantile([ccvaluesControl(options.selectionCriteria,1);ccvaluesControl(options.selectionCriteria,2)],1-options.level);
    Hcc = ccvalues(options.selectionCriteria,:)>=sigThreshold;
else
    % Base selection on p-value of correlation results using a
    % Holm-Bonferroni correction
    pvalues = anticCC(:,3:4);
    [~,~,Hcc] = selectHolmBonSignCells(pvalues,'level',options.level,'selectionCriteria',options.selectionCriteria);
end
% create selector for direction-selective cells
N = size(anticCC,1);
sigLeft =  false(N,1);sigRight =  false(N,1);
sigLeft(options.selectionCriteria) = Hcc(:,1) & ~Hcc(:,2);
sigRight(options.selectionCriteria) = ~Hcc(:,1) & Hcc(:,2);

varargout{1} = Hcc;
varargout{2} =  [find(sigLeft);find(sigRight)];
varargout{3} = anticCC;
end

