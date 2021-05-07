function printAndSave(nameOfFileCalling,varargin)
% printAndSave(nameOfFileCalling) - prints current figure to dir specified
% in figurePanelPath.m. Can also save data to dir specified in
% path2SaveResults.m 
% 
% Input: 
% nameOfFileCalling - string specifying name to use when printing figure
%
% If user sets the global variable printOn to true, printAndSave will run
% the print command using nameofFileCalling as the filename. A script calling printAndSave can determine its filename 
% by running mfilename. 
% 
% OPTIONAL :
% If user sets the global variable saveResults to true, 
% calling printAndSave(nameOfFileCalling,'data',d)
% will save the data stored in d. This option was meant for automatically saving results used in 
% the Ramirez_Aksay 2020 paper and is more cumbersome to use than the save command. The results are saved in a directory specified in
% path2SaveResults.m. The user must also create a global structure called
% figureAndFilename. figureAndFilename must have a field whose name equals
% the string specified in 'nameofFileCalling'. The value of the field must
% be a string specifying what name to use when saving the data 
% 
% calling printAndSave(nameOfFileCalling,'formattype',formatString)
% The string formatString specifies the formattype variable to use in the
% print command
% 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 

% extract optional input
options = struct('data',[],'formattype','-dpdf','addPrintOps',[]);
options = parseNameValueoptions(options,varargin{:});


global printOn saveResults figureAndFilename

% only print and save if user has set these variables to true 
if isempty(saveResults)
    saveResults = false;
end

if isempty(printOn)
    printOn = false;
end

if printOn
    figurePDir = figurePanelPath;
    if isempty(nameOfFileCalling)
        error('To print, you must either run the file using `Run` or manually enter the print command into the command window');
    end
    fprintf('printing to\ndirectory:%s\nwith name:%s\nas type:%s\n...\n',figurePDir,nameOfFileCalling,options.formattype)
    if ~isempty(options.addPrintOps)
        print(gcf,options.formattype,options.addPrintOps,[figurePDir nameOfFileCalling])
    else
        print(gcf,options.formattype,[figurePDir nameOfFileCalling])
    end
end

if saveResults
    if isempty(figureAndFilename)
        error('NAME TO SAVE RESULTS NOT SPECIFIED: user did not create figureAndFilename global. see ramirezAksay2020_natcomm_allscripts_master.m for an example')
    end
    
    if isempty(options.data)
        error('DATA TO SAVE NOT SPECIFIED: data,d, must be specified with a call printAndSave(nameOfFileCalling,''data'',d)');
    else
        data = options.data;
    end
    
    resultDir = path2SaveResults;
    if isempty(nameOfFileCalling)
        error('To print, you must either run the file using `Run` or manually enter the print command into the command window');
    end
    
    try 
        name2saveresults = figureAndFilename.(nameOfFileCalling);
    catch me 
        fprintf('The global variable must have a fieldname that equals %s.\nThe value of the field is the name used to save the data\n',nameOfFileCalling)
        fprintf('%s:%s\n',me.identifier,me.message);
    end
    fprintf('saving results to\ndirectory:%s\nwith name:%s\n...\n',resultDir,[name2saveresults '.mat'])
    save([resultDir name2saveresults '.mat'],'data')
end
end

