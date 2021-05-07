function [thresholdL,thresholdR] = determineThresholdLESeperate(I,varargin)
options = struct('region2initTh',[]);
options = parseNameValueoptions(options,varargin{:});
% function [thresholdL,thresholdR] = determineThresholdLESeperate(I,varargin)
% options = struct('region2initTh',[]);
% options = parseNameValueoptions(options,varargin{:});
% adr
% ea lab
% weill cornell medicine
% 10/2012 -202x

[H,W]=size(I);
% initialize threshold 
if isempty(options.region2initTh)
    thresholdL = quantile(I(:),0.1);
    thresholdR = thresholdL;
else
    thresholdL = quantile(I(options.region2initTh),0.1);
    thresholdR = thresholdL;
end
fprintf('current threshold %0.2f\n',thresholdL);

if isempty(options.region2initTh)
    verticalLine = floor(W/2);
else
    [~,x]=find(options.region2initTh);
    verticalLine = round(mean(x));
end

figure;
subplot(2,2,1);
imagesc(I);colormap('gray'); hold on;
plot([1 1]*verticalLine,[1 H],'r');
xlabel('x');ylabel('y');
xlim([1 W]);
ylim([1 H]);

subplot(2,2,2);
plot(I(:,verticalLine),1:H)
ylim([1 H]);
ylabel('y');xlabel('Intensity');
axis ij


subplot(2,2,3);
if isempty(options.region2initTh)
    histogram(I(:));
else
    histogram(I(options.region2initTh));
end
xlabel('intensity')

subplot(2,2,4);
imagesc(I<thresholdL)
title('thresholded image')

happy = false;
while ~happy
    yesOrNo = input('happy with threshold for left eye? Type y or n for Yes or No \n','s');
    switch yesOrNo
        case 'y'
            happy = true;
        case 'n'
            happy = false;
            % update threshold
            thresholdL = input('please enter threshold for left eye\n');
            subplot(2,2,4);
            imagesc(I<thresholdL)
            title('thresholded image')     
    end
end

happy = false;
while ~happy
    yesOrNo = input('happy with threshold for right eye? Type y or n for Yes or No \n','s');
    switch yesOrNo
        case 'y'
            happy = true;
        case 'n'
            happy = false;
            % update threshold
            thresholdR = input('please enter threshold for right eye\n');
            subplot(2,2,4);
            imagesc(I<thresholdR)
            title('thresholded image')     
    end
end


end

