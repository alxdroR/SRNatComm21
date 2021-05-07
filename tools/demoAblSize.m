function demoAblSize()
abobj = ablationViewer('fishid','fBB','refsize',[1084 1476 76],'loadImages',true);
figure;imagesc(abobj.images.channel{1}(:,:,3));
q = abobj.offset;
t = linspace(0,2*pi);
hold on;

rawobj = rawData('fishid','fBB','fileNumber',3);
largeScale = rawobj.micron2pixel(50);
rcpix2micron = largeScale/50;

r = (30/2)*rcpix2micron; % convert 30 micron diameter into a radius in pixels 
plot(q(1,1)+cos(t)*r(1),q(1,2)+sin(t)*r(1),'r')
plot(q(2,1)+cos(t)*r(1),q(2,2)+sin(t)*r(1),'r')

% notice that 30 micron diameter circle covers damage. Also notice that
% damage spans rougly planes 1-2-3-4 with 20 micron spacing between planes
implay(abobj.images.channel{1})