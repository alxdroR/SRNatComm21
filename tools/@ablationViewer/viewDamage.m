function viewDamage(abobj,varargin)
       options = struct('axisHandle',[],'figureHandle',gcf,'plane',[],'outline',true,'movie',false,'channel',1,'average',true);
            options = parseNameValueoptions(options,varargin{:});
            
            
            % visualize geometric approximation to damage
            
            % create circles with appropriate locations and radius
            %damageOutline = coord2mask(abobj.offset,[0 0 0],abobj.radius,size(abobj.images));
            % fuse this approximate image with
            if options.outline
                damageOutline = getDamageMask(abobj,'average',options.average);
                adjStack = imadjust3d_stretch(abobj.images.channel{options.channel},[0.01 0.9]);
                I2show = imfuse3d(adjStack,damageOutline);
             else
                [H,W,NP] = size(abobj.images.channel{1});
                I2show = zeros(H,W,3,NP,class(abobj.images.channel{options.channel}));
                if options.channel == 1
                    % show in green
                    I2show(:,:,2,:) = imadjust3d_stretch(abobj.images.channel{options.channel},[0.01 0.97]);
                elseif options.channel == 2
                    % show in red
                    I2show(:,:,1,:) = imadjust3d_stretch(abobj.images.channel{options.channel},[0.01 0.97]);
                elseif options.channel == 3
                    % show in black and white
                     I2show = zeros(H,W,1,NP,class(abobj.images.channel{options.channel}));
                     I2show(:,:,1,:) = imadjust3d_stretch(abobj.images.channel{options.channel},[0.01 0.97]);
                end
            end
          
            if isempty(options.axisHandle)
                  grabFigure(options.figureHandle);
                if ~isempty(options.plane)
                    nPlanes = length(options.plane);
                    options.axisHandle = cell(nPlanes,1);
                    for j=1:nPlanes
                        options.axisHandle{j} = subplot(nPlanes,1,j);
                    end
                else
                    options.axisHandle = gca;
                end
            end
            
            if isempty(options.plane)
                % changed axes(options.axisHandle{1}) -> if statement which
                % prevents an error when axisHandle is not a cell (i.e. if
                % there is no existing figure)
                if iscell(options.axisHandle)
                    axes(options.axisHandle{1})
                else
                    axes(options.axisHandle);
                end
                if options.movie
                    implay(imadjust3d_stretch(abobj.images.channel{1},[0.01 0.99]))
                    implay(imadjust3d_stretch(abobj.images.channel{2},[0.01 0.99]))
                else
                    montage(I2show)
                end
            else
                nPlanes = length(options.plane);
                for j=1:nPlanes
                     axes(options.axisHandle{j});
                    imshow(I2show(:,:,:,options.plane(j)));
                end
            end
            
end