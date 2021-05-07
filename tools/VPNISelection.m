classdef VPNISelection < behCaAnalysis
    properties (Constant, Hidden)
        options = VPNISelectionOptions % constant handle to eyePOptions handle class
    end
    properties (GetAccess = private,Transient,NonCopyable)
        f % handle to FL obj
        e % handle to eyeP obj
        yIsInLeftHemi = []
    end
    properties (Access = protected)
        eye2Downsample = 'both'
        hemi2Use = 'both'
        direction2Use = 'leftward'
    end
    properties (Dependent)
        eye2DownsampleIdx
        dims2regress
        thresholdSlopeSign
    end
    % older properties .. not sure
    properties
        spontEpochs = 'all'
        missingSamples = 'none'
        stimTime = []
        stim = []
        additionalSelector
        %methodTypes = {'miri2011','Lee2015','Daie2015'};
        regressor = 'Behavior'
    end
    methods
        function obj = VPNISelection(varargin)
            if nargin > 0
                parserObj = parseNameValuePropertySet;
                obj = parserObj.initProperties(obj,varargin{:});
                obj.check4VaryingMissingData(obj.f.y,1);
            end
        end
        function [corrMatrix,pVals,ZScores,bhat,R2,pTH,vTH,vpniCells,burstCells] = Miri2011(obj,varargin)
            switch obj.options.eye2Use
                case 'ipsi eye'
                    obj.hemi2Use = 'left';
                    obj.eye2Downsample = 'left';
                    switch obj.options.dir2Use
                        case 'ipsiversive'
                            obj.direction2Use = 'leftward';
                        case 'contraversive'
                            obj.direction2Use = 'rightward';
                    end
                    [cLH,pValsL,ZScoresLH,bhatLH,R2LH,pLTH,vLTH] = obj.computeCpCvPvalPthZScore;
                    
                    obj.hemi2Use = 'right';
                    obj.eye2Downsample = 'right';
                    switch obj.options.dir2Use
                        case 'ipsiversive'
                            obj.direction2Use = 'rightward';
                        case 'contraversive'
                            obj.direction2Use = 'leftward';
                    end
                    [cRH,pValsR,ZScoresRH,bhatRH,R2RH,pRTH,vRTH] = obj.computeCpCvPvalPthZScore;
                case 'contra eye'
                    obj.hemi2Use = 'left';
                    obj.eye2Downsample = 'right';
                    switch obj.options.dir2Use
                        case 'ipsiversive'
                            obj.direction2Use = 'leftward';
                        case 'contraversive'
                            obj.direction2Use = 'rightward';
                    end
                    [cLH,pValsL,ZScoresLH,bhatLH,R2LH,pLTH,vLTH] = obj.computeCpCvPvalPthZScore;
                    
                    obj.hemi2Use = 'right';
                    obj.eye2Downsample = 'left';
                    switch obj.options.dir2Use
                        case 'ipsiversive'
                            obj.direction2Use = 'rightward';
                        case 'contraversive'
                            obj.direction2Use = 'leftward';
                    end
                    [cRH,pValsR,ZScoresRH,bhatRH,R2RH,pRTH,vRTH] = obj.computeCpCvPvalPthZScore;
            end
            % now combine left and right hemisphere results
            corrMatrix = obj.combineLRHemisphere(cLH,cRH);
            pVals = obj.combineLRHemisphere(pValsL,pValsR);
            pTH = obj.combineLRHemisphere(pLTH,pRTH);
            vTH = obj.combineLRHemisphere(vLTH,vRTH);
            ZScores = obj.combineLRHemisphere(ZScoresLH,ZScoresRH);
            bhat = obj.combineLRHemisphere(bhatLH,bhatRH);
            R2 = obj.combineLRHemisphere(R2LH,R2RH);
            if obj.options.computeZScores && obj.options.zScoreMC
                ZScores = obj.miriZScoreMotionCorrect(ZScores);
            end
            if obj.options.compCCPValTh
                vpniCells = (pVals(1,:) <= pTH)' ;
                burstCells = (pVals(1,:) > pTH)' & (pVals(2,:) <= vTH)' ;
                if obj.options.verbose
                    fprintf('number of VPNIs= %d\n',sum(vpniCells));
                    fprintf('number of burst cells= %d\n',sum(burstCells));
                end
            else
                vpniCells=NaN;
                burstCells=NaN;
            end
        end
        function [vpniCells,varargout] = Lee2015(obj,varargin)
            options = struct('verbose',true,'spontSTh',0.4,'SOKRRatioMax',3);
            options = parseNameValueoptions(options,varargin{:});
            
            % spontaneous sensitivity calc
            [maxCCS,selectedVarsS] = obj.computeLeeSensitivity;
            
            % OKR sensitivity calc
            obj = obj.swapStimEyeRegressor;
            [maxCCOKR,selectedVarsOKR] = obj.computeLeeSensitivity;
            
            vpniCells = maxCCS >= options.spontSTh & (maxCCS./maxCCOKR) < options.SOKRRatioMax & obj.additionalSelector;
            if options.verbose
                fprintf('number of VPNIs= %d\n',sum(vpniCells));
                fprintf('number passing spont. sensitivity = %d\n',sum(maxCCS >= 0.4));
                fprintf('number passing spont/okr sensitivity ratio = %d\n',sum((maxCCS./maxCCOKR) < 3));
            end
            varargout{1} = maxCCS;
            varargout{2} = selectedVarsS;
            varargout{3} = maxCCOKR;
            varargout{4} = selectedVarsOKR;
        end
        function regBool = get.dims2regress(obj)
            if isempty(obj.yIsInLeftHemi) && ~strcmp(obj.hemi2Use,'both')
                error('propery yIsInLeftHemi must be populated with a boolean selector to split y0 values into left and right hemisphere');
            else
                switch obj.hemi2Use
                    case 'left'
                        regBool = obj.yIsInLeftHemi;
                    case 'right'
                        regBool = ~obj.yIsInLeftHemi;
                    case 'both'
                        regBool = true(obj.f.N,1);
                end
            end
        end
        function rei = get.eye2DownsampleIdx(obj)
            switch obj.eye2Downsample
                case 'left'
                    rei = obj.e.leftEyeIndex;
                case 'right'
                    rei = obj.e.rightEyeIndex;
                case 'both'
                    rei = [obj.e.leftEyeIndex,obj.e.rightEyeIndex];
            end
        end
        function tss = get.thresholdSlopeSign(obj)
            switch obj.direction2Use
                case 'leftward'
                    tss = ones(1,'int8');
                case 'rightward'
                    tss = -ones(1,'int8');
            end
        end
        function obj = swapStimEyeRegressor(obj)
            if strcmp(obj.regressor,'Behavior')
                % swap behavior as X var with stim
                obj.regressor = 'Stim';
            else
                obj.regressor = 'Behavior';
            end
            stimCopy = obj.stim;
            stimTimeCopy = obj.stimTime;
            obj.stim = obj.X0;
            obj.stimTime = obj.tx0;
            obj.X0 = stimCopy;
            obj.tx0 = stimTimeCopy;
        end
        function obj = insertMissingSamples(obj)
            if ~ischar(obj.missingSamples)
                obj = obj.setXSamples2Nan(obj.missingSamples);
                obj = obj.setySamples2Nan(obj.missingSamples);
            end
        end
        function obj = NaNNonSpontEpochs(obj)
            if ~ischar(obj.spontEpochs)
                obj = obj.setXSamples2Nan(~obj.spontEpochs);
                obj = obj.setySamples2Nan(~obj.spontEpochs);
            end
        end
    end
    methods(Access=protected)
        function y = send2threshold(obj,x)
            y = obj.threshold(x,obj.thresholdSlopeSign,obj.options.threshold);
        end
        function vDS = downsampleV(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % decimate time-vector and eye positions to obtain sampling
            % frequencies closer to those used for recording fluroescence
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            dtf = length(obj.f.imgPeriod);
            dte = nanmean(obj.e.dt);
            if dtf < dte
                error('Cannot downsample behavioarl var because ca imaging period is greater than sample period of behavioral variable');
            else
                vDS = obj.avgAsDecimation(obj.e.v(:,obj.eye2DownsampleIdx),obj.e.tv,obj.f.tAvg);
            end
        end
        function eyDS = downsampleE(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % decimate time-vector and eye positions to obtain sampling
            % frequencies closer to those used for recording fluroescence
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            dtf = length(obj.f.imgPeriod);
            dte = nanmean(obj.e.dt);
            if dtf < dte
                error('Cannot downsample behavioarl var because ca imaging period is greater than sample period of behavioral variable');
            else
                eyDS = obj.avgAsDecimation(obj.e.y(:,obj.eye2DownsampleIdx),obj.e.t,obj.f.tAvg);
            end
        end
        function dataCombo = combineLRHemisphere(obj,dataL,dataR)
            if sum(obj.yIsInLeftHemi) == 0
                % nothing to combine
                dataCombo = dataR;
            elseif sum(~obj.yIsInLeftHemi) == 0
                % nothing to combine
                dataCombo = dataL;
            else
                [pL,nL]= size(dataL);
                [pR,nR] = size(dataR);
                if pL ~= pR
                    error('data being combined should be two arrays of size pxnL, pxnR. p dim does not match');
                end
                dataCombo = NaN(pL,nL+nR);
                dataCombo(:,obj.yIsInLeftHemi) = dataL;
                dataCombo(:,~obj.yIsInLeftHemi) = dataR;
            end
        end
        function [ccMatrix,pvals,ZScores,bhat,R2,pTh,vTh] = computeCpCvPvalPthZScore(obj,varargin)
            % initialize output
            pTh = NaN; vTh = NaN;ZScores=NaN;bhat=NaN;R2 = NaN;
            X = setUpRegressionMatrix(obj);
            if obj.options.removeTwitches
                X = obj.f.removeTwitches(X);
                [ccMatrix,pvals] = regression.corr(X,...
                    obj.f.removeTwitches(...
                    obj.f.y(:,obj.dims2regress))...
                    );
            else
                [ccMatrix,pvals] = regression.corr(X,...
                    obj.f.y(:,obj.dims2regress));
            end
            if obj.options.compCCPValTh
                lambda = obj.storey2004AutoLambda(pvals(1,:));
                pTh = obj.storey2004FDRThreshold(pvals(1,:),obj.options.alphaCP,lambda);
                lambda = obj.storey2004AutoLambda(pvals(2,:));
                vTh = obj.storey2004FDRThreshold(pvals(2,:),obj.options.alphaCV,lambda);
            end
            if obj.options.computeZScores
                if obj.options.addRegressorAvg
                    if obj.options.removeTwitches
                        X = [X nanmean(...
                            obj.f.removeTwitches(obj.f.y)...
                            ,2)];
                    else
                        X = [X nanmean(obj.f.y,2)];
                    end
                end
                if obj.options.removeTwitches
                    [ZScores,bhat,R2] = obj.computeMiriTZScore(X,...
                        obj.f.removeTwitches(obj.f.y(:,obj.dims2regress)));
                else
                    [ZScores,bhat,R2] = obj.computeMiriTZScore(X,obj.f.y(:,obj.dims2regress));
                end
            end
        end
        function X = setUpRegressionMatrix(obj)
            X = obj.convolve([obj.downsampleE,obj.downsampleV],...
                obj.f.tAvg,obj.options.tau,obj.options.deMeanConvolved);
        end
        function [maxCC,selectedVars] = computeLeeSensitivity(obj,varargin)
            obj = obj.setUpRegression('aboveAndBelow',true,'removeConvMean',true);
            obj = obj.getXYWoutNans;
            ccMatrix = obj.computeCpCvPvalPthZScore(varargin{:});
            [maxCC,selectedVars] = caRegression.findMaxCorrVars([],obj.y,'ccMatrix',ccMatrix);
        end
    end
    
    methods(Static)
        function y = threshold(x,slope,offset)
            y = slope*x - offset;
            y(y<0) = 0;
        end
        function [Xc,tau] = convolve(X,t,tau,varargin)
            % X is a Nxp matrix.  Each column will be convolved
            % with a fixed vector approximating an exponential function with
            % known time constant
            if nargin > 3
                removeConvMean = varargin{1};
            else
                removeConvMean = true;
            end
            [N,p] = size(X);
            if any(any(isnan(X)))
                X(isnan(X))=0;
            end
            % convolution kernal (tau is in seconds)
            ker=exp(-(t-t(1))/tau);
            Xc = zeros(2*N-1,p);
            for i=1:p
                Xc(:,i) = conv(ker,X(:,i));
            end
            % remove edge effects
            Xc = Xc(1:N,:);
            
            if removeConvMean
                % subtract mean
                Xc = Xc - ones(N,1)*mean(Xc);
            end
        end
        function xDS = avgAsDecimation(x,tHigh,tLow)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % decimate time-vector and eye positions to obtain sampling
            % frequencies closer to those used for recording fluroescence
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [ntLow,dimtLow] = size(tLow);
            dimtHigh = size(x,2);
            if dimtHigh > size(tHigh,2) && size(tHigh,2)==1
                tHigh = repmat(tHigh(:),1,dimtHigh);
            end
            xDS = NaN(ntLow,dimtHigh*dimtLow);
            for lowDimInd = 1 : dimtLow
                currentGridPoints = tLow(:,lowDimInd);
                for highDimInd = 1 : dimtHigh
                    for lowInd = 1 : ntLow-1
                        highPntsInBinBOOL =  tHigh(:,highDimInd)>= currentGridPoints(lowInd) & tHigh(:,highDimInd) < currentGridPoints(lowInd+1);
                        if sum(highPntsInBinBOOL) >= 1
                            xDS(lowInd,highDimInd + (lowDimInd-1)*dimtHigh) = nanmean(x(highPntsInBinBOOL,highDimInd));
                        else
                            if lowInd > 1
                                xDS(lowInd,highDimInd + (lowDimInd-1)*dimtHigh ) = xDS(lowInd-1,highDimInd + (lowDimInd-1)*dimtHigh);
                            end
                        end
                    end
                end
            end
        end
        function [ZScores,bhat,R2,varargout] = computeMiriTZScore(X,y)
            % compute TScores compute ZScores using varying orthonormolized
            % matrices
            p = size(X,2);
            rankX = rank(X);
            totalNumVars = size(X,2);
            % if nxp X matrix is not low rank compute p regressions where
            % first regressor is interpretable and others are orthogonolized
            % run ML to find linear regression coefficient estimates
            if rankX==totalNumVars
                numReg2Run = size(y,2);
                TScores = NaN(p,numReg2Run);
                ZScores = NaN(p,numReg2Run);
                R2 = NaN(p,numReg2Run);
                for regInd = 1 : p
                    vars2Orthonorm = setdiff(1:totalNumVars,regInd);
                    Q = gramSchmidt([X(:,regInd) X(:,vars2Orthonorm)]);
                    bhat = regression.OLSCoefs(Q,y);
                    [TScores(regInd,:),R2(regInd,:)] = regression.OLSCoefTScores(X,y,bhat,'coef2Score',1,'XisOrthoNorm',true);
                    ZScores(regInd,:) = regression.OLSCoefZScores(TScores(regInd,:));
                end
            else
                bhat = regression.OLSCoefs(X,y);
                [TScores,R2] = regression.OLSCoefTScores(X,y,bhat);
                ZScores = regression.OLSCoefZScores(TScores);
            end
            varargout{1} = TScores;
        end
        function ZCorrected = miriZScoreMotionCorrect(ZScores)
            % compute the SD from a pseudo-empirical distribution computed by
            % taking negative half of ZScore Distribution and then
            % combining that with its mirror image around 0
            p = size(ZScores,1);
            pseudoSTD = NaN(p,1);
            for ind = 1 : p
                pseudoSTD(ind) = nanstd([ZScores(ind,ZScores(ind,:)<0),-ZScores(ind,ZScores(ind,:)<0)],[],2);
            end
            ZCorrected = ZScores./pseudoSTD;
        end
        function pThreshold = storey2004FDRThreshold(p,alpha,lambda)
            gammaVs = alpha./sort([10.^(0:1:4),3*10.^(0:1:4)]);
            fdrCurve = NaN(length(gammaVs),1);
            counter=1;
            for gamma = gammaVs
                fdrCurve(counter) = sum(p>lambda)*gamma/(max(1,sum(p<=gamma))*(1-gamma)); % note this matches eq. 3 in storey2004 and is written as in Miri2011
                counter = counter+1;
            end
            pThreshold = gammaVs(find(fdrCurve<alpha,1));
        end
        function lambda = storey2004AutoLambda(p)
            lambdaRange = 0:0.05:0.95;
            phiStats = NaN(length(lambdaRange),1);
            for k = 1 : length(lambdaRange)
                phiStats(k) = VPNISelection.storey2004Phihat(p,lambdaRange(k));
            end
            minPhiObs = min(phiStats);
            mseEstimate = NaN(length(lambdaRange),1);
            for k = 1 : length(lambdaRange)
                phiBSEstimates = bootstrp(100,@(x) VPNISelection.storey2004Phihat(x,lambdaRange(k)),p);
                mseEstimate(k) = mean((phiBSEstimates-minPhiObs).^2);
            end
            [~,lambdaRangeInd] = min(mseEstimate);
            lambda = lambdaRange(lambdaRangeInd);
        end
        function phi = storey2004Phihat(p,lambda)
            m = length(p);
            R = sum(p<=lambda);
            W = m - R;
            phi = W/((1-lambda)*m);
        end
        function [equalNumNaNs,zNaNLocations] = check4VaryingMissingData(Z,dim2check)
            % if dim = 1 check if each column has same number of NaNs
            zNaNLocations = isnan(Z);
            totalNumNans = sum(zNaNLocations,dim2check);
            if sum(totalNumNans)==0
                % no nans at all
                equalNumNaNs = true;
            else
                varInNumNans = diff(totalNumNans);
                notEqual = any(varInNumNans~=0);
                equalNumNaNs = ~notEqual;
                if equalNumNaNs
                    % run an extra test. NaNs must be in the same rows
                    totalNumNaNsAcrossC = sum(zNaNLocations,2);
                    uniqueTotals = unique(totalNumNaNsAcrossC);
                    numC = size(Z,2);
                    totalsInRowsNotMeetingCriteria = setdiff([0,numC],uniqueTotals);
                    numImproperRows = length(totalsInRowsNotMeetingCriteria);
                    equalNumNaNs = numImproperRows == 0;
                end
            end
            if ~equalNumNaNs
                error(['NaNs varying across dim= ' num2str(dim2check) ]);
            end
        end
        function [maxCC,selectedVars] = findMaxCorrVars(X,y,varargin)
            options = struct('ccMatrix',[]);
            options = parseNameValueoptions(options,varargin{:});
            if isempty(options.ccMatrix)
                ccMatrix = caRegression.corr(X,y);
            else
                ccMatrix = options.ccMatrix;
            end
            [~,selectedVars] = max(abs(ccMatrix),[],2);
            [~,dimy] = size(y);
            maxCC = NaN(dimy,1);
            for yind = 1 : dimy
                maxCC(yind) = ccMatrix(yind,selectedVars(yind));
            end
        end
    end
end

