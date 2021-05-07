function [fname,varargout] = getFilenames(fid,varargin)
% [fname,varargout] = getFilenames(fid,varargin)
% options = struct('dir',[],'expcond',[],'fileNumber',[],'fileType','raw','singleCellAblations',false,'addF2Header',false,'caTraceType','NMF','onlySaveNonFused',false,'appendFileType',true);
% fileType: {'raw','constructHeader','eye','laserStartTimes','catraces',...

% [fname] = getFilenames(fid,varargin)
% Input:
% fid -- character or number or empty.  Leave empty for filenames
% of reference brain,
% Name-value pairs
% 'expcond' ---
%
% fileNumber --- integer specifying a specific file to se
%
% fileType --
% {'raw','eye','catraces','expMetaData','metaDataProc','medianImages',...
% 'damageImages','refBrain','tiffRefBrain','ImageCoordPoints',...
%  'damageOutline','damageCoordPoints','staFalsePos','b4aftCellClass'}
%
options = struct('dir',[],'expcond',[],'fileNumber',[],'fileType','raw','singleCellAblations',false,'addF2Header',false,'caTraceType','NMF','onlySaveNonFused',false,'appendFileType',true);
options = parseNameValueoptions(options,varargin{:});
% check if user is requesting an ablation experiment
% if so, make sure they specified experimental condition
% and set condition variable
% expcond = [];
% if ~isempty(fid)
%     if ischar(fid) || ~isempty(options.expcond)
%         if isempty(options.expcond)
%             %   error('ablation experiments require a condition specification');
%             %    warning('specify `expcond` variable if ablation exp')
%         else
%             % add an option to be able to use any string
%             % but make previous Keywords ('before' == 'B')
%             % backwards compatible
%             expcond = options.expcond;
%             switch options.expcond
%                 case 'before'
%                     expcond = 'B';
%                 case 'after'
%                     expcond = 'A';
%                 case 'damage'
%                     expcond = '_damage';
%                 case 'damageBefore'
%                     expcond = '_damageBefore';
%             end
%         end
%     end
% end
[rootDataPath,smallDataPath,filedirs] = rootDirectories;
if ispc
    fileDelim = '\';
else
    fileDelim = '/';
end

% construct filepath
switch options.fileType
    case 'constructHeader'
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        if isempty(options.dir)
            fname = fstart;
        else
            fname = [options.dir fstart];
        end
    case 'raw'
        if isempty(options.dir)
            if options.singleCellAblations
                rootDir = filedirs.singleCell.rawCa;
            else
                rootDir = filedirs.rawCa;
            end
        else
            rootDir = options.dir;
        end
        % beginning characters of filename
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        if ~isempty(options.fileNumber)
            % Construct a single filename for a specific plane
            if options.fileNumber < 10
                plane = ['00' num2str(options.fileNumber) '.tif'];
            else
                plane = ['0' num2str(options.fileNumber) '.tif'];
            end
            fname{1} = [rootDir fstart '_' plane];
        else
            % construct multiple filenames for all tiff data in this directory
            % matching the fid name
            dir2search = rootDir;
            regExpTag = ['^' fstart '_' '\d\d\d.tif'];
            fileType = '.tif';
            fname = dataNameConventions.findMatches(dir2search,regExpTag,fileType);
        end
    case 'eye'
        if isempty(options.dir)
            rootDir = filedirs.eyePosition;
        else
            rootDir = options.dir;
        end
        % beginning characters of filename
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        if ~isempty(options.fileNumber)
            fname{1} = [rootDir fstart '_' num2str(options.fileNumber) '.mat'];
        else
            % construct multiple filenames for all tiff data in this directory
            % matching the fid name
            regExpTag = ['^' fstart '_' '\d*.mat'];
            fileType = '.mat';
            fname = dataNameConventions.findMatches(rootDir,regExpTag,fileType);
        end
    case 'laserStartTimes'
        if isempty(options.dir)
            rootDir = filedirs.eyePosition;
        else
            rootDir = options.dir;
        end
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        % check for start times relative to calcium imaging start
        regExpTag = ['^' fstart '_' '\d*offset.mat'];
        fileType = '.mat';
        fnameOffset = dataNameConventions.findMatches(rootDir,regExpTag,fileType);
        fname = fnameOffset;
    case 'catraces'
        if options.appendFileType
            fileType = '.mat';
        else
            fileType = [];
        end
        if strcmp(options.caTraceType,'CCEyes')
            ending = ['_maxCCLoc' fileType];
        elseif strcmp(options.caTraceType,'NMF')
            ending = ['_EPSelect' fileType];
        elseif strcmp(options.caTraceType,'MO')
            ending = ['_IMOpenSelect' fileType];
        end
        if isempty(options.dir)
            rootDir = filedirs.caTimeseries;
        else
            rootDir = options.dir;
        end
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        fname = [rootDir fstart '_' 'traces' ending];
    case 'regressionMaps'
        if isempty(options.dir)
            rootDir = filedirs.avgImgsAllPlanes;
        else
            rootDir = options.dir;
        end
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        fname = [rootDir fstart '_' 'regressionMaps'];
    case 'expMetaData'
        if options.singleCellAblations
            rootDir = filedirs.singleCell.rawCaManualMetaData;
        else
            if isfield(filedirs,'rawCaManualMetaData')
                rootDir = filedirs.rawCaManualMetaData;
            else
                rootDir=[];
            end
        end
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        if strcmp(options.expcond,'_damage')
            fname = [rootDir 'f' num2str(fid) 'damageexpMetaData.mat'];
        else
            fname = [rootDir fstart 'expMetaData.mat'];
        end
    case 'regLandmarks'
        if isempty(options.dir)
            if options.singleCellAblations
                rootDir = filedirs.singleCell.registration.landmarks;
            else
                rootDir = filedirs.registration.landmarks;
            end
        else
            rootDir = options.dir;
        end
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        fname = [rootDir fstart '-BigWarp-landmarks2.csv'];
    case 'damageCoordPoints'
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        fname = [filedirs.coarseAbl.registration.landmarks fstart];
    case 'checkRegQuality'
        %  constructing filenames for output of checkRegQuality.m a script which creates fused images of registered moving and target brains
        if isempty(options.dir)
            if options.singleCellAblations
                rootDir = filedirs.singleCell.registration.checkRegQuality;
            else
                rootDir = filedirs.registration.checkRegQuality;
            end
        else
            rootDir = options.dir;
        end
        if options.onlySaveNonFused
            ending = '.tif';
        else
            ending = '-Fuse.tif';
        end
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        shortFileName = [fstart '-BigWarp-landmarks2' ending];
        fname = [rootDir shortFileName];
        varargout{1} = shortFileName;
    case 'checkRegQualityCoarseAbl'
        rootDir = filedirs.coarseAbl.registration.checkRegQuality;
        if options.onlySaveNonFused
            ending = '.tif';
        else
            ending = '-Fuse.tif';
        end
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        shortFileName = [fstart ending];
        fname = [rootDir shortFileName];
        varargout{1} = shortFileName;
    case 'metaDataProc'
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        fname = [smallDataPath fstart 'expMetaData.mat'];
    case 'medianImages'
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        if isempty(options.dir)
            fname = [filedirs.avgImgsAllPlanes fstart '_' 'medI'];
        else
            fname = [options.dir fstart '_' 'medI'];
        end
    case 'averageImages'
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        if isempty(options.dir)
            fname = [filedirs.avgImgsAllPlanes fstart '_' 'avg'];
        else
            fname = [options.dir fstart '_' 'avg'];
        end
    case 'damageOutline'
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        fname = [filedirs.coarseAbl.damgeOutlines fstart '.mat'];
    case 'findOverlappingCells'
        % I gave this one an odd name and haven't correctd 3/10/2021
        fstart = dataNameConventions.constructHeader('findOverlappingCells-',[fid(2:end) options.expcond],varargin{:});
        fname = [filedirs.NMFMOCmp fstart];
    case 'ImageCoordPoints'
        fname = [smallDataPath num2str(fid) '-1-caImageCP.mat'];
    case 'staFalsePos'
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        fname = [smallDataPath fstart  '_' 'staFalsePos.mat'];
    case 'b4aftCellClass'
        fstart = dataNameConventions.constructHeader(fid,[]);
        fname = [smallDataPath fstart '_' 'b4aftCellClass.mat'];
    case 'eyeavi'
        % beginning characters of filename
        fstart = dataNameConventions.constructHeader(fid,options.expcond,varargin{:});
        if ~isempty(options.fileNumber)
            fname{1} = [rootDataPath 'MATFiles' fileDelim fstart '_' num2str(options.fileNumber) '.avi'];
        else
            % construct multiple filenames for all tiff data in this directory
            % matching the fid name
            dir2search = [rootDataPath 'MATFiles' fileDelim];
            regExpTag = ['^' fstart '_' '\d*.avi'];
            fileType = '.avi';
            fname = dataNameConventions.findMatches(dir2search,regExpTag,fileType);
        end
    case 'OKRstim'
        fstart = dataNameConventions.constructHeader(num2str(fid),'_stim',varargin{:}); % updated code has not been tested
        if ~isempty(options.fileNumber)
            fname{1} = [rootDataPath 'MATFiles' fileDelim fstart '_' num2str(options.fileNumber) '.mat'];
        else
            % construct multiple filenames for all tiff data in this directory
            % matching the fid name
            dir2search = [rootDataPath 'MATFiles' fileDelim];
            regExpTag = ['^' fstart '_' '\d*.mat'];
            fileType = '.mat';
            fname = dataNameConventions.findMatches(dir2search,regExpTag,fileType);
        end
end
end
