function  setFontProperties(ha,varargin)
% setFontProperties(ha)
% Set Font Properties to my preferred values and sizes 
% 
% ha -- matlab Axis Object (see
% https://www.mathworks.com/help/matlab/graphics-objects.html)
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020

options = struct('fontSize',7,'fontName','Arial','fontColor','k');
options = parseNameValueoptions(options,varargin{:});

xlabelObject = get(ha,'XLabel');
ylabelObject = get(ha,'YLabel');

% set the axis 
set(ha,'XColor',options.fontColor,'YColor',options.fontColor,'FontName',options.fontName,'FontSize',options.fontSize)
set(xlabelObject,'FontName',options.fontName,'FontSize',options.fontSize,'Color',options.fontColor);
set(ylabelObject,'FontName',options.fontName,'FontSize',options.fontSize,'Color',options.fontColor);

end

