function varargout = plotKTraces(time,Y,varargin)
% varargout = plotKTraces(time,Y,varargin) - plot simultaneously recorded
% neural traces 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020


options = struct('traceSpacing',1.3,'traceColor','b','traceLineWidth',1,...
    'showTraceIndex',true,'indexColor','r','indexFontSize',7,'axes',[],...
    'textFontColor','k','textFontSize',9,'textFontName','Arial','numberTraces',false);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.axes)
    figure; hold on;
else
    axes(options.axes); hold on;
end

numTraces = size(Y,2);
if size(time,2) == 1
    time = repmat(time(:),1,numTraces);
end
for ci=1:numTraces
    if strcmp(options.traceColor,'vary')
        plot(time(:,ci),Y(:,ci) + (ci-1)*options.traceSpacing,...
            'LineWidth',options.traceLineWidth);
    elseif iscell(options.traceColor)
         plot(time(:,ci),Y(:,ci) + (ci-1)*options.traceSpacing,...
            'color',options.traceColor{ci},'LineWidth',options.traceLineWidth);
    else
        plot(time(:,ci),Y(:,ci) + (ci-1)*options.traceSpacing,...
            'color',options.traceColor,'LineWidth',options.traceLineWidth);
    end
    if options.numberTraces
        text(time(1,ci)-6,Y(1,ci) + (ci-1+0.1)*options.traceSpacing,...
            num2str(ci),'color',options.textFontColor,'FontSize',options.textFontSize,'FontName',options.textFontName);
    end
    if options.showTraceIndex
        text(69,-(ci-1)*options.traceSpacing+0.4,num2str(ci),'color',options.indexColor,'FontSize',options.indexFontSize,'FontName','Arial')
    end
end

varargout{1} = gca;
end

