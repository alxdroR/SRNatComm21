function varargout=saccadeTimePredictionError(varargin)
% saccadeTimePredictionErrir - plot relative absolute difference between saccade time prediction and actual saccade time 
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
global saveCSV
options = struct('sigLeft',[],'uniqueIDsFromCOI',[],'IDsFromCellsOfInterest',[],'FDFF',[],'TF',[],...
    'riseThreshold',0.04,'STEM',[],'binTimes',[],'showBinMedian',false,'minNumSamples',10,'XLIM',[]);
options = parseNameValueoptions(options,varargin{:});

ISImin = 3; ISImax = 20;
if isempty(options.STEM) || isempty(options.binTimes)
    if isempty(options.uniqueIDsFromCOI) || isempty(options.IDsFromCellsOfInterest)
        loadAnticipatorySelectionCriteria
    else
        uniqueIDsFromCOI = options.uniqueIDsFromCOI;
        IDsFromCellsOfInterest = options.IDsFromCellsOfInterest;
        sigLeft = options.sigLeft;
    end
    onDirection = sigLeft(uniqueIDsFromCOI); % if the cell is leftward coding (1) then the ON direction is left(1) Otherwise the ON direction is 0;
    if isempty(options.FDFF) || isempty(options.TF)
        [FDFF,TF] = loadfullData(IDsFromCellsOfInterest,'dff',false,'useDeconvF',true);
    else
        FDFF = options.FDFF;
        TF = options.TF;
    end
    [allData] = gatherPreSaccadeEventTraces(FDFF,TF,onDirection,IDsFromCellsOfInterest,[ISImin ISImax],...
        'binTimes',-30:1/3:0,'ISIwidth',0.5,'tau','future saccade','cutTimeGTISI',false,'NaNInvalidPoints',true);
    [STEstimate,ST,STEM,binTimes] = predictTimeUntilUpcomingSaccade(FDFF,TF,onDirection,IDsFromCellsOfInterest,...
        'ISImin',ISImin,'ISImax',ISImax,'allData',allData,'chooseKCellsAtRandom',[],'runLinearModel',false,'riseThreshold',options.riseThreshold);
    varargout{1} = allData;
    varargout{2} = STEstimate;
    varargout{3} = ST;
    varargout{4} = STEM;
    varargout{5} = binTimes;
else
    STEM=options.STEM;
    binTimes = options.binTimes;
end

% format data to plot into a sharable format
data.predictionErrorSamples = STEM;
data.timeBeforeSaccade = binTimes;

% calculate mean and standard error. NaN out elements that had less than 5
% samples 
nsamp = sum(~isnan(data.predictionErrorSamples));
steSTEM = nanstd(data.predictionErrorSamples)./sqrt(nsamp); steSTEM(nsamp<options.minNumSamples)=NaN; % standard error
if options.showBinMedian
    mSTEM = nanmedian(data.predictionErrorSamples);mSTEM(nsamp<options.minNumSamples)=NaN;
else
    mSTEM = nanmean(data.predictionErrorSamples);mSTEM(nsamp<options.minNumSamples)=NaN;
end
% plot   
figure;errorbar(data.timeBeforeSaccade(end-24:end),mSTEM,steSTEM)
ylim([0 1])
if ~isempty(options.XLIM)
    xlim(options.XLIM);
end
xlabel('time before saccade (s)');
ylabel('abs((estimate - actual)/fixation duration)')
box off;setFontProperties(gca)
set(gcf,'PaperPosition',[0 0 2.2 2.2])

fprintf('sample size per bin ranges from %d-%d predictions\n',max(10,min(nsamp)),max(nsamp));

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 5i.csv'],'a');
    fprintf(fileID,'Panel\ni\n');
   % fprintf(fileID,'|prediction - actual|/fixation duration\n');
    tBefore = data.timeBeforeSaccade(end-24:end);
     %fprintf(fileID,'\ntime before saccade(s)');
            %dlmwrite([fileDirs.scDataCSV 'Figure 5i.csv'],tBefore,'delimiter',',','-append','coffset',1);
            %fprintf(fileID,'Sample Index\n');
            %dlmwrite([fileDirs.scDataCSV 'Figure 5i.csv'],[(1:size(data.predictionErrorSamples,1))' data.predictionErrorSamples],'delimiter',',','-append');      
    for k = 1 : length(nsamp)
        if nsamp(k) >= 10
            %fprintf(fileID,'\nactual time until saccade(s) fixed at,%0.3f',pB.binParameter(k));
            fprintf(fileID,'\ntime before saccade(s) fixed at %0.3f\n',tBefore(k));
           % dlmwrite([fileDirs.scDataCSV 'Figure 5i.csv'],tBefore,'delimiter',',','-append','coffset',1);
            fprintf(fileID,'Sample Index,|prediction - actual|/fixation duration\n');
            dlmwrite([fileDirs.scDataCSV 'Figure 5i.csv'],[(1:nsamp(k))' data.predictionErrorSamples(~isnan(data.predictionErrorSamples(:,k)),k)],'delimiter',',','-append');
        end
    end
    fclose(fileID);
end