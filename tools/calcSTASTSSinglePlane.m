function [STA,STS,varargout] = calcSTASTSSinglePlane(y,t,saccadeTimes,saccadeDirection,Ta,Tb,minNumSamples,varargin)
%calcSTA Summary of this function goes here
%   Detailed explanation goes here
options = struct('runSTACIcalc',false,'numBootSamples',100,'CIalpha',0.05,'runAnova1',false);
options = parseNameValueoptions(options,varargin{:});

% parameters for matrix of responses and NaNs
Tstart = 0; Tend = 30;
binTimes = [Tstart:1/3:Tend];

Tstart = -30; Tend = 0;
binTimesR = [Tstart:1/3:Tend];

counter = 1;
bt = [binTimesR(1:end-1) binTimes];

nCells = size(y,2);
STA = NaN(nCells,length(bt),2);
STS = NaN(nCells,length(bt),2);
if options.runSTACIcalc
    CILower = NaN(nCells,length(bt),2);
    CIUpper = NaN(nCells,length(bt),2);
else
    CILower = [];
    CIUpper = [];
end
if options.runAnova1
    anovaPvalue = NaN(nCells,2);
else
    anovaPvalue = [];
end
psign = cell(nCells,2);
numComparisons= cell(nCells,2);


nTrialsL = zeros(nCells,length(bt));
nTrialsR = zeros(nCells,length(bt));

if sum(saccadeDirection) >= minNumSamples && sum(~saccadeDirection) >= minNumSamples
    % Cut responses into times after saccade (interpolate the
    % starting value using 1 second before saccade)
    [STR2,timeSegments2,direction,absTime2] = STresponses(y,saccadeTimes,saccadeDirection,t,'startpoint', ...
        -1.03,'endpoint','all','removeInvalids',false,'useSaccadeDuration',false);
    
    % interpolate responses
    STRM = raggedArray2Matrix(timeSegments2,STR2,binTimes);
    D = cat(1,direction{:});
    
    % w.r.t times before saccade--expand to include the point after the
    % upcoming saccade for better interpolation results
    [STR,timeSegments,direction,absTime] = STresponses(y,saccadeTimes,saccadeDirection,t,'startpoint', ...
        0,'endpoint','all','removeInvalids',false,'useSaccadeDuration',false,'runAnova1',false);
    if length(absTime{1})<length(saccadeTimes)
        timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(1:end-1,1));
    else
        timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(:,1));
    end
    timeRevSegExpand=timeRevSeg;
    STRExpand = STR;
    
    for ii=1:length(absTime2)
        for jj=1:length(absTime2{ii})-1
            if ~any(isnan(timeRevSegExpand{ii}{jj}))
                if ~isempty(timeSegments{ii}{jj+1})
                    if ~isnan(timeSegments{ii}{jj+1}(1))
                        timeRevSegExpand{ii}{jj} = [timeRevSegExpand{ii}{jj};timeSegments{ii}{jj+1}(1)];
                        STRExpand{ii}{jj} = [STRExpand{ii}{jj};STRExpand{ii}{jj+1}(1)];
                    end
                end
            end
        end
    end
    
    STRMR = raggedArray2Matrix(timeRevSegExpand,STRExpand,binTimesR);
    
    
    
    nTrials = length(STR{1});
    for cellIndex  = 1 : nCells
        % Just like the last trial of STRM is NaNs, the first trial of STRM
        % should be NaNs. However, the code is such that the first trial is
        % ignorned. Until this is fixed, we just exclude the first fixation
        % from analysis and start at 2:nTrials
        strmIndices = (2:nTrials) + (cellIndex-1)*nTrials;
        
        % combine responses for this cell before and after
        % saccade
        cellSpecificResponses = [STRMR(strmIndices-1,1:length(binTimesR)-1) STRM(strmIndices,:)];
        
        % divide responses acorrding to left/right trials
        % before averaging
        D4cell = D(strmIndices);
        yL = cellSpecificResponses(D4cell==1,:);
        yR = cellSpecificResponses(D4cell==0,:);
        
        % determine if there are enough fixations within the chosen window
        [~,TbIndex] = min(barrierALEX(bt-Tb,0,Inf));
        [~,TaIndex] = min(barrierALEX(bt-Ta,0,Inf));
        zeroIndex = find(bt==0);
        
        nTrialsL(counter,:) = sum(~isnan(yL),1);
        nTrialsR(counter,:) = sum(~isnan(yR),1);
        
        enoughLongFixationsL = min(nTrialsL(counter,TbIndex:TaIndex)) >= minNumSamples;
        enoughLongFixationsR = min(nTrialsR(counter,TbIndex:TaIndex)) >= minNumSamples;
        if enoughLongFixationsL && enoughLongFixationsR
            % calculate average
            staL = nanmean(yL,1);
            staR = nanmean(yR,1);
            
            STA(counter,:,1) = staL;
            STA(counter,:,2) = staR;
            
            % it might be better to measure confidence intervals as a proxy of
            % noise for standard deviation which we could do with
            
            if options.runSTACIcalc || options.runAnova1
                if ~isempty(yL)
                    mL = bootstrp(options.numBootSamples,@nanmean,yL);
                    qL  = quantile(mL,[1-options.CIalpha/2 options.CIalpha/2],1);
                else
                    qL = NaN(2,1);
                end
                if ~isempty(yR)
                    mR = bootstrp(options.numBootSamples,@nanmean,yR);
                    qR  = quantile(mR,[1-options.CIalpha/2 options.CIalpha/2],1);
                else
                    qR = NaN(2,1);
                end
                if options.runSTACIcalc
                    CILower(counter,:,1) = qL(2,:);
                    CILower(counter,:,2) = qR(2,:);
                    CIUpper(counter,:,1) = qL(1,:);
                    CIUpper(counter,:,2) = qR(1,:);
                end
                
                if options.runAnova1
                    pL=anova1(yL(:,nTrialsL(counter,:)>=minNumSamples),[],'off'); 
                    pR=anova1(yR(:,nTrialsR(counter,:)>=minNumSamples),[],'off');
                    anovaPvalue(counter,1) = pL;
                    anovaPvalue(counter,2) = pR;
                    
                    % sign test to check which responses are above zero
                    % useableIndices = find(nTrialsL(counter,1:zeroIndex)>=minNumSamples);
                    useableIndices = find(nTrialsL(counter,:)>=minNumSamples); % changed this to use times before and after saccade - adr 3/2/2018
                    psign{counter,1} = NaN(length(useableIndices),1);
                    %if length(useableIndices) > 0
                    numComparisons{counter,1} = bt(nTrialsL(counter,1:zeroIndex)>=minNumSamples);
                    % end
                    if ~isempty(yL)
                        count = 1;
                        for timeIndex = useableIndices
                            if nansum(yL(:,timeIndex))>0
                                psign{counter,1}(count) = signrank(yL(:,timeIndex),0,'tail','right');
                            end
                            count = count+1;
                        end
                    end
                    % sign test to check which responses are above zero
                    % useableIndices = find(nTrialsR(counter,1:zeroIndex)>=minNumSamples);
                    useableIndices = find(nTrialsR(counter,:)>=minNumSamples);% changed this to use times before and after saccade - adr 3/2/2018
                    psign{counter,2} = zeros(length(useableIndices),1);
                    %if length(useableIndices) > 0
                    % numComparisons{counter,2} = bt(useableIndices);
                    numComparisons{counter,2} = bt(nTrialsR(counter,1:zeroIndex)>=minNumSamples);
                    %end
                    if ~isempty(yR)
                        count = 1;
                        for timeIndex = useableIndices
                            if nansum(yR(:,timeIndex))>0
                                psign{counter,2}(count) = signrank(yR(:,timeIndex),0,'tail','right');
                            end
                            count = count+1;
                        end
                    end
                end
            end
            
            
            STS(counter,:,1) = nanstd(yL,1,1);
            STS(counter,:,2) = nanstd(yR,1,1);
            if 0
                % calculate variance of residuals
                resL = yL(:,TbIndex:TaIndex) - ones(size(yL,1),1)*staL(TbIndex:TaIndex);
                resR = yR(:,TbIndex:TaIndex) - ones(size(yR,1),1)*staR(TbIndex:TaIndex);
                
                noiseSTDL = mean(nanstd(resL,[],2));
                noiseSTDR = mean(nanstd(resR,[],2));
                
                % calculate SNR
                snr(counter,1) = signalSTDL/noiseSTDL;
                snr(counter,2) = signalSTDR/noiseSTDR;
            end
        end
        counter = counter + 1;
    end
end

varargout{1} = bt;
varargout{2} = nTrialsL;
varargout{3} = nTrialsR;
%if options.runSTACIcalc
varargout{4} = CILower;
varargout{5} = CIUpper;
%end
%if options.runAnova1
varargout{6} = anovaPvalue;
%end
varargout{7} = psign;
varargout{8} = numComparisons;
end

