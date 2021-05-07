classdef ablationViewer
    
    properties
        fishID % see constructor for identification information
        radius
        offset
        damageMask
        nImages
        images
        refSize
        transformedZ
        regMethod
        regTransform
        scanImageHeader
        expMetaData
    end
    properties(Constant)
        expcond = 'damage'
    end
    methods
        function abobj = ablationViewer(varargin)
            options = struct('fishid',[],'refsize',[],'loadImages',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % -- load the data if this is required
            if isempty(options.fishid)
                error('need to specify a fish ID number');
            end
            % set ID property
            abobj.fishID = options.fishid;
            % load meta data if it exist
            expdataFile = getFilenames(abobj.fishID,'expcond',abobj.expcond,'fileType','expMetaData');
            if exist(expdataFile,'file')==2
                load(expdataFile,'expMetaData')
            else
                expMetaData = makeMetaDataStruct;
            end
            abobj.expMetaData = expMetaData;
            
            % load damage coordinates
            damageOutFname = getFilenames(abobj.fishID(2:end),'expcond',['-' abobj.expcond 'Outline'],'fileType','damageOutline');
            if exist(damageOutFname,'file')==2
                load(damageOutFname,'damageRadius','damageOffset','damageMask');
                % set properties
                abobj.radius = damageRadius;
                abobj.offset = damageOffset;
                abobj.damageMask = damageMask;
            end
            
            if options.loadImages || strcmp(abobj.fishID,'fK') || strcmp(abobj.fishID,'fI')
                if strcmp(abobj.fishID,'fK') || strcmp(abobj.fishID,'fI')
                    abobj.nImages = 8;
                else
                sFilePath = getFilenames(abobj.fishID,'expcond',['_' abobj.expcond],'fileType','medianImages');
                if exist([sFilePath '.mat'],'file')==2
                    imH = load(sFilePath);
                    abobj.images = imH.images;
                    %                 if 0
                    %                 % sometimes missing channels are set to zero
                    %                 % when they should just be empty
                    %                 for channelNumber = 1 :3
                    %                     if ~isempty(abobj.images.channel{channelNumber})
                    %                         isMissing = var(var(abobj.images.channel{channelNumber}(:,:,1))) == 0;
                    %                         if isMissing
                    %                             abobj.images.channel{channelNumber} = [];
                    %                         end
                    %                     end
                    %                 end
                    %                 end
                    abobj.nImages = size(abobj.images.channel{1},3);
                else
                    abobj.images.channel = cell(1,3);
                end
                end
            else
                abobj.nImages = size(abobj.damageMask,3);
            end
            
           if isempty(options.refsize)
                [~,~,fileDirs] = rootDirectories;
                refBrainFilename = fileDirs.twoPBridgeBrain;
                refBrainHeader = imfinfo(refBrainFilename);
                Nref = length(refBrainHeader);
                Href = refBrainHeader(1).Height;
                Wref = refBrainHeader(1).Width;
                abobj.refSize = [Href,Wref,Nref];
            else
                abobj.refSize = options.refsize;
            end
            abobj=abobj.getRegistrationTransform;
        end
        function registerDamageImages(abobj,varargin)
            options = struct('saveon',true,'fixedPoints',true,'fixedData',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            fixedPoints = [];
            movingPoints = [];
            if options.fixedPoints
                % check and load fixed points if they exist
                [~,transformFilename] = registrationTransformFilename(abobj.fishID,1);
                if exist(transformFilename,'file')==2
                    load(transformFilename);
                end
            end
            
            [movingPoints,fixedPoints]=cpselect3D(abobj.images.channel{1},'fixedPoints',fixedPoints,'movingPoints',movingPoints,'fixedData',options.fixedData);
            
            if options.saveon
                % get file name
                [~,transformFilename] = registrationTransformFilename(abobj.fishID,1);
                shouldSave = overwriteCheck(transformFilename);
                if shouldSave
                    save(transformFilename,'movingPoints','fixedPoints');
                end
            end
        end
        function abobj=makeDamageOutline(abobj,varargin)
            options = struct('saveon',true);
            options = parseNameValueoptions(options,varargin{:});
            
            [Hlocal,Wlocal,Nlocal]=size(abobj.images.channel{1});
            
            % adjust image
            Ilocal = cell(3,1);
            %  Iadjusted = zeros(Hlocal,Wlocal,Nlocal,'uint16');
            for ch=1:3
                Ilocal{ch} = zeros(Hlocal,Wlocal,Nlocal,'uint16');
                for k=1:Nlocal
                    Ilocal{ch}(:,:,k) = imadjust(uint16(abobj.images.channel{ch}(:,:,k)));
                    % abobj.images.channel{ch}(:,:,k) = Iadjusted(:,:,k);
                end
            end
            
            % plot the figure
            fh=figure;
            %   mh=montage(reshape(abobj.images.channel{1},[Hlocal,Wlocal,1,Nlocal]));
            mh=montage(reshape(Ilocal{1},[Hlocal,Wlocal,1,Nlocal]));
            continueResponse = 'y';
            damageOffset = [];
            damageRadius = [];
            damageMask = false(Hlocal,Wlocal,Nlocal);
            
            while strcmpi(continueResponse,'y')
                disp('take this time to zoom in to a location if needed.  type dbcont then press return to bring up the ellipse selection object')
                keyboard
                % ask user to add an ellipse
                eobj = imellipse;
                wait(eobj);
                epos = getPosition(eobj);
                
                % determine the x,y,z value of the ellipse position
                xdataMontage = get(mh,'XData');
                
                % ellipse z position
                numColumns = xdataMontage(2)/Wlocal;
                rowSelected = ceil(epos(2)/Hlocal);
                columnSelected = ceil(epos(1)/Wlocal);
                z = (rowSelected-1)*numColumns+columnSelected;
                
                
                % ellipse position minium x,y translated from montage coordinates
                minx = mod(epos(1),Wlocal);
                if minx==0
                    minx = Hlocal;
                end
                miny = mod(epos(2),Hlocal);
                if miny == 0
                    miny = Wlocal;
                end
                
                damageOffset = [damageOffset;[minx+epos(3)/2,miny+epos(4)/2,z]];
                damageRadius = [damageRadius;epos(3)/2];
                
                % create large mask
                mask = createMask(eobj);
                % save cropped mask
                damageMask(:,:,z) = damageMask(:,:,z)+mask(Hlocal*(rowSelected-1)+1:Hlocal*rowSelected,Wlocal*(columnSelected-1)+1:Wlocal*columnSelected);
                continueResponse = input('more points? Y/N:\n','s');
            end
            % set properties
            abobj.radius = damageRadius;
            abobj.offset = damageOffset;
            abobj.damageMask = damageMask;
            
            if options.saveon
                %  damageOutFname = damageOutlineFilename(abobj.fishID);
                damageOutFname = getFilenames(abobj.fishID,'expcond','damage','fileType','damageOutline');
                shouldSave = overwriteCheck(damageOutFname);
                if shouldSave
                    save(damageOutFname,'damageOffset','damageRadius','damageMask');
                end
            end
        end
        function viewMedianRegisteredRCLocation(abobj,varargin)
            options = struct('bridgeBrainImage',[],'methodUsedInPaper',false,'viewMedianLoc',false);
            options = parseNameValueoptions(options,varargin{:});
            
            if isempty(options.bridgeBrainImage)
                [~,~,fileDirs] = rootDirectories;
                bbI = rawData.loadTIFF(fileDirs.twoPBridgeBrain,'useImread',false);
            else
                bbI = options.bridgeBrainImage;
            end
            
            U = abobj.offset;
            if options.methodUsedInPaper
                [medianRC,~,XBB]=abobj.medianRegisteredRClocation;
                if options.viewMedianLoc
                    XBB(:,1) = medianRC;
                end
            else
                fish2BridgeLandmarksFile = getFilenames(abobj.fishID(2:end),'expcond',['-' abobj.expcond 'CP.csv'],'fileType','damageCoordPoints');
                coorPoints = dlmread(fish2BridgeLandmarksFile,',');
                XBB = affineTransformBigWarp(U,coorPoints(:,1:3),coorPoints(:,4:6),'useMatrixMult',true,'onlyComputeTransform',false);
            end
            XBBPixels = makeProjections.coor2pixels(XBB,[abobj.refSize(2),abobj.refSize(1),abobj.refSize(3)]);
            if options.methodUsedInPaper
                % find planes in Bridge Brain Selected
                if size(XBBPixels,1) >= 2
                    uniBBPlanes = unique(XBBPixels(1:2,3));
                else
                    fprintf('%s should break code\n',abobj.fishID)
                    uniBBPlanes = unique(XBBPixels(1,3));
                end
            else
                uniBBPlanes = unique(XBBPixels(:,3));
            end
            for uniPlaneIndex = uniBBPlanes(:)'
                pSelect = XBBPixels(:,3)==uniPlaneIndex;
                figure('Position',[123,186,1622,789]);subplot(1,4,[1:3]);imagesc(bbI(:,:,uniPlaneIndex),[0 800]);colormap('gray');hold on;
                plot(XBB(pSelect,1),XBB(pSelect,2),'r.')
                movingFishC = U(pSelect,:);
                movingFishPlane = unique(movingFishC(:,3));
                subplot(1,4,4);imagesc(abobj.images.channel{1}(:,:,movingFishPlane),[0 800]);colormap('gray');hold on;
                plot(U(pSelect,1),U(pSelect,2),'r.')
            end
        end
        %       abobj=getDamageOutline(abobj);
        [abobj,Nreference]=getRegistrationTransform(abobj,varargin);
        abobj = rotateImages90(abobj);
        viewDamage(abobj,varargin);
        [medianRC,medianLength,registeredPoints]=medianRegisteredRClocation(abobj);
    end
    
end

