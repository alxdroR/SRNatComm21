function slopeHistosSameDirSaccades(varargin)
% slopeHistosSameDirSaccades
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

options = struct('AnticipatoryAnalysisMatrix',[],'XLABEL',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.AnticipatoryAnalysisMatrix) 
   loadSRSlopes
else
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
end
%%
% find the slopes measured after a saccade occurred in the same direction
sameDir = AnticipatoryAnalysisMatrix(:,10);
% check if a rise-time was detected 
Rtimes = AnticipatoryAnalysisMatrix(:,2); % rise-times 
cellWasActive = ~isnan(Rtimes);

% For the slopes to have any meaning the linear model must be valid. There
% are cases where this is not true
gof = AnticipatoryAnalysisMatrix(:,5);
gofCriteria = gof>=0.4;

slopesSameDir = AnticipatoryAnalysisMatrix(gofCriteria & sameDir & cellWasActive,1); % slopes 
slopesOppDir = AnticipatoryAnalysisMatrix(gofCriteria & ~sameDir & cellWasActive,1); % slopes 

%%
figure; 
[Fsd,Xsd]= ecdf(slopesSameDir);
[Fod,Xod]= ecdf(slopesOppDir);

plot(Xsd,Fsd); hold on;
plot(Xod,Fod,'Color',[1 1 1]*0.06);
box off; xlabel(options.XLABEL);ylabel('cumulative fraction of fixations');  setFontProperties(gca)

%%
global printOn 

if isempty(printOn)
    printOn = false;
end
if printOn
    figurePDir = figurePanelPath;
    thisFileName = mfilename;
    set(gcf,'PaperPosition',[0 0 2.2 2.2])
    if isempty(thisFileName)
        error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
    end
    print(gcf,'-dpdf',[figurePDir thisFileName])
end
%% Results 