function eyeobj = saccadeDetection(eyeobj,varargin)
            % detect when saccades occur or allow user to fill the
            % associated properties
            %
            % eyeobj = eyeobj.saccadeDetection
            %        Invoke the method this way if saccade times are already
            %    saved onto disk and you are asking to load the contents
            %    into memory. Saccade times must exist in a .mat file, with a full filename
            %    as specified in the saccadeTimeFilename
            %    function.
            %        If a file does not exist, SaccadeTimes will use the findSaccadeTimes function
            % to calculate saccade times based on a thresholded estimate of
            % the velocity.
            %
            % saccadeTimes will be specified as a cell array, with the same
            % cell length and units as the time property. The ith cell element in the
            % array, saccadeTimes{i}, is an Mx2 array where M is an integer
            % equal to the number of saccades for all p samples. M can depend on i.
            % saccadeTimes{j}(:,1) gives
            % the start times of the saccades and saccadeTimes{j}(:,2) gives the end
            % times of the saccades.  These do not need to be integers since they
            % are specified in the same units as the time property.
            %
            % eyeobj = eyeobj.saccadeDetection('saccadeTimes',X)
            % Invoke this way if you are manually changing the saccadeTimes
            % property.
            %
            % Optional Inputs: 
            %  'thresholdUnits'  {'dps','relative'}
            %
            % Determines if the threshold is interpretted as a hard threshold in
            % degrees per second (dps) or interpretted as the number of standard deviations 
            % away from the mean to use as a threshold (relative). The
            % latter is good if saccade velocities are not stereotyped. 
            
            
            % - parse inputs
%            options = struct('saccadeTimes',[]);
            
%             %# read the acceptable names
%             optionNames = fieldnames(options);
%             
%             %# count arguments
%             nArgs = length(varargin);
%             if round(nArgs/2)~=nArgs/2
%                 error('saccadeDetection needs propertyName/propertyValue pairs')
%             end
%             
%             for pair = reshape(varargin,2,[]) %# pair is {propName;propValue}
%                 inpName = pair{1};
%                 %inpName = lower(pair{1}); %# make case insensitive
%                 
%                 if any(strcmp(inpName,optionNames))
%                     %# test for the right class here
%                     options.(inpName) = pair{2};
%                 else
%                     error('%s is not a recognized parameter name',inpName)
%                 end
%             end
%             
            options = struct('saccadeTimes',[],'threshold',3,'minThreshold',10,'filterOrder',0.5,'thresholdUnits','relative');
            options = parseNameValueoptions(options,varargin{:});
            
            loadData = true;
            if ~isempty(options.saccadeTimes)
                loadData = false;
            end
            if ~loadData
                % set property to user specified value
                if ~isnumeric(options.saccadeTimes)
                    eyeobj.saccadeTimes = options.saccadeTimes;
                else
                    eyeobj.saccadeTimes{1} = options.saccadeTimes;
                end
                eyeobj.saccadeTimeFilePath = 'user set;not on disk';
            else
                % attempt to load data if it is saved on disk otherwise run
                % the findSaccadeTimes algorithm
              %  saccFilePath = saccadeTimeFilename(eyeobj.fishID,eyeobj.locationID,eyeobj.expCond);
                saccFilePath =[];% adr -6/12/2015 -- temp change 
                loadData = true;
                if exist(saccFilePath,'file')~=2
                    loadData = false;
                end
                if loadData
                    load(saccFilePath);
                    eyeobj.saccadeTimes = all_full;
                    eyeobj.saccadeTimeFilePath = saccFilePath;
                else
                    eyeobj.saccadeTimeFilePath = 'not saved on disk';
                    eyeobj.saccadeDetectionAlgorithm = 'median filter with hardcoded threshold'; % remove hardcoded here and in find_sac_times(todo)
                    eyeobj.saccadeDetectionParamters.threshold = options.threshold;
                    eyeobj.saccadeDetectionParamters.filterOrder = options.filterOrder;
                    
                    narrays = length(eyeobj.position);
                    for arrayInd = 1 : narrays
                       
                        % run findSaccadeTimes algorithm
                      %  [localSacPnts,localSacDir,localConjSac,localSacVel,localSacRegIndex,localSacAmp] = ...
                         %   find_saccade_times_obsolete(eyeobj.position{arrayInd},eyeobj.time{arrayInd});
                           [localSacPnts,localSacDir,localConjSac,localSacVel,localSacRegIndex,localSacAmp] = ...
                            findSaccadeTimes(eyeobj.position{arrayInd},'time',eyeobj.time{arrayInd},...
                            'threshold',options.threshold,'filterOrder',options.filterOrder,'thresholdUnits',options.thresholdUnits,...
                           'minThreshold',options.minThreshold);
                        eyeobj.saccadeTimes{arrayInd} = localSacPnts;
                        eyeobj.saccadeDirection{arrayInd} = localSacDir;
                        eyeobj.saccadeVelocity{arrayInd} = localSacVel;
                        eyeobj.conjugateSaccade{arrayInd} = localConjSac;
                        eyeobj.saccadeIndex{arrayInd} = localSacRegIndex;
                        eyeobj.saccadeAmplitude{arrayInd} = localSacAmp;
                    end
                end
            end
        end