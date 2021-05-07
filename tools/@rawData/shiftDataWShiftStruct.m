function shiftedData = shiftDataWShiftStruct(shiftX,scaleX,data,isImage)
shiftedData = data;
scaleShiftX =preRegShift([],'scaleX',scaleX,'shiftX',shiftX);
if sum(scaleShiftX)~=0
    N = length(scaleShiftX);
    if isImage
        [H,W,Ndata] = size(data);
        if Ndata ~= N
            error('Image must have same nuber of planes as that in shiftX');
        end
        shiftedData = zeros(H,W+max(abs(scaleShiftX)),N,class(data));
    end
    for n = 1 : N
        if isImage
            shiftedData(:,(1:W) + scaleShiftX(n),n) = data(:,:,n);
        else
            planeInd = data(:,3)==n;
            shiftedData(planeInd,1) = data(planeInd,1) + scaleShiftX(n);
        end
    end
end
end

