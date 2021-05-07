function rebuttalSRONONExamples(varargin)
% rebuttalSRONONExamples
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x
options = struct('showDeconv',false);
options = parseNameValueoptions(options,varargin{:});

% Use the switch statement to select which type of neuron to show and print
% I call neurons with short duration activity burst neurons
% I call neurons with long, post-saccade fixation activity tonic neurons
% and I call neurons with neurons with pre-saccadic fixation activity
% anticipatory

% construct features that are unique to particular cells such
% as indices that identify the cell across all the data, the
% particular time in the experiment to focus on
showAll = true;
if showAll
    cellTypesV = {'ex1','ex2','ex3','ex4','ex5','ex6','ex7','scaleBar'};
else
    cellTypesV = {'ex3'};
end
for index = 1 : length(cellTypesV)
    cellTypes = cellTypesV{index};
    
    switch cellTypes
        case 'ex1' % doesn't rise
            expIndex = 3;planeIndex = 13;
            cellIndices = 20;
            timeOffset2plot = 28;axesOverlap = 0.23;
            % amount to shrink eye position plot (if this is not done, the
            % aspect ratio is weird. The amount of shrinkage should vary with
            % number of traces)
            
            eyeSubPlotHeightShrink = 1/2;
        case 'ex2' % does rise, plus a strange one
            expIndex = 4;planeIndex = 9;
            %cellIndices = [98,136];
            cellIndices = [57];
            timeOffset2plot = 1;axesOverlap = 0.23;
            eyeSubPlotHeightShrink = 1/2;
        case 'ex3' % 1 rises wrong direction on the same-direction
            expIndex = 4;planeIndex = 13;
            %cellIndices = [40,35];
            cellIndices = [32];
            timeOffset2plot = 0;axesOverlap = 0.23;
            
            eyeSubPlotHeightShrink = 1/2;
        case 'ex4' % pre-saccadic ramping and non-ramping
            expIndex = 5;planeIndex = 9;
            cellIndices = [47];
            timeOffset2plot = 0;axesOverlap = 0.19;
            
            eyeSubPlotHeightShrink = 1/2;
        case 'ex5' % not great ramping but a little of everything
            expIndex = 5;planeIndex = 10;
            % cellIndices = [152,165,38,92,181];
            cellIndices = [107,114,20,132];
            timeOffset2plot = 0;axesOverlap = 0.2;
            eyeSubPlotHeightShrink = 1/2;
        case 'ex6' % good ramping but misses one
            expIndex =8;planeIndex = 6;
            cellIndices = [8];
            timeOffset2plot = 0;axesOverlap = 0.23;
            eyeSubPlotHeightShrink = 1/2;
        case 'ex7'
            expIndex =8;planeIndex = 14;
            cellIndices = [10];
            timeOffset2plot = 0;axesOverlap = 0.23;
            
            eyeSubPlotHeightShrink = 1/2;
        case 'scaleBar'
            temporalDimensionLength = 10; % seconds
            dFFLength = 1; % dF/F
            degreesLength = 10; % degrees
            timeOffset2plot = 20;  axesOverlap = -0.12;
            YAxesRange = 2*4 + 1; % range of YAxis to show
            eyeSubPlotHeightShrink = 1/2;
    end
    traceSpacing = 1.3;
    switch cellTypes
        case 'ex5'
            traceSpacing = 1.0;
    end
    %  YAxesRange = traceSpacing*length(cellIndices) + 1;
    YAxesRange = 5.2;
    % plot properties that do not vary
    dFFLineWidth = 1.5; dFFLineColor = [0 0 1];
    leftEyeColor = [1 1 1]*0.4;
    rightEyeColor = [1 1 1]*0;
    lineAtEyeBaselineColor = [1 1 1]*0.4;
    timeWidth = 60*4+7; % amount of time to show in seconds
    eyeRange = 50; % range in degrees to show eye movements
    
    
    if ~strcmp(cellTypes,'scaleBar')
        % load the data ------------------------
        [caobj,eyeobj] = plotActivityWEyes.loadCaEyeObjs(expIndex);
        if options.showDeconv
            [dFF,timeF,E,eyeTime,deconvAU] = plotActivityWEyes.extractCaEyeObjs(...
                caobj,eyeobj,planeIndex,cellIndex,'runDFF',true,'returnDeconvF',true,'haveDeconvMatchDFF',true);
            activity = deconvAU;
         else
            [dFF,timeF,E,eyeTime] = plotActivityWEyes.extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndices,'runDFF',true,'returnDeconvF',false);
            activity = dFF;
        end
        
        
        % plot the loaded data -----------------
        figure;ax(1)=subplot(2,1,1);
        plotKTraces(timeF,activity,'traceSpacing',traceSpacing,'traceColor',dFFLineColor,'traceLineWidth',dFFLineWidth,...
            'showTraceIndex',false,'axes',ax(1));
        xlim([0 timeWidth]+timeOffset2plot);ylim([0 YAxesRange]+min(activity(:,1))-0.1);
        box off; axis off
        
        ax(2)=subplot(2,1,2);
        plot(eyeTime,E(:,1),'color',leftEyeColor); hold on; plot(eyeTime,E(:,2),'color',rightEyeColor);
        % plot([0 eyeTime(end)],[1 1]*0,'--','color',lineAtEyeBaselineColor)
        xlim([0 timeWidth]+timeOffset2plot); ylim([0 eyeRange]+ min(min(E)))
        linkaxes(ax,'x')
        axis off; box off;  setFontProperties(gca)
        %setFontProperties(gca)
    else
        figure;ax(1)=subplot(2,1,1);
        plot([0 temporalDimensionLength]+(timeOffset2plot+4.4),[1 1]*0,'k'); hold on;
        plot([1 1]*(timeOffset2plot+4.4),[0 dFFLength],'k'); xlim([0 timeWidth]+timeOffset2plot);ylim([0 YAxesRange]-1);
        
        ax(2)=subplot(2,1,2);
        plot([0 temporalDimensionLength]+(timeOffset2plot+4.4),[1 1]*0,'k'); hold on;
        plot([1 1]*(timeOffset2plot+4.4),[0 degreesLength],'k')
        xlim([0 timeWidth]+timeOffset2plot); ylim([0 eyeRange]-1);linkaxes(ax,'x')
    end
    
    % shrink the second axes
    ax(2).Position(4) = ax(2).Position(4)*eyeSubPlotHeightShrink;
    % bring the axes closer together
    ax(2).Position(2)=ax(1).Position(2)-ax(1).Position(4)+axesOverlap;
    
    global printOn
    
    if isempty(printOn)
        printOn = false;
    end
    if printOn
        %set(gcf,'PaperPosition',[0 0 4.25 2.0]);
        set(gcf,'PaperPosition',[0 0 4.8 4.4]);
        figurePDir = figurePanelPath;
        thisFileName = mfilename;
        if isempty(thisFileName)
            error('mfilename does not work when evaluating cells. To print, you must either run the file using `Run` or manually enter the print command into the command window');
        end
        print(gcf,'-dpdf',[figurePDir thisFileName '-' cellTypes])
        %   print(gcf,'-dpdf',[ rootLocation '\figures\figurePanels\multipleTraceExamples-' cellTypes])
    end
end
