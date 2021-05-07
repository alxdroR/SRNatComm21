function [STACriteria,varargout] = createEyeMovementSelector(varargin)
options = struct('dirName',[],'filename','calcSTA2NMFOutput','level',1e-2,'selectionCriteria',[]);
options = parseNameValueoptions(options,varargin{:});


[STA,bt,anovaPvals,nTrialsL,nTrialsR,STCIL,STCIU,STS,pSign,numCompPsign]=calcSTA2loadSavedResults('dirName',options.dirName,'filename',options.filename);
[STACriteria,anovaPKeep] = selectHolmBonSignCells(anovaPvals,'level',options.level,'selectionCriteria',options.selectionCriteria);

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
varargout{11} = options.level;
varargout{12} = anovaPKeep;
end

