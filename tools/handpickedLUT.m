function [cm,colorBinValue]=handpickedLUT(varargin)
options = struct('printLUTCSVFile',false,'saveDir',[],'fileName','handpickedLUT.csv','displayColormap',false,'ROYGBIV',[]);
options = parseNameValueoptions(options,varargin{:});
% [cm,colorBinValue]=handpickedLUT
% load and combine LUTs to create the final color scheme used for plotting the continuum of fixation-saccade responses
% adr
% ea lab
% weill cornell medicine 
% 10/2012 - 2020

totalNumColors = 256;
valuePerColor = (360/(totalNumColors-1)); % discretization. There are 360 values for phi and 256 colors in the LUT (but only 255 for coloring the display since 1 is used for background)
% my decisions about where the OFF and ON colors should meet up is based on
% figure 3C which moves from -180 to 180. I also give the values that are
% displayed in ImageJ in parentheses

[~,~,fileDirs] = rootDirectories;
if ~isempty(options.ROYGBIV)
    dispGrad = options.ROYGBIV;
else
    dispGrad = imread([fileDirs.maps 'STADisplayGradient'],'tif');
end
if options.printLUTCSVFile
    if isempty(options.saveDir)
        options.saveDir = fileDirs.maps;
    end
end
row2use = 40; % could be any integer from 2-100.

% split the .tif file into specific sections
% pattern is linspace(colorStart,colorEnd,#bins)
% #bins formula is given by 
% nbins/255 = (angle size)/360
% or nbins = (255/360)*(angle size)
% or nbins = (angle size)/valuePerColor

numRedBins = round(abs(-90 - -45)/valuePerColor);
m90m15Reds = squeeze(dispGrad(row2use,round(linspace(1,110,numRedBins)),:));
numOrangeBins =  ceil((30 - -45)/valuePerColor);
m15p45Orange=squeeze(dispGrad(row2use,round(linspace(150,504,numOrangeBins)),:)); 
numYellowBins1 = 0;
%p90p90Yellow = squeeze(dispGrad(row2use,round(linspace(504,580,numYellowBins1)),:)); 
p90p90Yellow = [];
numYellowBins2 = ceil((90-30)/valuePerColor);
p45p90Yellow = squeeze(dispGrad(row2use,round(linspace(580,685,numYellowBins2)),:));
numGreenBins = ceil((150-90)/valuePerColor);
p90p150Green = squeeze(dispGrad(row2use,round(linspace(685,840,numGreenBins)),:));
numBlueBins1 = ceil((180-150)/valuePerColor);
p150p180Blue=squeeze(dispGrad(row2use,round(linspace(840,890,numBlueBins1)),:)); 
numBlueBins2 = ceil((179-150)/valuePerColor);
m180m150Blue=squeeze(dispGrad(row2use,round(linspace(890,1009,numBlueBins2)),:));
numRemainingBins = 256 - (numRedBins + numOrangeBins + numYellowBins1 + numYellowBins2 + numGreenBins + numBlueBins1 + numBlueBins2);
m150m90IndVio=squeeze(dispGrad(row2use,round(linspace(1009,1174,numRemainingBins)),:)); 

if options.printLUTCSVFile
    % convert to order that files were saved in avgZBrainMakeProjections.m for 
    % display in imageJ
    % : 90-(90+360) which is equal to 
    % : 90-180; -180:90 
    
   
   cm = [p90p150Green;p150p180Blue;m180m150Blue;m150m90IndVio;m90m15Reds;m15p45Orange;p45p90Yellow;p90p90Yellow];
   cm(1,:) = [0 0 0];
   csvwrite([options.saveDir options.fileName],[(0:255)' cm]);
end

if options.displayColormap
    % this re-ordering just ensures that the colorbar follows the same pattern as 
    % what was plotted in figure 3C
    % -90 - 180; -180 - -90 
    
    cm = [m90m15Reds;m15p45Orange;p90p90Yellow;p45p90Yellow;p90p150Green;p150p180Blue;m180m150Blue;m150m90IndVio];
    cm = double(cm)/256;
    
    figure;
    subplot(121)
    colorBinValue  = round([0:255]*valuePerColor)+90; % this is the range used in ImageJ. 90-180 is correct. Subtract 360 to interpret the other values
    imagesc(1,colorBinValue,[0:255]');colormap(cm)
    subplot(122)
    % values need to be (incorrectly) labelled -180 to 180 for legacy, compatability reasons
    % with other code
    colorBinValue  = round([0:255]*valuePerColor)-180;
    imagesc(1,colorBinValue,[0:255]');colormap(cm)
end

% use the same output sent to ImageJ 
cm = [p90p150Green;p150p180Blue;m180m150Blue;m150m90IndVio;m90m15Reds;m15p45Orange;p45p90Yellow;p90p90Yellow];
cm(1,:) = [0 0 0];
cm = double(cm)/256;
colorBinValue  = [-8000,(0:254).*valuePerColor+90];
colorBinValue(66:end) = colorBinValue(66:end)-360;
end