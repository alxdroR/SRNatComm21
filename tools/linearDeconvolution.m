function yDeconv = linearDeconvolution(y,varargin)
options = struct('tauGCaMP',2,'time',[],'initCondBurnTime',1000);
options = parseNameValueoptions(options,varargin{:});

if ~isempty(options.time)
    if length(options.time)==1
        dt = options.time;
    elseif length(options.time)>1
        dt = options.time(2)-options.time(1);
    end
else
    dt = 1;
end

D = size(y,2)+options.initCondBurnTime;
gamma2 = exp(-dt/options.tauGCaMP);

% deconvolution matrix
G = spdiags([ones(D,1),-gamma2*ones(D,1)],[0,-1],D,D);
% pad input to erase initial condition dependence
paddedy = [y(:,1)*ones(1,options.initCondBurnTime) y]';
yDeconv = (G*paddedy)';
yDeconv = yDeconv(:,(options.initCondBurnTime+1):end);
end

