function [hbPassingCellsBOOL,varargout] = selectHolmBonSignCells(pvals,varargin)
%options.level  significance level
options = struct('level',1e-2,'selectionCriteria',[]);
options = parseNameValueoptions(options,varargin{:});

if ~isempty(options.selectionCriteria)
    N = length(pvals);
    pvals = pvals(options.selectionCriteria,:);
end


H = holmBonCorrection(pvals,options.level);
if ~isempty(options.selectionCriteria)
    hbPassingCellsBOOL = false(N,1);
    hbPassingCellsBOOL(options.selectionCriteria) = (H(:,1) | H(:,2));
else
    hbPassingCellsBOOL = (H(:,1) | H(:,2));
end
varargout{1} = pvals;
varargout{2} = H;
end

