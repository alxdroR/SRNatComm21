function varargout = numberSingleSRCellsAblated()
% numberSingleSRCellsAblated - report how many SR cells were ablated 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020 


[~,asc,numFixations,iscontrol]=populationDurationStats('summaryStat',@nanmedian,'computeChangeStat',true,'changeType','percent');

% remove early test animals that had <4 cells ablated and present the table
numberSRAblated = asc.notControl.total(asc.notControl.total>=4);

fprintf('resulting in the ablation of %d-%d cells in total\n',min(numberSRAblated),max(numberSRAblated))
varargout{1}=asc;
varargout{2} = numFixations;
varargout{3} = iscontrol;