function [varargout] = calcSTA2Time2TimeIndex(timeVector,findIndexOfTheseTimes)
numberOfTimes2find = length(findIndexOfTheseTimes);
varargout = cell(numberOfTimes2find,1);
for i = 1 : numberOfTimes2find
    [~,varargout{i}] = min(barrierALEX(timeVector-findIndexOfTheseTimes(i),0,Inf));
end
end

