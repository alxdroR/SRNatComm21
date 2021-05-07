% ----------- select cells based on correlation map and hard-threshold on distance
        function [fluorescence,localCoordinates,rawobj] = ccCellSelect(rawobj,varargin)
            options = struct('fileNumber',rawobj.fileNumber,'cellsize',4,'channel',1,'spread',7,'corrCut',0.3,...
                'Wbrder',5,'Hbrder',5,'motionC',false,'coordIn',[],'preAverage',false,'useTwitchDetector',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % we need movies and images check if this has already been loaded
            if rawobj.fileNumber ~= options.fileNumber
                rawobj = rawobj.calcCCMap('fileNumber',options.fileNumber,'channel',options.channel,'cellsize',options.cellsize,...
                    'motionC',options.motionC,'preAverage',options.preAverage,'useTwitchDetector',options.useTwitchDetector);
            elseif isempty(rawobj.ccMap)
                rawobj = rawobj.calcCCMap('fileNumber',options.fileNumber,'channel',options.channel,'cellsize',options.cellsize,...
                    'motionC',options.motionC,'preAverage',options.preAverage,'useTwitchDetector',options.useTwitchDetector);
            end
            
            if isempty(options.spread)
                error('distance between pixels must be specified');
            end
            
            % boxsize
            [boxsize,temp] = rawobj.micron2pixel(options.cellsize);
            spreadPixel=rawobj.micron2pixel(options.spread);
            
            % compute border margins in which pixels must reside
            WmarginPx = rawobj.micron2pixel(options.Wbrder);
            HmarginPx = rawobj.micron2pixel(options.Hbrder);
            
            narrays = length(rawobj.metaData);
            fluorescence = cell(narrays,1);
            localCoordinates = cell(narrays,1);
            for arrayInd = 1 : narrays
                H = rawobj.metaData{arrayInd}.acq.linesPerFrame;
                W = rawobj.metaData{arrayInd}.acq.pixelsPerLine;
               
                
                % compute borders
                Wbrder = [WmarginPx(arrayInd) W-WmarginPx(arrayInd)];
                Hbrder = [HmarginPx(arrayInd) H-HmarginPx(arrayInd)];
                
                % find max correlation across regressors
                
                if options.preAverage
                    maxcp = max(abs(rawobj.ccMapSA{arrayInd}.channel{options.channel}),[],3);
                else
                    maxcp = max(abs(rawobj.ccMap{arrayInd}.channel{options.channel}),[],3);
                end
                if isempty(options.coordIn)
                    % calculate correlated pixels above threshold then find index
                    % of point with local maximal intensity,
                    rsave=rawData.getCCIndices(maxcp,options.corrCut,spreadPixel,WmarginPx(arrayInd),...
                        rawobj.images.channel{options.channel}(:,:,arrayInd),boxsize(arrayInd));
                    
                    % take fluorescence traces at selected indices
                    % and calculate maximal correlation at these points
                    
                    % covert saved subIndices to linear indices
                    linInd = sub2ind([H,W],rsave(:,2),rsave(:,1));
                    cIs = maxcp(linInd);
                    coord = rsave(cIs>options.corrCut,:);
                    linInd =linInd(cIs>options.corrCut);
                else
                    coord = options.coordIn;
                    linInd = sub2ind([H,W],coord(:,2),coord(:,1));
                end
                
                if ~isempty(coord)
                    if options.preAverage
                        y =  rawobj.moviesSA{arrayInd}(:,linInd);
                    else
                        if options.motionC
                            y=rawData.nnaverage(rawobj.moviesMC{arrayInd}.channel{options.channel},...
                                rawobj.images.channel{options.channel}(:,:,arrayInd),coord,boxsize,temp);
                        else
                            y=rawData.nnaverage(rawobj.movies{arrayInd}.channel{options.channel},...
                                rawobj.images.channel{options.channel}(:,:,arrayInd),coord,boxsize,temp);
                        end
                    end
                    
                    if isempty(options.coordIn)
                        % sort traces by correlations
                        [~,srtind]=sort(cIs(cIs>options.corrCut),'descend');
                        fluorescence{arrayInd} =  y(:,srtind);
                        localCoordinates{arrayInd} =  coord(srtind,:);
                    else
                        fluorescence{arrayInd} =  y;
                        localCoordinates{arrayInd} =  coord;
                    end
                end
            end
        end % end cell selection
