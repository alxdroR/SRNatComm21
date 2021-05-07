function [actualTime] = eyeTime2AblationRelTime(eyeobj,varargin)
options = struct('stackTimes',[],'expDates',[],'animalNumbers',[],'ablationTimeMeta',[],'useFirstAblation',true,'planeIndex',1,'time',[]);
options = parseNameValueoptions(options,varargin{:});

% the user is allowed to send in any time (in seconds) to calculate, not just the time
% property of eyeobj.
if isempty(options.time)
    if isnumeric(options.planeIndex)
        origTime = eyeobj.time{options.planeIndex}./3600;
    else
        origTime = cellfun(@(x) x./3600,eyeobj.time,'UniformOutput',false);
    end
else
    origTime = options.time./3600;
    if size(origTime,2) > size(origTime,1)
        origTime = origTime';
    end
end


% construct the date and animal recorded based on filenaming convention for
% data recorded in 2019
dateNumDivider = regexp(eyeobj.fishID,'_');
expDate = eyeobj.fishID(1:dateNumDivider(1)-1);
animalNumber = eyeobj.fishID(dateNumDivider(1)+1:dateNumDivider(2)-1);

if isempty(options.stackTimes)
    [~,stackTimes,expDates,animalNumbers] = grabBehaviorVideoFilenames;
    % add a check to make sure expDates and animalNumbers are supplied
    fcount = find(cellfun(@(x) strcmp(x,expDate),expDates) & cellfun(@(x) strcmp(x,animalNumber),animalNumbers));
    if isempty(fcount)
        error('animal %s_%s was not used by functions collecting time meta data',expDate,animalNumber);
    end
    
    stackTimes = stackTimes(fcount);
else
    stackTimes = options.stackTimes;
    
end

if isempty(options.ablationTimeMeta)
    if ~isempty(options.stackTimes)
        expDates = options.expDates;
        animalNumbers = options.animalNumbers;
        fcount = find(cellfun(@(x) strcmp(x,expDate),expDates) & cellfun(@(x) strcmp(x,animalNumber),animalNumbers));
    end
    ablationTimeMeta = grabAblEndTimeFromFilename;
    ablationTimeMeta = ablationTimeMeta(fcount);
else
    ablationTimeMeta = options.ablationTimeMeta;
end

if options.useFirstAblation
    zeroHour = ablationTimeMeta.fractionalHour(1);
else
    zeroHour = ablationTimeMeta.fractionalHour(end);
end


if ~isempty(stackTimes.(eyeobj.expCond))
    if isnumeric(options.planeIndex)
        fileModTime = stackTimes.(eyeobj.expCond){options.planeIndex};
        modTimeFracHour = hour(fileModTime) + minute(fileModTime)/60 + second(fileModTime)/(60*60);
        
        recStartTimeFracHour = bsxfun(@minus,modTimeFracHour,origTime(end,:));
        % change time to be the fractional hour that everything was recorded
        actualTime = bsxfun(@plus,origTime,recStartTimeFracHour-zeroHour);
        
        % convert to minutes
        actualTime = actualTime.*60;
    else
        modTimeFracHour = cellfun(@(x) hour(x) + minute(x)/60 + second(x)/(60*60),stackTimes.(eyeobj.expCond),'UniformOutput',false);
        recStartTimeFracHour = cellfun(@(x,y) bsxfun(@minus,y,x(end,:)),origTime,modTimeFracHour,'UniformOutput',false);
        actualTime = cellfun(@(x,y) bsxfun(@plus,x,y-zeroHour),origTime,recStartTimeFracHour,'UniformOutput',false);
        % convert to minutes
        actualTime = cellfun(@(x) x.*60,actualTime,'UniformOutput',false);
    end
    
else
    actualTime = NaN;
end

end

