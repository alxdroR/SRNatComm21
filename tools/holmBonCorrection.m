function H = holmBonCorrection(pvals,alpha,varargin)
% Use Holm-Bonferroni criteria to determine the "significance" of a p-value
% 
% H = holmBonCorrection(pvals,alpha)
% uses the Holm-Bonferroni method to determine the signficance of multiple 
% p-values, pvals, at a given significance level, alpha. H is a vector
% with the same lenght as pvals that is 1 if the null hypothesis was
% rejected and 0 otherwise. 
%
%  When performing multiple hypotheses tests, $H_1,H_2,....H_m$, the probability, $\alpha$, of declaring at least one 
% of the test results significant when it is not increases with the number of tests. 
% To control this familywise error at level $\alpha$, the Holm-Bonferroni correction method orders the p-values from lowest to 
% highest and rejects or fails to reject each p-value using a monotonically increasing rejection criteria. 
% For more details see <https://en.wikipedia.org/wiki/Holm%E2%80%93Bonferroni_method>
% <http://www.gs.washington.edu/academics/courses/akey/56008/lecture/lecture10.pdf>
%
%   OUTPUT
% H -- Vector of Boolean variables equal in length to pval. If pval(i) 
%      is significant according to the Holm-Bonerroni correction method
%      H(i) is true.
%
% adr
% 3/16/2018
options = struct('doNotIncludeNaNRows',false);
options = parseNameValueoptions(options,varargin{:});


H = false(size(pvals));
numTests = numel(H);
if options.doNotIncludeNaNRows
    bothRowsAreNaN = isnan(pvals(:,1)) & isnan(pvals(:,2));
    numWeShouldNotCount = sum(bothRowsAreNaN);
    numTests = numTests - numWeShouldNotCount;
end
[pvalsS,sortInd] = sort(pvals(:),'ascend');
for nc = 1 : numTests
    if pvalsS(nc) < alpha/(numTests-nc+1) 
        H(sortInd(nc))=true;
    end
end

end

