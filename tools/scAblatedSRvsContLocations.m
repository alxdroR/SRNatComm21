function  scAblatedSRvsContLocations()
% transform single ablated SR and control cell locations from local
% coordinates to ZBrain coordinates. Then compute the number of nearby
% eye-movement related cells and make plot
 
% transform single ablated SR and control cell locations from local
% coordinates to ZBrain
% coordinates.----------------------------------------------
% Registration: 
% center-of-mass locations within movies  ---->  bridge brain particular to -----> ZBrain
% used to determine where to ablate              that fish 
%
global saveCSV 
% Directories containing data
[~,~,fileDirs] = rootDirectories;
handSelectedFootprintDir = fileDirs.caTimeseries;

% load the Z-Brain scale used to convert pixels to microns ------------------------
zBrainFile = fileDirs.ZBrain;
zBrainMeta = rawData.grabMetaData(zBrainFile,'isImageJFile',true,'checkIfScanImageFile',false);
ZBrainMic2Pix = [zBrainMeta.XMicPerPix,zBrainMeta.YMicPerPix,zBrainMeta.ZMicPerPlane];
% list of animals
[fid,expcond,expDates,animalNumbers] = listAnimalsWithImaging('singleCellAblations',true);
ZBCMu =[]; ZBCPix = []; expGroup = cell(length(fid),1); ZBCGroup = [];
for expIndex = 1:length(fid)
    % load metadata giving information about this particular experiment 
    ablationResults = singleCellAblationKey(expDates{expIndex},'animalNumber',animalNumbers{expIndex});
    % determine if this fish was a control or not
    if (ablationResults.nSRLHit+ablationResults.nSRRHit)>=4
        expGroup{expIndex} = 'SR';
    elseif ablationResults.nNotEye > 4
        expGroup{expIndex} = 'C';
    else
        expGroup{expIndex} = NaN;
    end
    if ~isnan(expGroup{expIndex})
        % load the bridge brain scale used to convert pixels to microns (this is constant across all planes and cells in this animal)------------------------
        bridgeBrainFile = [fileDirs.singleCell.ablDamage getFilenames(fid{expIndex},'expcond','avgDamage.tif','fileType','constructHeader')];
        bridgeBrainMeta = rawData.grabMetaData(bridgeBrainFile,'isImageJFile',true,'checkIfScanImageFile',false);
        bridgeBrainMic2Pix = [bridgeBrainMeta.XMicPerPix,bridgeBrainMeta.YMicPerPix,bridgeBrainMeta.ZMicPerPlane];
        
        % load bridge brain to z-brain landmarks for this animal
        % -------------------
        BB2ZLandmarkFile = getFilenames(fid{expIndex},'expcond','avgDamage','fileType','regLandmarks','singleCellAblations',true);
        coorPointsBB2Z = dlmread(BB2ZLandmarkFile,',');
        
        % begin loading scale used to convert pixels to microns for the plane
        % containing this cell--------------------------------
        if ablationResults.BImagesFormDVSequence
            % the images in these experiments were taken as a dorsal-ventral
            % stack, the tag for the file before ablations is always B and the entire movie was registered to the z-brain
            %avgImgFilename = ['/Users/alexramirez/Dropbox/Science/research/onMyPlate/zfishEyeMapping/data/singleCellAblationsPartialBackup/proc/videoAverages/' 'f' num2str(fid{expIndex}) expCondPerCell{cellIndex} '_avg'];
            %avgImgFilename = getFilenames(fid{expIndex},'expcond','B','fileType','averageImages');
            avgImgFilename = getFilenames(fid{expIndex},'expcond','B','fileType','averageImages');
            fishBeforeMovieMeta = rawData.grabMetaData([avgImgFilename '.tif'],'isImageJFile',true,'checkIfScanImageFile',false);
            localPlaneMic2Pix = [fishBeforeMovieMeta.XMicPerPix,fishBeforeMovieMeta.YMicPerPix,fishBeforeMovieMeta.ZMicPerPlane];
        end
        
        % load landmarks (if possible) ---------
        if ablationResults.BImagesFormDVSequence
            fish2BBLandmarkFile = getFilenames(fid{expIndex},'expcond','B','fileType','regLandmarks','singleCellAblations',true);
            coorPoints = dlmread(fish2BBLandmarkFile,',');
            lmMovingImage = coorPoints(:,1:3);
            lmTargetImage = coorPoints(:,4:6); % bridge brain
        end
        
        % load coordinates of ablated cells--------------------
        if strcmp(expGroup{expIndex},'C')
            % use metadata to create  file locations of handselected footprints around ablations for each plane (control fish only)
            LC = [];expCondPerCell = [];
            numberOfDuringAblFiles = length(ablationResults.duringAblReg); % 2 conventions used when saving data. This number might equal number of ablation planes (each sequence of ablation images in a unique .tif file), but could also be 1 file with concatenated planes
            for drAblIndex = 1 : numberOfDuringAblFiles
                numberOfTargetImgs = length(ablationResults.duringAblReg(drAblIndex).targetImgCond); % this is 1 if each ablation plane is in a separate file or equals number of planes concatenatd planes into single ablation file
                for targInd = 1 : numberOfTargetImgs
                    targetImgIndex = ablationResults.duringAblReg(drAblIndex).targetImgInds(targInd);
                    footprintFile = [handSelectedFootprintDir getFilenames(fid{expIndex},'expcond',[ablationResults.duringAblReg(drAblIndex).targetImgCond{targInd} num2str(targetImgIndex) '_traces_handSelectedFootprints.mat'],'fileType','constructHeader')];
                    % load coordinates for this fish
                    if exist(footprintFile,'File')==2
                        load(footprintFile)
                        LC = [LC;[localCoordinates repmat(targetImgIndex,size(localCoordinates,1),1)]];
                        expCondPerCell = [expCondPerCell;repmat({ablationResults.duringAblReg(drAblIndex).targetImgCond{targInd}},size(localCoordinates,1),1)];
                    end
                end
            end
            localCoordinates = LC;
        elseif strcmp(expGroup{expIndex},'SR')
            % metadata contains the coordinates of ablated SR. extract this
            % directly 
            localCoordinates = [cellfun(@(x) x.XYPosition(1),ablationResults.SRHitIDs),cellfun(@(x) x.XYPosition(2),ablationResults.SRHitIDs),cellfun(@(x) x.ID(1),ablationResults.SRHitIDs)];
            expCondPerCell = cellfun(@(x) x.expCond,ablationResults.SRHitIDs,'Uniform',false);
        end
       
        BBCMu = []; BBCPix = [];
        numberOfCells = size(localCoordinates,1);
        if numberOfCells == 0
            keyboard
        end
        for cellIndex = 1:numberOfCells
            planeIndex = localCoordinates(cellIndex,3);
            
            % if necessary finish loading scale used to convert pixels to microns for the plane containing this cell.
            % --------------------------------------
            if ~ablationResults.BImagesFormDVSequence
                % the images in these experiments were not taken in any particular order. z-information is not important.
                % furthermore, the x-y scale could change depending on the file so we wait to extract information after loading until we specify the
                % plane being analyzed
                avgImgFilename = getFilenames(fid{expIndex},'expcond',expCondPerCell{cellIndex},'fileType','averageImages');
              % fprintf('%s\n',avgImgFilename);
                load(avgImgFilename,'expMetaData');
                %save([avgImgFilename '.mat'],'expMetaData');
                [~,~,xymicperpix] = rawData.mic2pix(1,expMetaData.scanParam{planeIndex});
                localPlaneMic2Pix = [xymicperpix,xymicperpix];
            end
            
            % if necessary finish loading the landmarks for the plane containing this cell
            % -----------------------------------------
            if ~ablationResults.BImagesFormDVSequence
                fish2BBLandmarkFile = getFilenames(fid{expIndex},'expcond',[expCondPerCell{cellIndex} num2str(planeIndex)],'fileType','regLandmarks','singleCellAblations',true);
                coorPoints = dlmread(fish2BBLandmarkFile,',');
                lmMovingImage = coorPoints(:,1:2);
                lmTargetImage = coorPoints(:,4:6); % bridge brain
            end
            
            % load location of this cell in pixels
            if ablationResults.BImagesFormDVSequence
                U = localCoordinates(cellIndex,:);
            else
                U = localCoordinates(cellIndex,1:2);
            end
            
            % transform coordinates
            Umu = (U-0.5).*repmat(localPlaneMic2Pix,size(U,1),1); % convert to microns
            XBBmu = affineTransformBigWarp(Umu,lmMovingImage,lmTargetImage,'useMatrixMult',true,'onlyComputeTransform',false); % transform
            nPoints = size(XBBmu,1);
            XBB = XBBmu.*(repmat(1./bridgeBrainMic2Pix,nPoints,1))+1; % convert bridge brain coordinates to pixels
            BBCMu = [BBCMu;XBBmu];
            BBCPix = [BBCPix;XBB];
        end
        
        % now transform all the bridge-brain points to the z-brain----
        ZBCMuThisFish = affineTransformBigWarp(BBCMu,coorPointsBB2Z(:,1:3),coorPointsBB2Z(:,4:6));
        ZBCMu = [ZBCMu;ZBCMuThisFish];
        nPoints = size(BBCMu,1);
        ZBCPix = [ZBCPix;ZBCMuThisFish.*(repmat(1./ZBrainMic2Pix,nPoints,1))]; % convert coordinates to pixels
        
        % create a tag to segregate points from control and SR animals
        if strcmp(expGroup{expIndex},'SR')
            ZBCGroup = [ZBCGroup;true(nPoints,1)];
        elseif strcmp(expGroup{expIndex},'C')
            ZBCGroup = [ZBCGroup;false(nPoints,1)];
        end
    end
end
% -------------------------------------------------------------------------------------------------
% plot zBrain coordinates to view results in a different way
ZBCGroup = ZBCGroup==1;
%figure;plot3(ZBCMu(ZBCGroup,1),ZBCMu(ZBCGroup,2),ZBCMu(ZBCGroup,3),'.'); hold on;plot3(ZBCMu(~ZBCGroup,1),ZBCMu(~ZBCGroup,2),ZBCMu(~ZBCGroup,3),'.');xlabel('rc');ylabel('lr');zlabel('dv')

% Count number of nearby eye movement cells
% -------------------------------------------------------------------------------------------------------

% load eye-movement related cell coordinates 
finalActiveCellCriteria = createFootprintSelector('cutCellsWLowSignal',true,'staDFFFilename','calcSTA2NMFOutput','lowSigPercentile',0.01);
STACriteria = createEyeMovementSelector('filename','calcSTA2NMFOutput','selectionCriteria',finalActiveCellCriteria);
[sigLeft,sigRight,Hcc,uniqueIDsFromCOI] = createSRCellSelector('filename','calcAnticCorrAllCellsOutput','selectionCriteria',STACriteria);
[~,CoordMu] = registeredCellLocationsBigWarp('register2Zbrain',true);
eyeMoveCoordinates = CoordMu(STACriteria & ~(sigLeft | sigRight),:);
nEMNonSRCells = sum(STACriteria & ~(sigLeft | sigRight));

rV = 10:5:50; % distance around ablated cell in microns
numberAblCells = size(ZBCMu,1);
numberEMNeighbors = NaN(numberAblCells,1);
nPoints = size(eyeMoveCoordinates,1);
for distIndex = 1:length(rV)
    r = rV(distIndex);
    for ind = 1 : numberAblCells
        currentPoint = ZBCMu(ind,:);
        % L2 distance between ablated cell at `currentPoint` and
        % eye-movement coordinates 
        currentDistances = sqrt(sum((eyeMoveCoordinates- repmat(currentPoint,nPoints,1)).^2,2));
        % count fraction within circle
        numberEMNeighbors(ind,distIndex) = sum(currentDistances<=r)./nEMNonSRCells;
    end
end
numberEMNeighborsSR = numberEMNeighbors(ZBCGroup==1,:);
numberEMNeighborsC  = numberEMNeighbors(ZBCGroup~=1,:);

% correct for difference in number of samples 
numSR = sum(ZBCGroup==1);
numC = sum(ZBCGroup~=1);
numC2Plot = numSR;
rng('default');
numberEMNeighborsC2Plot = numberEMNeighborsC(randperm(numC,numC2Plot),:);
% -------------------------------------------------------------------------------------------------------


% plot results -------------------------------------------------------------------------------------------------------
figure;
errorbar(rV,mean(numberEMNeighborsSR),std(numberEMNeighborsSR)/sqrt(numSR)); hold on;
errorbar(rV,mean(numberEMNeighborsC2Plot),std(numberEMNeighborsC2Plot)/sqrt(numC2Plot));
xlim([9.5 50.5]);
xlabel('r (microns)');ylabel({'fraction of non-SR, eye-movement cells' 'within r of ablated cells'});
legend('SR','Control','Location','northwest');box off; legend boxoff
setFontProperties(gca)
set(gcf,'PaperPosition',[0 0 2.5 2.5])
printAndSave(['scAblLocAnalysis'])

nSR = size(numberEMNeighborsSR,1);
nC = size(numberEMNeighborsC2Plot,1);
fprintf('SR: n=%d cells examined over %d fish\n',nSR,sum(cellfun(@(x) strcmp('SR',x),expGroup)));
fprintf('Control: %d samples examined over %d fish \n',nC,sum(cellfun(@(x) strcmp('C',x),expGroup)));

if saveCSV
    [~,~,fileDirs] = rootDirectories;
    fileID = fopen([fileDirs.scDataCSV 'Supplementary Figure 9.csv'],'a');
    fprintf(fileID,'Fraction of non-SR eye-movement cells within r microns of ablated cells\n');
    fprintf(fileID,'\n\nAblated SR Cells\n');
    fprintf(fileID,'r');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 9.csv'],rV,'delimiter',',','-append','coffset',1);
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 9.csv'],numberEMNeighborsSR,'delimiter',',','-append','coffset',1);
    
    fprintf(fileID,'\n\nAblated Control Cells\n');
    fprintf(fileID,'r');
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 9.csv'],rV,'delimiter',',','-append','coffset',1);
    dlmwrite([fileDirs.scDataCSV 'Supplementary Figure 9.csv'],numberEMNeighborsC2Plot,'delimiter',',','-append','coffset',1);
    fclose(fileID);
end
end

