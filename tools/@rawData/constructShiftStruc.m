function varargout = constructShiftStruc(varargin)
if iscell(varargin{1})
    filenames = varargin{1};
    numPlanes = length(filenames);
    registrationShifts = struct('shiftX',zeros(numPlanes,1),'shiftY',zeros(numPlanes,1),...
        'scaleX',zeros(numPlanes,1),'scaleY',zeros(numPlanes,1),'changesInScale',false,'changesInShift',false);
    if length(varargin)>1
        registrationShifts.split = varargin{2};
    end
    for planeInd = 1 : numPlanes
        simeta = rawData.grabMetaData(filenames{planeInd});
        registrationShifts.shiftX(planeInd) = simeta.acq.scaleXShift;
        registrationShifts.shiftY(planeInd) = simeta.acq.scaleYShift;
        registrationShifts.scaleX(planeInd) = simeta.acq.linesPerFrame/simeta.acq.scanAmplitudeX;
        registrationShifts.scaleY(planeInd) = simeta.acq.pixelsPerLine/simeta.acq.scanAmplitudeY;
        
        % check for a change
        if planeInd > 1
            if(registrationShifts.shiftX(planeInd) ~= registrationShifts.shiftX(1))
                registrationShifts.changesInShift = true;
            elseif(registrationShifts.shiftY(planeInd) ~= registrationShifts.shiftY(1))
                registrationShifts.changesInShift = true;
            elseif(registrationShifts.scaleX(planeInd) ~= registrationShifts.scaleX(1))
                registrationShifts.changesInScale = true;
            elseif(registrationShifts.scaleY(planeInd) ~= registrationShifts.scaleY(1))
                registrationShifts.changesInScale = true;
            end
        end
    end
    varargout{1} = registrationShifts;
elseif isstruct(varargin{1})
    simeta = varargin{1};
    shiftX = simeta.acq.scaleXShift;shiftY = simeta.acq.scaleYShift;
    scaleX = simeta.acq.linesPerFrame/simeta.acq.scanAmplitudeX;scaleY = simeta.acq.pixelsPerLine/simeta.acq.scanAmplitudeY;
    varargout{1} = shiftX;
    varargout{2} = shiftY;
    varargout{3} = scaleX;
    varargout{4} = scaleY;
end
end
