function rampVRiseTimeSameDirSaccades(varargin)
% rampVRiseTimeSameDirSaccades
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202
global saveCSV

options = struct('AnticipatoryAnalysisMatrix',[],'YLABEL',[],'YLIM',[],'showBinMedian',false,'minNumSamples',10,'missingSampVal',NaN,'SRMatrixIDs',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.AnticipatoryAnalysisMatrix) 
   loadSRSlopes
else
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
    fixationIDs = options.SRMatrixIDs;
end
%% Extract the relevant information from the analyses matrices
% find the slopes measured after a saccade occurred in the same direction
sameDir = AnticipatoryAnalysisMatrix(:,10);


gof = AnticipatoryAnalysisMatrix(:,5);
% For the slopes to have any meaning the linear model must be valid. There
% are cases where this is not true
gofCriteria = gof>=0.4;
slopesSameDir = AnticipatoryAnalysisMatrix(gofCriteria & sameDir ,1); % slopesSameDir 
RtimeSameDir = AnticipatoryAnalysisMatrix(gofCriteria & sameDir,2); % rise-times 

slopesOppDir = AnticipatoryAnalysisMatrix(gofCriteria & ~sameDir ,1); % slopesSameDir 
RtimeOppDir = AnticipatoryAnalysisMatrix(gofCriteria & ~sameDir,2); % rise-times 


figure;binCenters = -10.5:0.5:0;
pB = plotBinner([RtimeSameDir slopesSameDir],binCenters);
[binnedData,binVar,numberSampSame,binCenters] = binData(pB,'median',options.showBinMedian,'minNumSamples',options.minNumSamples,'missingSampVal',options.missingSampVal);
errorbar(binCenters,binnedData,sqrt(binVar./numberSampSame)); hold on;

binCenters = -10.5:0.5:0;
pB = plotBinner([RtimeOppDir slopesOppDir],binCenters);
[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',options.showBinMedian,'minNumSamples',options.minNumSamples,'missingSampVal',options.missingSampVal);
errorbar(binCenters,binnedData,sqrt(binVar./numberSamp),'Color',[1 1 1]*0.06); hold on;
if ~isempty(options.YLIM)
    ylim(options.YLIM);
end
xlim([-11.1 -0.5]);box off;xlabel('time of activity rise (s)');ylabel(options.YLABEL);setFontProperties(gca)

[ncS,nfS,neS]=getSampleSizeFromSRMatrix(fixationIDs(gofCriteria & sameDir,:));
[ncO,nfO,neO]=getSampleSizeFromSRMatrix(fixationIDs(gofCriteria & ~sameDir,:));
fprintf('Same Direction: %d fixations from %d cells examined over %d independent fish\n',neS,ncS,nfS)
fprintf('sample size per bin ranges from %d-%d fixations\n',max(0,min(numberSampSame)),max(numberSampSame));
fprintf('Oppo Direction: %d fixations from %d cells examined over %d independent fish\n',neO,ncO,nfO)
fprintf('sample size per bin ranges from %d-%d fixations\n',max(0,min(numberSamp)),max(numberSamp));


global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    set(gcf,'PaperPosition',[0 0 2.2 2.2])
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
     end
    print(gcf,'-dpdf',[figurePDir thisFileName])
   % print(gcf,'-dpdf',[rootLocation '\resubmission\figuresNEW\figurePanels\rampVRiseTime'])
end
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 5.csv'],'a');
    fprintf(fileID,'Panel\nc\n');
    
    fprintf(fileID,'same direction\n');
    pB = plotBinner([RtimeSameDir slopesSameDir],binCenters);
    indices2bin = binData(pB,'onlyReturnIndicesPerBin',true);
    numSamp = cellfun(@(x) size(x,1),indices2bin);
    IDs = fixationIDs(gofCriteria,:);
    for k = 1 : length(binCenters)
       if numSamp(k) >= options.minNumSamples
            fprintf(fileID,'\ntime of activity rise(s),%0.3f',binCenters(k));
            fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Within-Plane Cell ID,Sample Index,slope(arb. units),same direction(1=yes/0=no)\n');
            dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 5.csv'],[IDs(indices2bin{k},:) (1:numSamp(k))' pB.data(indices2bin{k},2) true(numSamp(k),1)],'delimiter',',','-append');
       end
    end
    
    fprintf(fileID,'opposite direction\n');
    pB = plotBinner([RtimeOppDir slopesOppDir],binCenters);
    indices2bin = binData(pB,'onlyReturnIndicesPerBin',true);
    numSamp = cellfun(@(x) size(x,1),indices2bin);
    IDs = fixationIDs(gofCriteria,:);
    for k = 1 : length(binCenters)
       if numSamp(k) >= options.minNumSamples
            fprintf(fileID,'\ntime of activity rise(s),%0.3f',binCenters(k));
            fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Within-Plane Cell ID,Sample Index,slope(arb. units),same direction(1=yes/0=no)\n');
            dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 5.csv'],[IDs(indices2bin{k},:) (1:numSamp(k))' pB.data(indices2bin{k},2) false(numSamp(k),1)],'delimiter',',','-append');
       end
    end
    fclose(fileID);
end