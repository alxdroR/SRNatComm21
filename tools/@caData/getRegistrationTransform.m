function caobj=getRegistrationTransform(caobj,varargin)
            % caobj=getRegistrationTransform(caobj,Name,Value)
            %   Loads pre-saved affine transformation matrix created 
            % by the function ___. getRegistrationTransform takes this 
            % matrix and creates a special transformation structure 
            % using the image processing toolbox function maketform 
            % 
            % Name-Value Pair arguments
            % 
            % Method -- only 1 option supported (future versions should
            % support more). String set to - '2dstitch'
            %
            % NumPlanesRefBrain--specify how many planes are in the
            % reference brain. Use [] to indicate 
            % [](default)| 
          
            options = struct('method','2dstitch','NumPlanesRefBrain',[]);
            options = parseNameValueoptions(options,varargin{:});
            
          %  if strcmp(caobj.expCond,'after')
          %      transformFileName = registrationTransformFilename(caobj.fishID,caobj.locationID,'before');
          %  else
          %      transformFileName = registrationTransformFilename(caobj.fishID,caobj.locationID,caobj.expCond);
         %   end
             transformFileName = getFilenames(caobj.fishID,'expcond','before','fileType','ImageCoordPoints');
            if exist(transformFileName,'file')==2
                load(transformFileName)
                if exist('offsetc','var')~=0
                    load(transformFileName,'offsetc')
                    Nlocal=size(offsetc,1);
                    for plane = 1 : Nlocal
                        translation2d = [eye(2,3);[offsetc(plane,1) offsetc(plane,2) 1]];
                        caobj.regTransform{plane} = maketform('affine',translation2d);
                    end
                    caobj.transformedZ = offsetc;
                else
                    
                    if isempty(options.NumPlanesRefBrain)
                       % refBrainFilename=refbrainFilename('fileFormat','tiff');
                         refBrainFilename=refbrainFilename;
                        refBrainHeader = imfinfo(refBrainFilename);
                        Nreference = length(refBrainHeader);
                    else
                        Nreference = options.NumPlanesRefBrain;
                    end
                    switch options.method
                        case '2dstitch'
                            
                            Nlocal = length(caobj.fluorescence);
                            [caobj.regTransform,caobj.transformedZ] = approx3dTransform(movingPoints,fixedPoints,Nlocal,Nreference);
                            % hack until I re-learn/re-write
                            % approx3dTransform
                            registeredZCoordinates = caobj.transformedZ;
                            if caobj.fishID == 1
                                sRemPlanes = 5:5:5*length(registeredZCoordinates(41:end));
                                sFixedPlanes = 3:3:(sRemPlanes(end)+2);
                                bestMatchFixedInd = zeros(length(sRemPlanes),1);
                                indFixedPlanes = [1:length(sFixedPlanes)]+10;
                                for jj=1:length(sRemPlanes)
                                    [~,bestMatchSubInd]=min(abs(sFixedPlanes-sRemPlanes(jj)));
                                    bestMatchFixedInd(jj) = indFixedPlanes(bestMatchSubInd);
                                end
                                caobj.transformedZ(41:end) = bestMatchFixedInd;
                            elseif caobj.fishID == 7
                                sRemPlanes = 5:5:5*length(registeredZCoordinates(31:end));
                                sFixedPlanes = 3:3:(sRemPlanes(end)+2);
                                bestMatchFixedInd = zeros(length(sRemPlanes),1);
                                indFixedPlanes = [1:length(sFixedPlanes)]+13;
                                for jj=1:length(sRemPlanes)
                                    [~,bestMatchSubInd]=min(abs(sFixedPlanes-sRemPlanes(jj)));
                                    bestMatchFixedInd(jj) = indFixedPlanes(bestMatchSubInd);
                                end
                                caobj.transformedZ(31:end) = bestMatchFixedInd;
                            end
                        case '3daffine'
                            error('in progress')
                    end
                end
            end
        end