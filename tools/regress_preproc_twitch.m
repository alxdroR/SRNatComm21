function [stat,tmap] = regress_preproc_twitch(N,Ts,E,tframes,varargin)
% stat] = regress_preproc(y,Ts,E)
% Create necessary data matrix (allign samples and build data matrix) to regresses pixel 
% intensities against convolved eye-position as described in Miri et.al. 2010.
%   Input: y -- Nxp matrix of fluroescence samples.  N is the number of frames
%               recorded and p is the number of pixels in the image.
%
%          Ts -- sampling rate at which fluroescence was recorded
%
%          E -- N2x3 matrix whose first column contains the times at which
%               eye-positions were recorded and whos last two columns
%               contain left and right eye positions.  N2 is the number
%               samples taken of eye-position and is usually much greater
%               than N
%         tframes -- frames when twiches occur.  These will be removed 
% problems with the approch: many times the covariates based on eye
% position can lower the mean-squared error substantially compared to
% a fully regularized estimator (i.e. compared to the sample variance).
% The final products however 1.) sometimes appear to be single pixels/don't
% easily translate into things a human would call a cell
% 2.) have fluroescence traces that don't easily correlate by eye with
% either eye position or eye velocity
% 3.) because of problems 1 automated methods for circling
% pixel/cells that correlate with eye position (e.g. using regionprops)
% fails to always give meaningfull results

if isempty(varargin)
    offset = 0;
else
    offset = varargin{1};
end
% decimate time-vector and eye positions to obtain sampling 
% frequencies closer to those used for recording fluroescence
[ted,Ed,tmap]=allign_samples(E,N,Ts,tframes,offset);
 
% build regression variables
X = build_regressors(ted,Ed);
% assume a priori knowledge that firing rate has a better linear
% correlation with eye-position related variables and use a fixed known
% filter between Ca and firing rate.  Convolve regressors and mean subtract
[Xc,tau] = conv_fixed_CIRF(X,ted);

stat.Xconv = Xc; 
stat.t = ted;
stat.Ts = Ts;
stat.Xnc = X;
stat.tau = tau;
stat.Ed = Ed;
end

function X = build_regressors(ted,Ed)
Ed = detrend(Ed);
% subtract the median from eye positions
Ed = Ed - ones(length(Ed),1)*median(Ed);

% create a positive and negative only stimulus
Ep = Ed; Ep(Ep<0) = 0;
En = Ed; En(En>0) = 0;


% create velocity vector
v = [[0 0];diff(Ed)./(diff(ted)*[1 1])];

% create a postive and negative velocity
vp = v; vp(vp<0) = 0;
vn = v; vn(vn>0) = 0;

% correlated regressors
%X = [Ed v Ep En vp vn];
% a lower condition number usually results from
%X = [Ed v Ep vp];
X = [Ep En vp vn];
%X = [Ed(:,1) v(:,1)];
%X  = Ed(:,1);
end

function [ted,Ed,tmap]=allign_samples(E,N,Ts,tframes,offset)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% decimate time-vector and eye positions to obtain sampling 
% frequencies closer to those used for recording fluroescence
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
te = E(:,1)-offset; % times at which eye-position was recorded 
good = setdiff(1:N,tframes);
Ngood = length(good);

Ed = zeros(Ngood,2);
for tt=1:Ngood
    spnt = ceil(te/Ts)==good(tt);
    tmap{tt} = find(spnt);
    if sum(spnt)>1
        Ed(tt,:)=mean(E(spnt,2:3));
    elseif sum(spnt)==1
        Ed(tt,:)=(E(spnt,2:3));
    else
        if tt>1
            Ed(tt,:) = Ed(tt-1,:);
        end
    end
        
end

ted = good'*Ts;


end

function [Xc,tau] = conv_fixed_CIRF(X,ted)
% X is a Nxp matrix.  Each column will be convolved 
% with a fixed vector approximating an exponential function with 
% known time constant 

[N,p] = size(X);
  tau = 1.89;
  % convolution kernal (tau is in seconds) 
  ker=exp(-(ted-ted(1))/tau);
  
Xc = zeros(2*N-1,p);
for i=1:p
    Xc(:,i) = conv(ker,X(:,i));
end
% remove edge effects
Xc = Xc(1:N,:);

% subtract mean 
Xc = Xc - ones(N,1)*mean(Xc);
end
