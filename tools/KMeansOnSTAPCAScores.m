function [bestSilValue,bestNumClus,meanSSE,meanSil,pcaModel,silValuesCell] = KMeansOnSTAPCAScores(scores,K)


% Cluster PCA model responses using information from both directions 
% ----------------------------------

% we want to cluster responses that are
N = size(scores)/2;
pcaModel = [scores(1:N,1:3)  scores(N+1:2*N,1:3)];


%K = 10;
meanSil = zeros(K,1);
meanSSE = zeros(K,1);
kmeansops = statset;
kmeansops.UseParallel=true;
silValuesCell = cell(length(2:K),1);
for k=2:K
    [idx,~,sumD] = kmeans(pcaModel,k,'Replicates',5,'Options',kmeansops);
    silValues = silhouette(pcaModel,idx);
    meanSil(k) = mean(silValues);
    silValuesCell{k-1} = silValues;
    meanSSE(k) = mean(sumD);
end
[bestSilValue,bestNumClus]=max(meanSil);

end

