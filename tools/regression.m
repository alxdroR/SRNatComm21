classdef regression
    
    methods (Static)
        function [ccMatrix,varargout] = corr(X,y)
            if any(isnan(X(:))) || any(isnan(y(:)))
                ccMatrix = nancorr(X,y);
                pval = NaN(size(ccMatrix));
            else
                [ccMatrix,pval] = corr(X,y);
            end
            varargout{1} = pval;
        end
        function bhat = OLSCoefs(X,y)
            bhat = pinv(X)*y;
        end
        function [Tscores,R2] = OLSCoefTScores(X,y,bhat,varargin)
            options = struct('coef2Score','all','XisOrthoNorm',false,'dXTXI',[]);
            options = parseNameValueoptions(options,varargin{:});
            p = size(bhat,1);
            if ischar(options.coef2Score)
                coef2Score = bhat;
            elseif isnumeric(options.coef2Score)
                coef2Score = bhat(options.coef2Score,:);
            end
            N = size(X,1);
            tScoreDim = size(coef2Score,1);
            if options.XisOrthoNorm
                dXTXI = ones(tScoreDim,1);
            else
                if isempty(options.dXTXI)
                    dXTXI = diag(inv(X'*X));
                    if isnumeric(options.coef2Score)
                        dXTXI = dXTXI(options.coef2Score);
                    end
                end
            end
            res = y-X*bhat; % calculate residual
            numRegressions = size(bhat,2);
            Tscores = NaN(tScoreDim,numRegressions);
            R2 = NaN(1,numRegressions);
            sigma2y = var(y);
            for k = 1 : numRegressions
                sigma2Est = res(:,k)'*res(:,k)./(N-p);
                betaSE = sqrt(dXTXI*sigma2Est);
                Tscores(:,k) = coef2Score(:,k)./betaSE;
                R2(k) = 1 - sigma2Est/sigma2y(k);
            end
        end
        function Zscores = OLSCoefZScores(Tscores,varargin)
            [p,numRegressions] = size(Tscores);
            Zscores = NaN(p,numRegressions);
            for regInd = 1 : p
                currentTSamples = Tscores(regInd,:);
                [~,sortedTSampInd] = sort(currentTSamples);
                fracBelowTScoreSorted = (0:numRegressions-1)./numRegressions;
                fracBelowCurrentTScore =  NaN(1,numRegressions);
                fracBelowCurrentTScore(sortedTSampInd) = fracBelowTScoreSorted;
                % commented out is the very slow but easier to understand
                % method for computing the same thing
                %                 fracBelowCurrentTScore = NaN(1,numRegressions);
                %                 for k = 1 : numRegressions
                %                     fracBelowCurrentTScore(k) = sum(currentTSamples < currentTSamples(k),2)/numRegressions;
                %                 end
                Zscores(regInd,:) = icdf('normal',fracBelowCurrentTScore,0,1);
                % set the minimum TScore to a value that does not
                % result in inf
                [minTScoreVal,TScoreMinInd] = min(currentTSamples);
                Zscores(regInd,TScoreMinInd) = minTScoreVal;
            end
        end
    end
end

