function [D,RT,offset,popAvgDer,rtindex] = computePopAvgSlopeRTV2(popAvg,binTimes,varargin)
options = struct('riseThreshold',0.03,'accBasedRT',false,'runLinearModel',false,'debugPlot',false);
options = parseNameValueoptions(options,varargin{:});

dt = binTimes(2)-binTimes(1);
popAvgDer = diff(popAvg)./dt;
if ~isempty(options.debugPlot)
    timeIndexStart=find(~isnan(popAvg),1);
    figure(options.debugPlot);plot(binTimes,popAvg,'b:.');
    hold on;plot(binTimes(1:end-1)+dt/2,popAvgDer,'k:.')
    plot([binTimes(timeIndexStart) 0],[1 1]*options.riseThreshold,'k--');
end
if options.accBasedRT
    popAvgDer2 = diff(popAvgDer)./dt;
    %  we want to highlight positive accelerations when the derivative is positive
    popAvgDer2(popAvgDer(1:end-1)<0 & popAvgDer2>0) = -popAvgDer2(popAvgDer(1:end-1)<0 & popAvgDer2>0);
    [~,mxind]=max(popAvgDer2);
    rtindex = mxind+1;
else
    rtindex = find(popAvgDer>options.riseThreshold,1);
end
if ~isempty(rtindex)
    RT = binTimes(rtindex)+dt/2;
    derRise2Saccade = popAvgDer(rtindex:end);
    offset =  popAvg(rtindex);
else
    rtindex = NaN;
    RT = binTimes(find(~isnan(popAvg),1));
    derRise2Saccade = popAvgDer;
    offset = popAvg(find(~isnan(popAvg),1));
end

if ~options.runLinearModel
    D = NaN(length(derRise2Saccade),1);
    D(1) = derRise2Saccade(1);
    if length(D) > 1
        for i = 2 : length(D)
            D(i) = nanmedian(derRise2Saccade(1:i));
        end
    end
else
    relTimes = binTimes(rtindex:end);
    relDFF = popAvg(rtindex:end);
    D = NaN(length(relTimes)-1,1);
    
    lmod=fitlm(relTimes(1:2),relDFF(1:2));
    D(1) = lmod.Coefficients.Estimate(2);
    if length(D) > 1
        for i = 2 : length(D)
            lmod=fitlm(relTimes(1:i+1),relDFF(1:i+1));
            D(i) = lmod.Coefficients.Estimate(2);
        end
    end
end
%popAvgDer=popAvgDer2;
end

