function countours = footprint2Contour(A,H,W,varargin)

nCells = size(A,2);
countours = cell(nCells,1);
for cellIndex = 1 : nCells
    binaryFootprint = (A(:,cellIndex)~=0);
    [nzRow,nzCol]=find(reshape(binaryFootprint,H,W));
    chInd = convhull([nzCol,nzRow]);
    countours{cellIndex} = [nzCol(chInd),nzRow(chInd)];
end
end

