function createSTAs(varargin)
% createSTAs - wrapper to run calcSTA2
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
options = struct('dirName',[],'filename','calcSTA2NMFOutput','NMFDir',[],'PDir',[],'useTwitches',false,'runSTACIcalc',true,...
    'runAnova1',true,'useDeconvF',false,'useDeNoiseF',false,'normFunction','dff','singleCellAblationsFULL',false,...
    'Ta',-5,'Tb',5,'minNumberSaccades',5);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.dirName)
    [~,~,fileDirs] = rootDirectories;
    options.dirName = fileDirs.sta;
end

[STA,STS,bt,nTrialsL,nTrialsR,STCIL,STCIU,anovaPvals,pSign,numCompPsign] = calcSTA2('NMF',options.Ta,options.Tb,options.minNumberSaccades,'useTwitches',options.useTwitches,...
    'runSTACIcalc',options.runSTACIcalc,'runAnova1',options.runAnova1,'useDeconvF',options.useDeconvF,'useDeNoiseF',options.useDeNoiseF,'normFunction',options.normFunction,...
    'singleCellAblationsFULL',options.singleCellAblationsFULL,'NMFDir',options.NMFDir,'PDir',options.PDir);
[fList,pList] = matlab.codetools.requiredFilesAndProducts('calcSTA2');
dateRun = date;
save([options.dirName options.filename],'STA','STS','bt','nTrialsL','nTrialsR','STCIL','STCIU','anovaPvals','pSign','numCompPsign','dateRun','fList','pList','options');