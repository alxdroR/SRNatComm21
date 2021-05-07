function figurePDir = figurePanelPath 
if 1
   figurePDir = '/Users/alexramirez/Dropbox/Science/research/onMyPlate/zfishEyeMapping/figures/figurePanels/';
    %figurePDir = '/Users/alexramirez/Dropbox/Science/research/onMyPlate/zfishEyeMapping/text/NatureCommResubmission/rebuttal/rebutalReview/';
   %figurePDir = '/Users/alexramirez/Dropbox/Science/research/onMyPlate/zfishEyeMapping/text/NatureComm2021Resubmission/figures/paperFigs/';
else
% return the absolute file path where figure panels will be printed
thisFileName = mfilename;
fpath=fileparts(which(thisFileName));
 
figureDir = [fpath(1:end-4) 'figures'];
 
if ispc
    dirSep = '\';
else
    dirSep = '/';
end
figurePDir = [fpath(1:end-4) 'figures' dirSep 'figurePanels' dirSep];
 
% create the folders if they do not exist 
fdxist = exist(figureDir,'dir');
fpxist = exist(figurePDir,'dir');
if fdxist~=7
    mkdir(fpath(1:end-4),'figures');
    mkdir(figureDir,'figurePanels');
elseif fpxist ~= 7 
    mkdir(figureDir,'figurePanels');
end

end
