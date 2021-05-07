function [allData,animals,indices2keep] = gatherPreSaccadeEventTraces(F,TF,onDirection,IDsFromCellsOfInterest,ISIBounds,varargin)
options = struct('binTimes',0:1/3:30,'ISIwidth',1,'tau','past saccade','cutTimeGTISI',true,'NaNInvalidPoints',false,'randomSaccadeTimes',false);
options = parseNameValueoptions(options,varargin{:});


ISImin = ISIBounds(1);
ISImax = ISIBounds(2);
numConditions = ISImax - ISImin + 1; % number of ISI values we calculate population average at time of saccade
binTimes = options.binTimes;
allData = cell(numConditions,1);
animals = cell(numConditions,1);
indices2keep = [];
for ISIFix = ISImin:ISImax
    % segment the input data according to activity after a saccade
    [dFFISI,binTimes,animalOut,keptIndices]=loadSingleTrialResponses(F,TF,IDsFromCellsOfInterest,'direction','preceeding ON','ONdirection',onDirection,'cells','all',...
        'interp2gridThenCat',true,'binTimes',binTimes,'tau',options.tau,'ISI',ISIFix+0.5,'ISIwidth',options.ISIwidth,'randomSaccadeTimes',options.randomSaccadeTimes);
    if options.cutTimeGTISI
        maxTimeIndex = find(abs(binTimes)>=ISIFix,1);
        % the only relevant portion for the test is activity at ISI
        allData{ISIFix-ISImin+1} = dFFISI(:,1:maxTimeIndex);
        animals{ISIFix-ISImin+1} = animalOut;
    else
        allData{ISIFix-ISImin+1} = dFFISI;
        animals{ISIFix-ISImin+1} = animalOut;
    end
    if options.NaNInvalidPoints
        %numSamplesVsTimeISI = sum(~isnan(allData{ISIFix-ISImin+1})); validPoints = (numSamplesVsTimeISI == numSamplesVsTimeISI(end));
        [~,minind] = min(abs(-ISIFix-binTimes)); validPoints = false(1,length(binTimes));validPoints(minind:length(binTimes))=true;
        allData{ISIFix-ISImin+1}(:,~validPoints) = NaN;
       % fprintf('Number of cells cut-off being used = %d\n',numSamplesVsTimeISI(end))
    end
    indices2keep = [indices2keep;keptIndices];
end
end

