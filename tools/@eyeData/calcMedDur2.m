function [dur,eyeobj,ISIAllPlanes] = calcMedDur2(eyeobj,varargin)
%  dur = calcAvgDur(eyeobj,varargin)
% calculate average time spent at a position after a leftward/rightward saccade for a
% given eye.
%
% Names: plane, eye, direction
% values: #, {'left','right','both'}, {'left','right','both'}
% for both
% dur(1) - left eye, leftward
% dur(2) - left eye, rightward
options = struct('plane',1,'eye','left','direction','left','ISI',false,'sacTh',true,'maxRecordingTime','none');
options = parseNameValueoptions(options,varargin{:});

if isempty(eyeobj.saccadeTimes{1})
    eyeobj = eyeobj.saccadeDetection;
end
eyes = {'left','right'};
switch options.eye
    case 'left'
        eyeIndex = 1;
    case 'right'
        eyeIndex = 2;
    case 'both'
        eyeIndex = 1:2;
        if nargout>2
            warning('call this function with right and left eye separately to get ISI samples');
        end
end
switch options.direction
    case 'left'
        dirIndex = 1;
    case 'right'
        dirIndex = 0;
    case 'both'
        dirIndex = 1:-1:0;
        if nargout>2
            warning('call this function with right and left direction separately to get ISI samples');
        end
end
%  eyeobj = removeNonSimultaneous(eyeobj);
switch options.plane
    case 'all'
        options.plane = 1:length(eyeobj.position);
end
if options.ISI
    dur = [];
    stdISI = [];
else
    dur = zeros(length(eyeIndex)*length(dirIndex),1);
    stdISI = zeros(length(eyeIndex)*length(dirIndex),1);
end
% localRate = eyeobj.calcMedRate('eye','both','direction','both','plane','all');
if options.sacTh
    numThreshold = 5;
else
    numThreshold = 0;
end
cnt =1;
for i=1 : length(eyeIndex)
    for j=1:length(dirIndex)
        ISIAllPlanes = [];
        if dirIndex(j)==1
            nsac = eyeobj.calcNumSac('eye',eyes{eyeIndex(i)},'direction','left','plane','all');
        else
            nsac = eyeobj.calcNumSac('eye',eyes{eyeIndex(i)},'direction','right','plane','all');
        end
        if sum(nsac) >= numThreshold
            for k=1:length(options.plane)
                %  isGoodPlane = localRate(1,k) >= rateThreshold & localRate(2,k) >= rateThreshold ;
                %if isGoodPlane
                if length(eyeobj.saccadeTimes{options.plane(k)}{eyeIndex(i)})>1
                    if strcmp(options.maxRecordingTime,'none')
                        saccadeTimeEnd = eyeobj.time{options.plane(k)}(end,1);
                    else
                        saccadeTimeEnd = options.maxRecordingTime;
                    end
                    saccadeStartTimes = eyeobj.saccadeTimes{options.plane(k)}{eyeIndex(i)}(:,1);
                    saccadesToKeep  = saccadeStartTimes <= saccadeTimeEnd;
                    saccadeStartTimes = saccadeStartTimes(saccadesToKeep);
                    saccadeDirections = eyeobj.saccadeDirection{options.plane(k)}{eyeIndex(i)};
                    saccadeDirections = saccadeDirections(saccadesToKeep);
                    
                    
                    currDirIndex = saccadeDirections(1:end-1)==dirIndex(j);
                    ISI = diff(saccadeStartTimes);
                    ISIAllPlanes = [ISIAllPlanes;ISI(currDirIndex)];
                end
                % end
            end
        else
            warning('Total number of fixations must be greater than 5 for use. Disqualifying this animal-2/17/2016');
        end
        if ~isempty(ISIAllPlanes)
            % median inter-saccade interval in the right direction
            dur(cnt) = median(ISIAllPlanes);
            stdISI(cnt) = std(ISIAllPlanes);
        else
            dur(cnt) = NaN;
            stdISI(cnt)=NaN;
        end
        cnt = cnt+1;
        
        
    end
end
end