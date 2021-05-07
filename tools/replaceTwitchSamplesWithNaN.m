function FwNaN = replaceTwitchSamplesWithNaN(F,twitchFrames)
%replaceTwitchSamplesWithNaN Sample points that occuring during a twitch
%are replaced with NaN
%  FwNaN = replaceTwitchSamplesWithNaN(F,twitchFrames)

if iscell(F)
    numPlanes = length(F);
    if ~iscell(twitchFrames)
        error('Both F and twitchFrames need to be of the same data type, e.g both cells, both matrices');
    end
    FwNaN = cell(numPlanes,1);
    for planeIndex = 1 : numPlanes
        T = size(F{planeIndex},1);
        FwNaN{planeIndex} = F{planeIndex};
        frames2change = twitchFrames{planeIndex};
        frames2change(frames2change<=0) = 1;
        frames2change(frames2change>T) = T;
        if ~isempty(F{planeIndex})
            FwNaN{planeIndex}(frames2change,:) = NaN;
        end
    end
else
    FwNaN = F;
    T = size(F,1);
    frames2change = twitchFrames;
    frames2change(frames2change<=0) = 1;
    frames2change(frames2change>T) = T;
    
    if ~isempty(F)
        FwNaN(frames2change,:)=NaN;
    end
end

