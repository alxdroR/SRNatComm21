function varargout = graphChoiceProbWTime(varargin)
% graphChoiceProbWTime - plot choice probability calculated from SR cells as a function of time
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
global saveCSV
rng('default')
options = struct('sigLeft',[],'uniqueIDsFromCOI',[],'IDsFromCellsOfInterest',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.uniqueIDsFromCOI) ||  isempty(options.IDsFromCellsOfInterest)
    loadAnticipatorySelectionCriteria
else
    uniqueIDsFromCOI = options.uniqueIDsFromCOI;
    IDsFromCellsOfInterest = options.IDsFromCellsOfInterest;
    sigLeft = options.sigLeft;
end

onDirection = sigLeft(uniqueIDsFromCOI);
[activityTraces,time4ActivityTraces] = loadfullData(IDsFromCellsOfInterest,'dff',false,'useDeconvF',true);
numCellsV = [1,4,16];
[CP,ISIVector,~,allData,~,bt] = saccadeChoiceProbability(activityTraces,time4ActivityTraces,onDirection,IDsFromCellsOfInterest,'avgRandwRplcmnt',true,'numCellsInAvg',numCellsV);
CPEndDist = zeros(length(CP),length(numCellsV),7,size(CP{1},3));
for ti = 0:6
    for isiInd = 1 : length(CP)
        %gatherCP = cellfun(@(x) x(:,end-ti),CP,'UniformOutput',false);
        gatherCP = CP{isiInd}(:,end-ti,:);
        CPEndDist(isiInd,:,ti+1,:) = gatherCP;
    end
end

data.CPMatrix = CPEndDist; % fixation durations x time until saccade
data.rows = ISIVector;
data.numCellsV = numCellsV;
data.time = -bt(1:7);

% compute statistics
nsamples = size(data.CPMatrix,1);
y = squeeze(nanmean(data.CPMatrix));
sem = squeeze(nanstd(data.CPMatrix)./sqrt(nsamples));
lowerError = (y-sem);
upperError = (y+sem);

% plot
figure;
for numCellInd = 1 : 3
    subplot(1,3,numCellInd)
    fill([data.time fliplr(data.time)],[upperError(numCellInd,:) fliplr(lowerError(numCellInd,:))],[1 1 1]*0.6,'LineStyle','none'); hold on;
    plot(data.time,y(numCellInd,:),'color',[0 114 189]./256);
    plot(linspace(-2,0,length(data.time)),ones(1,length(data.time))*0.5,':.','color',[1 1 1]*0.0);
    if data.numCellsV(numCellInd)==0
        title('1 cell');
    else
        title([num2str(data.numCellsV(numCellInd)) ' cells'])
    end
    box off;setFontProperties(gca);
    xlim([-2.00 0.0]);ylim([0.49 1])
    if numCellInd > 1
        set(gca,'YTickLabel',[]);
    end
end
subplot(1,3,1)
xlabel('time until saccade (s)');ylabel('choice probability');
set(gcf,'PaperPosition',[0 0 3.5 2.2],'InvertHardcopy','off','Color',[1 1 1]);

% print and save
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

% print stats quoted in the paper
fprintf('mean choice probability equals %0.3f\n',mean(y,2))

varargout{1}=activityTraces;
varargout{2}=time4ActivityTraces;
if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Figure 5a.csv'],'a');
    fprintf(fileID,'Panel\na\n');
    for k = 1:3
        if numCellsV(k) == 1
            fprintf(fileID,'choice probabilities using %d cell\n',numCellsV(k));
        else
            fprintf(fileID,'choice probabilities using %d cells\n',numCellsV(k));
        end
        fprintf(fileID,',time until saccade(s)');
        dlmwrite([fileDirs.scDataCSV 'Figure 5a.csv'],data.time,'delimiter',',','-append','coffset',1);
        fprintf(fileID,'\nFixation Duration (s),Sample Index\n');
        dlmwrite([fileDirs.scDataCSV 'Figure 5a.csv'],[ISIVector' (1:nsamples)' squeeze(data.CPMatrix(:,k,:))],'delimiter',',','-append');
    end
    fclose(fileID);
end