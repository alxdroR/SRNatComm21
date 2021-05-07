function rawobj = timeAverage(rawobj,varargin)
% average the movie stack stored in rawData
options = struct('fast',false,'motionC',false,'channel',1,'useTwitchDetector',false,'statisticFnc',@median,'singleCellAblations',false);
options = parseNameValueoptions(options,varargin{:});

rawobj = rawobj.updateMovies(varargin{:});

% check if user wants twitch correction but does not have a motion corrected video loaded and did not ask to load a motion
% corrected video
if options.useTwitchDetector && isempty(rawobj.moviesMC)
    error('Twitch Removal Has been selected but twitches have not yet been found. Motion correcion first');
end

narrays = length(rawobj.movies);
if narrays>0
    oneImage = zeros(rawobj.metaData{1}.acq.linesPerFrame,rawobj.metaData{1}.acq.pixelsPerLine,narrays,'single');
    rawobj.images.channel = {oneImage,oneImage,oneImage};
    for channel = 1:3
        for arrayInd = 1 : narrays
            [d1,d2,T] = size(rawobj.movies{arrayInd}.channel{channel});
            % only analyze if this channel is in the raw data
            if d1 ~= 0 && d2 ~= 0
                % which indices to average 
                if options.useTwitchDetector
                    avgind = setdiff(1:T,rawobj.twitchFrames);
                else
                    avgind = 1:T;
                end
                
                % which video to average (motion corrected or not)
                if options.motionC 
                    % even if they wanted motion correction, this channel
                    % might not have been motion corrected
                    if ~isempty(rawobj.moviesMC{arrayInd}.channel{channel})
                        rawobj.images.channel{channel}(:,:,arrayInd) = options.statisticFnc(rawobj.moviesMC{arrayInd}.channel{channel}(:,:,avgind),3);
                    else
                        rawobj.images.channel{channel}(:,:,arrayInd) = options.statisticFnc(rawobj.movies{arrayInd}.channel{channel}(:,:,avgind),3);
                    end
                else
                    rawobj.images.channel{channel}(:,:,arrayInd) = options.statisticFnc(rawobj.movies{arrayInd}.channel{channel}(:,:,avgind),3);
                end
            end
        end
    end
end
end
