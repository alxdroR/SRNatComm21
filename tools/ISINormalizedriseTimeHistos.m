function ISINormalizedriseTimeHistos(varargin)
% ISINormalizedriseTimeHistos - histogram of SR RiseTimes normalized by the
% fixation duration
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
% normalized rise times
normedRiseTimes = AnticipatoryAnalysisMatrix(:,2)./ISIMatrix; % rise-times w.r.t upcoming saccade divided by ISI
riseMeasured = ~isnan(AnticipatoryAnalysisMatrix(:,2));

% format data to plot into a sharable format
data.riseNormed = normedRiseTimes(riseMeasured);

% plot
XLABEL = 'activity rise-time normalized by fixation duration';
YLABEL = 'fraction of all fixations';
YTICKLABEL = {'0','0.05','0.1','0.15'};
YLIM = [0 0.15]; YTICK = [0,0.05,0.1,0.15];
paperWidth = 2.2;
paperHeight = paperWidth;
paperPosition = [1 1 paperWidth paperHeight];

% There is an argument to be made that we should only use ISI >= 10 if we
% want to look at a histogram with 10 bins and our temporal resolution is 1
% second. A binwidth of 0.1 with ISI equal to say 5 implies that we can
% distinguish risetimes with 500ms precision.
binEdges = -1:0.1:0;
figure;
histogram(data.riseNormed,binEdges,'Normalization','probability');box off; xlabel(XLABEL);ylabel(YLABEL);
set(gca,'YTickLabel',YTICKLABEL,'YTick',YTICK);setFontProperties(gca)
ylim(YLIM);
set(gcf,'PaperPosition',paperPosition)

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

% print stats quoted in the paper
% Testing if the distribution is uniform
% method 1: uniform on the interval -1 to 0
% pd = makedist('Uniform','Lower',-1,'Upper',0);
%[h,pval]=chi2gof(normedConditionalRiseTimes,'CDF',pd); pd won't work with
%Matlab 2016 but does work with 2017
n=sum(~isnan(data.riseNormed));
edges = linspace(-1,0,11);
expectedCounts = n * diff(edges);
[h,p]=chi2gof(data.riseNormed,'edges',edges,'expected',expectedCounts);
fprintf('\n\n We found that, across cells and fixations, normalized rise times\nwere not peaked at a single value, as expected if time of rise was linearly related\n')
fprintf('to fixation duration, but rather non-uniformly distributed across the full\n range of possible values \n')
fprintf('(Fig. 4F; p<0.001 (p=%0.6f), n=%d)\n\n',p,n)
if saveCSV
    fixationIDsUsed = fixationIDs(riseMeasured,:);
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 4f.csv'],'a');
    fprintf(fileID,'Panel\nf\n');
    fprintf(fileID,',Animal ID,Imaging Plane ID,Within-Plane Cell ID,Fixation Sample Index,time of activity rise normalized by fixation duration\n');
    dlmwrite([fileDirs.scDataCSV 'Figure 4f.csv'],[fixationIDsUsed (1:size(fixationIDsUsed,1))' data.riseNormed],'delimiter',',','-append','coffset',1);
    fclose(fileID);
end
