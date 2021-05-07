function [oldOut1,oldOut2,varargout] = rootDirectories
% [~,~,fileDirs] = rootDirectories - file paths of data used throughout code for loading and saving
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

dataDir = '/Users/alexramirez/Documents/SRNatComm21Data/';

% Z Brain mask database
fileDirs.ZBrainMasks = [dataDir 'ZBrainMaskDatabase.mat'];

% Z Brain 
fileDirs.ZBrain = [dataDir 'registration/Elavl3-H2BRFP.tif'];

% EYE POSITION (ANGLE OF ELLIPSE FIT TO CONTRAST-THRESHOLDED CONTRAST IMAGES OF ZEBRAFISH; fileType 'eye' in getFilenames)
fileDirs.eyePosition = [dataDir 'analyzedBehaviorAndImaging/behavior10to20Hz/'];

% TIME-AVERAGE IMAGES
fileDirs.avgImgsAllPlanes = [dataDir 'avgImages/'];

% REGISTRATION RELATED FILES
% metadata 
fileDirs.registration.createPreRegShiftScanStru = [dataDir 'registration/'];

% landmarks for creating registration transforms
fileDirs.registration.landmarks = [dataDir 'registration/landmarks/'];
fileDirs.singleCell.registration.landmarks = [dataDir 'registration/singleCellAbl/landmarks/'];
fileDirs.coarseAbl.registration.landmarks = [dataDir 'registration/coarseAblDmgRegistration/landmarks/'];

% locations of brains that were registered to
fileDirs.twoPBridgeBrain = [dataDir 'registration/rf2March2019ImgOrientation.tif'];
fileDirs.singleCell.ablDamage = [dataDir 'singleCellAvgStacks/avgStacks/'];

% coarse ablations
fileDirs.coarseAbl.damgeOutlines = [dataDir 'avgImages/coarseAblOutlines/'];

% CALCIUM TIMESERIES EXTRACTED FROM CALCIUM VIDEOS WITHIN FOOTPRINTS [fileType 'catraces' with various settings to caTraceType in
% getFilenames]
fileDirs.caTimeseries = [dataDir 'analyzedBehaviorAndImaging/CaTracesAndFootprints/'];

% MISC ANALYSES ------
fileDirs.sta = [dataDir 'analyzedBehaviorAndImaging/']; % createSTAs.m
fileDirs.ccTimeBeforeSaccade = [dataDir 'analyzedBehaviorAndImaging/'];
fileDirs.maps = [dataDir 'analyzedBehaviorAndImaging/maps/'];
fileDirs.phiMapColorLUT = [dataDir 'analyzedBehaviorAndImaging/maps/STADisplayGradient.tif'];
fileDirs.NMFMOCmp = [dataDir 'analyzedBehaviorAndImaging/CaTracesAndFootprints/'];
fileDirs.coarseAblCC = [dataDir 'analyzedBehaviorAndImaging/'];
fileDirs.scAblCVsTfd =  [dataDir 'analyzedBehaviorAndImaging/'];
fileDirs.coarseAbl.invTauEffect = [dataDir 'analyzedBehaviorAndImaging/'];
fileDirs.registration.demoLandmarks =[dataDir 'registration/landmarks/demonstrateImgRegistration-cpdemopoints.mat'];  % special points for demonstration purposes

% odd output is due to historical reasons
oldOut1 = [];
oldOut2 = [];
varargout{1} = fileDirs;
end

