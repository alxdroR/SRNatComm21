function [timeInfo,parsedAblMetaFiles,expDates,animalNumbers] = grabAblEndTimeFromFilename
%[parsedAblMetaFiles,expDates,animalNumbers] = constructOldAblationTimeLocationFiles;
[parsedAblMetaFiles,expDates,animalNumbers] = grabAblationTimeFilenames;
fileDelim = fileDelimeter;
numAnimals = length(parsedAblMetaFiles);

timeInfo = struct('hour',cell(numAnimals,1),'min',cell(numAnimals,1),'fractionalHour',cell(numAnimals,1));
for fcount = 1 : numAnimals
    
        numFiles = length(parsedAblMetaFiles(fcount).times);
        timeInfo(fcount).hour = cell(numFiles,1);
        timeInfo(fcount).min = cell(numFiles,1);
        timeInfo(fcount).fractionalHour = zeros(numFiles,1);
        for fileIndex = 1 : numFiles
            fullPath = parsedAblMetaFiles(fcount).times{fileIndex};
            indicesOfFileDelim = regexp(fullPath,fileDelim); % all the / or \ in the filename
            keepFromStartToThisIndex = indicesOfFileDelim(end); % the last file delimeter is where the filename starts
            name = fullPath(keepFromStartToThisIndex+1:end);
            
            % get the date/time information
            indexOfDateTime = regexp(name,'ROIHopTimes-','end');
            dateTimeInfo = name(indexOfDateTime+1:end-4);
            infoDividerIndices=regexp(dateTimeInfo,'-');
            hourValue = dateTimeInfo(infoDividerIndices(3)+1:infoDividerIndices(4)-1);
            minValue = dateTimeInfo(infoDividerIndices(4)+1:length(dateTimeInfo));
         %  fprintf('%s: hour=%s, minute=%s\n',name,hourValue,minValue);
           
           timeInfo(fcount).hour{fileIndex} = hourValue;
           timeInfo(fcount).min{fileIndex} = minValue;
           timeInfo(fcount).fractionalHour(fileIndex) = str2double(hourValue) + str2double(minValue)/60;
        end
end