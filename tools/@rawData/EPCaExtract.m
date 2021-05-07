function [fluorescence,localCoordinates,ABinary,C,S,Por,b2,f2,rawobj] = EPCaExtract(rawobj,varargin)
options = struct('merge_thr',0.95,'tau',5,...
    'min_size_thr_postWarmup',16,'space_thresh_postWarmup',0.05,'time_thresh_postWarmup',0.05,...
    'max_size_thr',320,'K',250,'p',0,'channel',1,'motionC',false,'useTwitchDetector',false,...
    'tauGCaMP',1.3,'useImread',true,'singleCellAblations',false,'initialFootprints',[],'testingMode',false);
options = parseNameValueoptions(options,varargin{:});

if options.motionC
    [d1,d2,~] = size(rawobj.moviesMC{1}.channel{options.channel}); % size of movies
else
    [d1,d2,~] = size(rawobj.movies{1}.channel{options.channel});
end

if options.testingMode
    fluorescence={1};localCoordinates={1};ABinary=[];C=[];S=[];Por=[];b2=[];f2=[];
else
    optionsCNMF = CNMFSetParms(...
        'd1',d1,'d2',d2,...                         % dimensions of datasets
        'search_method','dilate','dist',3,...       % search locations when updating spatial components
        'deconv_method','constrained_foopsi',...    % activity deconvolution method
        'temporal_iter',2,...                       % number of block-coordinate descent steps
        'ssub',2,...
        'fudge_factor',0.98,...                     % bias correction for AR coefficients
        'merge_thr',options.merge_thr,...                    % merging threshold
        'gSig',options.tau,...
        'max_size_thr',options.max_size_thr...
        );
    
    
    % this last part is just incase user sends in options not
    % listed above but part of CNMFSetParms. For example send in
    % 'block_size',[20,20] will change the default block_size
    % set in CNMFSetParms
    optionsCNMF = parseNameValueoptions(optionsCNMF,varargin{:});
    % K number of components to be found
    % p - order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
    imagingPeriod = rawobj.metaData{1}.acq.linesPerFrame*rawobj.metaData{1}.acq.msPerLine;
    if options.motionC
        [fluorescence{1},localCoordinates{1},ABinary,C,S,Por,b2,f2] = demoCorePipeline(double(rawobj.moviesMC{1}.channel{options.channel}),options.p,options.K,options.tau,optionsCNMF,imagingPeriod,...
            'tauGCaMP',options.tauGCaMP,'initialFootprints',options.initialFootprints,'min_size_thr_postWarmup',options.min_size_thr_postWarmup,'space_thresh_postWarmup',...
            options.space_thresh_postWarmup,'time_thresh_postWarmup',options.time_thresh_postWarmup);
    else
        [fluorescence{1},localCoordinates{1},ABinary,C,S,Por,b2,f2] = demoCorePipeline(double(rawobj.movies{1}.channel{options.channel}),options.p,options.K,options.tau,optionsCNMF,imagingPeriod,...
            'tauGCaMP',options.tauGCaMP,'initialFootprints',options.initialFootprints,'min_size_thr_postWarmup',options.min_size_thr_postWarmup,'space_thresh_postWarmup',...
            options.space_thresh_postWarmup,'time_thresh_postWarmup',options.time_thresh_postWarmup);
    end
end

end
% ----------- select cells based on standard-deviation map and hard-threshold on distance
