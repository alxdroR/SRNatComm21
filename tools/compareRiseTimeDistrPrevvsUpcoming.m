function compareRiseTimeDistrPrevvsUpcoming(varargin)
% compareRiseTimeDistrPrevvsUpcoming - plot cumulative distribution of SR RiseTimes relative to previous and upcoming saccade 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020

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
Rtimes = AnticipatoryAnalysisMatrix(:,2); % rise-times 
RtimeFromLastSaccade = ISIMatrix - abs(Rtimes);
riseMeasured = ~isnan(RtimeFromLastSaccade);

% format data to plot into a sharable format
data.risePS = RtimeFromLastSaccade(riseMeasured);
data.riseUS = Rtimes(riseMeasured);

% plot
figure; 
ecdf(abs(data.riseUS));hold on; ecdf(abs(data.risePS));box off; xlabel({' time of activity rise (s)'});ylabel('cumulative fraction of all fixations'); setFontProperties(gca)
xlim([0 31]);ph=get(gca,'Children');ph(1).Color = [0.0 0.1882 0.3137];
lh=legend('a','b');
set(lh,'FontName','Ariel','FontSize',6.5,'Box','off','LineWidth',0.1)
set(gcf,'PaperPosition',[0 0 2.2 2.2])

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

if saveCSV
    fixationIDsUsed = fixationIDs(riseMeasured,:);
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 4e.csv'],'a');
    fprintf(fileID,'Panel\ne\n');
    fprintf(fileID,',Animal ID,Imaging Plane ID,Within-Plane Cell ID,Fixation Sample Index,Time of activity rise relative to upcoming saccade,Time of activity rise relative to previous saccade\n');
    dlmwrite([fileDirs.scDataCSV 'Figure 4e.csv'],[fixationIDsUsed (1:size(fixationIDsUsed,1))' data.riseUS data.risePS],'delimiter',',','-append','coffset',1);
    fclose(fileID);
end