function [dt,t] = replaceMissingEyeTimes(t)
dt = diff(t);
[N,numEyes] = size(t);
for eyeIndex =1 : numEyes
    badPoints = find(dt(:,eyeIndex)==0);
    for bpIndex = 1 : length(badPoints)
        if badPoints(bpIndex)+2 <= N
            % we can replace the missing value assuming equal spacing
            dtapprox = ( t(badPoints(bpIndex)+2,eyeIndex) - t(badPoints(bpIndex),eyeIndex) )/2;
            t(badPoints(bpIndex)+1,eyeIndex) = t(badPoints(bpIndex),eyeIndex) + dtapprox;
        else
            dtavg = mean(diff(t(1:N-1,eyeIndex)));
            t(badPoints(bpIndex)+1,eyeIndex) = t(badPoints(bpIndex),eyeIndex) + dtavg;
        end
    end
end
dt = diff(t);
end

