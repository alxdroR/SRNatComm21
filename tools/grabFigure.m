function  figureHandle=grabFigure(figureHandle)
if isempty(figureHandle)
    figureHandle=figure;
else
    figure(figureHandle);
end
end

