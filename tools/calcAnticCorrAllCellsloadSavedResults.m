function varargout = calcAnticCorrAllCellsloadSavedResults(varargin)
% calcSTA2loadSavedResults
options = struct('dirName',[],'filename','calcAnticCorrAllCellsOutput','useShuffledMethod',false);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.dirName)
    [~,smallDataPath] = rootDirectories;
    options.dirName = smallDataPath;
end

if exist([options.dirName options.filename '.mat'],'file')~=0
    if options.useShuffledMethod 
        load([options.dirName options.filename],'anticCCControl');
        output = anticCCControl;
    else
        load([options.dirName options.filename],'anticCC');
        output=anticCC;
    end
else
    reply=input(['run pre-saccade correlation calculation on all cells\nand save results to file ' [options.dirName options.filename] '?\n[Press Enter for Y or type 0 for N]\n']);
    if isempty(reply)
        if options.useShuffledMethod
            anticCCControl = calcAnticCorrAllCells('NMF','useTwitches',false,'randomSaccadeTimes',true);
            [fList,pList] = matlab.codetools.requiredFilesAndProducts('calcAnticCorrAllCells','toponly');
            dateRun = date;
            commandOptions={'NMF','useTwitches','false','randomSaccadeTimes',true};save([smallDataPath 'calcAnticCorrAllCellsShuffledOutput'],'anticCCControl','fList','pList','dateRun','commandOptions');
        else
            runAnticCorrAllCells
        end
    else
        return
    end
end

varargout{1} = output;
end

