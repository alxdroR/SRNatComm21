function [F,TF,Ecell,Tcell,IDindex,IDindex2,varargout] = loadfullData(ID,varargin)
options = struct('dff',true,'NMF',true,'expcond','before','useTwitches',true,'data2align',[],'useDeconvF',false);
options = parseNameValueoptions(options,varargin{:});

[fid,expCond] = listAnimalsWithImaging;
uniqueAnimals = unique(ID(:,1));
F = cell(length(uniqueAnimals),1);
TF = cell(length(uniqueAnimals),1);
Ecell = cell(length(uniqueAnimals),1);
Tcell = cell(length(uniqueAnimals),1);

IDindex = [];IDindex2 = [];
if ~isempty(options.data2align)
    dataOut = [];
end
for index1 = 1:length(uniqueAnimals)
    expIndex = uniqueAnimals(index1);
    uniquePlanes = unique(ID(ID(:,1)==expIndex,2));
    % requested data set
  %  if ischar(fid{expIndex})
   %     caobj=caData('fishid',fid{expIndex},'expcond',options.expcond,'loadImages',false,'EPSelectedCells',options.NMF,'loadCCMap',false);
    %    eyeobj = eyeData('fishid',fid{expIndex},'expcond',options.expcond);
    %else
     %   caobj=caData('fishid',fid{expIndex},'loadImages',false,'EPSelectedCells',options.NMF,'loadCCMap',false);
      %  eyeobj = eyeData('fishid',fid{expIndex});
    %end
    caobj=caData('fishid',fid{expIndex},'expcond',expCond{expIndex},'loadImages',false,'NMF',options.NMF,'loadCCMap',false);
    eyeobj = eyeData('fishid',fid{expIndex},'expcond',expCond{expIndex});
    F{index1} = cell(length(uniquePlanes),1);
    TF{index1} = cell(length(uniquePlanes),1);
    Ecell{index1} = cell(length(uniquePlanes),1);
    Tcell{index1} = cell(length(uniquePlanes),1);
    if options.useDeconvF
        Y=caobj.nmfDeconvF;
    else
        Y = caobj.fluorescence;
    end
    if ~options.useTwitches
        FOneAnimal = replaceTwitchSamplesWithNaN(Y,caobj.twitchFrames);
    else
         FOneAnimal = Y;
    end
    for index2 = 1:length(uniquePlanes)
        planeIndex = uniquePlanes(index2);
        % requested data set
        Ecell{index1}{index2} = eyeobj.centerEyesMethod('planeIndex',planeIndex,'eye','both');
        Tcell{index1}{index2} = eyeobj.time{planeIndex};
        cells2view = ID((ID(:,1)==expIndex & ID(:,2)==planeIndex),3);
        
        if options.dff
            F{index1}{index2} = dff(FOneAnimal{planeIndex}(:,cells2view));
        else
            F{index1}{index2} = FOneAnimal{planeIndex}(:,cells2view);
        end
        TF{index1}{index2} = caobj.time{planeIndex}(:,cells2view);
        IDindex = [IDindex;[ ones(size(F{index1}{index2},2),1)*[index1 index2] (1:size(F{index1}{index2},2))'] ];
        IDindex2 = [IDindex2;[ ones(size(F{index1}{index2},2),1)*[expIndex planeIndex] cells2view(:)] ];
        
        if ~isempty(options.data2align)
            dataOut = [dataOut;options.data2align(ID(:,1)==expIndex & ID(:,2)==planeIndex,:)];
        end
    end
end

if ~isempty(options.data2align)
    varargout{1} = dataOut;
end
end

