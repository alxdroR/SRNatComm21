function [imageTransformFilePath,damageTransformFilePath,damageTransformFilePathNew] = registrationTransformFilename(fid,varargin)
%medianImageFilename construct filename for saccade times structure 
% [ sFilePath ] = medianImageFilename(fid)
%   given file identifier, fid, for a specific experiment
%   medianImageFilename returns a string containing the full filename
%   where saccade times are stored.
% fid -     identifier for the experiment user is 
%           requesting information for. fid is a numeric 
%           value for imaging experiments. fid is a letter (string)
%           for experiments in which an ablation was performed
%
%  [ sFilePath ] = medianImageFilename(fid,lind)
%       Experiments in which several regions of the same animal
%  were recorded are not uniquely identified by fid.  In this case 
%  an additional integer, lind, is required.  The integer is 1 for rostral 
%  hindbrain recordings and 2 for caudal hindbrain recordings.
% 
%   [ sFilePath ] = medianImageFilename(fid,lind,expCond)
%      Ablation experiments require a specification of 
%  recording conditions as occuring before or after ablation. expCond 
%  is a string that can either be 'before' or 'after'
%
% OUTPUT:
%   sFilePath is a string containing the full filename
%   where saccade times are stored.

% coded steps:
%       - convert identification information to strings required to create path
%       - construct pathname and finally fullname


%       - convert fid to strings required to create path
if 1
lid = []; expCond = [];
if length(varargin)>0
    lid = varargin{1};
    if length(varargin)>1
        expCond = varargin{2};
        if strcmp(expCond,'after')
            error('After images are not registered to the reference brain...only before images');
        end
    end
    
end
    [~,rootPath] = rootDirectories;
damagefilename = [fid '-damageCP.mat'];
imagefilename = [num2str(fid) '-' num2str(lid) '-caImageCP.mat'];

damageTransformFilePath = [rootPath '/' damagefilename];
%damageTransformFilePathNew = [rootPath '/' damagefilename];
imageTransformFilePath = [rootPath '/' imagefilename];

else 


if ischar(fid)
 expCond = 'before';
end

[~,~,loc,~,folder,pathAdd] = filePaths(fid,lid,expCond);

% construct path name for different scenarios 
if ~isempty(pathAdd)
   procPath = [folder pathAdd '/']; 
else
   procPath = [folder ];
end

filename = ['talk_manual_offset.mat'];
% full filename for 
imageTransformFilePath = [procPath filename];
damageTransformFilePath = [folder(1:end-7) 'damage/' filename];

 [~,savepath] = rootDirectories;
damageTransformFilePathNew = [savepath '\' num2str(fid) '-' num2str(lid) '-caImageCP.mat'];
end

end

