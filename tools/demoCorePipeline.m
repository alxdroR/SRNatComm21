function [Fselected,cm,A_or,C_or,S_or,P_or,b2,f2] = demoCorePipeline(Y,p,K,tau,optionsCNMF,imgPeriod,varargin)
% [Fselected,cm,ASelected] =demoCorePipeline(Y,p,K,tau,optionsCNMF)
% see demo_script


options = struct('A_or',NaN,'b2',NaN,'C_or',NaN,'f2',NaN,'P_or',NaN,'tauGCaMP',1.3,'initialFootprints',[],...
    'min_size_thr_postWarmup',16,'space_thresh_postWarmup',0.05,'time_thresh_postWarmup',0.05);
options = parseNameValueoptions(options,varargin{:});
% options.A_or, b2, C_or, f2, P_or should be NaN to run everything from
% scratch or with the appropriate values to only run non-negative
% deconvolution
if any(isnan(options.A_or))
    runEverything = true;
elseif any(isnan(options.b2))
    runEverything = true;
elseif any(isnan(options.C_or))
    runEverything = true;
elseif any(isnan(options.f2))
    runEverything = true;
elseif ~(isstruct(options.P_or))
    runEverything = true;
else
    runEverything = false;
end

% discrete time CIRF tau
tauGCaMP = options.tauGCaMP;
tauGCaMPD = exp(-imgPeriod/tauGCaMP);

% Data pre-processing
[P,Y] = preprocess_data(Y,p);

% update spatial components
[d1,d2,T] = size(Y);                                % dimensions of dataset
d = d1*d2;
Yr = reshape(Y,d,T);

if runEverything
    if ~isempty(options.initialFootprints)
        optionsCNMF.spatial_method = 'constrained';
        [Ain,bin,Cin] = update_spatial_components(Yr,[],[],options.initialFootprints,P,optionsCNMF);
        P.p = 0;    % set AR temporarily to zero for speed
        [Cin,fin,P] = update_temporal_components(Yr,Ain,bin,Cin,[],P,optionsCNMF);
        optionsCNMF.spatial_method = 'regularized';
    else
        % fast initialization of spatial components using greedyROI and HALS
        [Ain,Cin,bin,fin,center] = initialize_components(Y,K,tau,optionsCNMF,P);
    end
    
    [A,b,Cin] = update_spatial_components(Yr,Cin,fin,[Ain,bin],P,optionsCNMF);
    
    % update temporal components
    P.p = 0;    % set AR temporarily to zero for speed
    [C,f,P,S,YrA] = update_temporal_components(Yr,A,b,Cin,fin,P,optionsCNMF);
    
    % classify components
    optionsCNMF.min_size_thr = options.min_size_thr_postWarmup;
    optionsCNMF.space_thresh = options.space_thresh_postWarmup;
    optionsCNMF.time_thresh = options.time_thresh_postWarmup;
    [ROIvars.rval_space,ROIvars.rval_time,ROIvars.max_pr,ROIvars.sizeA,keep] = classify_components(Y,A,C,b,f,YrA,optionsCNMF);
    if 0
    keep = (ROIvars.rval_space > optionsCNMF.space_thresh) & (ROIvars.rval_time > optionsCNMF.time_thresh) & (ROIvars.sizeA > optionsCNMF.min_size_thr);
    else
        warning('demoCorePipeline no longer reflects what was done in the paper because line 62 is commented out');
    end
    if sum(keep)>0
        % merge found components
        %keep = true(size(A,2),1);
        [Am,Cm,K_m,merged_ROIs,Pm,Sm] = merge_components(Yr,A(:,keep),b,C(keep,:),f,P,S,optionsCNMF);
        
        % refine estimates excluding rejected components
        [A2,b2,C2] = update_spatial_components(Yr,Cm,f,[Am,b],Pm,optionsCNMF);
        Pm.p = p;    % restore AR value and set tau
        Pm.g = tauGCaMPD;
        optionsCNMF.restimate_g = false;
        [C2,f2,P2,S2] = update_temporal_components(Yr,A2,b2,C2,f,Pm,optionsCNMF);
        [A_or,C_or,S_or,P_or] = order_ROIs(A2,C2,S2,P2); % order components
        Fselected = A_or'*Yr;
        cm = com(A_or,d1,d2);
    else
        warning('NO FOOTPRINTS PASSED KEEP CRITERIA');
        Fselected = [];cm=[];A_or=A;C_or=C;S_or=S;P_or=P;b2=b;f2=f;
    end
else
    A_or = options.A_or;
    b2 = options.b2;
    C_or = options.C_or;
    f2 = options.f2;
    P_or = options.P_or;
    S_or = NaN;
    Fselected = NaN;
    cm = NaN;
    P_or.g = tauGCaMPD;
    optionsCNMF.restimate_g = false;
    [C2,f2,P2,S2] = update_temporal_components(Yr,A_or,b2,C_or,f2,P_or,optionsCNMF);
end

end

