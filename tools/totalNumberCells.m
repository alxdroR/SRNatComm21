function [numCells,numPlanesV] = totalNumberCells(cellFinderMethod,varargin)
%numCells = totalNumberCells(cellFinderMethod) returns total number of
%cells in each plane in the entire data set
%   
% INPUT:
% cellFinderMethod - As of 6/8/2017 there are three different methods used for extracting 
%                   cells from raw calcium movies. cellFinderMethod is a string describing which 
%                   method we want to use when counting cell numbers.
%                   Options are: {'NMF','MO','CCEyes'}; 
%                   NMF is Efftychios P and Liam P's method for determining
%                   spatial footprints, MO uses morphological opening on
%                   average images and CCEyes bases center of mass location
%                   and pixels most correlated with a set of eye
%                   position/velocity regressors
%
% OUTPUT
% numCells - Np x1 vector. Np is the total number of planes in the data
%           set. Np(i) gives the number of cells found in plane i. 
%           The ordering of planes is based on the order of animals in 
%           listAnimalsWithImaging and on the ordering of planes used when 
%           analyzing movies (see rawData class).
%
% numPlanesV - 20 x 1 vector giving number of planes per animal
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020
options = struct('dir',[]);
options = parseNameValueoptions(options,varargin{:});

[fid,expCond]=listAnimalsWithImaging(varargin{:});
numCells = [];
numPlanesV = [];
for expIndex = 1 : length(fid)
     caTracesFileName = getFilenames(fid{expIndex},'expcond',expCond{expIndex},'fileType','catraces','caTraceType',cellFinderMethod,'dir',options.dir);
     load(caTracesFileName,'fluorescence');
%      if strcmp(cellFinderMethod,'NMF')
%         load([caTracesFileName '_EPSelect'],'A');
%     elseif strcmp(cellFinderMethod,'MO')
%         load([caTracesFileName '_IMOpenSelect'],'A','fluorescence');
%         A=fluorescence; % num cells in fluorescence is <= A because of size cutoff
%     elseif strcmp(cellFinderMethod,'CCEyes')
%         load([caTracesFileName '-A'],'A');
%     end
    numPlanes = length(fluorescence);
    numPlanesV = [numPlanesV;numPlanes];
    for planeIndex = 1 : numPlanes
        if strcmp(cellFinderMethod,'NMF')
            numCellsInPlane = size(fluorescence{planeIndex},1);
        else
            numCellsInPlane = size(fluorescence{planeIndex},2);
        end
        numCells = [numCells;numCellsInPlane];
    end
end


end

