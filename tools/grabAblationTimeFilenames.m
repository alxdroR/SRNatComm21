function [stackPaths,expDates,animalNumbers] = grabAblationTimeFilenames
%expDates =      {'51419','51519','51519','51619','51619','52219','52219','52319','52319','52419','52919','53019','6519','6519','6619','6619','61219','61919','62019','62019','7119','7319','71019','71119','71119'};
%animalNumbers = {'1',     '1',      '2',    '1',    '2',   '1',     '2',        '1',    '2',    '1',    '1',   '1','1',   '2',    '1' ,   '2','1','1','1','2','1','1','1','1','2'};
[~,~,expDates,animalNumbers] = listAnimalsWithImaging('singleCellAblations',true);


fileDelim = fileDelimeter;
rootDataStorage = '/Volumes/Samsung_T5/singleCellAblations/rawAblationMetaData/';
stackFiles = dir(rootDataStorage);

numAnimals = length(expDates);
stackPaths = struct('times',cell(numAnimals,1));
for expCounter=1:length(expDates)
    expDate = expDates{expCounter};
    animalNumber = animalNumbers{expCounter};
    
    for i = 1 : length(stackFiles)
        if( ~stackFiles(i).isdir )
            
            if ~isempty(regexp(stackFiles(i).name,['f' expDate '_' animalNumber], 'once'))
                %fprintf('times:   %s \\ %s\n',stackFiles(i).folder,stackFiles(i).name);
                stackPaths(expCounter).times = [stackPaths(expCounter).times;{[stackFiles(i).folder fileDelim stackFiles(i).name]}];
            end
        end
    end
    
end
end