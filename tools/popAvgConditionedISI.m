function popAvgConditionedISI(varargin)
% popAvgConditionedISI - plot exemplars of population SR dF/F activity before upcoming saccade (on directions) 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

options = struct('sigLeft',[],'uniqueIDsFromCOI',[],'IDsFromCellsOfInterest',[],'FDFF',[],'TF',[],'scaleBar',0.2);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.uniqueIDsFromCOI) ||  isempty(options.IDsFromCellsOfInterest) || isempty(options.IDsFromCellsOfInterest)
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
ISIprobePoints = [5 12];
STRSamples = cell(length(ISIprobePoints),1);
numCells =zeros(length(ISIprobePoints),1);
numFish = zeros(length(ISIprobePoints),1);
for isiIndex=1:length(ISIprobePoints)
    [dFFISI,binTimes,animalOut]=loadSingleTrialResponses(FDFF,TF,IDsFromCellsOfInterest,'direction','preceeding ON','ONdirection',onDirection,'cells','all',...
        'interp2gridThenCat',true,'binTimes',-30:1/3:0,'tau','future saccade','ISI',ISIprobePoints(isiIndex)+0.5,'ISIwidth',0.5);
    numSamplesVsTimeISI = sum(~isnan(dFFISI)); validPoints = (numSamplesVsTimeISI == numSamplesVsTimeISI(end));
    dFFISI(:,~validPoints) = NaN;numSamplesVsTimeISI(~validPoints)=0;
    
    % count the number of fish and cells used
    numcells = 0;
    fishused = unique(animalOut(:,1));
    nfish = length(fishused);
    for ei = fishused'
        planeused = unique(animalOut(animalOut(:,1)==ei,2));
        for pi = planeused'
            cellsused  = unique(animalOut(animalOut(:,1)==ei & animalOut(:,2)==pi,3));
            numcells = numcells + length(cellsused);
        end
    end    
    STRSamples{isiIndex} = dFFISI;
    numCells(isiIndex) = numcells;
    numFish(isiIndex) = nfish;
end

% format data to plot into a sharable format
data.time = binTimes;
data.dFFSamples = STRSamples;
data.fd = ISIprobePoints;
data.numCells = numCells;
data.numFish = numFish;

% plot
numsstd2show = 1;
XLABEL = {'time until saccade (s)'};
YLABEL = 'dF/F';
showYaxis = false;
if ~isempty(options.scaleBar)
    showYScaleBar = true;
else
    showYScaleBar = false;
end
scaleLineWidth = 0.5;
XLIM = [-13 0];

figure; hold on;
for isiIndex=1:length(data.fd)
    nSamplesVTime = sum(~isnan(data.dFFSamples{isiIndex}));
    fprintf('ISI=%d: number of samples=%0.4f,numcells=%d,numfish=%d\n',data.fd(isiIndex),nSamplesVTime(end),data.numCells(isiIndex),data.numFish(isiIndex));
    
    ymean = nanmean(data.dFFSamples{isiIndex});
    sem = nanstd(data.dFFSamples{isiIndex})./sqrt(nSamplesVTime);
    heb = errorbar(data.time,ymean-ymean(find(~isnan(ymean),1)),numsstd2show*sem); hold on;
    if isiIndex==1
        blueColor = heb.Color;
    else
        heb.Color = blueColor;
    end
end

if showYaxis
    ylabel(YLABEL);
else
    if showYScaleBar
        plot([1 1]*(-12.5),[0 options.scaleBar],'k','LineWidth',scaleLineWidth)
        th = text(-13,options.scaleBar/5,[num2str(100*options.scaleBar) '% dF/F']);
        th.Rotation=90;th.FontName='Arial';th.FontSize=6;
    end
end
lH=legend('fd=5s','fd=12s','Location','northwest');lH.FontName='Arial';lH.FontSize=6;lH.Box= 'off';
xlim(XLIM);box off;xlabel(XLABEL); setFontProperties(gca);
if ~showYaxis
    set(gca,'YColor','w','YTick',[],'YTickLabel',[]);
end
set(gcf,'PaperPosition',[0 0 2.2 2.2],'InvertHardcopy','off','Color',[1 1 1]);

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)