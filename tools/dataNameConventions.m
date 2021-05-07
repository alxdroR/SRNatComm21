classdef dataNameConventions
    
    properties
    end
    
    methods
        function obj = dataNameConventions(varargin)
            
        end
        
    end
    methods (Static)
        function fname = findMatches(dir2search,regExpTag,fileType)
            % find data files in dir2search that match the regExpTag and fileType.
            % output is sorted by filenumber
            dcont = dir([dir2search '*' fileType]);
            %dcont = dir(dir2search);
            cnt = 1;
            namesUnsorted = [];
            for i=1:length(dcont)
                stop = regexp(dcont(i).name,regExpTag,'once');
                if ~isempty(stop)
                    namesUnsorted{cnt}.full = [dir2search dcont(i).name];
                    namesUnsorted{cnt}.filename = dcont(i).name;
                    cnt = cnt+1;
                end
            end
            
            if ~isempty(namesUnsorted)
                % sort filenames
                nfiles = length(namesUnsorted);
                forder = zeros(nfiles,1);
                for j=1:nfiles
                    fnum = regexp(namesUnsorted{j}.filename,{'_[0-9]*\.',fileType});
                    forder(j)=str2double(namesUnsorted{j}.filename(fnum{1}+1:fnum{2}-1));
                end
                [~,si]=sort(forder);
                fname=cell(nfiles,1);
                for j=1:nfiles
                    fname{j} = namesUnsorted{si(j)}.full;
                end
            else
                fname = [];
            end
        end
        
        function fstart = constructHeader(fid,expcond,varargin)
            options = struct('addF2Header',false);
            options = parseNameValueoptions(options,varargin{:});
            if options.addF2Header
                fstart = ['f' num2str(fid) num2str(expcond)];
            else
                fstart = [num2str(fid) num2str(expcond)];
            end
        end
        function fileNumber = identifyFileNumber(fileIndex,cellArrayOfFileNames,varEnding)
            indicatorFnc = @(y) strcmp(y,num2str(fileIndex));
            matchingFileBool = cellfun(@(x) indicatorFnc(x(regexp(x,['_\d*' varEnding])+1:regexp(x,varEnding)-1)),cellArrayOfFileNames);
            fileNumber = find(matchingFileBool);
        end
        function fileIndex = identifyFileIndex(fileName,varEnding)
            if strcmp(varEnding,'.')
                varEnding = '\.';
            end
            fnum = regexp(fileName,{['_\d*' varEnding],varEnding});
            fileIndex = str2double(fileName(fnum{1}+1:fnum{2}-1));
        end
    end
end

