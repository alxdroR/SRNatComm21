function [splitData,splitIndex,varargout] = spontDataSplitPlanes(fid2check,varargin)
% The dataset in zfishEyeMappingData contains two animals whose files are
% the concatenation of a rostraly imaged set of images from dorsal-ventral
% and a caudally imaged set.
%
% data2split must be a matrix
% the dimension to split must be the last one
fid = listAnimalsWithImaging;
splitData = false;
if ~isempty(intersect(fid2check,{fid{1},fid{5},fid{14}}))
    splitData = true;
    if strcmp(fid2check,fid{1})
            splitIndex = 39;
        elseif strcmp(fid2check,fid{5})
            splitIndex = 29;
        elseif strcmp(fid2check,fid{14})
            splitIndex = 6;
    end
    if ~isempty(varargin)
        data2split = varargin{1};
        numDimData = ndims(data2split);
        if numDimData ==2
            [n1,n2]=size(data2split);
            if (n1==1) || (n2==1)
                numDimData=1;
                N = length(data2split);
            else
                N = size(data2split,numDimData);
            end
        else
            N = size(data2split,numDimData);
        end
        splitSet = {1:splitIndex,(splitIndex+1):N};
        if numDimData == 1
            dataOut = {data2split(splitSet{1}),data2split(splitSet{2})};
        elseif numDimData == 2
            dataOut = {data2split(:,splitSet{1}),data2split(:,splitSet{2})};
        elseif numDimData == 3
            dataOut = {data2split(:,:,splitSet{1}),data2split(:,:,splitSet{2})};
        end
        varargout{1} = dataOut;
    end
else
    splitIndex = NaN;
    if ~isempty(varargin)
        varargout{1} = varargin{1};
    end
end
end

