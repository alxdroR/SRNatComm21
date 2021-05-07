function [A,I] = handselect(varargin)
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

options = struct('fullImagePath',[],'channel',1,'saveName',[],'image',[],'useImread',false,'isScanImageFile',true,'secondaryImg',[]);
options = parseNameValueoptions(options,varargin{:});

% load image or transfer from options
if ~isempty(options.image)
    I = options.image;
elseif ~isempty(options.fullImagePath)
    if strcmp(options.fullImagePath(end-3:end),'.tif')
        if options.isScanImageFile
            [FCh1,FCh2,FCh3] = rawData.loadScanImageTIFF(options.fullImagePath,'useImread',options.useImread);
            eval(['I=' 'FCh' num2str(options.channel) ';']);
        else
            I = rawData.loadTIFF(options.fullImagePath,'useImread',options.useImread);
        end
        
    elseif strcmp(options.fullImagePath(end-3:end),'.mat')
        load(options.fullImagePath,'I');
    else
        error('The image to load can only be a .mat or .tif file');
    end
end

% load secondary image from options or from filename
if ~isempty(options.secondaryImg)
    if ischar(options.secondaryImg)
        if options.isScanImageFile
            [FCh1,FCh2,FCh3] = rawData.loadScanImageTIFF(options.secondaryImg,'useImread',options.useImread);
            eval(['I2=' 'FCh' num2str(options.channel)]);
        else
            I = rawData.loadTIFF(options.secondaryImg,'useImread',options.useImread);
        end
    else
        I2 = options.secondaryImg;
    end
else
    I2 = [];
end

[d1,d2] = size(I);
figure;
if ~isempty(I2)
    subplot(121); imagesc(I2);
    subplot(122); imagesc(I,[0 600]);
else
    imagesc(I,[0 600]);
end
hold on;

totalNumCellsGuess = 10; Afull = false(d1*d2,totalNumCellsGuess);
localCoordinates = zeros(totalNumCellsGuess,2);
actualTotalNum = 0;
if ~isempty(options.saveName)
    if exist(options.saveName,'file')==2
        load(options.saveName);
        actualTotalNum = size(localCoordinates,1); 
        for existIndex = 1 : actualTotalNum
            [nzRow,nzCol]=find(reshape(Afull(:,existIndex),d1,d2));
            chInd=convhull([nzRow,nzCol]);
            outline=[nzCol(chInd),nzRow(chInd)];
            plot(outline(:,1),outline(:,2),'r')
            text(localCoordinates(existIndex,1),localCoordinates(existIndex,2),num2str(existIndex),'color','r');
        end
        Afull = [Afull false(d1*d2,totalNumCellsGuess)];
        localCoordinates = [localCoordinates;zeros(totalNumCellsGuess,2)];
    end
end

circleCells = true;
while circleCells
    [BW,xi,yi]=roipoly;
    plot(xi,yi,'r');
    text(mean(xi),mean(yi),num2str(actualTotalNum+1),'color','r');
    reply = input('circle another cell [c] / discard current cell [d] / stop [s]\n','s');
    
    if strcmp(reply,'c') || strcmp(reply,'s')
        actualTotalNum = actualTotalNum + 1;
        Afull(:,actualTotalNum) = BW(:);
        localCoordinates(actualTotalNum,:) = [mean(xi),mean(yi)];
        if ~isempty(options.saveName)
            save(options.saveName,'Afull','localCoordinates')
        end
        % if the user wants more than the space we allocated
        if actualTotalNum == totalNumCellsGuess
            Afull = [Afull false(d1*d2,totalNumCellsGuess)];
            localCoordinates = [localCoordinates;zeros(totalNumCellsGuess,2)];
        end
    end
    if strcmp(reply,'s')
        circleCells = false;
    end
end
Afull = Afull(:,1:actualTotalNum);
localCoordinates = localCoordinates(1:actualTotalNum,:);
A = sparse(Afull);
if ~isempty(options.saveName)
    save(options.saveName,'Afull','localCoordinates')
end
end

