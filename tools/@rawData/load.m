% ---- load movies
function rawobj = load(rawobj,varargin)
options = struct('fast',false,'channel','all','useImread',true,'singleCellAblations',false,'verbose',false);
options = parseNameValueoptions(options,varargin{:});

if isempty(rawobj.currentFile)
    rawobj=rawobj.setFiles2Load(varargin{:});
end
rawobj.currentFile = rawobj.file2Load{rawobj.fileNumber};
narrays = 1;
if narrays>0
    rawobj.movies = cell(narrays,1);
    rawobj.metaData = cell(narrays,1);
    for arrayInd = 1 : narrays
        rawobj.metaData{arrayInd} = rawobj.grabMetaData(rawobj.currentFile);
        if options.verbose
            fprintf('-----------loading file-----------\n%s\n',rawobj.currentFile);
        end
        if ~isempty(rawobj.metaData{arrayInd})
            [FCh1,FCh2,FCh3] = rawobj.loadScanImageTIFF(rawobj.currentFile,'fast',options.fast,'channel',options.channel,'useImread',options.useImread);
        else
            [FCh1,FCh2,FCh3] = rawobj.loadTIFF(rawobj.currentFile,'fast',options.fast);
        end
        rawobj.movies{arrayInd}.channel = {FCh1,FCh2,FCh3};
    end
end
end % end load movies