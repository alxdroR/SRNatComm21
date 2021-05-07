function cellIndex=plane2ind(caobj,subIndex,plane)
% cellIndex=plane2ind(caobj,subIndex,plane)
% Output
% cellIndex - index of cell in an array containing all
%             identified cells in this fish
% Input
% subIndex -  index of that cell in its respective recording
%               plane
% plane    -  plane cell number cellIndex was recorded in
offset = 0;
for plne=1:plane-1
    offset = offset + size(caobj.fluorescence{plne},2);
end
if ischar(subIndex)
    [~,N] = size(caobj.fluorescence{plane});
    subIndex = 1:N;
end
    cellIndex = subIndex + offset;
end