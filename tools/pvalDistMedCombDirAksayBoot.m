function pvalDistMedCombDirAksayBoot()
%pvalDistMedCombDirAksayBoot - compute multiple sets of change in
%fixation duration after single-cell ablations, variable y in related methods
%section of the paper. Compute the p-values and distribution of means 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202x 

[~,~,fileDirs] = rootDirectories;
loadPreRunData = true;
if loadPreRunData
    load([fileDirs.scAblCVsTfd 'pvalDistMedCombDirAksayBoot.mat'],'data');
else
    % set random number generator
    rng('default')
    B = 100; % number of boots
    data = struct('durations',cell(B,1),'asc',cell(B,1));
    [~,~,numFixations,iscontrol]=populationDurationStats('summaryStat',@nanmedian,'computeChangeStat',true,'changeType','percent');
    for b = 1 : B 
        [durations,asc]=populationDurationStats('summaryStat',@nanmedian,'computeChangeStat',true,'changeType','percent','aksayBootMethod',numFixations);
        % now change durations to only include fields for ablations of multiple cells
        [durations,asc] = filterByAblationSize(durations,[7 25],asc,'aksayBootMethod',true);
        %[durations,asc] = filterByAblationSize(durations,[0 4],asc);
        
        data(b).durations=durations;
        data(b).asc = asc;
        fprintf('completed %d out of %d runs\n',b,B)
    end
    save([fileDirs.scAblCVsTfd 'pvalDistMedCombDirAksayBoot.mat'],'data');
end

% compute the results for sham ablation 
numFixations2use = 33;
shamNullDist = create1animal1pointNullDataSet('K',numFixations2use);
fprintf('non-ablated animals ...n=%d\n',sum(~isnan(shamNullDist.dBothStat)))
%%
% find distribution of means
B = length(data); 
meanSamples = NaN(B,2);
Pdist = zeros(B,1);
for b = 1 : B
    meanSamples(b,1) = nanmean(data(b).durations.experiment);
    meanSamples(b,2) = nanmean(data(b).durations.control);
    p=ranksum(data(b).durations.control,data(b).durations.experiment,'tail','left');
    Pdist(b) = p;
end
%%
fprintf('larger increases in fixation duration (%0.3f - %0.3f [min-max], median=%0.3f, n=%d bootstrap computations, see Methods)\n',...
    min(meanSamples(:,1)),max(meanSamples(:,1)),median(meanSamples(:,1)),B)
fprintf('than control targeted ablations(%0.3f - %0.3f [min-max], median=%0.3f)\n',...
    min(meanSamples(:,2)),max(meanSamples(:,2)),median(meanSamples(:,2)))
minP = min(Pdist);
maxP = max(Pdist);
medP = median(Pdist);
fprintf('p-values that ranged from %0.6f to %0.6f (median p-value equaled %0.6f).\n',minP,maxP,medP);

