function [saccadePoints,saccadeDirection,conjugateSaccade,...
    saccadeVelocity,saccadeRegionIndex,saccadeAmplitude] = findSaccadeTimes(e,varargin)
% change function name to findSaccadeTimes and update comments to reflect (todo)
% new function outputs and new options for velocity determination (todo)
% algorithm and for threshold determination (todo)
% 
% add name-value pairs to allow user to specify algorithm,  (todo)
% for velocity determination (median filter, kalman filter, no filter) (todo)
% and for threshold determination (hard cut off, standard deviation) (todo)
% add different appropriate if statement for selecting velocity calc (todo)
% and threshold calculator (todo)
%
% 
% FIND_SACCADE_TIMES - USES A VELOCITY THRESHOLD ALGORITHM TO DETERMINE
% INDICES WHEN SACCADES OCCUR IN EYE-POSITION DATA
%   ind = find_saccade_times(e)
%   Returns indices, ind, corresponding to times when the velocity of the Tx2 array, e
%   (where T is the total number of eye position samples), is greater than a threshold of 3 standard deviations 
%   from mean velocity.  velocity is calculated as diff(medfilt1(e,7)).  When multiple, consecutive, samples cross threshold
%   returns the index corresponding to the first sample in the threshold
%   crossing block. ind{1} are the threshold crossing indices for e(:,1)
%   and ind{2} for e(:,2).
%
%   cind --- indices when both eyes move together
% 
%   [ind,tind,v] = find_saccade_times(e,t)
%   uses Tx1 vector t to compute velocity as diff(e)./diff(t).  In addition to threshold crossing 
%   indices, returns the times (computed as tind=t(ind)) of threshold
%   crossing and velocity
%  
%  [ind,tind] = find_saccade_times(_,Name,Value)- use name value pairs to 
%  set specific user options (listed below) in the algorithm
%
%  Name-Value pair arguments-Specify optional comma-separated pairs of Name,Value arguments, where Name is the argument name and Value is the corresponding value. Name must appear inside single quotes (' '). 
%  You can specify several name and value pair arguments in any order as Name1,Value1,...,NameN,ValueN.
%
%  Name              Value
%  threshold         any double greater than 0.  Sets the number of
%                    standard deviations above mean velocity where threshold will be set.
%
%  order            any integer greater than 0.  sets the order of 1D median
%                   filter run on each column of the array e, before
%                   computing velocity
%           
%  verify           boolean variable set to true or false.  use to 
%                   plot traces in array e along with times of threshold 
%                   crossing and allow for user removal/addition of points.
%                   Since saccades are usually visble by eye, this can 
%                   be used to get correct false positives/negatives 
%
% adr
% 10/2/2013


% set default parameter values
% updating to use newer options setting methods -adr 02/16/2016
 options = struct('time',[],'saccadeTimes',[],'threshold',20,'filterOrder',0.5,'thresholdUnits','relative','view',false,'minThreshold',10,'minISI',1.4);
 options = parseNameValueoptions(options,varargin{:});
            
fOSeconds = options.filterOrder;
view = options.view;
t = options.time;


%fO = 7;% filter order
%nsigma = 3; % number of std above mean for threshold
%view = false; % user verification
%t = [];


% % set any user values and check for time vector
% if ~isempty(varargin)
%     NI = length(varargin); % number of inputs (should be an odd number)
%     t = varargin{1};
%     if NI > 1
%         inpi = 2:2:NI;
%         vali = 3:2:NI;
%         for i=1:length(inpi)
%             switch lower(varargin{inpi(i)})
%                 case 'threshold'
%                     nsigma = varargin{vali(i)};
%                 case 'order'
%                     fO = varargin{vali(i)};
%                 case 'view'
%                     view = varargin{vali(i)};
%             end
%         end
%     end
% end

% determine dt used for calculating velocity
if isempty(t)
    dt = [1 1];
else
    dt = diff(t);
end
% correct any errors in recording. No two points were possibly recorded
% simultaneously...error with online eye-position extraction
if any(dt==0)
    dt = replaceMissingEyeTimes(t);
end
fO=round(fOSeconds/mean(dt(:,1))); % filter order is number of 
                             % samples required to average a window 
                             % 500 ms in size (assuming equal sampling
                             % intervals)
efilt1 = medfilt1(e(:,1),fO);
efilt1(1) = e(1,1);
efilt2 = medfilt1(e(:,2),fO);
efilt2(1) = e(1,2);
% instantaneous velocity of trace with high-frequency noise filtered
velocity = [diff(efilt1)./dt(:,1) diff(efilt2)./dt(:,2)];

% set any Inf values to NaN
velocity(isinf(velocity)) = NaN;

% choose a threshold equal to cutoff tail nsigma
switch options.thresholdUnits
    case 'relative'
        th = nanmean(abs(velocity)) + options.threshold*nanstd(abs(velocity));
        th = max(options.minThreshold,th); % minimum threshold will be 10 degrees/sec
    case 'dps'
        th = [1 1]*options.threshold;
end
%th = [1 1]*100;
%th = [10,20];


% subtract threshold
velMinusThresh = bsxfun(@minus,abs(velocity),th);

% find where zero-crossing occurs
[samplesAboveThresh,eyeThatCrossed ] = find(sign(velMinusThresh)==1);

% saccade indices including consecutive times
initSaccadePoints{1} = samplesAboveThresh(eyeThatCrossed==1);initSaccadePoints{2} = samplesAboveThresh(eyeThatCrossed==2);

minISI = options.minISI; % seconds 
minISIpoints = round(minISI./mean(dt));

% determine start and stop times
saccadePoints = cell(2,1);
saccadeDirection = cell(2,1);
saccadeVelocity = cell(2,1);
saccadeAmplitude = cell(2,1);
conjugateSaccade = cell(2,1);
saccadeRegionIndex = cell(2,1);
if ~isempty(initSaccadePoints{1}) && ~isempty(initSaccadePoints{2})
    for eyeInd = 1:2
        startTimes = [max(1,initSaccadePoints{eyeInd}(1));initSaccadePoints{eyeInd}(find(diff(initSaccadePoints{eyeInd})>minISIpoints(eyeInd))+1)];
        stopTimes = zeros(size(startTimes));
        saccadePoints{eyeInd} = zeros(length(startTimes),2);
        conjugateSaccade{eyeInd} = false(length(startTimes),1);
        % determine the direction of the saccade (positive is to the left)
        saccadeDirection{eyeInd} = (e(startTimes+1,eyeInd) - e(startTimes,eyeInd))>0;
        % stop times defined by peak (max or min) within ~333ms in eye position after saccade start
        normalizedSignal = e(:,eyeInd)-min(e(:,eyeInd));
        T = size(e,1);
        saccadeVelocity{eyeInd} = zeros(length(startTimes),1);
        saccadeAmplitude{eyeInd} = saccadeVelocity{eyeInd};
      %  figure;plot(efilt1); hold on;
        for startInd = 1 : length(startTimes)
           if 0 
            % define end by max or min amplitude
            if saccadeDirection{eyeInd}(startInd)
                [~,peakInd] = max(abs(normalizedSignal(startTimes(startInd):min(T,startTimes(startInd)+5))));
            else
                [~,peakInd] = min(abs(normalizedSignal(startTimes(startInd):min(T,startTimes(startInd)+5))));
            end
            stopTimes(startInd) = startTimes(startInd)+peakInd-1;
           else
               
% % %                % MOVING THRESHOLD RULE
% % %                if startInd > 1
% % %                  ISI = t(startTimes(startInd+1),eyeInd) - t(startTimes(startInd),eyeInd);
% % %                  if ISI <= 5
% % %                     % previous velocity 
% % %                     maxPV = max(abs(velocity(max(1,[-minISIpoints:minISIpoints]+startTimes(startInd-1)),eyeInd)));
% % %                     % current velocity 
% % %                     maxCV = max(abs(velocity(max(1,[-minISIpoints:minISIpoints]+startTimes(startInd)),eyeInd)));
% % %                     % show contentious fixation
% % %                     if  maxCV/maxPV < 0.1 
% % %                         plot(startTimes(startInd),efilt1(startTimes(startInd)),'ro')
% % %                         plot(startTimes(startInd-1),efilt1(startTimes(startInd-1)),'ro')
% % %                     end
% % %                  end
% % %                end
               % define end as 1 second after saccade start detection
               [~,peakInd] = min(abs(  t(:,eyeInd) - ( t(startTimes(startInd),eyeInd) + 1) ));
               % sampling rate is usually soo low that we get 1 to 2 points during
               % the time of tinerest.  Hence, I just take the difference between
               % these points as an estimate of slope
               [~,seventyMSIndex] = min(abs(t(:,eyeInd)-(t(startTimes(startInd),eyeInd)+0.07)));
               indexDiff = max(1,seventyMSIndex-startTimes(startInd));
               [~,onethoMSIndex] = min(abs(t(:,eyeInd)-(t(startTimes(startInd),eyeInd)+1)));
               indexDiffoneT = max(1,onethoMSIndex-startTimes(startInd));
               if indexDiffoneT>1
                localVel = diff(e([0:indexDiffoneT-1]+startTimes(startInd),eyeInd))./diff(t([0:indexDiffoneT-1]+startTimes(startInd),eyeInd));
               else
                   localVel= nan;
               end
               saccadeVelocity{eyeInd}(startInd) = max(abs(localVel))*(2*saccadeDirection{eyeInd}(startInd)-1);
               %saccadeVelocity{eyeInd}(startInd) = (e(startTimes(startInd)+indexDiff,eyeInd)-e(startTimes(startInd),eyeInd))./(t(startTimes(startInd)+indexDiff,eyeInd)-t(startTimes(startInd),eyeInd));
               if saccadeDirection{eyeInd}(startInd)
                   [localMax,ampPeakInd] = max(abs(normalizedSignal(startTimes(startInd):peakInd)));
               else
                   [localMax,ampPeakInd] = min(abs(normalizedSignal(startTimes(startInd):peakInd)));
               end
               localAmp = abs(localMax - normalizedSignal(startTimes(startInd)));
                saccadeAmplitude{eyeInd}(startInd) = localAmp*(2*saccadeDirection{eyeInd}(startInd)-1);
           end
           stopTimes(startInd) = peakInd;
        end
        saccadePoints{eyeInd} = [t(startTimes,eyeInd) t(stopTimes,eyeInd)];
        
        %saccadeVelocity{eyeInd} = (e(stopTimes,eyeInd)-e(startTimes,eyeInd))./(saccadePoints{eyeInd}(:,2)-saccadePoints{eyeInd}(:,1));
        
        % [~,peakInd] = max(abs(normalizedSignal(startTimes(startInd):min(T,startTimes(startInd)+5))));
       
        saccadeRegionIndex{eyeInd} = [startTimes stopTimes];
    end
    [~,conjugateEye1Ind,conjugateEye2Ind] = intersect(saccadePoints{1}(:,1),saccadePoints{2}(:,1));
    conjugateSaccade{1}(conjugateEye1Ind) = true;
    conjugateSaccade{2}(conjugateEye2Ind) = true;
    
else
%    warning('no saccades detected')
end

        


% NOTE-get rid of false positive/negative stuff in future version (todo)
% move to a check_saccade_detection_beta code (todo)


% keep track of number of false positives
fp=0;
% false negatives
fn =0;
 if view
     fig = figure('Position',[50 100 1200 800]);
     for j=1:size(e,2)
        % rpt = 1; % loop through plotting and sorting out false positives negatives etc.
        % while rpt
             clf;
             plot(e(:,j),'b:.'); hold on;
              title(['eye ' num2str(j)]);
             
             if isempty(ind)
                 'NO SACCADES DETECTED!'
                 break
             else
             for k=1:length(ind{j})
                 h=plot(ind{j}(k),e(ind{j}(k),j),'ro');
                 set(h,'UserData',k);
             end
            
             if 0
                 disp('remove missclassified indices')
                 disp('type return then press enter when finished')
                 keyboard
                 Ikept = deletedROIs; % get the indices of all saved points
                 fp = fp + length(ind{j})-length(Ikept);
                 ind{j} = ind{j}(Ikept);
                 
                 disp('Place a datatip on any missing saccade locations\n Remember to hold down Alt then click when adding more than 1 location');
                 % declare data cursor object
                 dcm_obj = datacursormode(fig);
                 % set some of its properties
                 set(dcm_obj,'DisplayStyle','datatip',...
                     'SnapToDataVertex','off','Enable','on')
                 
                 % c_info will contain all of users points
                 keyboard
                 c_info = getCursorInfo(dcm_obj);
                 fn = fn + length(c_info);
                 if ~isempty(c_info)
                     np = cat(1,c_info(:).Position);
                     ind{j} =sort([ind{j};round(np(:,1))]);
                 end
                 term = input('Good?  Press `q` if yes and any other key to fix any mistakes\n','s');
                 if strcmp(term,'q')
                     break
                 end
             end
             %end
         end
     end
 end
 
 if 0 
 if ~isempty(t)
     tind{1} = t(ind{1});
     tind{2} = t(ind{2});

 %cind = [setdiff(ind{1},ind{2});setdiff(ind{2},ind{1})];
 cind = [];
 for j=1:length(ind{1})
     dI = zeros(size(ind{2}));
     for k=1:length(ind{2})
         dI(k) =abs(ind{1}(j)-ind{2}(k));
     end
     if min(dI)>5
         cind = [cind;ind{1}(j)];
     end
 end
 for j=1:length(ind{2})
     dI = zeros(size(ind{1}));
     for k=1:length(ind{1})
         dI(k) =abs(ind{2}(j)-ind{1}(k));
     end
     if min(dI)>5
         cind = [cind;ind{2}(j)];
     end
 end
 end
      
        
allind = union(ind{1},ind{2});
da = diff(allind);
allind = allind(da>4);


conjl = ones(size(allind));
for j=1:length(cind)
    conjl(allind==cind(j))=0;
end

%nonconj = [setdiff(ind{1},ind{2});setdiff(ind{2},ind{1})];
%ind2 = [cind ones(length(cind),1);nonconj zeros(length(nonconj),1)];
 
end

