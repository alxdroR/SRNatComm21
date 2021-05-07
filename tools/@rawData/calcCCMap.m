% ----- create correlation map with rectified eye position
        function rawobj = calcCCMap(rawobj,varargin)
            % rawobj = calcCCMap
            % calculate correlation map between spatially averaged movies and
            % decimated eye-trace regressors.  Regressors are rectified
            % position (positions above and below zero) and rectified
            % velocity (velocity above and below zero). Name-value pairs
            %
            % fileNumber -- number specifying which plane to load and
            %               analyze. Default is
            % cellsize --  size of box around which we take spatial average
            %              (in microns). Default is 4
            % channel --   channel to use when calculating correlation.
            %              Default is channel 1.
            options = struct('fileNumber',rawobj.fileNumber,'cellsize',4,'channel',1,'preAverage',false,...
                'motionC',false,'useTwitchDetector',false);
            options = parseNameValueoptions(options,varargin{:});
            
            if options.motionC
                % we need motion-corrected movies and images check if this has already been loaded
                if rawobj.fileNumber ~= options.fileNumber 
                    [rawobj] = rawobj.motionCorrect('fileNumber',options.fileNumber,'channel',options.channel);
                elseif isempty(rawobj.moviesMC)
                    [rawobj] = rawobj.motionCorrect('fileNumber',options.fileNumber,'channel',options.channel);
                end
                rawobj.movies = [];
            else
                if rawobj.fileNumber ~= options.fileNumber 
                    rawobj = rawobj.load('fileNumber',options.fileNumber);
                    rawobj = rawobj.timeAverage('fileNumber',options.fileNumber);
                end
                if isempty(rawobj.movies)
                    rawobj = rawobj.load('fileNumber',options.fileNumber);
                end
                if isempty(rawobj.images)
                    rawobj = rawobj.timeAverage('fileNumber',options.fileNumber);
                end
            end
            if options.useTwitchDetector
                rawobj = rawobj.timeAverage('fileNumber',options.fileNumber,'useTwitchDetector',options.useTwitchDetector);
            end
            
            % spatially-average pixels before correlating with eye position
            [pixelRadius,temp] = rawobj.micron2pixel(options.cellsize);
            if options.motionC
                 narrays = length(rawobj.moviesMC);
            else
            narrays = length(rawobj.movies);
            end
            if narrays > 0
            % load eye traces for decimating to movie size
            eyeobj = eyeData('fishid',rawobj.fishID,'locationID',1,'expcond',rawobj.expCond);
            
            rawobj.ccMap =cell(narrays,1);
            for arrayInd = 1 : narrays
                 if options.motionC
                     [H,W,T] = size(rawobj.moviesMC{arrayInd}.channel{options.channel}); % size of movies
                 else
                      [H,W,T] = size(rawobj.movies{arrayInd}.channel{options.channel}); % size of movies
                 end
                
                if options.preAverage
                    if options.motionC
                        % spatially average movie
                        Fmat=rawData.nnaverage(rawobj.moviesMC{arrayInd}.channel{options.channel},...
                            'all',pixelRadius,temp);
                        rawobj.moviesMC = [];
                    else
                        % spatially average movie
                        Fmat=rawData.nnaverage(rawobj.movies{arrayInd}.channel{options.channel},...
                            'all',pixelRadius,temp);
                    end
                    rawobj.moviesSA{arrayInd} = Fmat;
                else
                    if options.motionC
                        Fmat = reshape(rawobj.moviesMC{arrayInd}.channel{options.channel},[H*W,T]);
                    else
                        Fmat = reshape(rawobj.movies{arrayInd}.channel{options.channel},[H*W,T]);
                    end
                    Fmat = Fmat';
                end
                % decimate eye traces
                Ts = rawobj.metaData{arrayInd}.acq.msPerLine*rawobj.metaData{arrayInd}.acq.linesPerFrame; % sampling inverval
               % syncOffset = rawobj.calcSyncOffset(rawobj.fishID,rawobj.expCond,arrayInd);
                edec = regress_preproc_twitch(T,Ts,[eyeobj.time{options.fileNumber}(:,1) eyeobj.position{options.fileNumber}],[],0);
                
                % calculate correlation coefficient
                if options.useTwitchDetector
                    corrind = setdiff(1:T,rawobj.twitchFrames);
                else
                    corrind = 1:T;
                end
               
                cc=zscore(single(Fmat(corrind,:)),1)'*zscore(edec.Xconv(corrind,:),1)/length(corrind);
                if options.preAverage
                    rawobj.ccMapSA{arrayInd}.channel = {[],[],[]};
                    rawobj.ccMapSA{arrayInd}.channel{options.channel} = reshape(cc,[H,W,size(edec.Xconv,2)]);     
                else
                    rawobj.ccMap{arrayInd}.channel = {[],[],[]};
                    rawobj.ccMap{arrayInd}.channel{options.channel} = reshape(cc,[H,W,size(edec.Xconv,2)]);
                end
            end
            end
        end % end correlation map
