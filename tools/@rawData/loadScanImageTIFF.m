function [FCh1,FCh2,FCh3] = loadScanImageTIFF(filename,varargin)
options = struct('fast',false,'channel','all','useImread',true);
options = parseNameValueoptions(options,varargin{:});

% get information about the fname
[header,Iinfo] = rawData.grabMetaData(filename,varargin{:});

% total number of frames recorded
numFrames = header.acq.numberOfFrames;
if options.fast
    numFrames = min(numFrames,20);
end

if strcmp(options.channel,'all')
    % if pictures were averaged we don't load
    % all frames
    if header.acq.averaging
        T = header.acq.numberOfChannelsSave;
    else
        T = numFrames*header.acq.numberOfChannelsSave;
    end
    if T ~= length(Iinfo)
        T = length(Iinfo);
    end
    % load all data
    Fmat = zeros(header.acq.linesPerFrame,header.acq.pixelsPerLine,T,'uint16'); % calcium time-series
    if options.useImread
        for i=1:T
            Fmat(:,:,i)=imread(filename,'Index',i,'PixelRegion',{[1 header.acq.linesPerFrame],[1 header.acq.pixelsPerLine]});
        end
    else
        TifLink = Tiff(filename,'r');
        for i = 1:T
            TifLink.setDirectory(i);
            Fmat(:,:,i) = TifLink.read();
        end
        TifLink.close();
    end
    
    % save channels with appropriate labels
    if header.acq.numberOfChannelsSave == 3
        FCh3 = Fmat(:,:,3:3:T);
        FCh2 = Fmat(:,:,2:3:T);
        FCh1 = Fmat(:,:,1:3:T);
    elseif header.acq.numberOfChannelsSave == 2
        % check which combo was saved: 1,3; 1,2; 2,3
        if header.acq.savingChannel1
            FCh1 = Fmat(:,:,1:2:T);
            if header.acq.savingChannel2
                FCh2 = Fmat(:,:,2:2:T);
                FCh3 = [];
            elseif header.acq.savingChannel3
                FCh3 = Fmat(:,:,2:2:T);
                FCh2 = [];
            end
        elseif header.acq.savingChannel2
            FCh1 = [];
            FCh2 = Fmat(:,:,1:2:T);
            FCh3 = Fmat(:,:,2:2:T);
        end
        
    else % check which channel was saved: 1 2 or 3
        FCh1 = [];FCh2=[];FCh3 = [];
        if header.acq.savingChannel1
            FCh1 = Fmat(:,:,1:T);
        elseif header.acq.savingChannel2
            FCh2 = Fmat(:,:,1:T);
        elseif header.acq.savingChannel3
            FCh3 = Fmat(:,:,1:T);
        end
    end
else
    FCh1 = 1; FCh2 = []; FCh3 = [];
    if options.useImread
        Fmat = zeros(header.acq.linesPerFrame,header.acq.pixelsPerLine,numFrames,length(options.channel),'uint16'); % calcium time-series
        % check if requested channel was saved
        % and determine correct offset if it was
        options.channel = sort(options.channel(:)');
        saveChIndex = [header.acq.savingChannel1 header.acq.savingChannel2 header.acq.savingChannel3];
        offset = zeros(length(options.channel),1);
        cnt=1;
        for ch=options.channel
            if ~saveChIndex(ch)
                error(['channel ' num2str(ch) ' was not saved']);
            end
            % the offset is the index of
            offset(cnt) = find(find(saveChIndex) == ch);
            cnt = cnt+1;
        end
        
        % load data
        for chind = 1:length(options.channel)
            for i=1:numFrames
                Fmat(:,:,i,chind)=imread(filename,'Index',(i-1)*header.acq.numberOfChannelsSave+offset(chind),...
                    'PixelRegion',{[1 header.acq.linesPerFrame],[1 header.acq.pixelsPerLine]});
            end
            % save channels with appropriate labels
            eval(['FCh' num2str(options.channel(chind)) '=Fmat(:,:,:,chind);']);
        end
    else
        Fmat = zeros(header.acq.linesPerFrame,header.acq.pixelsPerLine,length(Iinfo),'uint16'); % calcium time-series
        TifLink = Tiff(filename,'r');
        for i = 1:length(Iinfo)
            TifLink.setDirectory(i);
            Fmat(:,:,i) = TifLink.read();
        end
        TifLink.close();
        
        for chind = options.channel
            channelIndices = (1:header.acq.numberOfChannelsSave:length(Iinfo)) + (chind-1);
            % save channels with appropriate labels
            eval(['FCh' num2str(chind) '=Fmat(:,:,channelIndices);']);
        end
    end
    
end
end % end loadTIFF
