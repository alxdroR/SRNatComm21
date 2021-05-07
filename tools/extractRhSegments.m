%function [groupedStatistic,groupedLocation,statisticMatrix,columnNames,options] = extractRhSegments(location,statistic,varargin)
function varargout = extractRhSegments(location,statistic,varargin)

% [groupedStatistic,groupedLocation] = extractRhSegments(location,statistic)
% 
%       Based on the value of location, this function groups the corresponding
%  statistic value into 1 of 4 categories: rostral,middle,caudal,tail. The
%  dividing lines of these fields can be changed using Name/value properties.
% 
%  INPUT
%  Nx1 vectors location and statistic
% 
%  OUPUT 
%  groupedStatistic is a structure with fields:
%  'rostral','middle','caudal','tail'
%  which contain the values of statistic grouped into these fields. 
%  groupedLocation is a structure with the same fields as groupedStatistic 
%  containing grouping indices for each region
%
%  NAME/VALUE options
%  'rostral' - [x1,x2] where x1 and x2 specify the start and stop of hte
%  rostral borders.  Same goes for 'middle','caudal' and 'tail'
%
% [groupedStatistic,groupedLocation,statisticMatrix,columnNames] = extractRhSegments(location,statistic)
%   
%   statisticMatrix groups the statistic values into a matrix with each
%   column representing a category.  The columns are arranged to contain 
%   rostral,middle,caudal,tail.  The columnNames cell array contains the
%   corresponding names.  This function uses NaNs to equalize the number of
%   rows between columns when sample sizes are unequal.
  
options = struct('groupNames',[],'rostral',[0 450],'middle',[450 800],'caudal',[800 1350],'tail',[1400 1400],'borderStructure',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.groupNames)
    if isempty(options.borderStructure)
        % no new names were suppled. Use default names
         options.groupNames = {'rostral','middle','caudal','tail'};
         options.borderStructure = struct('rostral',options.rostral,'middle',options.middle,'caudal',options.caudal,'tail',options.tail);
    else
        % potential new names were supplied 
        borderStructNames = fieldnames(options.borderStructure);
        numNames = length(borderStructNames);
        options.groupNames = cell(numNames,1);
        for i = 1 : numNames
            options.groupNames(i) = borderStructNames(i);
        end
    end
elseif isempty(options.borderStructure)
    error('If groupNames is not empty, you must supply the structure borderStructure giving the boundaries for each field name listed in groupNames');
end
if nargin>=2
    if length(location)~=length(statistic)
        error('Each value in the input statistic needs a corresponding location value');
    end
    
    createMatrix = true;
    if iscell(statistic)
        statistic = cat(1,statistic);
        createMatrix = false;
    end
    
    columnNames = options.groupNames;
    %groupedStatistic = struct('rostral','middle','caudal','tail');
     groupedStatistic = struct(columnNames{1},[]); % there is at least 1 field name
    groupedLocation = groupedStatistic;
    
    % group into groupedStatistic structure
    numberSamples = zeros(1,length(columnNames));
    for j=1:length(columnNames)
       % groupingIndex = location >= options.(columnNames{j})(1) & location <= options.(columnNames{j})(2);
         groupingIndex = location >= options.borderStructure.(columnNames{j})(1) & location <= options.borderStructure.(columnNames{j})(2);
        groupedStatistic.(columnNames{j}) = statistic(groupingIndex);
        groupedLocation.(columnNames{j}) = groupingIndex;
        numberSamples(j) = sum(groupingIndex);
    end
    
    if createMatrix
        % create grouped matrix
        maxNumSamp = max(numberSamples);
        statisticMatrix = zeros(maxNumSamp,length(columnNames));
        for j=1:length(columnNames)
            statisticMatrix(:,j) = [groupedStatistic.(columnNames{j});NaN(maxNumSamp-numberSamples(j),1)];
        end
    else
        statisticMatrix = NaN;
    end
    varargout{1} = groupedStatistic;
    varargout{2} = groupedLocation;
    varargout{3} = statisticMatrix;
    varargout{4} = columnNames;
    varargout{5} = options;
else
    varargout{1} = options;
end

end

