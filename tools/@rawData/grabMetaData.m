function [meta,hinfo] = grabMetaData(filename,varargin)
options = struct('checkIfScanImageFile',true,'isImageJFile',false);
options = parseNameValueoptions(options,varargin{:});

hinfo = imfinfo(filename);
meta = struct('acq',struct('linesPerFrame',hinfo(1).Height,'pixelsPerLine',hinfo(1).Width,...
    'numberOfFrames',length(hinfo),'numberOfChannelsSave',1,...
    'savingChannel1',true,'savingChannel2',false,'savingChannel3',false,...
    'averaging',false,'msPerLine',1));

if options.checkIfScanImageFile
    if isfield(hinfo(1),'ImageDescription')
        meta=parseHeader(hinfo(1).ImageDescription); % information recorded by scanimage
        meta.imagingPeriod = meta.acq.msPerLine*hinfo(1).Height;
        meta.Height = hinfo(1).Height;
        meta.Width = hinfo(1).Width;
        meta.NumImages = length(hinfo);
        meta.numSlices = length(hinfo)/meta.acq.numberOfChannelsSave;
        meta.avgPixelTime = meta.acq.msPerLine/hinfo(1).Width;
    end
elseif options.isImageJFile
    if isfield(hinfo(1),'ImageDescription')
        spaceStartInd=regexp(hinfo(1).ImageDescription,'spacing=');
        if ~isempty(spaceStartInd)
            zSpacing=str2double(hinfo(1).ImageDescription((8:10)+spaceStartInd));
        else
            warning('Scale Information Not Saved With Image');
            zSpacing = NaN;
        end
        
        spaceStartInd=regexp(hinfo(1).ImageDescription,'channels=');
        numChannels=str2double(hinfo(1).ImageDescription(9+spaceStartInd));
        
        meta = struct('Width',hinfo(1).Width,'Height',hinfo(1).Height,...
            'XMicPerPix',1./hinfo(1).XResolution,'YMicPerPix',1./hinfo(1).YResolution,'ZMicPerPlane',zSpacing,....
            'numImages',length(hinfo),'numSlices',length(hinfo)/numChannels,'numChannels',numChannels);
    end
end
end
