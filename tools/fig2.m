classdef fig2 < figures & srPaperPlots
    %fig2 - print figure panels in figure 2
    % adr
    % ea lab
    % weill cornell medicine
    % 10/2012 - 2020
    
    properties
        dFFRange
        timeWidth
        eyeRange
        dFFLineWidth
        dFFLineColor
        deconvLineWidth
        deconvLineColor
        ID = [0 0 0]
        dFF
        timeF
        E
        eyeTime
        deconvAU
        allIDs
        STA
        deconvSTA
        deconvOffset
        STCIU
        STCIL
        nTrialsL
        nTrialsR
        STRDFRange
        rightSTAColor
        leftSTAColor
        lineAtZeroWidth
        spaceBetweenSTRLR
        tauLimits
        STRSTAPaperPosition
        strAXOffset
        strAXHeight
        staAXOffset
        staAXHeight
    end
    
    methods
        function obj = fig2(varargin)
            options = struct('dFFRange',[],'timeWidth',[],'eyeRange',[],'dFFLineWidth',1,'dFFLineColor',[0 0 1],...
                'STAFilename','calcSTA2NMFOutput','STADeconvFilename','calcSTA2NMFDeconvOutput','allIDsForFigure',[],...
                'showSTADeconv',false,'deconvLineWidth',1,'deconvLineColor',[0 0 0],'paperPosition',[],...
                'STRDFRange',[],'rightSTAColor',[],'leftSTAColor',[],'lineAtZeroWidth',[],'spaceBetweenSTRLR',[],'tauLimits',[],'STRSTAPaperPosition',[],...
                'strAXOffset',[],'strAXHeight',[],'staAXOffset',[],'staAXHeight',[],'deconvOffset',false);
            options = parseNameValueoptions(options,varargin{:});
            
            % set properties fixed across all subpanels
            obj.dFFRange = options.dFFRange;
            obj.timeWidth = options.timeWidth;
            obj.eyeRange = options.eyeRange;
            obj.dFFLineWidth = options.dFFLineWidth;
            obj.dFFLineColor = options.dFFLineColor;
            obj.deconvLineWidth = options.deconvLineWidth;
            obj.deconvLineColor = options.deconvLineColor;
            obj.STRDFRange = options.STRDFRange;
            obj.rightSTAColor = options.rightSTAColor;
            obj.leftSTAColor = options.leftSTAColor;
            obj.lineAtZeroWidth = options.lineAtZeroWidth;
            obj.spaceBetweenSTRLR = options.spaceBetweenSTRLR;
            obj.tauLimits = options.tauLimits;
            obj.strAXOffset = options.strAXOffset;
            obj.strAXHeight = options.strAXHeight;
            obj.staAXOffset = options.staAXOffset;
            obj.staAXHeight = options.staAXHeight;
            obj.deconvOffset = options.deconvOffset;
            % paperPosition has default values if user doesn't provide
            % values
            if ~isempty(options.STRSTAPaperPosition)
                obj.STRSTAPaperPosition = options.STRSTAPaperPosition;
            else
                obj.STRSTAPaperPosition = obj.paperPosition;
            end
            if ~isempty(options.paperPosition)
                obj.paperPosition = options.paperPosition;
            end
            % load STA related data common to all plots
            IDALL = getIDFullDataSet('NMF');
            
            [~,~,dirFiles] = rootDirectories;
            load([dirFiles.sta options.STAFilename],'STA','STCIL','STCIU','nTrialsL','nTrialsR');
            if options.showSTADeconv
                deconvSTA=load([dirFiles.sta options.STADeconvFilename],'STA');
            end
            if isempty(options.allIDsForFigure)
                obj.allIDs = IDALL;
                obj.STA = STA;
                obj.STCIU = STCIU;
                obj.STCIL = STCIL;
                obj.nTrialsL = nTrialsL;
                obj.nTrialsR = nTrialsR;
                if options.showSTADeconv
                    obj.deconvSTA = deconvSTA.STA;
                end
            else
                indices = NaN(size(options.allIDsForFigure,1),1);
                for cell2PlotIndexIndex =1 : size(options.allIDsForFigure,1)
                    indices(cell2PlotIndexIndex) = find(IDALL(:,1) == options.allIDsForFigure(cell2PlotIndexIndex,1) ...
                        & IDALL(:,2) == options.allIDsForFigure(cell2PlotIndexIndex,2) & ...
                        IDALL(:,3) == options.allIDsForFigure(cell2PlotIndexIndex,3));
                end
                obj.allIDs = IDALL(indices,:);
                obj.STA = STA(indices,:,:);
                obj.STCIU = STCIU(indices,:,:);
                obj.STCIL = STCIL(indices,:,:);
                obj.nTrialsL = max(nTrialsL(indices,:),[],2);
                obj.nTrialsR = max(nTrialsR(indices,:),[],2);
                if options.showSTADeconv
                    obj.deconvSTA = deconvSTA.STA(indices,:,:);
                end
            end
        end
        function obj=runFig2bi(obj,ID,varargin)
            obj=runPlotActivityWEyesClass(obj,ID,varargin{:});pause(0.1);
            [obj,tau,STRL,STRR]=runPlotSTRSTAClass(obj,ID,varargin{:});
            fig2.toCSV('c',tau,STRL,STRR);
        end
        function obj=runFig2bii(obj,ID,varargin)
            obj=runPlotActivityWEyesClass(obj,ID,varargin{:});pause(0.1);
            [obj,tau,STRL,STRR]=runPlotSTRSTAClass(obj,ID,varargin{:});
            fig2.toCSV('d',tau,STRL,STRR);
        end
         function obj=runFig2biii(obj,ID,varargin)
            obj=runPlotActivityWEyesClass(obj,ID,varargin{:});pause(0.1);
            [obj,tau,STRL,STRR]=runPlotSTRSTAClass(obj,ID,varargin{:});
            fig2.toCSV('e',tau,STRL,STRR);
         end
        function obj=runPlotActivityWEyesClass(obj,ID,varargin)
            options = struct('timeOffset2plot',[],'axesOverlap',[],'showAxis',true,'showDeconv',false,'traceFilename',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if any(ID ~= obj.ID)
                expIndex = ID(1);planeIndex = ID(2);cellIndex = ID(3);
                [caobj,eyeobj] = plotActivityWEyes.loadCaEyeObjs(expIndex);
                if options.showDeconv
                    [dFF,timeF,E,eyeTime,deconvAU] = plotActivityWEyes.extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndex,'runDFF',true,'returnDeconvF',true,'haveDeconvMatchDFF',true);
                    obj.deconvAU = deconvAU;
                else
                    [dFF,timeF,E,eyeTime] = plotActivityWEyes.extractCaEyeObjs(caobj,eyeobj,planeIndex,cellIndex,'runDFF',true,'returnDeconvF',false);
                    obj.deconvAU = [];
                end
                obj.ID = ID;
                obj.dFF = dFF;
                obj.timeF = timeF;
                obj.E = E;
                obj.eyeTime = eyeTime;
            end
            activityEyeObj = plotActivityWEyes('filename',options.traceFilename,'paperPosition',obj.paperPosition,...
                'eyeTime',obj.eyeTime,'angle',obj.E,'leftEyeIndex',1,'rightEyeIndex',2,'caTime',obj.timeF,'dFF',obj.dFF,'deconvF',obj.deconvAU,...
                'dFRange',obj.dFFRange,'timeWidth',obj.timeWidth,'eyeRange',obj.eyeRange,'timeOffset2plot',options.timeOffset2plot,...
                'axesOverlap',options.axesOverlap,'dFFLineWidth',obj.dFFLineWidth,'dFFLineColor',obj.dFFLineColor,...
                'deconvLineWidth',obj.deconvLineWidth,'deconvLineColor',obj.deconvLineColor,'showAxis',options.showAxis);
            activityEyeObj.plot;
        end
        function [obj,varargout]=runPlotSTRSTAClass(obj,ID,varargin)
           options = struct('timeOffset2plot',[],'axesOverlap',[],'showAxis',true,'strstaFilename',[]);
            options = parseNameValueoptions(options,varargin{:});
            
            if ~isempty(obj.deconvSTA)
                [sta2plot,staCIL2plot,staCIU2plot,STRL,STRR,bt,deconvSTA] = plotSTRSTA.extractSTRSTA(...
                    obj.allIDs,ID,obj.STA,obj.STCIL,obj.STCIU,obj.dFF,obj.timeF,'deconvSTA',obj.deconvSTA,'haveDeconvMatchDFF',true);
            else
                [sta2plot,staCIL2plot,staCIU2plot,STRL,STRR,bt] = plotSTRSTA.extractSTRSTA(...
                    obj.allIDs,ID,obj.STA,obj.STCIL,obj.STCIU,obj.dFF,obj.timeF);
                deconvSTA = [];
            end
            
            strSTAObj = plotSTRSTA('filename',options.strstaFilename,'paperPosition',obj.STRSTAPaperPosition,...
                'time',bt,'STRL',STRL,'STRR',STRR,'STA',sta2plot,'STACIL',staCIL2plot,'STACIU',staCIU2plot,'deconvSTA',deconvSTA,....
                'dFRange',obj.STRDFRange,'rightSTAColor',obj.rightSTAColor,'leftSTAColor',obj.leftSTAColor,...
                'lineAtZeroWidth',obj.lineAtZeroWidth,'spaceBetweenSTRLR',obj.spaceBetweenSTRLR,'tauLimits',obj.tauLimits,...
                'strAXOffset',obj.strAXOffset,'strAXHeight',obj.strAXHeight,'staAXOffset',obj.staAXOffset,'staAXHeight',obj.staAXHeight,'deconvOffset',obj.deconvOffset);
            
            strSTAObj.plot;
            [~,aind]= min(abs(bt-obj.tauLimits(1)));
            [~,bind] = min(abs(bt-obj.tauLimits(2)));
            varargout{1} = bt(aind:bind);
            varargout{2} = STRL(:,aind:bind);
            varargout{3} = STRR(:,aind:bind);
        end
    end
     methods(Static)
         function toCSV(panel,tau,STRL,STRR)
            global saveCSV
            if saveCSV
                [~,~,fileDirs] = rootDirectories;
                fileID = fopen([fileDirs.scDataCSV 'Figure 2.csv'],'a');
                fprintf(fileID,'Panel\n%s,Saccade-triggered fluorescence responses around saccades to the left\n',panel);
                fprintf(fileID,',time around saccade(s)');
                dlmwrite([fileDirs.scDataCSV 'Figure 2.csv'],tau,'delimiter',',','-append','coffset',1);
                fprintf(fileID,',Sample Index\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 2.csv'],[(1:size(STRL,1))' STRL],'delimiter',',','-append','coffset',1);
                fprintf(fileID,',Saccade-triggered fluorescence responses around saccades to the right\n');
                fprintf(fileID,',time around saccade(s)');
                dlmwrite([fileDirs.scDataCSV 'Figure 2.csv'],tau,'delimiter',',','-append','coffset',1);
                fprintf(fileID,',Sample Index\n');
                dlmwrite([fileDirs.scDataCSV 'Figure 2.csv'],[(1:size(STRR,1))' STRR],'delimiter',',','-append','coffset',1);
                fclose(fileID);
            end
        end
     end
end

