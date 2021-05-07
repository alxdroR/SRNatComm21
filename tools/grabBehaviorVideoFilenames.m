function [stackPaths,stackTimes,expDates,animalNumbers] = grabBehaviorVideoFilenames
%expDates =      {'51419','51519','51519','51619','51619','52219','52219','52319','52319','52419','52919','53019','6519','6519','6619','6619','61219','61919','62019','62019','7119','7319','71019','71119','71119'};
%animalNumbers = {'1',     '1',      '2',    '1',    '2',   '1',     '2',        '1',    '2',    '1',    '1',   '1','1',   '2',    '1' ,   '2','1','1','1','2','1','1','1','1','2'};

[~,~,expDates,animalNumbers] = listAnimalsWithImaging('singleCellAblations',true);

fileDelim = fileDelimeter;
rootDataStorage = '/Volumes/Samsung_T5/singleCellAblations/rawVideos/';
stackFiles = dir(rootDataStorage);

numAnimals = length(expDates);
stackPaths = struct('before',cell(numAnimals,1),'during',cell(numAnimals,1),'after',cell(numAnimals,1));
stackTimes = struct('before',cell(numAnimals,1),'during',cell(numAnimals,1),'after',cell(numAnimals,1));

for expCounter=1:length(expDates)
    expDate = expDates{expCounter};
    animalNumber = animalNumbers{expCounter};
    
    for i = 1 : length(stackFiles)
        if( ~stackFiles(i).isdir )
            animalIDPattern = ['f' expDate '_' animalNumber];
            if ~isempty(regexp(stackFiles(i).name,[animalIDPattern '_B_\d*.avi'], 'once'))
                stackPaths(expCounter).before = [stackPaths(expCounter).before;{[stackFiles(i).folder fileDelim stackFiles(i).name]}];
                stackTimes(expCounter).before = [stackTimes(expCounter).before;{datetime(stackFiles(i).date)}];
            elseif ~isempty(regexp(stackFiles(i).name,[animalIDPattern '_A_\d*.avi'], 'once'))
                stackPaths(expCounter).after = [stackPaths(expCounter).after;{[stackFiles(i).folder fileDelim stackFiles(i).name]}];
                stackTimes(expCounter).after = [stackTimes(expCounter).after;{datetime(stackFiles(i).date)}];
            elseif ~isempty(regexp(stackFiles(i).name,[animalIDPattern '_during_\d*.avi'], 'once'))
                stackPaths(expCounter).during = [stackPaths(expCounter).during;{[stackFiles(i).folder fileDelim stackFiles(i).name]}];
                stackTimes(expCounter).during = [stackTimes(expCounter).during;{datetime(stackFiles(i).date)}];
            end
        end
    end
    
end
end