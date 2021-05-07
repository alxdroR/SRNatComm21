function runAnticCorrAllCells(varargin)
% runAnticCorrAllCells - wrapper to run calcAnticCorrAllCells
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
options = struct('useTwitches',false,'dirName',[],'filename','calcAnticCorrAllCellsOutput');
options = parseNameValueoptions(options,varargin{:});

if isempty(options.dirName)
    [~,~,fileDirs] = rootDirectories;
    options.dirName = fileDirs.ccTimeBeforeSaccade;
end
anticCC=calcAnticCorrAllCells('NMF',varargin{:});
[fList,pList] = matlab.codetools.requiredFilesAndProducts('calcAnticCorrAllCells');
dateRun = date;
save([options.dirName options.filename],'anticCC','fList','pList','dateRun','options');
