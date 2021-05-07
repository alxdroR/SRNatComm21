function [invTimeConstants,goodnessOfFit,varargout ] = fitExp2SingleFixations(E,varargin)
%fitExp2SingleFixations : Given an eye trace or eyeData object return tau from an exponential
%fit for each fixation along with goodness-of-fit
%   Input:
% E - N x 2 matrix of eye traces or eyeData object. If E is an Nx2 matrix
%    user must also enter time points for E using the call
%     fitExp2SingleFixations(E,'time',t); where t is an Nx2 matrix
%
% Output:
% invTimeConstants{eyeInd}(j) - gives measurement of inverted timeconstant
%                              for eye labeled with index eyeInd for
%                              fixation j
%
% adr
% 9/27/2017
%

options = struct('time',[],'plane','all','startSegment',1,'stopSegment',3,'eye2analyze','both','fastFit',false,...
    'lineApprox',false,'demo',false,'r2DemoCut',0.2,'gofMeasure','r2');
options = parseNameValueoptions(options,varargin{:});

if ~isobject(E)
    if isempty(options.time)
        error('User must also enter Nx2 matrix of time points, t, using fitExp2SingleFixations(E,''time'',t)');
    else
        [N,p] = size(E);
        [Nt,pt] = size(options.time);
        if p < 2 || pt < 2
            error('E must be an N x 2 matrix where E(:,1) is eye position for one eye (called left) and E(:,2) is pos for the other eye');
        elseif Nt ~= N
            error('The number of rows in E and time must be equal');
        end
    end
    % set-up eyedata object
    eyePositions = E;
    clear E;
    % create an eye Data object
    E = eyeData('position',eyePositions,'time',options.time);
    E = E.saccadeDetection;
end

switch options.eye2analyze
    case 'both'
        eyeIndV = 1:2;
    case 'left'
        eyeIndV = 1;
    case 'right'
        eyeIndV = 2;
end
segmentedPositionArray = cell(1,2);
segmentedTimeArray = cell(1,2);
absSegTime = cell(1,2);
numSegments = [0 0];

for arrayInd = 1 : length(E.position)
    centeredPosition = E.centerEyesMethod('planeIndex',arrayInd);
    [cutData,timeSegments,~,~,~,absTimeSeg] = saccadeTrigCut2(centeredPosition,E.saccadeTimes{arrayInd},options.startSegment,options.stopSegment,E.time{arrayInd});
    cutDataTemp = cell(2,1);
    timeSegTemp = cell(2,1);
    absTimeSegTemp = cell(2,1);
    for eyeInd=1:2
        %   - segment eye position traces by saccade times
        
        if ~isempty(cutData{eyeInd})
            cutDataTemp{eyeInd} = cell(1,1);
            timeSegTemp{eyeInd} = cell(1,1);
            absTimeSegTemp{eyeInd} = cell(1,1);
            cnt = 1;
            for segInd =1:length(absTimeSeg{eyeInd})
                if isempty(cutData{eyeInd}{segInd})
                    %  'stop here'
                else
                    cutDataTemp{eyeInd}{cnt} = cutData{eyeInd}{segInd};
                    timeSegTemp{eyeInd}{cnt} = timeSegments{eyeInd}{segInd};
                    absTimeSegTemp{eyeInd}{cnt} = absTimeSeg{eyeInd}{segInd};
                    cnt = cnt+1;
                end
            end
        end
    end
    cutData = cutDataTemp;
    timeSegments = timeSegTemp;
    absTimeSeg = absTimeSegTemp;
    
    for eyeInd=1:2
        for k1=1:length(cutData{eyeInd})
            numSegments(eyeInd) = numSegments(eyeInd)+1;
            segmentedPositionArray{eyeInd}{numSegments(eyeInd)} = cutData{eyeInd}{k1};
            segmentedTimeArray{eyeInd}{numSegments(eyeInd)} = timeSegments{eyeInd}{k1};
            absSegTime{eyeInd}{numSegments(eyeInd)}=absTimeSeg{eyeInd}{k1};
        end
    end
end

%[~,~,~,~,~,~,~,~,~,segmentedPositionArray,segmentedTimeArray,absSegTime]=E.pvregression('plane',options.plane,'stopSegment'...
%    ,options.stopSegment,'startSegment',options.startSegment,'calcReg',false,'use4SaccadeTrigCutwConcatCallONLY',true);

invTimeConstants = cell(length(eyeIndV),1);
goodnessOfFit = cell(length(eyeIndV),1);

if options.demo
    figure;
    mx = nanmean(E.position{1});
    plot(E.time{1}(:,1),E.position{1}(:,1)-mx(1)); hold on;
    plot(E.time{1}(:,2),E.position{1}(:,2)-mx(2));
end
for eyeInd=eyeIndV
    invTimeConstants{eyeInd} = zeros(length(segmentedPositionArray{eyeInd}),1);
    goodnessOfFit{eyeInd} = zeros(length(segmentedPositionArray{eyeInd}),2);
    for j=1:length(segmentedPositionArray{eyeInd})
        fixationSegment = segmentedPositionArray{eyeInd}{j};
        % define linear regression variables
        y = fixationSegment(2:end);
        x = fixationSegment(1:end-1);
        % linear regression
        if ~options.fastFit
            lmod = LinearModel.fit(x-mean(x),y-mean(y),'intercept',false);
            gamma = lmod.Coefficients.Estimate;
            r2  = lmod.Rsquared.Ordinary;
            modelP = lmod.anova.pValue;
            dt = mean(diff(segmentedTimeArray{eyeInd}{j}));
            itau = -log(gamma)/dt;
        else
            if options.lineApprox
                tSeg = segmentedTimeArray{eyeInd}{j};
                Xmodel = [ones(length(tSeg),1) tSeg ];
                theta = pinv(Xmodel)*fixationSegment;
                itau = -theta(2)/theta(1);
                switch options.gofMeasure
                    case 'r2'
                        ccxy = corr(tSeg,fixationSegment);
                        r2 = ccxy*ccxy;
                        gofstat = r2;
                    case 'residualVar'
                        squaredError = nanmean( (Xmodel*theta - fixationSegment).^2 );
                        gofstat = squaredError;
                end
                %r2 = 1-nansum( (Xmodel*theta - fixationSegment).^2 )/(nanvar(fixationSegment,1)*sum(~isnan(fixationSegment)));
                modelP = NaN;
                
                if options.demo
                    
                    if r2 > options.r2DemoCut && itau > -inf
                        % if absSegTime{eyeInd}{j}(1) <= E.time{eyeInd}(end,2)
                        % plot(tSeg + absSegTime{eyeInd}{j}(1) - tSeg(1),theta(1) + theta(2)*tSeg + theta(3)*tSeg.^2,'k','LineWidth',3);
                        plot(tSeg + absSegTime{eyeInd}{j}(1) - tSeg(1),theta(1) + theta(2)*tSeg ,'k','LineWidth',3);
                        %plot(tSeg + absSegTime{eyeInd}{j}(1) - tSeg(1),theta(1)*(exp(-itau*tSeg)) ,'k','LineWidth',3);
                        %end
                    end
                    
                end
            else
                gamma = pinv(x-mean(x))*(y-mean(y));
                ccxy = corr(x,y);
                if gamma <= 0
                    % segment is too noisy for the model and the estimate no
                    % longer makes snes
                    gamma = NaN;
                end
                r2 = ccxy*ccxy; % in this case r2 is easily related to the correlation
                modelP = NaN; % haven't bothered to add the right test yet. 10/27/2017 adr
                dt = mean(diff(segmentedTimeArray{eyeInd}{j}));
                itau = -log(gamma)/dt;
            end
        end
        
        
        % gammaP = lmod.Coefficients.pValue;
        
        
        invTimeConstants{eyeInd}(j) = itau;
        goodnessOfFit{eyeInd}(j,:) = [gofstat modelP(1)];
    end
end
varargout{1} = segmentedPositionArray;
varargout{2} = absSegTime;
end

