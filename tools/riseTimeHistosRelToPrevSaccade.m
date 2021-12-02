function riseTimeHistosRelToPrevSaccade(varargin)
% riseTimeHistosRelToPrevSaccade - histogram times when SR activity
% increases relative to previous saccade
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202

options = struct('AnticipatoryAnalysisMatrix',[],'ISIMatrix',[]);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.AnticipatoryAnalysisMatrix) || isempty(options.ISIMatrix) 
   loadSRSlopes
else
    AnticipatoryAnalysisMatrix = options.AnticipatoryAnalysisMatrix;
    ISIMatrix = options.ISIMatrix;
end

Rtimes = AnticipatoryAnalysisMatrix(:,2); % rise-times 
RtimeFromLastSaccade = ISIMatrix - abs(Rtimes);
riseMeasured = ~isnan(RtimeFromLastSaccade);

% format data to plot into a sharable format
data.risePS = RtimeFromLastSaccade(riseMeasured);
data.riseUS = Rtimes(riseMeasured);

% plot
figure; 
histogram(data.risePS,0:0.5:31,'Normalization','probability','FaceColor',[0.0 0.1882 0.3137]);box off; xlabel({'activity rise-time' 'relative to previous saccade (s)'});ylabel('fraction of all fixations'); setFontProperties(gca)
xlim([0 31]);ylim([0 0.08])
set(gcf,'PaperPosition',[1 1 2.2 2.2])

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)

% print stats quoted in the paper
Rtime_quantiles = quantile(data.risePS,[0.1 0.5 0.9]);
var_ratio = nanvar(data.risePS)/nanvar(data.riseUS);
fprintf('\n\nThe timing of activity initiation relative\nto the occurrence of the previous saccade was generally more variable,\nwith a range\n')
fprintf('of %0.3f to %0.3f seconds and variance (%0.3f seconds^2) that was %0.3f times\nlarger than when measured with respect to upcoming saccade (%0.3f seconds^2)\n',Rtime_quantiles(1),Rtime_quantiles(3),nanvar(data.risePS),var_ratio,nanvar(data.riseUS)); 


[h,p] = kstest2(data.riseUS,data.risePS);
n = sum(~isnan(data.risePS));
fprintf('\n\nwe rejected the null hypothesis that these two measurements\nin the time of rise come from the same distribution\n')
fprintf('(Fig. 4E, p<0.001 (p=%0.6f), n=%d; two-sample KS-test)\n',p,n)

