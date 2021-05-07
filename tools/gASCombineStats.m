function [statSort,statAGSort,varargout] = gASCombineStats(gASStruct,varargin)
%gASCombineStats - function designed for the structure returned by the
%function gatherAblationStatistics
%   Combines behavioral statistic across both left and right eyes and combines data before and after ablation. Then sorts results by ablation
%   ablation location name.

options = struct('ablationCondition','before and after','removeHBLocationLabel',false,'fidArray2Use',[],'expCond',[]);
options = parseNameValueoptions(options,varargin{:});

% obtain the name of the statistic
allNames = fieldnames(gASStruct.leftEye.before);
statisticName = allNames{1};

if ~isempty(options.fidArray2Use)
    fidArray2Use = options.fidArray2Use;
    nAll = length(fidArray2Use);
    minNumFixations = NaN(nAll,1);
    statBefore = [];
    statAfter = [];
    animalKeepB = [];
    animalKeepA = [];
    statAGBefore = [];
    statAGAfter = [];
    statNBefore = [];
    statNAfter = [];
    ecBefore = [];
    ecAfter = [];
    itGOFB = [];
    itGOFA = [];
    for expIndex = 1  : nAll
        animalName = fidArray2Use{expIndex};
        BIndexL=cellfun(@(x) strcmp(x,animalName),gASStruct.leftEye.before.animalName);
        BIndexR=cellfun(@(x) strcmp(x,animalName),gASStruct.rightEye.before.animalName);
        statBeforeSA = [gASStruct.leftEye.before.(statisticName)(BIndexL);gASStruct.rightEye.before.(statisticName)(BIndexR)];
        
        AIndexL=cellfun(@(x) strcmp(x,animalName),gASStruct.leftEye.after.animalName);
        AIndexR=cellfun(@(x) strcmp(x,animalName),gASStruct.rightEye.after.animalName);
        statAfterSA = [gASStruct.leftEye.after.(statisticName)(AIndexL);gASStruct.rightEye.after.(statisticName)(AIndexR)];
        numBefore = sum(~isnan(statBeforeSA));
        numAfter = sum(~isnan(statAfterSA));
        nB = length(statBeforeSA);
        nA = length(statAfterSA);
        %         if numBefore == 0
        %             animalKeepB = [animalKeepB;false(nB,1)];
        %         else
        %             animalKeepB = [animalKeepB;true(nB,1)];
        %         end
        %          if numAfter == 0
        %             animalKeepA = [animalKeepA;false(nA,1)];
        %         else
        %             animalKeepA = [animalKeepA;true(nA,1)];
        %         end
        
        minNumFixations(expIndex) = min(numBefore,numAfter);
        if minNumFixations(expIndex)==0
            minNumFixations(expIndex) = NaN;
            animalKeepB = [animalKeepB;false(nB,1)];
            animalKeepA = [animalKeepA;false(nA,1)];
        else
            animalKeepB = [animalKeepB;true(nB,1)];
            animalKeepA = [animalKeepA;true(nA,1)];
            % keyboard
        end
        statBefore = [statBefore;statBeforeSA];
        statAfter = [statAfter;statAfterSA];
        statBID = [gASStruct.leftEye.before.animalIndex;gASStruct.rightEye.before.animalIndex];
        statAID = [gASStruct.leftEye.after.animalIndex;gASStruct.rightEye.after.animalIndex];
        statAGBefore = [statAGBefore;[gASStruct.leftEye.before.ablationGroup(BIndexL);gASStruct.rightEye.before.ablationGroup(BIndexR)]];
        statAGAfter = [statAGAfter;[gASStruct.leftEye.after.ablationGroup(AIndexL);gASStruct.rightEye.after.ablationGroup(AIndexR)]];
        statNBefore = [statNBefore;[gASStruct.leftEye.before.animalName(BIndexL);gASStruct.rightEye.before.animalName(BIndexR)]];
        statNAfter = [statNAfter; [gASStruct.leftEye.after.animalName(AIndexL);gASStruct.rightEye.after.animalName(AIndexR)]];
        
        ecBefore = [ecBefore;repmat({options.expCond{expIndex}},nB,1)];
        ecAfter = [ecAfter;repmat({options.expCond{expIndex}},nA,1)];
        itGOFB  = [itGOFB ; [gASStruct.leftEye.before.other(BIndexL);gASStruct.rightEye.before.other(BIndexR)]];
        itGOFA = [itGOFA; [gASStruct.leftEye.after.other(AIndexL);gASStruct.rightEye.after.other(AIndexR)]];
    end
else
    
    % combine the results from both eyes and possibly combine results before and after ablation
    statBefore = [gASStruct.leftEye.before.(statisticName);gASStruct.rightEye.before.(statisticName)];
    statAfter = [gASStruct.leftEye.after.(statisticName);gASStruct.rightEye.after.(statisticName)];
    statBID = [gASStruct.leftEye.before.animalIndex;gASStruct.rightEye.before.animalIndex];
    statAID = [gASStruct.leftEye.after.animalIndex;gASStruct.rightEye.after.animalIndex];
    
    % use the ablation location name to sort according to group
    statAGBefore = [gASStruct.leftEye.before.ablationGroup;gASStruct.rightEye.before.ablationGroup];
    statAGAfter = [gASStruct.leftEye.after.ablationGroup;gASStruct.rightEye.after.ablationGroup];
    statNBefore = [gASStruct.leftEye.before.animalName;gASStruct.rightEye.before.animalName];
    statNAfter = [gASStruct.leftEye.after.animalName;gASStruct.rightEye.after.animalName];
end
switch options.ablationCondition
    case 'before and after'
        stat = [statBefore;statAfter];
        statID = [statBID;statAID];
    case 'before'
        stat = statBefore;
    case 'after'
        stat = statAfter;
end
switch options.ablationCondition
    case 'before and after'
        if options.removeHBLocationLabel
            statAGBefore = cellfun(@(z) replaceLocationLabel(z,'B'),statAGBefore,'Uniform',false);
            statAGAfter = cellfun(@(z) replaceLocationLabel(z,'A'), statAGAfter,'Uniform',false);
        else
            statAGBefore = cellfun(@(z) [z 'B'],statAGBefore,'Uniform',false);
            statAGAfter = cellfun(@(z) [z 'A'],statAGAfter,'Uniform',false);
        end
        statAG = cat(1,statAGBefore,statAGAfter);
    case 'before'
        if options.removeHBLocationLabel
            statAG =  cellfun(@(z) replaceLocationLabel(z,[]),statAGBefore,'Uniform',false);
        else
            statAG = statAGBefore;
        end
    case 'after'
        if options.removeHBLocationLabel
            statAG = cellfun(@(z) replaceLocationLabel(z,[]), statAGAfter,'Uniform',false);
        else
            statAG = statAGAfter;
        end
end

[statAGSort,sortIndex]=sort(statAG);
statSort = stat(sortIndex);
statIDSort = statID(sortIndex,:);
varargout{1} = statBefore;
varargout{2} = statAfter;
varargout{3} = statAGBefore;
varargout{4} = statAGAfter;
if ~isempty(options.fidArray2Use)
    varargout{5} = animalKeepB;
    varargout{6} = animalKeepA;
    varargout{7} = statNBefore;
    varargout{8} = statNAfter;
    varargout{9} = ecBefore;
    varargout{10} = ecAfter;
    varargout{11} = itGOFB;
    varargout{12} = itGOFA;
    varargout{13} = statIDSort;
else
    varargout{5} = statIDSort;
end
end

function nameOut = replaceLocationLabel(name,expCond)
if strcmp(name(1),'r')
    % this name has the format rI-J for rhombomeres I -J
    % replace this format with h for hindbrain, then add the
    % experimental condition expCond
    nameOut = ['h' expCond];
elseif strcmp(name(1),'s')
    nameOut = [name expCond];
end
end

