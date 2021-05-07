function [validNMFSelector,varargout] = createFootprintSelector(varargin)
% createFootprintSelector - remove cells registered to midbrain and implement maxpeak
% dff cutoff 
% 
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
options = struct('cutCellsWLowSignal',false,'staDFFDir',[],'staDFFFilename','calcSTA2NMFOutput','lowSigPercentile',0.01,'CoorDir',[]);
options = parseNameValueoptions(options,varargin{:});


% load registered points 
Coordinates = registeredCellLocationsBigWarp('register2Zbrain',true,'NMFDir',options.CoorDir);

% determine which points are in the Midbrain
inMB = removeCellsRegistered2MB(Coordinates);

varargout{1} = inMB;
varargout{2} = Coordinates;
if options.cutCellsWLowSignal
    if isempty(options.staDFFDir)
        [~,~,fileDirs] = rootDirectories;
        options.staDFFDir = fileDirs.sta;
    end
    % determine quantile from STA computed from df/f to determine what a
    % low signal cell is 
    dffSTAStruct = load([options.staDFFDir options.staDFFFilename],'STA');
    peakSTALevels = max(squeeze(max(abs(dffSTAStruct.STA),[],2)),[],2);
    lowLevel = quantile(peakSTALevels,options.lowSigPercentile);
    
    validNMFSelector = ~inMB & (peakSTALevels >= lowLevel);
    varargout{3} = (peakSTALevels >= lowLevel);
    varargout{4} = isnan(peakSTALevels);
    varargout{5} = lowLevel;
else
    validNMFSelector = ~inMB;
end
end


