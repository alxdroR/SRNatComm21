 function saveDataAllPlanes(rawobj,varargin)
            % save traces and images from all Planes
            options = struct('cellsize',4,'channel',1,'spread',7,'corrCut',0.3,...
                'Wbrder',5,'Hbrder',5,'motionC',false,'preAverage',false,'useTwitchDetector',false,'saveFiles',true);
            options = parseNameValueoptions(options,varargin{:});
            
            % load meta data if it exist
            expdataFile = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','expMetaData');
            if exist(expdataFile,'file')==2
                load(expdataFile)
            else
                expMetaData = makeMetaDataStruct;
            end
            
                % we don't load all planes at once since this will overload RAM
            % and might not be possible
            filenames = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','raw');
            narrays = length(filenames);
            if narrays>0
                fluorescence = cell(narrays,1);
                localCoordinates = cell(narrays,1);
                ccMap = cell(narrays,1);
                twitchFrames = cell(narrays,1);
                twitchTimes = cell(narrays,1);
                MCerror = cell(narrays,1);
                syncOffset = zeros(narrays,1);
                for arrayInd = 1 : narrays
                    % select cells for this plane
                    [f1plane,c1plane,rawobj]=...
                        rawobj.ccCellSelect('fileNumber',arrayInd,'cellsize',options.cellsize,'channel',options.channel,'spread',options.spread,...
                        'corrCut',options.corrCut,'Wbrder',options.Wbrder,'Hbrder',options.Hbrder,'motionC',options.motionC,...
                        'preAverage',options.preAverage,'useTwitchDetector',options.useTwitchDetector);
                    
                    if arrayInd==1
                        % given width, height, we can now intialize images
                        % assuming that width and height are constant across
                        % planes
                        oneImage = zeros(rawobj.metaData{1}.acq.linesPerFrame,rawobj.metaData{1}.acq.pixelsPerLine,narrays,'single');
                        images.channel = {oneImage,oneImage,oneImage};
                        for chNum=1:3
                            images.channel{chNum}(:,:,arrayInd) = rawobj.images.channel{chNum};
                        end
                    else
                        for chNum=1:3
                            images.channel{chNum}(:,:,arrayInd) = rawobj.images.channel{chNum};
                        end
                    end
                    fluorescence{arrayInd} = f1plane{1};
                    localCoordinates{arrayInd} = c1plane{1};
                    if options.preAverage
                        ccMap{arrayInd}.channel =rawobj.ccMapSA{1}.channel;
                    else
                        ccMap{arrayInd}.channel =rawobj.ccMap{1}.channel;
                    end
                    twitchFrames{arrayInd} = rawobj.twitchFrames;
                    twitchTimes{arrayInd} = rawobj.twitchTimes;
                    MCerror{arrayInd} = rawobj.MCError;
                    
                    expMetaData.scanParam{arrayInd} = rawobj.metaData{1};
                    
                    syncOffset(arrayInd) = rawData.calcSyncOffset(rawobj.fishID,rawobj.expCond,arrayInd);
                              
                end
                
                saveTraceName = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','catraces');
                cellSelectParam = options;
                
                saveImgName = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','medianImages');
                
                saveMetaName = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','metaDataProc');
                if options.saveFiles
                save(saveTraceName,'fluorescence','localCoordinates','ccMap','cellSelectParam','expMetaData','twitchFrames','twitchTimes','MCerror','syncOffset')
                  save(saveImgName,'images')
                    save(saveMetaName,'expMetaData');
                end
              
            end
            
         end % end saveDataAllPlanes