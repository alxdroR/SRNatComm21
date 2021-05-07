function [valueAtSaccade,SEMValueAtSaccade,offset,NFixations,samples] = shiftPopAvgComputeDffAtSaccade(allData,binTimes,varargin)
% shiftPopAvgComputeDffAtSaccade-
% Shift population average to zero at the time activity begins to rise.
% Then store activity at the time of saccade
%
%



options = struct('ISImin',2,'ISImax',20,'deconvolve',false,'randomTimes',false,'tauGCaMP',2);
options = parseNameValueoptions(options,varargin{:});

ISImax = options.ISImax; ISImin =options.ISImin; % values of ISI we will test


% we need to randomly sample cells to find risetime and offset
% population measurements
offset =NaN(length(ISImin:ISImax),1); count = 1;
valueAtSaccade = NaN(length(ISImin:ISImax),1);
SEMValueAtSaccade = NaN(length(ISImin:ISImax),1);
NFixations = NaN(length(ISImin:ISImax),1);
samples = cell(length(ISImin:ISImax),1);
for ISIFix = ISImin:ISImax
    dFFISI = allData{ISIFix-ISImin+1};
    if options.randomTimes
        for k = 1 : size(dFFISI,1)
            vals = dFFISI(k,~isnan(dFFISI(k,:)));
            dFFISI(k,end) = vals(randperm(length(vals),1));
        end
    end
    ymean = nanmean(dFFISI);
    numFixEvents = sum(~isnan(dFFISI(:,end)));
    if options.deconvolve
        dt = binTimes(2)-binTimes(1);
        D = sum(~isnan(ymean))+100;
        gamma2 = exp(-dt/options.tauGCaMP);
        G = spdiags([ones(D,1),-gamma2*ones(D,1)],[0,-1],D,D);
        dFFD = G*[dFFISI(:,find(~isnan(ymean),1))*ones(1,100) dFFISI(:,find(~isnan(ymean),1):end)]';
        dFFD = dFFD(101:end,:);
        if options.randomTimes
            dFFD = dFFD(randperm(size(dFFD,1)),:);
        end
        ymeanD = nanmean(dFFD,2);
        SEMValueAtSaccade(count) = nanstd(dFFD(end,:))./sqrt(numFixEvents);
        popAvg =ymeanD-ymeanD(1);
        [~,~,offset(count)] = computePopAvgSlopeRT(popAvg,binTimes(find(~isnan(ymean),1):end),'riseThreshold',0.04);
        valueAtSaccade(count) = popAvg(end);
    else
        SEMValueAtSaccade(count) = nanstd(dFFISI(:,end))./sqrt(numFixEvents);
        popAvg =ymean-ymean(find(~isnan(ymean),1));
         [~,~,offset(count)] = computePopAvgSlopeRT(popAvg,binTimes,'riseThreshold',0.04);
        valueAtSaccade(count) = popAvg(end);
    end
    NFixations(count) = numFixEvents;
    samples{count} = dFFISI(:,end) - offset(count);
    count = count + 1;
end

% now shift to make all population averages start at the time of rise
valueAtSaccade = valueAtSaccade - offset;

end

