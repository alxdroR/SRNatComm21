function rangeVector=posRangePopAggregate(varargin)
options = struct('opt1',0,'rangeLower',0.01,'rangeUpper',0.99);
options = parseNameValueoptions(options,varargin{:});


fid = listAnimalsWithImaging;
rangeVector = zeros(length(fid),2);
for expIndex = 1:length(fid)
    if ischar(fid{expIndex})
        eyeobj=eyeData('fishid',fid{expIndex},'locationid',1,'expcond','before');
    else
        eyeobj=eyeData('fishid',fid{expIndex},'locationid',1,'expcond',[]);
    end
    
    PSingleAnimal = [];
    numPlanes = length(eyeobj.position);
    for planeIndex = 1 : numPlanes       
            E = eyeobj.centerEyesMethod('planeIndex',planeIndex);
            PSingleAnimal = [ PSingleAnimal; E];       
    end
    rangeVector(expIndex,:) = mean(quantile(PSingleAnimal,[options.rangeLower options.rangeUpper]),2); % average quantiles across eyes 
end

