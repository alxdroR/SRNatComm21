function [expName,expCond,varargout] = listAnimalsWithImaging(varargin)
options = struct('singleCellAblations',false,'ablatedSRAnimals',false,'singleCellAblationsFULL',false,'coarseAblationRegistered',false);
options = parseNameValueoptions(options,varargin{:});

% fid = listAnimalsWithImaging
%   fid is a list of all the animals in the data set where calcium was
%   imaged. Animals labeled with a character had ablations performed on
%   them after imaging.

if options.singleCellAblations
     expDates =      {'51419','51519','51519','51619','51619','52219','52219','52319','52319','52419','52919','53019','6519','6519','6619','6619','61219','61919','62019','62019','7119','7319','71019','71119','71119','71819'};
    animalNumbers = {'1',     '1',      '2',    '1',    '2',   '1',     '2',        '1',    '2',    '1',    '1',   '1','1',   '2',    '1' ,   '2','1','1','1','2','1','1','1','1','2','1'};
     expName = cell(1,length(expDates));
    for i=1:length(expDates)
        expName{i} = ['f' expDates{i} '_' animalNumbers{i} '_'];
    end
    expCond = repmat({'B'},1,length(expDates));
    varargout{1} = expDates;
    varargout{2} = animalNumbers;
elseif options.singleCellAblationsFULL
    % full means that traces taken inbetween ablation are included. I never analyzed offline the
    % 1-2 cell ablation data that was collected before 5/22/19 so these are
    % not included. This is intended for use with the 3rd Nat Comm rebuttal
    expDates =      {'52219','52219','52319','52319','52319','52319'  ,'52419','52419','52919','52919'   ,'53019','6519','6519','6519'   ,'6619','6619'   ,'6619','61219','61219'   ,'61919','62019','62019','7119','7319','71019','71119','71119','71819'};
    animalNumbers = {'1',     '2',     '1',  '1',      '2'  ,  '2'    , '1',   '1'    ,   '1',   '1'     ,  '1',   '1'  , '2',    '2'    , '1' , '1'      ,  '2' ,  '1' ,   '1'     ,'1'    ,'1'    ,'2'    ,'1'   ,'1'   ,'1'    ,'1'    ,'2','1'};
    expCond =       {'B',     'B',   'B' , 'inbetween','B','inbetween','B','inbetween',   'B','inbetween',  'B',   'B'  , 'B','inbetween', 'B','inbetween',  'B' ,  'B' ,'inbetween','B'    ,'B'    ,'B'    ,'B'   ,'B'   ,'B'    ,'B'    ,'B','B'}; 
    expName = cell(1,length(expDates));
    for i=1:length(expDates)
        expName{i} = ['f' expDates{i} '_' animalNumbers{i} '_'];
    end
elseif options.ablatedSRAnimals
    % intended for use with the artificial dataset in reRunCalcSTA2
     expDates = {'52219', '52319','52419','52919','53019','6619','61219','7119','7319','71819'};
    animalNumbers = {'1', '1','1','1','1','2','1','1','1','1'};
    expName = cell(1,length(expDates));
    for i=1:length(expDates)
        expName{i} = ['f' expDates{i} '_' animalNumbers{i} '_'];
    end
    expCond = [{'B','B','B','B','B','B','B','B','B','B'}];
    varargout{1} = expDates;
    varargout{2} = animalNumbers;
elseif options.coarseAblationRegistered
    expName = {'fLL','fMM','fNN','fOO','fBB','fD','fE','fG','fGG','fHH','fI','fII','fJJ','fK','fKK','fL','fM','fPP','fQQ','fR','fS','fTT','fV','fWW','fX','fO','fC','fH','fQ','fT','fP','fN','fJ','fU','fW','fCC','fDD','fEE','fFF','fUU','fVV','fXX'};
    expCond = [repmat({'TBi'},1,4) repmat({'TBi'},1,26-4+1) repmat({'TUni'},1,7-1) repmat({'C'},1,9)];
    imgExpName = listAnimalsWithImaging;
    expIndex = NaN(length(expName),1);
    count = 1;
    for k = 1 : length(expName)
        inImgSet = cellfun(@(x) strcmp(x,expName{k}),imgExpName);
        if any(inImgSet)
            expIndex(k) = find(inImgSet);
        else
            expIndex(k) = count+length(imgExpName);
            count = count + 1;
        end
    end
    varargout{1} = expIndex;
else
    expName = {'f1','f3','f4','f6','f7','f11','f12','f13','f14','f16','fC','fD','fE','fG','fH','fI','fK','fL','fV','fX'};
    expCond = [repmat({[]},1,10) repmat({'B'},1,10)]; 
end
end

