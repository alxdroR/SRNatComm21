function [durations,ablationSizeCategory,varargout] = filterByAblationSize(durations,boundsOnTotalNumCells,ablationSizeCategory,varargin)
%filterByAblationSizeType
options = struct('aksayBootMethod',false);
options = parseNameValueoptions(options,varargin{:});


durationFieldNames = fieldnames(durations);
if length(durationFieldNames)==2
    baSeparate = true;
else
    baSeparate= false;
end

selectorNC = ablationSizeCategory.notControl.total >= boundsOnTotalNumCells(1) & ...
    ablationSizeCategory.notControl.total <= boundsOnTotalNumCells(2);

selectorC = ablationSizeCategory.control.total >= boundsOnTotalNumCells(1) & ...
    ablationSizeCategory.control.total <= boundsOnTotalNumCells(2);
varargout{1} = selectorC;
varargout{2} = selectorNC;
if baSeparate
    if options.aksayBootMethod
        error('Have not constructed the bootstrap method for this before and after section-ADR-9-8-2019');
    end
    expcnds = {'before','after'};
    for j=1:2
        durations.(expcnds{j}).inSRRF = durations.(expcnds{j}).inSRRF(selectorNC);
        durations.(expcnds{j}).outSRRF = durations.(expcnds{j}).outSRRF(selectorNC);
        durations.(expcnds{j}).controlL = durations.(expcnds{j}).controlL(selectorC);
        durations.(expcnds{j}).controlR = durations.(expcnds{j}).controlR(selectorC);
        durations.(expcnds{j}).control = durations.(expcnds{j}).control(selectorC);
        durations.(expcnds{j}).experiment = durations.(expcnds{j}).experiment(selectorNC);
    end
else
    durations.control = durations.control(selectorC);
    durations.experiment = durations.experiment(selectorNC);
    
    if ~options.aksayBootMethod
        durations.inSRRF = durations.inSRRF(selectorNC);
        durations.outSRRF = durations.outSRRF(selectorNC);
        durations.controlL = durations.controlL(selectorC);
        durations.controlR = durations.controlR(selectorC);
    end
end

ascFieldNames = fieldnames(ablationSizeCategory.control);
for i = 1 : length(ascFieldNames)
    ablationSizeCategory.control.(ascFieldNames{i}) = ablationSizeCategory.control.(ascFieldNames{i})(selectorC);
    ablationSizeCategory.notControl.(ascFieldNames{i}) = ablationSizeCategory.notControl.(ascFieldNames{i})(selectorNC);
end



end

