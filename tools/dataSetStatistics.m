classdef dataSetStatistics
    %dataSetStatistics  - prints dataset statistics printed in the text
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        numNMFCellsInHB
        numNMFCellsWithSTA
        numNMFCellsLowPeakSTA
        lowLevelDFF
        numMorpOpenCellsInHB
        numPlanesPerAnimal
        numEyeMovementCells
        numEyeMUseableActvCells
        typicalNumPerHindBrain
    end
    
    methods
        function obj = dataSetStatistics(varargin)
            options = struct('numNMFCellsInHB',NaN,'numNMFCellsWithSTA',NaN,'numNMFCellsLowPeakSTA',NaN,'lowLevelDFF',NaN,...
                'numMorpOpenCellsInHB',NaN,'numPlanesPerAnimal',NaN,...
                'numEyeMovementCells',NaN,'numEyeMUseableActvCells',NaN,...
                'cutCellsWLowSignal',true,'staDFFFilename','calcSTA2NMFOutput','lowSigPercentile',0.01,'eyeMoveFilename','calcSTA2NMFOutput');
            options = parseNameValueoptions(options,varargin{:});
            
            % load any missing properties that are not optional
            if isnan(options.numNMFCellsInHB) ||  isnan(options.numNMFCellsWithSTA) || isnan(options.numEyeMUseableActvCells)
                if options.cutCellsWLowSignal
                    [finalActiveCellCriteria,inMBCriteria,~,maxDFFCriteria,cantComputeSTA,lowLevelDFF] = createFootprintSelector('cutCellsWLowSignal',options.cutCellsWLowSignal,...
                        'staDFFFilename',options.staDFFFilename,'lowSigPercentile',options.lowSigPercentile);
                    options.numNMFCellsLowPeakSTA = sum(~cantComputeSTA & ~maxDFFCriteria);
                    options.lowLevelDFF = lowLevelDFF;
                    options.numNMFCellsWithSTA = sum(~inMBCriteria & ~cantComputeSTA);
                else
                    [finalActiveCellCriteria,inMBCriteria] = createFootprintSelector('cutCellsWLowSignal',options.cutCellsWLowSignal,'staDFFFilename',options.staDFFFilename);
                end
                options.numNMFCellsInHB = sum(~inMBCriteria);
                options.numEyeMUseableActvCells = sum(finalActiveCellCriteria); % equivalent to sum(~inMBCriteria & ~cantComputeSTA & maxDFFCriteria);
                if isnan(options.numEyeMovementCells)
                    % we need finalActiveCellCriteria so no point in loading this twice
                    STACriteria = createEyeMovementSelector('filename',options.eyeMoveFilename,'selectionCriteria',finalActiveCellCriteria);
                    options.numEyeMovementCells = sum(STACriteria);
                end
            end
            
            if isnan(options.numMorpOpenCellsInHB)
                CoordinatesMO = registeredCellLocationsBigWarp('register2Zbrain',true,'caExtractionMethod','MO');
                inMBMO = removeCellsRegistered2MB(CoordinatesMO);
                options.numMorpOpenCellsInHB = sum(~inMBMO);
            end
            
            if isnan(options.numPlanesPerAnimal)
                [~,planesV] = totalNumberCells('NMF');
                options.numPlanesPerAnimal = planesV;
            end
            if isnan(options.numEyeMovementCells)
                finalActiveCellCriteria = createFootprintSelector('cutCellsWLowSignal',options.cutCellsWLowSignal,...
                    'staDFFFilename',options.staDFFFilename,'lowSigPercentile',options.lowSigPercentile);
                STACriteria = createEyeMovementSelector('filename',options.eyeMoveFilename,'selectionCriteria',finalActiveCellCriteria);
                options.numEyeMovementCells = sum(STACriteria);
            end
            
            
            obj.numNMFCellsInHB = options.numNMFCellsInHB;
            obj.numNMFCellsWithSTA = options.numNMFCellsWithSTA;
            if ~isnan(options.numNMFCellsLowPeakSTA)
                obj.numNMFCellsLowPeakSTA = options.numNMFCellsLowPeakSTA;
                obj.lowLevelDFF = options.lowLevelDFF;
            end
            obj.numMorpOpenCellsInHB = options.numMorpOpenCellsInHB;
            obj.numPlanesPerAnimal = options.numPlanesPerAnimal;
            obj.numEyeMovementCells = options.numEyeMovementCells;
            obj.numEyeMUseableActvCells = options.numEyeMUseableActvCells;
            obj.typicalNumPerHindBrain = 40000;
        end
        
        function reportPage5(obj)
            obj.reportNumPlanes;
            obj.reportTotalNumCells;
            obj.reportExpectedNumCell3Brains;
            obj.reportNumActive;
            obj.reportNumActiveEyeMovement;
        end
        
        function reportNumPlanes(obj)
            numFish = length(obj.numPlanesPerAnimal);
            minNumPlanesPerFish = min(obj.numPlanesPerAnimal);
            maxNumPlanesPerFish = max(obj.numPlanesPerAnimal);
            
            fprintf('\nIn each fish (n=%d), we imaged a portion of the hindbrain using a stack of %d-%d horizontal planes.\n',numFish,minNumPlanesPerFish,maxNumPlanesPerFish)
        end
        
        function reportTotalNumCells(obj)
            fprintf('\n\nWe measured %d cells from all planes and fish in our data set.\n',obj.numMorpOpenCellsInHB)
        end
        
        function reportExpectedNumCell3Brains(obj)
            fprintf('\n\nThis number is larger than the %d neurons expected from sampling 3 complete hindbrains \n',obj.typicalNumPerHindBrain*3)
        end
        
        function reportNumActive(obj)
            percentActive = 100*obj.numNMFCellsInHB/obj.numMorpOpenCellsInHB;
            fprintf('\n\nThe NMF algorithm identified approximately a quarter (%0.3f percent) of hindbrain neurons (%d ROIs) as spontaneously active.\n',percentActive,obj.numNMFCellsInHB)
        end
        
        function reportNumActiveEyeMovement(obj)
            percentEyeRelated = 100*obj.numEyeMovementCells/obj.numEyeMUseableActvCells;
            fprintf('\n\n%0.3f percent (n=%d) of the spontaneously active hindbrain neurons had average activity related to eye movements.\n',percentEyeRelated,obj.numEyeMovementCells)
        end
        function reportMethodsSTACalc(obj)
            fprintf('Of the %d cells that were identified as active by NMF, %d cells passed our criteria for computing the saccade-triggered average.\n',...
                obj.numNMFCellsInHB,obj.numNMFCellsWithSTA)
            fprintf('Based on visual inspection of activity, we removed cells whose activity near saccade\nwas in the lowest %0.3f percent (%d total) of peak absolute\nsaccade-triggered average activity (peak absolute levels less than %0.3f percent dF/F) leaving %d cells for eye-movement analysis\n',...
                100*obj.numNMFCellsLowPeakSTA/obj.numNMFCellsWithSTA,obj.numNMFCellsLowPeakSTA,obj.lowLevelDFF*100,obj.numEyeMUseableActvCells);
        end
        function reportSelectionOfCellsRelated2EyeMovements(obj)
            fprintf('\n\n We set p to 0.01 and set the number of comparisons to %d*2=%d,\n which was the total number of ROIs found by the NMF algorithm\n',...
                obj.numEyeMUseableActvCells,2* obj.numEyeMUseableActvCells)
            fprintf('We rejected the null hypothesis for %d cells\n',obj.numEyeMovementCells);
        end
        function reportPCAMatrixSize(obj)
            fprintf('\n analyzed by PCA that had %d samples ... %d cells times two directions\n',2*obj.numEyeMovementCells,obj.numEyeMovementCells)
        end
        function reportPercentOfHindbrainDedicated2EyeM(obj)
            % probability of being active * probability of being eye
            % movement related given that cell is active
            percentActive = obj.numNMFCellsInHB/obj.numMorpOpenCellsInHB;
            percentEyeRelated = obj.numEyeMovementCells/obj.numEyeMUseableActvCells;
            percentActiveAndEyeRelated = 100*percentActive*percentEyeRelated;
            fprintf('\n\nIn summary, we found that about %0.3f percent of hindbrain neurons in larval zebrafish had\n responses associated with spontaneous saccades and fixations\n',percentActiveAndEyeRelated)
        end
    end
end

