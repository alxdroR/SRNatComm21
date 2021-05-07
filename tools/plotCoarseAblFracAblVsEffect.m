function plotCoarseAblFracAblVsEffect(data)% plot
global saveCSV

ind2show=find(data.numFish==29);
%ind2show=find(data.numFish==10);
minNumFixCut = data.minNumFixations;
minNumFixCut(data.minNumFixations<data.NminFloorValues(ind2show))=NaN;
Nmin = min(minNumFixCut);
numResamples = round(minNumFixCut./Nmin);
fracAblated = expandGFAbl2Resamples(data.fracAblated,numResamples);

showAvg = true;
figure;
if showAvg
    %binCenters = 0:0.001:0.1;
    binCenters = 0:0.02:0.1;
    %pB = plotBinner([repmat(fracAblated.Ant,100,1),100*data.effectSize{ind2show}(:)],binCenters);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',false);
    pB = plotBinner([fracAblated.Ant,100*data.effectSize{ind2show}(:,10)],binCenters);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',false);
   
    binnedData(numberSamp<5)=NaN;
    eh=errorbar(binCenters(~isnan(binnedData)),binnedData(~isnan(binnedData)),sqrt(binVar(~isnan(binnedData))./numberSamp(~isnan(binnedData))),'.-'); hold on;
    pointColor = [1 1 1]*0.6;
else
    pointColor = 'b';
end
pointColor = [1 1 1]*0.6;
plot(fracAblated.Ant,100*data.effectSize{ind2show}(:,10),'.','Color',pointColor);xlabel('fraction of SR cell population ablated');ylabel('% change in median fixation duration');
box off;setFontProperties(gca)
lmod=LinearModel.fit(repmat(fracAblated.Ant,100,1),100*data.effectSize{ind2show}(:));
hold on; plot(sort(repmat(fracAblated.Ant,100,1)),lmod.Coefficients.Estimate(1) + sort(repmat(fracAblated.Ant,100,1))*lmod.Coefficients.Estimate(2),'Color','k','LineWidth',0.5);
set(gca,'XTick',[0:0.02:0.1]);ylim([-50 150]);xlim([-0.01 0.1])%ylim([-100 250]);xlim([-0.01 0.1])
set(gcf,'PaperPosition',[0 0 2.2 2.2])
fprintf('fig 7 legend: CC between ... SR population lost is %0.3f\n',nancorr(repmat(fracAblated.Ant,100,1),100*data.effectSize{ind2show}(:)))
% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

minNumFixCut = data.minNumFixations(data.minNumFixations>=data.NminFloorValues(ind2show));
Nmin = min(minNumFixCut);
numResamples = round(minNumFixCut./Nmin);
fprintf('Each point is constructed using %d randomly selected samples from a single fish\n',Nmin);
fprintf('%d gray points sampled from %d fish are displayed\n',sum(~isnan(data.effectSize{ind2show}(:,10))),data.numFish(ind2show));
fprintf('Error bars: N = %d Bootstrap samples independently selected from %d fish (see Methods)\n',sum(~isnan(data.effectSize{ind2show}(:,10))),data.numFish(ind2show))
fprintf('The number of bootstrap samples per bin ranges from %d-%d\n',min(numberSamp),max(numberSamp))

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 7d.csv'],'a');
    fprintf(fileID,'Panel\nd\n');
    fprintf(fileID,'\nAnimal ID,Sample Index,Fraction of SR Pop. Ablated, %% change median fixation duration\n');
    treated = ~isnan(fracAblated.Ant);
    matrix2print  = [data.effectAnID{ind2show}(treated),(1:sum(treated))',fracAblated.Ant(treated),100*data.effectSize{ind2show}(treated,10)];
    [~,sortID] = sort(matrix2print(:,3));
    matrix2print = matrix2print(sortID,:);
    matrix2print(:,2) = (1:sum(treated))';
    dlmwrite([fileDirs.scDataCSV 'Figure 7d.csv'],matrix2print,'delimiter',',','-append');
    fclose(fileID);
end
end