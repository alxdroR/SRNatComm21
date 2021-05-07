function [nmin,Nmin,numResamples] = aksayResampleNumFixationStats(numFix4boot)
nmin = min([sum(numFix4boot.B,2) sum(numFix4boot.A,2)],[],2);
Nmin = min(nmin);
numResamples = round(nmin./Nmin);
end

