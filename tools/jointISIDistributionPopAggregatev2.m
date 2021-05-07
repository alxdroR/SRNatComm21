function [saccadeDirectionsMatrix,animalID]=jointISIDistributionPopAggregatev2(varargin)
% [saccadeDirectionsMatrix,animalID]=jointISIDistributionPopAggregatev2 -
% load fixation durations across all animals with calcium imaging   
% 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 

[fid,expCond] = listAnimalsWithImaging;
eyeLabels = {'left','right'};
saccadeDirectionsMatrix = struct('left',[],'right',[]);
animalID = struct('left',[],'right',[]);
for expIndex = 1:length(fid)
    eyeobj=eyeData('fishid',fid{expIndex},'expcond',expCond{expIndex});
    eyeobj = eyeobj.saccadeDetection;
    numPlanes = length(eyeobj.position);
    for planeIndex = 1 : numPlanes
        for eyeIndex = 1 :2
            saccadeDirectionsVector = diff(eyeobj.saccadeTimes{planeIndex}{eyeIndex}(:,1));
            saccadeDirectionsMatrix.(eyeLabels{eyeIndex}) = [saccadeDirectionsMatrix.(eyeLabels{eyeIndex});[saccadeDirectionsVector]];
            animalID.(eyeLabels{eyeIndex}) = [animalID.(eyeLabels{eyeIndex});...
                [ones(length(saccadeDirectionsVector),1)*[expIndex planeIndex] eyeobj.saccadeTimes{planeIndex}{eyeIndex}(1:end-1,1)]];
        end
    end
end

