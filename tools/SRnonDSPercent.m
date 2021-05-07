function SRnonDSPercent(varargin)
% SRnonDSPercent

options = struct('Hcc',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.Hcc)
% load Eye-movement related and Anticipatory cells to obtain many of the numbers below
loadAnticipatorySelectionCriteria
else
    Hcc = options.Hcc;
end

nonDirSelective = sum(Hcc(:,1) & Hcc(:,2));
fprintf('\n\n...occasions where dF/F was significantly correlated with\n upcoming saccades in both directions (n=%d cells, not shown)\n\n',nonDirSelective);

