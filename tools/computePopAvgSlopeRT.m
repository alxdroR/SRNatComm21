function [D,RT,offset,popAvgDer,rtindex] = computePopAvgSlopeRT(popAvg,binTimes,varargin)
options = struct('riseThreshold',0.03,'accBasedRT',false);
options = parseNameValueoptions(options,varargin{:});

dt = binTimes(2)-binTimes(1);
popAvgDer = diff(popAvg)./dt;

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
    D = nanmedian(popAvgDer(rtindex:end));
    offset =  popAvg(rtindex);
else
    RT = binTimes(find(~isnan(popAvg),1));
    D = nanmedian(popAvgDer);
    offset = popAvg(find(~isnan(popAvg),1));
end

%popAvgDer=popAvgDer2;
end

