function [analysisMatrix,ISI,dirInPlane,specialFixationdff,specialFixationtime] = rampSlopeAndTimeComputation(Y,saccadeTimes,saccadeDirection,timeF,OFFdirection,varargin)
options = struct('firingRate',[],'measureRelativeDFFAtSaccade',false,'visualizeStartStopTimes',false);
options = parseNameValueoptions(options,varargin{:});


% algorithm parameters
relaxTime =4; % amount of time after the start of the OFF direction to use to select threshold 


% create saccade-triggered responses
[STRInPlane,timeForSeg,dirInPlane,absTime] = STresponses(Y,saccadeTimes,saccadeDirection,timeF,'startpoint', ...
    0,'endpoint','all','removeInvalids',false,'useSaccadeDuration',false);
% construct time relative to upcoming saccade index
if length(absTime{1})<length(saccadeTimes)
    timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(1:end-1,1));
else
    timeRevSeg = constructTimeReverseSegments(absTime,saccadeTimes(:,1));
end

if ~isempty(options.firingRate)
    [na,firingLengths,noFiringLengths,firingStartIndices,firingEndIndices] = findNoFiringEpochs(options.firingRate,...
         varargin{:});
end
NCells = size(Y,2);
%numCellIndex = planeIndex + sum(numPlanesV(1:expIndex-1));
analysisMatrix = cell(NCells,1);
ISI = cell(NCells,1);
specialFixationdff = cell(2,1);specialFixationtime=cell(2,1);sfcount =1;
for cellIndex = 1: NCells
    %allCellIndex = cellIndex + sum(numCells(1:numCellIndex-1));
    % STR{allCellIndex} = STRInPlane{cellIndex};
    %  direction{allCellIndex} = dirInPlane{cellIndex};
    
    if isempty(options.firingRate)
        analysisMatrix{cellIndex} = NaN(length(STRInPlane{cellIndex})-1,10);
    else
        analysisMatrix{cellIndex} = NaN(length(STRInPlane{cellIndex})-1,10);
    end
    ISI{cellIndex} = NaN(length(STRInPlane{cellIndex})-1,1);
    
    if isempty(options.firingRate)
    [threshold] = riseThresholdGauss(STRInPlane{cellIndex},timeForSeg{cellIndex},dirInPlane{cellIndex},...
        OFFdirection(cellIndex),relaxTime );
    else
        threshold = 0;
    end
    if ~isnan(threshold)
        for nIndex = 2 : length(STRInPlane{cellIndex})
            xx = timeRevSeg{cellIndex}{nIndex-1}(~isnan(STRInPlane{cellIndex}{nIndex-1}));
            yy = STRInPlane{cellIndex}{nIndex-1}(~isnan(STRInPlane{cellIndex}{nIndex-1}));
            %coPval=NaN;
            potentialNonLin = false;
            if ~isempty(xx)
                if ~isempty(options.firingRate)
                    fireStartTimes = timeF(firingStartIndices{cellIndex},cellIndex); 
                    fireEndTimes = timeF(firingEndIndices{cellIndex},cellIndex);
                    
                    startIndicesInThisFixation = fireStartTimes >= saccadeTimes(nIndex-1,1) & ...
                        fireStartTimes < saccadeTimes(nIndex,1);
                    startTimesInThisFixation = fireStartTimes(startIndicesInThisFixation);
                    % if there are multiple bouts that finish within this
                    % fixation length(startTimesInThisFixation)>1. We care
                    % about the firing start that is closest to the
                    % upcoming saccade
                    if ~isempty(startTimesInThisFixation)
                        riseTime = startTimesInThisFixation(end)-saccadeTimes(nIndex,1);
                        riseTimeNotTriggeredToSaccade = startTimesInThisFixation(end);
                        
                        % find out when this bout ends relative to the saccade
                        endTimesActivityStartedInThisFixation = fireEndTimes(startIndicesInThisFixation);
                        endFiringRate = endTimesActivityStartedInThisFixation(end) -saccadeTimes(nIndex,1);
                        
                        if options.visualizeStartStopTimes
                            fvish = figure;plot(timeF(:,cellIndex)-saccadeTimes(nIndex,1),options.firingRate(:,cellIndex),'Marker','.');hold on;
                            plot(startTimesInThisFixation-saccadeTimes(nIndex,1),options.firingRate(startIndicesInThisFixation,cellIndex),'ro')
                            plot(endTimesActivityStartedInThisFixation-saccadeTimes(nIndex,1),0.1,'go')
                            plot([1 1]*(saccadeTimes(nIndex-1,1)-saccadeTimes(nIndex,1)),[0 1e4],'--','color',[1 1 1]*0.3)
                            plot([1 1]*0,[0 1e4],'--','color',[1 1 1]*0.3)
                            ylabel('non-negative constrained deconvolved fluorescence (au)')
                            title('demo cut-off (r/g=start/stop with cut-off)')
                            xlabel('time relative to fixation (s)')
                            
                            yyaxis right
                            plot(timeF(:,cellIndex)-saccadeTimes(nIndex,1),Y(:,cellIndex));ylabel('dF/F')
                            xlim([saccadeTimes(nIndex-1,1)-saccadeTimes(nIndex,1)-1 5])
                            keyboard
                            close(fvish)
                        end
                    else
                        riseTime = NaN; endFiringRate =NaN; riseTimeNotTriggeredToSaccade =NaN;
                    end
                else
                    % Find the first point that increased past threshold
                    minTPoint = find(yy(2:end)>threshold & diff(yy)>0,1);
                    riseTime = xx(minTPoint);
                    xxAbsTime = absTime{cellIndex}{nIndex-1}(~isnan(STRInPlane{cellIndex}{nIndex-1}));
                    riseTimeNotTriggeredToSaccade = xxAbsTime(minTPoint);
                    if isempty(riseTime)
                        riseTime = NaN;
                        riseTimeNotTriggeredToSaccade = NaN;
                    end
                        
                end
                % interpolate to the value at 0
                nextPoint = STRInPlane{cellIndex}{nIndex}(1);
                nextTime = timeForSeg{cellIndex}{nIndex}(1);
                if isnan(nextTime)
                    %keyboard
                    error('timeForSeg{cellIndex}{nIndex}(1) is NaN which will break the code. This should never happen')
                end
                Vq = interp1([xx(end) nextTime],[yy(end) nextPoint],xx(end):0.001:0);
                if options.measureRelativeDFFAtSaccade
                    % we subtract off the value of dF/F at the time of rise
                    % to measure increases in dF/F from where the trace
                    % began. 
                    if isnan(riseTime)
                        finalValue = NaN;
                    else
                        dFFAtTimeOfRise = yy(xx==riseTime); 
                        if isempty(dFFAtTimeOfRise)
                            finalValue = NaN;
                        else
                            finalValue = Vq(end) - dFFAtTimeOfRise;
                        end
                    end
                        
                else
                    % This is the interpolated dF/F value. By definition
                    % this is the change relative to the traces mean. 
                    finalValue = Vq(end);
                end
                if ~isnan(riseTime)
                    % minTPoint = max(1,minTPoint-1);
                    %localSlope = localSlopes(minTPoint);
                    %  riseTime = xx(minTPoint);
                    if ~isempty(options.firingRate)
                        anticRegion = xx'>=riseTime-0.1;
                    else
                        anticRegion = xx'>=riseTime-1.1;
                    end
                    
                    % cost for the part we fit a linear function to
                    tAntic = xx(anticRegion);
                    fAntic = yy(anticRegion);
                    nsamp = sum(~isnan(fAntic));
                else
                    % cell didn't rise for this direction
                    % use the entire trace
                    tAntic = xx;
                    fAntic = yy;
                    nsamp = sum(~isnan(fAntic));
                end
                
                if nsamp > 1
                    theta = pinv([ones(nsamp,1) tAntic(~isnan(fAntic))])*fAntic(~isnan(fAntic));
                    %lmod = fitlm(tAntic(~isnan(fAntic)),fAntic(~isnan(fAntic)));
                    %theta = lmod.Coefficients.Estimate;
                    localSlope = theta(2);
                    offset = theta(1); % save the offset for plotting purposes
                    gof = corr(fAntic(~isnan(fAntic)),[ones(nsamp,1) tAntic(~isnan(fAntic))]*theta );
                    %gof = lmod.Rsquared.Ordinary;
                    %coPval = lmod.Coefficients.pValue(2);
                    if gof < 0.4  && false
                        plot(tAntic(~isnan(fAntic)),fAntic(~isnan(fAntic)),'b.'); hold on 
                        plot(tAntic(~isnan(fAntic)),[ones(nsamp,1) tAntic(~isnan(fAntic))]*theta,'r');
                    end
                    if(gof < 0.7 && finalValue >= 0.1 && localSlope >= 0.1) % non-linear rise
                    %if(gof < 0.7 && finalValue < 0.05 && localSlope < 0.1) % failure to rise
                     %  if(gof > 0.7 && isnan(riseTime)  && localSlope < 0) % failure to rise
                        specialFixationdff{sfcount} = fAntic;
                        specialFixationtime{sfcount} = tAntic;
                        sfcount = sfcount + 1;
                        potentialNonLin = true;
                    end
                else
                    localSlope = NaN;
                    gof = NaN;
                    offset = NaN; % save the offset for plotting purposes
                end
                
                
            else
                nsamp = 0;
                localSlope = NaN;
                riseTime = NaN;
                riseTimeNotTriggeredToSaccade = NaN;
                finalValue = NaN;
                gof = NaN;
                offset = NaN; % save the offset for plotting purposes
                if ~isempty(options.firingRate)
                    endFiringRate = NaN;
                end
           end
            
            
            analysisMatrix{cellIndex}(nIndex-1,1) = localSlope;
            analysisMatrix{cellIndex}(nIndex-1,2) = riseTime;
            analysisMatrix{cellIndex}(nIndex-1,3) = nsamp;
            analysisMatrix{cellIndex}(nIndex-1,4) = finalValue;
            analysisMatrix{cellIndex}(nIndex-1,5) = gof;
            analysisMatrix{cellIndex}(nIndex-1,6) = offset;
            analysisMatrix{cellIndex}(nIndex-1,7) = saccadeTimes(nIndex-1,1);
            if ~isempty(options.firingRate)
                analysisMatrix{cellIndex}(nIndex-1,8) = endFiringRate;
            end
            analysisMatrix{cellIndex}(nIndex-1,9) = riseTimeNotTriggeredToSaccade;
            analysisMatrix{cellIndex}(nIndex-1,10) = saccadeDirection(nIndex)==saccadeDirection(nIndex-1);
            ISI{cellIndex}(nIndex-1) = saccadeTimes(nIndex)-saccadeTimes(nIndex-1);
            %analysisMatrix{cellIndex}(nIndex-1,11) = coPval;
            analysisMatrix{cellIndex}(nIndex-1,11) = potentialNonLin;
            
        end
    end
end
end

