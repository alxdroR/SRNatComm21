function [xPix,nearestOddWholeNumPixPerMicron,rawobj] = micron2pixel(rawobj,xMu)
% make sure meta data is calculated
if isempty(rawobj.metaData)
    % load tiff stacks
    filenames = getFilenames(rawobj.fishID,'expcond',rawobj.expCond,'fileType','raw','fileNumber',rawobj.fileNumber);
    narrays = length(filenames);
    rawobj.metaData = cell(narrays,1);
    for arrayInd = 1 : narrays
        if exist([filenames{arrayInd} ],'file')==2
            rawobj.metaData{arrayInd} = rawobj.grabMetaData(filenames{arrayInd});
        end
    end
end

narrays = length(rawobj.metaData);
xPix = zeros(narrays,length(xMu));
for arrayInd = 1 : narrays
    [xPix(arrayInd,:),pixPerMicron] = rawData.mic2pix(xMu,rawobj.metaData{arrayInd});
end

if mod(round(pixPerMicron),2)==0
    nearestOddWholeNumPixPerMicron = round(pixPerMicron)-1;
else
    nearestOddWholeNumPixPerMicron = round(pixPerMicron);
end
end