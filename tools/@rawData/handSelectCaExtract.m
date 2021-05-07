function [y,A,rawobj] = handSelectCaExtract(rawobj,varargin)
% handselect - manually select cells
% Cells are selected from a user-determined image file (default is the time
% average file from a motion corrected movie). After each cell is selected, the results will be saved to a user-selected
% directory (default is set in rootDirectories). Usually there is a secondary
% image the user will want to load to determine which cells to select based
% on properties in the secondary image
%
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 202x

options = struct('fullImagePath',[],'savedir',[],'fileNumber',rawobj.fileNumber,'channel',1,'motionC',false,'useTwitchDetector',false,'useImread',false,'isScanImageFile',true);
options = parseNameValueoptions(options,varargin{:});

if isempty(options.fullImagePath)
    % Data loading (dimensions are part of options)
    % we need movies and images check if this has already been loaded
    if options.motionC
        % we need motion-corrected movies and images check if this has already been loaded
        if rawobj.fileNumber ~= options.fileNumber
            [rawobj] = rawobj.motionCorrect('fileNumber',options.fileNumber,'channel',options.channel,'useImread',options.useImread);
        elseif isempty(rawobj.moviesMC)
            [rawobj] = rawobj.motionCorrect('fileNumber',options.fileNumber,'channel',options.channel,'useImread',options.useImread);
        end
    else
        if rawobj.fileNumber ~= options.fileNumber
            rawobj = rawobj.load('fileNumber',options.fileNumber,'useImread',options.useImread);
            rawobj = rawobj.timeAverage('fileNumber',options.fileNumber);
        end
        if isempty(rawobj.movies)
            rawobj = rawobj.load('fileNumber',options.fileNumber,'useImread',options.useImread);
        end
        if isempty(rawobj.images)
            rawobj = rawobj.timeAverage('fileNumber',options.fileNumber);
        end
    end
    if options.useTwitchDetector
        rawobj = rawobj.timeAverage('fileNumber',options.fileNumber,'useTwitchDetector',options.useTwitchDetector);
    end
    
    if options.motionC
        [d1,d2,d3] = size(rawobj.moviesMC{1}.channel{options.channel}); % size of movies
    else
        [d1,d2,d3] = size(rawobj.movies{1}.channel{options.channel});
    end
    I = rawobj.images.channel{options.channel};
else
    if strcmp(options.fullImagePath(end-3:end),'.tif')
        if options.isScanImageFile
            [FCh1,FCh2,FCh3] = rawobj.loadScanImageTIFF(options.fullImagePath,'useImread',options.useImread);
            eval(['I=' 'FCh' num2str(options.channel)]);
        else
            I = rawobj.loadTIFF(options.fullImagePath,'useImread',options.useImread);
        end
        
    elseif strcmp(options.fullImagePath(end-3:end),'.mat')
        load(options.fullImagePath,'I');
    else
        error('The image to load can only be a .mat or .tif file');
    end
end
figure;imagesc(I,[0 180]);
totalNumCellsGuess = 10; Afull = false(d1*d2,totalNumCellsGuess);

actualTotalNum = 0;
circleCells = true;
while circleCells
    BW=roipoly;
    reply = input('circle another cell [c] / discard current cell [d] / stop [s]','s');
    
    if strcmp(reply,'c') || strcmp(reply,'s')
        actualTotalNum = actualTotalNum + 1;
        Afull(:,actualTotalNum) = BW(:);
        
        if ~isempty(options.savedir)
            save(options.savedir,Afull)
        end
        % if the user wants more than the space we allocated
        if actualTotalNum == totalNumCellsGuess
            Afull = [Afull false(d1*d2,totalNumCellsGuess)];
        end
    end
    if strcmp(reply,'s')
        circleCells = false;
    end
end
Afull = Afull(:,1:actualTotalNum);
A = sparse(Afull);

% ------ this part should go elsewhere since it is related to having the
% movie 
if 0 
if options.motionC
    F=reshape(rawobj.moviesMC{1}.channel{options.channel},d1*d2,d3);
else
    F=reshape(rawobj.movies{1}.channel{options.channel},d1*d2,d3);
end
y = single(F)'*Afull;
y = y./d3;
% ---------------
end
end

