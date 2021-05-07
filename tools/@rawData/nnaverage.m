function [y,A]=nnaverage(F,ctrin,shapeRgnObj,varargin)
% nearest neighbor averaging
% [y,A]=nnaverage(F,ctrin,shapeRgnObj,varargin)
%  Input:
%       F - movie of size H,W,T

if isempty(varargin)
    chunkSize = 400;
else
    options = struct('chunkSize',400);
    options = parseNameValueoptions(options,varargin{:});
    chunkSize = options.chunkSize;
end
[H,W,T]=size(F);
if ischar(ctrin)
    nclass = W*H;
    ctr = [kron((1:W)',ones(H,1)) repmat((1:H)',W,1)];
else
    nclass = size(ctrin,1);
    ctr = ctrin;
end

if strcmp(shapeRgnObj.shape,'rect')
    y=zeros(T,nclass);
    for j=1:nclass
        ctr0 = ctr(j,:);
        shapeRgnObj.center = ctr0;
        [indI,indJ] = shapeRgnObj.makeBoxIndices;
        % calculate indices of local neighborhood
        pixelTraces = F(indI,indJ,:);
        rowSum = sum(pixelTraces,1);
        columnSum = sum(rowSum,2);
        spatialAvg = columnSum/( (indJ(end)-indJ(1)+1)*(indI(end)-indI(1)+1));
        y(:,j) = reshape(spatialAvg,[T,1]);
    end
else
    F = single(reshape(F,[H*W,T]));
    y=zeros(nclass,T);
    numSections = ceil(nclass/chunkSize);
    for section = 1 : numSections
        if section == numSections
            chunkIndices = 1:(nclass-(section-1)*chunkSize);
        else
            chunkIndices = (1:chunkSize);
        end
        idxInSection = chunkIndices + (section-1)*chunkSize;
        ctrSection = ctr(idxInSection,:);
        A = zeros(H*W,length(chunkIndices));
        for j = chunkIndices
            shapeRgnObj.center = ctrSection(j,:);
            A(:,j) = reshape(shapeRgnObj.makeFootprint,H*W,1);
        end
        numPixels = sum(A)';
        numPixels = max(numPixels,1);
        y(idxInSection,:) = (A'*F)./numPixels;
    end
    y = y';
end

end % end nnaverage
