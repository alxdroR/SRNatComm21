function [saccadeDirectionsMatrix,animalID]=jointSaccadeAmplitudeDistributionPopAggregate(varargin)
options = struct('opt1',0);
options = parseNameValueoptions(options,varargin{:});


[fid,expcond] = listAnimalsWithImaging;
eyeLabels = {'left','right'};
saccadeDirectionsMatrix = struct('left',[],'right',[]);
animalID = struct('left',[],'right',[]);
for expIndex = 1:length(fid)
    if ischar(fid{expIndex})
        eyeobj=eyeData('fishid',fid{expIndex},'expcond',expcond{expIndex});
    else
        eyeobj=eyeData('fishid',fid{expIndex},'expcond',expcond{expIndex});
    end
    eyeobj = eyeobj.saccadeDetection;
    numPlanes = length(eyeobj.position);
    for planeIndex = 1 : numPlanes
        for eyeIndex = 1 :2
            saccadeDirectionsVector = eyeobj.saccadeAmplitude{planeIndex}{eyeIndex};
            saccadeDirectionsMatrix.(eyeLabels{eyeIndex}) = [saccadeDirectionsMatrix.(eyeLabels{eyeIndex});[saccadeDirectionsVector(1:end-1) saccadeDirectionsVector(2:end)]];
            animalID.(eyeLabels{eyeIndex}) = [animalID.(eyeLabels{eyeIndex});...
                [ones(length(saccadeDirectionsVector)-1,1)*[expIndex planeIndex] eyeobj.saccadeTimes{planeIndex}{eyeIndex}(1:end-1,1)]];
        end
    end
end

