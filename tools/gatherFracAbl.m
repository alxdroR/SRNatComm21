function fracAblated = gatherFracAbl(varargin)
options = struct('constantRadius',true,'radius',15,'cylLength',20,...
    'weightRCAxis',false,'nSampleMap',[],'useSCControls',false,...
    'sigLeft',[],'sigRight',[],'STACriteria',[],'Coordinates',[],'fidArray2Use',[],'expCond',[]);
options = parseNameValueoptions(options,varargin{:});

%----------- load population-related data and statistics
% animals with ablations
if isempty(options.fidArray2Use) || isempty(options.expCond)
    [fidArray2Use,expCond] = listAnimalsWithImaging('coarseAblationRegistered',true);
    fidArray2Use = fidArray2Use(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
    expCond = expCond(cellfun(@(x) strcmp(x,'TBi') | strcmp(x,'C'),expCond));
else
    fidArray2Use = options.fidArray2Use;
    expCond = options.expCond;
end
nAll = length(fidArray2Use); % all the animals we will check

% total number of eye-movement related cells, population-related indices of
% anticipatory, non-anticipatory labels
if isempty(options.sigLeft) || isempty(options.sigRight) || isempty(options.STACriteria)
    loadAnticipatorySelectionCriteria;
else
    sigLeft = options.sigLeft;
    sigRight = options.sigRight;
    STACriteria = options.STACriteria;
end
anticLabel = sigLeft|sigRight;
nonAnticLabel = ~sigLeft & ~sigRight & STACriteria;

if isempty(options.Coordinates)
    Coordinates = registeredCellLocationsBigWarp('register2Zbrain',false);
else
    Coordinates = options.Coordinates;
end

if options.weightRCAxis
    wn2 = round(Coordinates(:,1));
    wn2(wn2<1)=1;wn2(wn2>length(weightNorm))=length(weightNorm);
    wAll = weightNorm(wn2);
end

if ~options.weightRCAxis
    NtotalAntic = sum(anticLabel); % total number of anticipatory cells
    NtotalNonAntic =  sum(nonAnticLabel); % total number of non-anticipatory cells
else
    NtotalAntic = sum(anticLabel.*wAll'); % total number of anticipatory cells
    NtotalNonAntic =  sum(nonAnticLabel.*wAll'); % total number of non-anticipatory cells
end

if options.constantRadius
    % a constant radius option
    %rawobj = rawData('fishid','f14','fileNumber',17);
    %largeScale = rawobj.micron2pixel(options.radius);
    if options.radius == 15
        largeScale = 42;
    end
    radius = [largeScale,largeScale];
end

fracAblated = struct('Ant',nan(nAll,1),'nonAnt',nan(nAll,1),'rccenter',nan(nAll,1));
% since planes are spaced apart by 3 microns in reference brain.
% 60 micron size damage equals 60/3=20 planes
l = options.cylLength;

for expIndex = 1  : nAll
    % Compute Fraction of Cells Ablated Given Ablation Location and
    % Size
    
    % ablation location and size info
    abobj = ablationViewer('fishid',fidArray2Use{expIndex});
    if ~isempty(abobj.offset)
        [~,~,regAblLocation] = abobj.medianRegisteredRClocation;
        
        if ~options.constantRadius
            radius = abobj.radius;
        end
        
        %l = 2*median(radius);
        numCellsL = findNumberCellsInCylnder(Coordinates,...
            struct('center',regAblLocation(1,:),'radius',radius(1),'length',l),...
            'selector',[anticLabel nonAnticLabel],...
            'weightRCAxis',options.weightRCAxis,'nSampleMap',options.nSampleMap);
        
        numCellsR = findNumberCellsInCylnder(Coordinates,...
            struct('center',regAblLocation(2,:),'radius',radius(2),'length',l),...
            'selector',[anticLabel nonAnticLabel],...
            'weightRCAxis',options.weightRCAxis,'nSampleMap',options.nSampleMap);
        
        
        nAntAblated = numCellsL(1) + numCellsR(1);
        nnonAntAblated = numCellsL(2) + numCellsR(2);
        
        fracAblated.Ant(expIndex) = nAntAblated/NtotalAntic;
        fracAblated.nonAnt(expIndex) = nnonAntAblated/NtotalNonAntic;
        fracAblated.rccenter(expIndex) = median(regAblLocation(:,1),1);
    else
        if strcmp(expCond{expIndex},'C') && options.useSCControls
            fracAblated.Ant(expIndex) = 0;
            fracAblated.nonAnt(expIndex) = 0;
            fracAblated.rccenter(expIndex) = 1250;
        else
            % unilateral ablation
            fracAblated.Ant(expIndex) = NaN;
            fracAblated.nonAnt(expIndex) = NaN;
            fracAblated.rccenter(expIndex) = NaN;
        end
    end
end
end

