function [nonActiveStat,activeStat,nonActiveCells,activeCells,fluorescence,cellIDs]=compareActiveNonActiveUseMOandNMFROIs(expIndex,planeIndexIN,hop,varargin)
options = struct('stat','MAD');
options = parseNameValueoptions(options,varargin{:});
% lop is little overlap percentage
% hop is high overlap percentage. If not numeric indicates that
% 'active cells are everything not considered lop';
%
% stat options {'MAD','Max','Top5','Corr'}

[fid,expCond] = listAnimalsWithImaging;

if ~isnumeric(expIndex)
    expIndexV = 1:20;
else
    expIndexV = expIndex;
end
activeCells=[];
%[~,smalldata]=rootDirectories;
cellIDs = struct('NMF',[],'MO',[]);
nonActiveStat = [];
activeStat = [];
for expIndex = expIndexV
    load(getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','catraces','caTraceType','MO'),'fluorescence','cellArea');
    load(getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','findOverlappingCells'));
    caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'NMF',true,'loadImages',false,'loadCCMap',false);
    
    if ~isnumeric(planeIndexIN)
        planeIndexV = 1:length(fluorescence);
    else
        planeIndexV = planeIndexIN;
    end
    
    for planeIndex=planeIndexV
        NMO=size(fluorescence{planeIndex},2);
        overlappingCellIndices = sameCells.EPvsIMO{planeIndex}(:,3)>=hop;
        if size(sameCells.EPvsIMO{planeIndex},1) == NMO
            % the indices in sameCells structure correspond to
            % indices of ROIs found by the morphological algorithm
            nonActiveCells = unique(sameCells.EPvsIMO{planeIndex}(~overlappingCellIndices,1));
        else
            % the indices in sameCells structure correspond to indices of
            % ROIS found by the NMF algorithm
            nonActiveCells = setdiff(1:NMO,unique(sameCells.EPvsIMO{planeIndex}(overlappingCellIndices,2)));
        end
        %         littleOverlap = sameCells.EPvsIMO{planeIndex}(:,3)<=lop;
        %         nCells = size(fluorescence{planeIndex},2);
        %         nCellsAll = length(cellArea{planeIndex});
        %         % we don't know which test produced more ROIs - the active algorithm or the
        %         % morphological opening. sameCells gives the % overlap for the algorithm
        %         % that gave the fewest cells
        %         if any(littleOverlap)
        %             if isnan(sameCells.EPvsIMO{planeIndex}(find(littleOverlap,1),1))
        %                 % active set has more ROIs (NaN,1,0)
        %                 nonActiveCells = sameCells.EPvsIMO{planeIndex}(littleOverlap,2);
        %             else
        %                 % IM open has more ROIs (3,NaN,0)
        %                 sameCells.EPvsIMO{planeIndex}(littleOverlap,1); % these could be active, false negatives or "active"
        %                 % regions that don't correspond to cells
        %
        %                 % these are the cells in the IMO set that don't have any
        %                 % correspondence with cells in the active set
        %                 nonActiveCells = [sameCells.EPvsIMO{planeIndex}(littleOverlap,2)' ...
        %                     setdiff(1:nCellsAll,unique(sameCells.EPvsIMO{planeIndex}(:,2)))];
        %                 nonActiveCells = nonActiveCells(~isnan(nonActiveCells));
        %             end
        %         else
        %             % somehow active ROIs and total cells all overlap
        %             nonActiveCells = 1:nCellsAll;
        %         end
        %          if isnumeric(hop)
        %             highOverlap = sameCells.EPvsIMO{planeIndex}(:,3)>=hop;
        %             activeCells = sameCells.EPvsIMO{planeIndex}(highOverlap,2);
        %          else
        %             activeCells = setdiff(1:nCellsAll,nonActiveCells);
        %          end
        %
        %         % temp problem fix
        %         maxCellArea = 12*12;
        %         q=find(cellArea{planeIndex}>maxCellArea);
        %         allCells = 1:nCellsAll;
        %         cellsInF = setdiff(allCells,q);
        %         for j=1:length(cellsInF)
        %             allCells(cellsInF(j)) = j;
        %         end
        %         allCells(q) = NaN;
        %         if planeIndex == 6 && expIndex==14
        %          %keyboard
        %         end
        %         % convert to index in F
        %         nonActiveCells = allCells(nonActiveCells);
        %         nonActiveCells = nonActiveCells(~isnan(nonActiveCells));
        %
        %         activeCells = allCells(activeCells);
        %         activeCells = activeCells(~isnan(activeCells));
        
        if strcmp(options.stat,'MAD')
            nonActiveMAD = median(abs(dff(fluorescence{planeIndex}(:,nonActiveCells))));
            activeMAD = median(abs(dff(caobj.fluorescence{planeIndex})));
            
            nonActiveStat = [nonActiveStat;nonActiveMAD'];
            activeStat = [activeStat;activeMAD'];
            
        elseif strcmp(options.stat,'Top5')
            nonActiveTop5 = quantile(dff(fluorescence{planeIndex}(:,nonActiveCells)),0.95);
            activeTop5 = quantile(dff(caobj.fluorescence{planeIndex}),0.95);
            
            nonActiveStat = [nonActiveStat;nonActiveTop5'];
            activeStat = [activeStat;activeTop5'];
        elseif strcmp(options.stat,'Max')
            nonActiveMax = max(dff(fluorescence{planeIndex}(:,nonActiveCells)));
            activeMax = max(dff(caobj.fluorescence{planeIndex}));
            
            nonActiveStat = [nonActiveStat;nonActiveMax'];
            activeStat = [activeStat;activeMax'];
            % size(caobj.fluorescence{10},2) ensures that nonactive cell
            % IDs will not overlap with NMF cell ids. 1:length(nonActive) ensures 
            % that we ignore overlapping cells
            numNMF = size(caobj.fluorescence{planeIndex},2);
            nonActiveCellIDs = numNMF + 1:length(nonActiveCells);
        
            cellIDs.NMF = [cellIDs.NMF;[ones(length(activeMax),1)*[expIndex planeIndex],...
                (1:numNMF)' true(numNMF,1)]];
             cellIDs.MO = [cellIDs.MO;[ones(length(nonActiveMax),1)*[expIndex planeIndex],...
                (1:length(nonActiveCells))' false(length(nonActiveCells),1)]];
        elseif strcmp(options.stat,'corr')
            % here is another fun stat -- the correlation between and a point imaged 3.1 seconds
            % later. noise and sngle spikes separated by long intervals should have no
            % correlation by these measure. multiple spikes should lead to correlations
            skip = 1;
            nonActiveCC=corr(fluorescence{planeIndex}(1:skip:200,nonActiveCells),fluorescence{planeIndex}(skip:skip:(200+skip),nonActiveCells));
            activeCC=corr(caobj.fluorescence{planeIndex}(1:skip:200,:),caobj.fluorescence{planeIndex}(skip:skip:(200+skip),:));
            
            nonActiveStat = [nonActiveStat;diag(nonActiveCC)];
            activeStat = [activeStat;diag(activeCC)];
        end
    end
end

end