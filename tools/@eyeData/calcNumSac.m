function [num,eyeobj] = calcNumSac(eyeobj,varargin)
% rate = calcAvgRate(eyeobj,varargin)
% calculate total number of saccades in a given direction for a
% given eye over total time
%
% Names: plane, eye, direction
% values: #, {'left','right','both'}, {'left','right','both'}
% for both
% rate(1) - left eye, leftward
% rate(2) - left eye, rightward
options = struct('plane',1,'eye','left','direction','left');
options = parseNameValueoptions(options,varargin{:});

if isempty(eyeobj.saccadeTimes{1})
    eyeobj = eyeobj.saccadeDetection;
end
switch options.eye
    case 'left'
        eyeIndex = 1;
    case 'right'
        eyeIndex = 2;
    case 'both'
        eyeIndex = 1:2;
end

switch options.direction
    case 'left'
        dirIndex = 1;
    case 'right'
        dirIndex = 0;
    case 'both'
        dirIndex = 1:-1:0;
end

switch options.plane
    case 'all'
        options.plane = 1:length(eyeobj.position);
end

num = zeros(length(eyeIndex)*length(dirIndex),length(options.plane));
for k=1:length(options.plane)
    cnt =1;
    
    for i=1 : length(eyeIndex)
        if ~isempty(eyeobj.saccadeTimes{options.plane(k)}{eyeIndex(i)})
            for j=1:length(dirIndex)
                num(cnt,k) = sum(eyeobj.saccadeDirection{options.plane(k)}{eyeIndex(i)}==dirIndex(j));
                cnt = cnt+1;
            end
        end
    end
end
% rate = median(rate,2);
end