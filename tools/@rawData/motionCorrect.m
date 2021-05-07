function [rawobj,twitchFrames] = motionCorrect(rawobj,varargin)
options = struct('channel',1);
options = parseNameValueoptions(options,varargin{:});

% channel must be a row vector
if length(options.channel)>1
    if size(options.channel,1)>1
        options.channel = options.channel';
    end
end

rawobj = rawobj.updateMovies(varargin{:});
if isempty(rawobj.images)
    rawobj = rawobj.timeAverage(varargin{:});
end

% intialize
narrays = length(rawobj.movies);
rawobj.moviesMC = cell(narrays,1);

% motion correct
for arrayInd = 1 : narrays
    rawobj.moviesMC{arrayInd}.channel = {[],[],[]};
    for j=options.channel
        if ~isempty(rawobj.movies{arrayInd}.channel{j})
            
            rawobj.moviesMC{arrayInd}.channel{j} = zeros(size(rawobj.movies{arrayInd}.channel{j}),'uint16');
            T = size(rawobj.movies{arrayInd}.channel{j},3);
            referenceTransform  = fft2(squeeze(rawobj.images.channel{j}(:,:,arrayInd)));
            motionCorrectError = zeros(T,1);
            for timeInd=1:T % loop across all slices
                movingTransform = fft2(single(rawobj.movies{arrayInd}.channel{j}(:,:,timeInd)));
                [output, G] = dftregistration(referenceTransform,movingTransform,100);
                rawobj.moviesMC{arrayInd}.channel{j}(:,:,timeInd)=uint16(abs(ifft2(G))); % save shifted image
                motionCorrectError(timeInd) = output(1);
            end
            %errorTh = quantile(motionCorrectError,0.95);
            medError  = median(motionCorrectError);
            MAD = median(abs(motionCorrectError-medError));
            errorTh = medError+5*MAD;
            twitchFrames = find(motionCorrectError >= errorTh);
            if ~isempty(twitchFrames)
                for jj=twitchFrames'
                    twitchFrames=[twitchFrames;[jj-2:jj+2]'];
                end
                twitchFrames = unique(twitchFrames);
                twitchFrames(twitchFrames<=0) = 1;
                twitchFrames(twitchFrames>T) = T;
            end
            if j==1
                rawobj.twitchFrames = twitchFrames;
                H = rawobj.metaData{1}.acq.linesPerFrame;
                Ts = rawobj.metaData{1}.acq.msPerLine*H;
                rawobj.twitchTimes = zeros(length(twitchFrames),2);
                for jj=1:length(twitchFrames)
                    rawobj.twitchTimes(jj,:)= [twitchFrames(jj)-1 twitchFrames(jj)]*Ts;
                end
                rawobj.MCError = motionCorrectError;
            end
        end
    end
end
end % end motion correction method