function [nonActiveStat,activeStat,nonActiveCells,activeCells,fluorescence]=compareActiveNonActive(expIndex,planeIndexIN,lop,hop,varargin)
options = struct('stat','MAD');
options = parseNameValueoptions(options,varargin{:});
% lop is little overlap percentage
% hop is high overlap percentage. If not numeric indicates that
% 'active cells are everything not considered lop';
%
% stat options {'MAD','Max','Top5','Corr'}
[fid,expCond] = listAnimalsWithImaging;
if ~isnumeric(expIndex)
    expIndexV = 1:length(fid);
else
    expIndexV = expIndex;
end
nonActiveStat = [];
activeStat = [];
for expIndex = expIndexV
    % motionCorrectIMOpenCaExtract
    load(getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','catraces','caTraceType','MO') ,'fluorescence','cellArea');
    % motionCorrectOverlappingCellsALL.m
    load(getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','findOverlappingCells'),'sameCells')
    if ~isnumeric(planeIndexIN)
        planeIndexV = 1:length(fluorescence);
    else
        planeIndexV = planeIndexIN;
    end
    for planeIndex=planeIndexV
        littleOverlap = sameCells.EPvsIMO{planeIndex}(:,3)<=lop;
        nCells = size(fluorescence{planeIndex},2);
        nCellsAll = length(cellArea{planeIndex});
        % we don't know which test produced more ROIs - the active algorithm or the
        % morphological opening. sameCells gives the % overlap for the algorithm
        % that gave the fewest cells
        if any(littleOverlap)
            if isnan(sameCells.EPvsIMO{planeIndex}(find(littleOverlap,1),1))
                % active set has more ROIs (NaN,1,0)
                nonActiveCells = sameCells.EPvsIMO{planeIndex}(littleOverlap,2);
            else
                % IM open has more ROIs (3,NaN,0)
                sameCells.EPvsIMO{planeIndex}(littleOverlap,1); % these could be active, false negatives or "active"
                % regions that don't correspond to cells
                
                % these are the cells in the IMO set that don't have any
                % correspondence with cells in the active set
                nonActiveCells = [sameCells.EPvsIMO{planeIndex}(littleOverlap,2)' ...
                    setdiff(1:nCellsAll,unique(sameCells.EPvsIMO{planeIndex}(:,2)))];
                nonActiveCells = nonActiveCells(~isnan(nonActiveCells));
            end
        else
            % somehow active ROIs and total cells all overlap
            nonActiveCells = 1:nCellsAll;
        end
        if isnumeric(hop)
            highOverlap = sameCells.EPvsIMO{planeIndex}(:,3)>=hop;
            activeCells = sameCells.EPvsIMO{planeIndex}(highOverlap,2);
        else
            activeCells = setdiff(1:nCellsAll,nonActiveCells);
        end
        
        % temp problem fix
        maxCellArea = 12*12;
        q=find(cellArea{planeIndex}>maxCellArea);
        allCells = 1:nCellsAll;
        cellsInF = setdiff(allCells,q);
        for j=1:length(cellsInF)
            allCells(cellsInF(j)) = j;
        end
        allCells(q) = NaN;
        if planeIndex == 6 && expIndex==14
            %keyboard
        end
        % convert to index in F
        nonActiveCells = allCells(nonActiveCells);
        nonActiveCells = nonActiveCells(~isnan(nonActiveCells));
        
        activeCells = allCells(activeCells);
        activeCells = activeCells(~isnan(activeCells));
        
        if strcmp(options.stat,'MAD')
            nonActiveMAD = median(abs(dff(fluorescence{planeIndex}(:,nonActiveCells))));
            activeMAD = median(abs(dff(fluorescence{planeIndex}(:,activeCells))));
            
            nonActiveStat = [nonActiveStat;nonActiveMAD'];
            activeStat = [activeStat;activeMAD'];
            
        elseif strcmp(options.stat,'Top5')
            nonActiveTop5 = quantile(dff(fluorescence{planeIndex}(:,nonActiveCells)),0.95);
            activeTop5 = quantile(dff(fluorescence{planeIndex}(:,activeCells)),0.95);
            
            nonActiveStat = [nonActiveStat;nonActiveTop5'];
            activeStat = [activeStat;activeTop5'];
        elseif strcmp(options.stat,'Max');
            nonActiveMax = max(dff(fluorescence{planeIndex}(:,nonActiveCells)));
            activeMax = max(dff(fluorescence{planeIndex}(:,activeCells)));
            
            nonActiveStat = [nonActiveStat;nonActiveMax'];
            activeStat = [activeStat;activeMax'];
        elseif strcmp(options.stat,'corr')
            % here is another fun stat -- the correlation between and a point imaged 3.1 seconds
            % later. noise and sngle spikes separated by long intervals should have no
            % correlation by these measure. multiple spikes should lead to correlations
            skip = 1;
            nonActiveCC=corr(fluorescence{planeIndex}(1:skip:200,nonActiveCells),fluorescence{planeIndex}(skip:skip:(200+skip),nonActiveCells));
            activeCC=corr(fluorescence{planeIndex}(1:skip:200,activeCells),fluorescence{planeIndex}(skip:skip:(200+skip),activeCells));
            
            nonActiveStat = [nonActiveStat;diag(nonActiveCC)];
            activeStat = [activeStat;diag(activeCC)];
        end
    end
end

end