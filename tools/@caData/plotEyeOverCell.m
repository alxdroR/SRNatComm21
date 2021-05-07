function plotEyeOverCell(caobj,varargin)
            % options = struct('cellNumber',[],'subIndex',[],'plane',[]);
            options = struct('deconvolve',false,'cellNumber',[],'subIndex',[],'plane',[],'axisHandle',[],'figureHandle',[],...
                'showSaccadeDetection',true,'cellColor','b');
            options = parseNameValueoptions(options,varargin{:});
            
            % determine which cell user has requested 
            if isempty(options.cellNumber)
                if isempty(options.subIndex) || isempty(options.plane)
                    error('must specify a cellNumber OR a plane and subIndex field');
                end
                subIndex = options.subIndex;
                plane = options.plane;
            else
                [subIndex,plane]=ind2plane(caobj,options.cellNumber);
            end
            
            % get desired signal
            zeroOneScale = @(x) (x-min(x))/(max(x)-min(x));
            if options.deconvolve
                cellSignal = caobj.deconvolve(struct('plane',plane,'subIndex',subIndex));
                cellSignal = zeroOneScale(cellSignal);
            else
                cellSignal = zeroOneScale(caobj.fluorescence{plane}(:,subIndex));
            end
            
            % get saccade times from eye data
            eyeobj = eyeData('fishId',caobj.fishID,'expCond',caobj.expCond);
            eyeobj = eyeobj.saccadeDetection;
            
            
            
            minTime = min(caobj.time{plane}(1,subIndex),min(eyeobj.time{plane}(1,:)));
            maxTime = min(caobj.time{plane}(end,subIndex),min(eyeobj.time{plane}(end,:)));
            
            
            if isempty(options.figureHandle) && isempty(options.axisHandle)
                figure;
            elseif ~isempty(options.figureHandle)
                figure(options.figureHandle); hold on;
            end
            if isempty(options.axisHandle)
                options.axisHandle = gca;
            end
            
            
            axes(options.axisHandle)
            plot(caobj.time{plane}(:,subIndex),cellSignal,'color',options.cellColor); hold on;
            xlim([minTime maxTime]);
            % set(gca,'XTickLabel',[])
            box off
            titlestr = caobj.generateTitle;
            title(options.axisHandle(1),titlestr);
            % show saccade times
            ylimits = [0 1];
            
            if options.showSaccadeDetection
                lineStyle = {'--',':'};
                lineColor = {'b','g'};
                for eyeNumber = 1:2
                    for saccadeNumber=1:length(eyeobj.saccadeTimes{plane}{eyeNumber})
                        plot([1 1]*eyeobj.saccadeTimes{plane}{eyeNumber}(saccadeNumber,1),[ylimits(1) ylimits(2)],...
                            'Color',lineColor{eyeNumber},'LineStyle',lineStyle{eyeobj.saccadeDirection{plane}{eyeNumber}(saccadeNumber)+1});
                    end
                end
            end
            
            plot(eyeobj.time{plane},zeroOneScale(eyeobj.position{plane}(:,1)),'k','LineWidth',0.1); hold on;
            plot(eyeobj.time{plane},zeroOneScale(eyeobj.position{plane}(:,2)),'color',[1 1 1]*0.4,'LineWidth',0.1);
            
            xlim([minTime maxTime])
            % set(gca,'XTickLabel',[])
            box off
            xlabel('time(seconds)')
         end