function rate = loadNMFRates(varargin)
%loadNMFRates - load non-negative deconvolved firing rates saved by NMF as
%implemented in EPCaExtractAllPlanes
%
% see also motionCorrectEPCaExtractAllData
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020


options = struct('cellsOfInterest','all','automatedTau',false);
options = parseNameValueoptions(options,varargin{:});

[fid,expCond] = listAnimalsWithImaging;

% which animal indices to loop
if isempty(options.cellsOfInterest) || ischar(options.cellsOfInterest)
    uniqueAnimalIndices = 1 : length(fid);
    ID = getIDFullDataSet('NMF');
    rate = initializePlotModelFitsCells(ID);
else
    uniqueAnimalIndices = unique(options.cellsOfInterest(:,1));
    rate = initializePlotModelFitsCells(options.cellsOfInterest);
end

for indexA = 1:length(uniqueAnimalIndices(:))
    expIndex = uniqueAnimalIndices(indexA);
    roiFilename = getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','catraces','caTraceType','NMF');
    
    % check if the file being loaded was created before or after I stopped
    % running NMF with an automated and fixed tau
    fileInfo = dir(roiFilename);
    if fileInfo.datenum<datenum('31-Dec-2020')
        hasAutoTau = true;
    else
        hasAutoTau = false;
    end
    if hasAutoTau
        if options.automatedTau
            nmfOutput = load(roiFilename,'frate');
            ratesInOneAnimal = nmfOutput.frate;
        else
            nmfOutput = load(roiFilename,'frateGCTauFixed');
            ratesInOneAnimal = nmfOutput.frateGCTauFixed;
        end
    else
        nmfOutput = load(roiFilename,'frate');
        ratesInOneAnimal = nmfOutput.frate;
    end
    
    numPlanes = length(ratesInOneAnimal);
    if isempty(options.cellsOfInterest) || ischar(options.cellsOfInterest)
        uniquePlanes = 1 : numPlanes;
    else
        animalBoolSelectionVector = options.cellsOfInterest(:,1)==expIndex;
        uniquePlanes = unique( options.cellsOfInterest(animalBoolSelectionVector,2) );
    end
    
    for indexB = 1:length(uniquePlanes(:))
        planeIndex = uniquePlanes(indexB);
        numCells = size(ratesInOneAnimal{planeIndex},1);
        
        if isempty(options.cellsOfInterest) || ischar(options.cellsOfInterest)
            cellIndicies = (1 : numCells)';
        else
            animalPlaneBoolSelectionVector = options.cellsOfInterest(:,1)==expIndex & options.cellsOfInterest(:,2)==planeIndex;
            cellIndicies = options.cellsOfInterest(animalPlaneBoolSelectionVector,3);
        end
        
        rate{indexA}{indexB} = ratesInOneAnimal{planeIndex}(cellIndicies,:)';
    end
    clear ratesInOneAnimal nmfOutput
end


end

