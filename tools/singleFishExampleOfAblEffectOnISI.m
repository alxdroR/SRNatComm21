function singleFishExampleOfAblEffectOnISI()
% singleFishExampleOfAblEffectOnISI - exemplar showing effect of cluster
% ablations in rhombomere 2-3 on left eye position traces
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 202x

% load 
fishID = 'fM';
expCond = 'A';
eyeObjA = eyeData('fishid',fishID,'expcond',expCond);
expCond = 'B';
eyeObjB = eyeData('fishid',fishID,'expcond',expCond);

% format data to plot into a sharable format
leftEyeIndex = 1; rightEyeIndex = 2;examplePlane = 1;
EBefore = eyeObjB.centerEyesMethod('planeIndex',examplePlane);
data.before.lefteye.time = eyeObjB.time{examplePlane}(:,leftEyeIndex);
data.before.lefteye.angle = EBefore(:,leftEyeIndex);
data.before.righteye.time = eyeObjB.time{examplePlane}(:,rightEyeIndex);
data.before.righteye.angle = EBefore(:,rightEyeIndex);
EAfter = eyeObjA.centerEyesMethod('planeIndex',examplePlane);
data.after.lefteye.time = eyeObjA.time{examplePlane}(:,leftEyeIndex);
data.after.lefteye.angle = EAfter(:,leftEyeIndex);
data.after.righteye.time = eyeObjA.time{examplePlane}(:,rightEyeIndex);
data.after.righteye.angle = EAfter(:,rightEyeIndex);

% plot
options = struct('colorbefore',[1 1 1]*0.3,'colorafter',[1 [1 1]*0]);
eye2draw = 'left';
durationShown = 70;
scaleBarDuration =10;
scaleWidthInDegrees = 0.75;
secondsScaleText = '';
fontname = 'Arial';
fontsize = 10;
dratio = daspect;
close(gcf);
widthInSeconds = 0.5*scaleWidthInDegrees*dratio(1)/dratio(2);
positionScaleText = '';

figure;
subplot(2,1,2)
eyeObjA.plot('plotPlane','all','color',options.colorafter,'drawEye',eye2draw,...
    'drawSaccadeTimes',false,'showNull',true,'axisHandle',{gca},'figureHandle',gcf)
hold on;ymin = -15;ymax = 20;xmin = 333;
ylim([ymin ymax]);xlim([0 durationShown]+xmin)
axis off

subplot(2,1,1)
eyeObjB.plot('plotPlane','all','color',options.colorbefore,'drawEye',eye2draw,...
    'drawSaccadeTimes',false,'showNull',true,'axisHandle',{gca},'figureHandle',gcf)
hold on;ymin = -15;ymax = 20;xmin = 180;
ylim([ymin ymax]);xlim([0 durationShown]+xmin)

% add scale bar
rectangle('Position',[xmin+5 ymin+2 scaleBarDuration scaleWidthInDegrees],'FaceColor','k')
text(xmin+5,ymin,secondsScaleText,'FontName',fontname,'FontSize',fontsize);
% position scalebar
rectangle('Position',[xmin+1.5 0 widthInSeconds 10],'FaceColor','k')
ht = text(xmin,0,positionScaleText,'FontName',fontname,'FontSize',fontsize);
set(ht,'Rotation',90)
axis off
set(gcf,'PaperPosition',[0 0 2.0 2.2])

% print and save 
thisFileName = mfilename;
printAndSave(thisFileName,'data',data)
