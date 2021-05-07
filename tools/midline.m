function [midlineMean,midlineSTD] = midline(varargin)
% the center of r4 is taken as the location of the Mauthner cell
% the center of r5 and r6 is taken as the location of the abducens nuclei 

% boundaries for r2, r3, and r7 are approximated by calculating the distance between r4 and r5 and 
% using equal spacing. r3 is actually taken as 80% of the spacing of other
% regions

options = struct('display','off','refbrain',[]);
options = parseNameValueoptions(options,varargin{:});

midlineSamples = [[570,479,30];[274,492,20];[941,482,10];[757,489,40]];
midlineMean = mean(midlineSamples,1);
midlineSTD = std(midlineSamples,[],1);


if strcmp(options.display,'on') && ~isempty(options.refbrain)
    for i=1:size(midlineSamples,1)
        figure;
        imagesc(options.refbrain(:,:,midlineSamples(i,3))); colormap('gray'); hold on;
        plot([1 1400],[1 1]*midlineMean(2),'r')
        plot([1 1400],[1 1]*(midlineMean(2)+midlineSTD(2)),'r--')
         plot([1 1400],[1 1]*(midlineMean(2)-midlineSTD(2)),'r--')
        %plot([1 1400],[1 1]*midlineSamples(i,2),'y--')
        plot(midlineSamples(i,1),midlineSamples(i,2),'r.')
    end
   end

end

