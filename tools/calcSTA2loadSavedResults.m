function varargout = calcSTA2loadSavedResults(varargin)
% calcSTA2loadSavedResults
options = struct('dirName',[],'filename','calcSTA2NMFOutput');
options = parseNameValueoptions(options,varargin{:});

if isempty(options.dirName)
    [~,~,fileDirs] = rootDirectories;
    options.dirName = fileDirs.sta;
end

% see createSTAs function if calcSTA2 has not yet been run
if exist([options.dirName options.filename '.mat'],'file')~=0
    load([options.dirName options.filename],'STA','STS','bt','nTrialsL','nTrialsR','STCIL','STCIU','anovaPvals','pSign','numCompPsign');
else
    reply=input(['run saccade-triggered average calculation on all cells\nand save results to file ' [options.dirName options.filename] '?\n[Press Enter for Y or type 0 for N]\n']);
    if isempty(reply)
        createSTAs
    else
        return
    end
end
varargout{1} = STA;
varargout{2} = bt;
varargout{3} = anovaPvals;
varargout{4} = nTrialsL;
varargout{5} = nTrialsR;
varargout{6} = STCIL;
varargout{7} = STCIU;
varargout{8} = STS;
varargout{9} = pSign;
varargout{10} = numCompPsign;
end

