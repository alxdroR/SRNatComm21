function rampVRiseTime(varargin)
% rampVRiseTime - histogram slope of SR dF/F activity before upcoming
% saccade (on directions) versus time of rise
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202x
global saveCSV

options = struct('AnticipatoryAnalysisMatrix',[],'YLIM',[],'YLabel','slope ((dF/F)/s)','SRMatrixIDs',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.AnticipatoryAnalysisMatrix) 
   loadSRSlopes
else
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
    fixationIDs = options.SRMatrixIDs;
end
gof = AnticipatoryAnalysisMatrix(:,5);
gofCriteria = gof>=0.4;
slopes = AnticipatoryAnalysisMatrix(gofCriteria,1); % slopes 
Rtime = AnticipatoryAnalysisMatrix(gofCriteria,2); % rise-times 
riseMeasured = ~isnan(Rtime);

% format data to plot into a sharable format
data.slopes = slopes(riseMeasured); % fixation durations x time until saccade
data.risetime = Rtime(riseMeasured);

% plot
figure;binCenters = -10.5:0.5:0;
pB = plotBinner([data.risetime data.slopes],binCenters);[binnedData,binVar,numberSamp,binCenters] = binData(pB,'median',false);
binnedData(numberSamp<10)=NaN;
errorbar(binCenters,binnedData,sqrt(binVar./numberSamp)); hold on;
if ~isempty(options.YLIM)
    ylim(options.YLIM);
end
xlim([-11.1 -0.5]);box off;xlabel('time of activity rise (s)');ylabel(options.YLabel);setFontProperties(gca)
set(gcf,'PaperPosition',[0 0 2.2 2.2])

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)
[nc,nf,ne]=getSampleSizeFromSRMatrix(fixationIDs(riseMeasured,:));
fprintf('%d fixations from %d cells examined over %d independent fish\n',ne,nc,nf)
fprintf('sample size per bin ranges from %d-%d fixations\n',max(10,min(numberSamp)),max(numberSamp));
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 5d.csv'],'a');
    fprintf(fileID,'Panel\nd\n');
    
    pB = plotBinner([data.risetime data.slopes],binCenters);
    indices2bin = binData(pB,'onlyReturnIndicesPerBin',true);
    numSamp = cellfun(@(x) size(x,1),indices2bin);
     IDs = fixationIDs(gofCriteria,:);
    for k = 1 : length(binCenters)
       if numSamp(k) >= 10
            fprintf(fileID,'\ntime of activity rise(s),%0.3f',binCenters(k));
            fprintf(fileID,'\nAnimal ID,Imaging Plane ID,Within-Plane Cell ID,Sample Index,slope(arb. units)\n');
            dlmwrite([fileDirs.scDataCSV 'Figure 5d.csv'],[IDs(indices2bin{k},:) (1:numSamp(k))' pB.data(indices2bin{k},2)],'delimiter',',','-append');
       end
    end
    fclose(fileID);
end