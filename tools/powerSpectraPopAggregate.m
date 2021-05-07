function [PSDALL,F,varargout]=powerSpectraPopAggregate(varargin)
% powerSpectraPopAggregate - compute power spectral data over all eye movements recorded simultaneously with calcium eye movements 
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020


[fid,expCond] = listAnimalsWithImaging;
eyeLabels = {'left','right'};


% Method 1 --- loop over eye traces, load, compute power spectra on
% segment, calculate a running average with STD
dF = 0.005;
F = 0:dF:2;
PSDALL = [];
ID = [];
for expIndex = 1:length(fid)
    eyeobj=eyeData('fishid',fid{expIndex},'locationid',1,'expcond',expCond{expIndex});
    eyeobj = eyeobj.saccadeDetection;
    numPlanes = length(eyeobj.position);
    for planeIndex = 1 : numPlanes
        for eyeIndex = 1 :1
            E = eyeobj.centerEyesMethod('planeIndex',planeIndex,'eye',eyeLabels{eyeIndex});
            time = eyeobj.time{planeIndex}(:,eyeIndex);
            dt = median(diff(time));
            fs = 1/dt;
            pxxEYE=pwelch(E,round(length(E)/2),5,F,fs);
            PSDALL = [PSDALL;pxxEYE];
            ID = [ID;[expIndex planeIndex]];
        end
    end
end
varargout{1} = ID;




