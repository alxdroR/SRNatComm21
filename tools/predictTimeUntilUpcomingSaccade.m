function [predictedST,actualST,STEM,binTimes] = predictTimeUntilUpcomingSaccade(F,TF,onDirection,IDsFromCellsOfInterest,varargin)
% [predictedST,RT,STEM,binTimes] = predictPopRiseTime(F,TF,onDirection,IDsFromCellsOfInterest,varargin)
%  Calculate a running median of the population average derivative as a
%  function of time before saccade. Do this for each ISI. For each
%  derivative estimate, estimate the rise-time based on a ramp-to-threshold
%  model
%
% adr
% 2013-2020
%
% see also saccadePredictionAccuracy
options = struct('allData',[],'ISImin',2,'ISImax',20,'useShuffleControl',false,'chooseKCellsAtRandom',[],...
    'debugPlot',false,'nonSR',false,'runLinearModel',false,'deconvolve',false,'tauGCaMP',2,'riseThreshold',0.04,'numSampCut',0);
options = parseNameValueoptions(options,varargin{:});

ISImax = options.ISImax; ISImin =options.ISImin; % values of ISI we will test

binTimes = -30:1/3:0;
if isempty(options.allData)
    allData = gatherPreSaccadeEventTraces(F,TF,onDirection,IDsFromCellsOfInterest,[ISImin ISImax],...
        'binTimes',-30:1/3:0,'ISIwidth',0.5,'tau','future saccade','cutTimeGTISI',false);
else
    allData = options.allData;
end

allDataD = cell(length(allData),1);
if options.deconvolve
    dt = binTimes(2)-binTimes(1);
    for ISIFix = 1:length(allData)
        beginNoNaN = find(sum(isnan(allData{ISIFix}))==0,1);
        sizeDeconvMatrix = length(binTimes)-beginNoNaN+1+100;
        gamma2 = exp(-dt/options.tauGCaMP);
        G = spdiags([ones(sizeDeconvMatrix,1),-gamma2*ones(sizeDeconvMatrix,1)],[0,-1],sizeDeconvMatrix,sizeDeconvMatrix);
        dFFD = G*[allData{ISIFix}(:,beginNoNaN)*ones(1,100) allData{ISIFix}(:,beginNoNaN:end)]';
        dFFD = dFFD(101:end,:);
        allDataD{ISIFix} = [NaN(beginNoNaN-1,size(dFFD,2));dFFD]';
    end
end

if options.deconvolve
    % determine training set threshold
    sumFinalValueVector = cellfun(@(x) nansum(x(:,end)),allDataD);
    numEventsVector = cellfun(@(x) size(x,1),allDataD);
    th = sum(sumFinalValueVector)/sum(numEventsVector);
else
    % determine training set threshold
    sumFinalValueVector = cellfun(@(x) nansum(x(:,end)),allData);
    numEventsVector = cellfun(@(x) size(x,1),allData);
    usable = numEventsVector>options.numSampCut;
    th = sum(sumFinalValueVector(usable))/sum(numEventsVector(usable));
end
if isempty(options.chooseKCellsAtRandom)
    RT = NaN(length(ISImin:ISImax),1);RTIND = RT;D = cell(length(ISImin:ISImax),1);
    predictedST = cell(length(ISImin:ISImax),1);actualST = predictedST;
    offset = RT;
    count = 1;
    if options.debugPlot
        fh=figure;
        fhD=figure;
    else
        fhD=[];
    end
    for ISIFix = ISImin:ISImax
        if numEventsVector(count)>options.numSampCut
            if options.deconvolve
                dFFISI = allDataD{ISIFix-ISImin+1};
                ymean = nanmean(dFFISI);
            else
                dFFISI = allData{ISIFix-ISImin+1};
                ymean = nanmean(dFFISI);
            end
            
            popAvg=ymean;%popAvg =ymean-ymean(find(~isnan(ymean),1));
            if options.nonSR
                popAvg = -popAvg;
            end
            if options.debugPlot
                figure(fhD);subplot(5,5,ISIFix);
            end
            [D{count},RT(count),offset(count),~,RTIND(count)] = computePopAvgSlopeRTV2(popAvg,binTimes,...
                'riseThreshold',options.riseThreshold,'runLinearModel',options.runLinearModel,...
                'debugPlot',fhD);
            if options.debugPlot
                figure(fh); subplot(5,5,ISIFix)
                plot(binTimes,ymean); hold on;
                if ~isnan(RTIND(count))
                    plot(binTimes(RTIND(count)),ymean(RTIND(count)),'ro')
                    plot([binTimes(RTIND(count)) 0],[1 1]*th,'k--');
                end
                title(['fd=' num2str(ISIFix)])
                if ~isnan(RTIND(count)) && false
                    plot(binTimes(RTIND(count)+1:end),D{count},'r:.')
                    xlim([-14 0]);ylim([0 0.14]);
                end
            end
            %predictedST{count} = binTimes(RTIND(count)+1:end)-(th-offset(count))./D{count}';
            rtPrediction = -(th-offset(count))./D{count}';
            
            % estimate when ramping model will cross threshold
            if ~isnan(RTIND(count))
                predictedST{count} = rtPrediction +  (binTimes(RTIND(count)+1:end) - binTimes(RTIND(count)));
                actualST{count} = binTimes(RTIND(count)+1:end);
            else
                predictedST{count} = NaN;
                actualST{count} = NaN;
            end
            count = count + 1;
        else
            predictedST{count} = NaN;
            actualST{count} = NaN;
            count = count + 1;
        end
    end
    % crossTime = (th-offset)./D + RT;
end
if options.debugPlot
    xlabel('time before saccade (s)');
    ylabel('slope estimate')
    % show the estimates of rise-time that these slope estimates map onto
    fh2=figure;
    count = 1;
    for ISIFix = ISImin:ISImax
        figure(fh2); subplot(5,5,ISIFix)
        if ~isnan(RTIND(count))
            plot(binTimes(RTIND(count)+1:end),predictedST{count},'b:.'); hold on;
            plot([-15 binTimes(end)],[1 1]*RT(count),'k--')
            xlim([-14 0]);ylim([-20 0]);
        end
        count = count + 1;
    end
    xlabel('time before saccade (s)');
    ylabel('rise time estimate','color','b')
    title(['pop avg at ISI=' num2str(ISIFix) '(s)'])
end

% create a matrix to average together the error
STEM = NaN(length(predictedST),25);
for count = 1 : length(predictedST)
    fd = ISImin + count-1;
    if length(predictedST{count})<=25
        STEM(count,25-length(predictedST{count})+1:25) = abs((predictedST{count} - actualST{count})/fd);
    else
        STEM(count,:) = abs((predictedST{count}(end-24:end) - actualST{count}(end-24:end))/fd);
    end
end

end

