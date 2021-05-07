function rsave=getCCIndices(maxcp,minCC,minDist,edgeExclusionSize,Iflt,maxIntWindow)
[H,W] = size(maxcp);
imgSize = [H,W];
%edgeExclusionSize = 13;
Wbrder = [edgeExclusionSize W-edgeExclusionSize];
Hbrder = [edgeExclusionSize H-edgeExclusionSize];
% sort calcium pixels
[sortedMaxCC,srtind]=sort(maxcp(:),'descend');

% I would think initial elimination of points outside of exclusion border would lead to same answers
% but faster .... couldn't figure this out
%inElRows = [repmat((1:H)',Wbrder(1),1);repmat((1:H)',imgSize(2)-Wbrder(2)+1,1)];
%inElCols = [kron((1:Wbrder(1))',ones(H,1));kron((Wbrder(2):imgSize(2))',ones(H,1))];
%inElInds = sub2ind(imgSize,inElRows,inElCols);
%relevantPixels = setdiff(1:W*H,inElInds);
% sort calcium pixels
%[sortedMaxCC,srtind]=sort(maxcp(relevantPixels),'descend');
boxRgnObj = rectImgRgns('length',maxIntWindow,'width',maxIntWindow,'imgSize',imgSize);
for j=1:length(srtind)
    % correlated pixel location
    [I1,J1]=ind2sub([imgSize(2),imgSize(1)],srtind(j));
    
    % center at the point with maximal intensity
    boxRgnObj.center = [J1,I1];
    [I1a,J1a] = rawData.maxVal2D(Iflt,boxRgnObj);
    
    % decide if we should we keep this point
    if j>1
        if J1a>Wbrder(1) && J1a < Wbrder(2)
            if I1a > Hbrder(1) && I1a < Hbrder(2)
                
                % decide whether we should exclude the point
                D = sqrt(sum(([J1a,I1a]-rsave).^2,2));
                r2 = rsave(D>=minDist,:);
                if  size(r2,1)==size(rsave,1)
                    rsave = [rsave;[J1a I1a]];
                    cnt = size(rsave,1);
                end
            end
        end
    else
        rsave = [J1a,I1a];% note that the first point gets a pass on the border requirement
    end
    % continue untill we reach pixels below correlation cut-off
    if sortedMaxCC(j) < minCC
        break
    end
end
end
