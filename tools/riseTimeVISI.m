function riseTimeVISI(varargin)
% riseTimeVISI - average time of SR activity rise normalized by fixation
% duration as a function of fixation duration
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
global saveCSV
options = struct('AnticipatoryAnalysisMatrix',[],'ISIMatrix',[],'SRMatrixIDs',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.AnticipatoryAnalysisMatrix) || isempty(options.ISIMatrix)
    loadSRSlopes
else
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
    ISIMatrix = options.ISIMatrix;
    fixationIDs = options.SRMatrixIDs;
end
riseTimes = AnticipatoryAnalysisMatrix(:,2);
% normalized rise times
normedRiseTimes = riseTimes./ISIMatrix; % rise-times w.r.t upcoming saccade divided by ISI
riseMeasured = ~isnan(riseTimes);

% calculate best fit line for normalized data
normRiseTimeVISIRegressionObjection = LinearModel.fit(ISIMatrix(riseMeasured),normedRiseTimes(riseMeasured));

% format data to plot into a sharable format
data.fd = ISIMatrix(riseMeasured);
data.riseNormed = normedRiseTimes(riseMeasured);
data.riseUS = riseTimes(riseMeasured);
data.lmodObj = normRiseTimeVISIRegressionObjection;

% plot
% create function for evaluating non-normalized data
rtVISIFnc = @(x) (data.lmodObj.Coefficients.Estimate(2)*x.^2 + data.lmodObj.Coefficients.Estimate(1)*x);

addBestFitLines = true;
bestFitLineColor = 'k';
YLABEL1 = {'activity rise-time' 'normalized by fixation duration'};
YLABEL2 = {'time of activity rise' 'relative to upcoming saccade (s)'};
XLABEL = 'fixation duration (s)';
YLIMRiseTimes = [-11 0];
YLIMNormedRiseTimes = [-1 0];
XLIM = [0 30];
binCenters = 1.5:27.5;
paperWidth = 4.4;
paperHeight = 2.2;
paperPosition = [0 0 paperWidth paperHeight];
pB = plotBinner([data.fd data.riseNormed],binCenters);
[binnedData,binVar,nSampTORErrorbar,binCenters] = binData(pB,'median',false);
binnedData(nSampTORErrorbar<10)=NaN;se = sqrt(binVar./nSampTORErrorbar);
subplot(121);
errorbar(binCenters,binnedData,se,se); hold on;
if addBestFitLines
    plot(binCenters,data.lmodObj.feval(binCenters),'Color',bestFitLineColor)
end
ylim(YLIMNormedRiseTimes);xlim(XLIM); box off; xlabel(XLABEL);ylabel(YLABEL1); setFontProperties(gca)

pB = plotBinner([data.fd data.riseUS],binCenters);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',false);
binnedData(numberSamp<10)=NaN;se = sqrt(binVar./numberSamp);
subplot(122);
errorbar(binCenters,binnedData,se,se); hold on;
plot(binCenters,-binCenters,'k--');
if addBestFitLines
    plot(binCenters,rtVISIFnc(binCenters),'Color',bestFitLineColor)
end
ylim(YLIMRiseTimes);xlim(XLIM); box off; xlabel(XLABEL);ylabel(YLABEL2); setFontProperties(gca)
set(gcf,'PaperPosition',paperPosition)

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

% print stats quoted in the paper
[nc,nf,ne]=getSampleSizeFromSRMatrix(fixationIDs(~isnan(riseTimes),:));
fprintf('%d fixations from %d cells examined over %d independent fish\n',ne,nc,nf)
fprintf('sample size per bin ranges from %d-%d fixations\n',max(10,min(nSampTORErrorbar)),max(nSampTORErrorbar));
fprintf('\n\nthere was a slight trend for activity to rise relatively quickly after the\nprevious saccade during short fixation durations and\nfor activity to rise later in the interval ')
fprintf('during longer fixations\n(Fig. 4G;')
fprintf('best fit line slope = %0.3f +- %0.3f(1/s), offset = %0.3f +- %0.3f).\n\n',data.lmodObj.Coefficients.Estimate(2),data.lmodObj.Coefficients.SE(2),...
    data.lmodObj.Coefficients.Estimate(1),data.lmodObj.Coefficients.SE(1))

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 4g.csv'],'a');
    fprintf(fileID,'Panel\ng\n');
    
    pB = plotBinner([data.fd data.riseNormed],binCenters);
    indices2bin = binData(pB,'onlyReturnIndicesPerBin',true);
    numSamp = cellfun(@(x) size(x,1),indices2bin);
     IDs = fixationIDs(~isnan(riseTimes),:);
    for k = 1 : length(binCenters)
       if numSamp(k) >= 10
            fprintf(fileID,'\nfixation duration(s),%0.3f',binCenters(k));
            fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Within-Plane Cell ID,Sample Index,normalized time of activity rise\n');
            dlmwrite([fileDirs.scDataCSV 'Figure 4g.csv'],[IDs(indices2bin{k},:) (1:numSamp(k))' pB.data(indices2bin{k},2)],'delimiter',',','-append');
           %     
           % sampleMatrix(1:length(indices2bin{k}),k) = pB.data(indices2bin{k},2);
        end
    end
    fclose(fileID);
end
