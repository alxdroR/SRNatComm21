classdef figures < nicePlot
    %figures - superclass containing basic properties/methods that all figure
    %panels will have
    %
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        data
        filename % the name of the file calling the figurePanel constructor
        paperPosition
    end
    
    methods
        function obj = figures
        end
        
        function printFigure(obj)
            if isempty(obj.data)
                printAndSave(obj.filename)
            else
                printAndSave(obj.filename,'data',obj.data)
            end
        end
        function obj=loadData(obj,varargin)
            global figureAndFilename
            options = struct('sourceDataFile',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            % try to load data
            if isempty(options.sourceDataFile)
                sourceDataFile = [];
                % try and construct filename with global variables
                resultDir = path2SaveResults;
                if isfield(figureAndFilename,obj.filename)
                    name2saveresults = figureAndFilename.(obj.filename);
                    sourceDataFile = [resultDir name2saveresults];
                else
                    warning('Cannot automaticaly construct filename');
                end
                
            else
                sourceDataFile = options.sourceDataFile;
            end
            if exist(sourceDataFile,'file')==2
                load(sourceDataFile,'data')
            else
                error('Given sourceDataFile does not exist');
            end
            % data structure should be loaded if it exists
            if ~exist('data','var')
                error('Plot requires a `data` structure containing the data to plot\n');
            else
                obj.data = data;
            end
        end
        function txtIntro = constructDataIntro(obj,varargin)
            options = struct('figName',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            global figureAndFilename
            % name of sourceData File
            if isfield(figureAndFilename,obj.filename)
                name2SaveResults = figureAndFilename.(obj.filename);
            else
                name2SaveResults = '';
            end
            txtIntro = sprintf('%s is a MATLAB.mat file containing a structure named `data` that has all the data required to plot figure %s\n',name2SaveResults,options.figName);
        end
    end
end

