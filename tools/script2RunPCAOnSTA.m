% script2RunPCAOnSTA - Run PCA on eye-movement responsive STAs and then
% calculate normalized coefficients
%
% adr
% ea lab
% weill cornell medicine
% 10/2012 - 2020

% select cells that pass the ANVOA test AND load STAs for all cells
loadSTAANOVACut;
deconvolve = true; pcaOnDeconv = false;
% determine the sta range that will be used in the PCA analysis
Ta = -5; Tb = 5;
[TaIndex,TbIndex]=calcSTA2Time2TimeIndex(bt,[Ta,Tb]);
[coef,score,expl,mu,lon,lat,STACAT,tauPCA,~,~,scoreNormed,~,S] = calcSTA2runPCA('filename','calcSTA2NMFDeconvOutput',...
    'timeBeforeSaccade',-5,'timeAfterSaccade',5,'selectionCriteria',STACriteria,'pc1PostSTAPos',true,'normalizeSTABeforePCA',true);

