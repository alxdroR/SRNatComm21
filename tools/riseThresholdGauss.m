function [threshold,mu,s] = riseThresholdGauss(y,timeFromSaccade,dir,offDir,relaxTime )
% y{nIndex}(t) is the fluorescence at time index t for trial nIndex
% dir(nIndex) is 1 if the previous saccade was to the left or 0 if it was
% to the right

samplesOFF = [];
for nIndex = 1 : length(y)
    if dir(nIndex)==offDir
        useableOFFTimes = timeFromSaccade{nIndex}>=relaxTime;
       samplesOFF = [samplesOFF;y{nIndex}(useableOFFTimes)];
    end
end

if sum(~isnan(samplesOFF))>1
    % calcualte 3 sigma (alpha = 0.001 line) from this
    %mu = nanmean((samplesOFF));
    %s = nanstd((samplesOFF));
    mu = nanmedian((samplesOFF));
    s = 1.4826*nanmedian(abs(mu-samplesOFF)); % less sensitive to outliers and faster than bootstraping
 
    if mu==0
        % this is too small.
         mu = nanmedian(samplesOFF(samplesOFF~=0));
        s = 1.4826*nanmedian(abs(mu-samplesOFF(samplesOFF~=0))); % less sensitive to outliers and faster than bootstraping
    end
     threshold = mu+3*s;
    
else
    threshold = NaN;
end
end

