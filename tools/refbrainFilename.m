function [sFilePath] = refbrainFilename
% separate file from getFilenames for historical reasons.  If I had a fast
% way to find and replace across (refbrainFilename) with
% getFilenames([],'fileType','refBrain') I would get rid of this function
% adr - June 13, 2015

sFilePath = getFilenames([],'fileType','refBrain');
end

