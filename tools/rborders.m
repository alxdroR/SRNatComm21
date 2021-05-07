function [rbndries,rspacing,regions,mcl] = rborders(varargin)
% the center of r4 is taken as the location of the Mauthner cell
% the center of r5 and r6 is taken as the location of the abducens nuclei 

% boundaries for r2, r3, and r7 are approximated by calculating the distance between r4 and r5 and 
% using equal spacing. r3 is actually taken as 80% of the spacing of other
% regions

options = struct('display','off','refbrain',[]);
options = parseNameValueoptions(options,varargin{:});

% mauthner cell location
%mcl = [ [536,384,37]; [546,597,37]];
mcl = [ [536,384,35];[536,384,36];[536,384,37];[536,384,38];[522,449,39];[522,449,40]; ];

% location of what looks like neighboring Mi2 cell in r5
mi2 = [591,592,37];

% location of what looks like rostral and caudal abducens nuclei
%rabd = [[623,398,53];[629,556,53]];
%cabd = [[716,380,53];[720,561,53]];

rabd = [[629,556,53];[625,555,54];[625,555,55]];
cabd = [[720,561,53];[720,568,54];[720,568,55]];


r6cntr =  mean(cabd(:,1));
r5cntr = mean(rabd(:,1));
r4cntr = mean(mcl(:,1));
rspacing = mean(diff([r4cntr,r5cntr,r6cntr]));
%rspacing = r5cntr(1,1) - r4cntr;

r34bndr = r4cntr-rspacing/2;
rbndries = [r34bndr-rspacing-0.8*rspacing,r34bndr-0.8*rspacing,r34bndr,r34bndr+rspacing,r34bndr+2*rspacing,r34bndr+3*rspacing,r34bndr+4*rspacing];

regions = {'r2','r3','r4','r5','r6','r7','r8'};

if strcmp(options.display,'on') && ~isempty(options.refbrain)
    rbndries = [-Inf rbndries Inf];
    textLocations = [rbndries(2)/2 diff(rbndries(2:end-1))/2 + rbndries(2:end-2) rbndries(end-1)+(1285-rbndries(end-1))/2];
    rctext = {'r1' regions{:}};


    for i=1:size(mcl,1)
        figure;
        imagesc(options.refbrain(:,:,mcl(i,3))); colormap('gray'); hold on;
        plot(mcl(i,1),mcl(i,2),'ro')
        for j=1:length(rbndries)
            plot([1 1]*rbndries(j),[100 1000],'y')
        end
    end
    for i=1:size(rabd,1)
        figure;
        imagesc(options.refbrain(:,:,rabd(i,3))); colormap('gray'); hold on;
        plot(rabd(i,1),rabd(i,2),'ro');
        plot(cabd(i,1),cabd(i,2),'ro');
        for j=1:length(rbndries)
            plot([1 1]*rbndries(j),[100 1000],'y')
        end
        for ind=2:length(rbndries)
            text(textLocations(ind-1),100,rctext{ind-1},'FontName','Arial','FontSize',12,'Color','y')
        end
    end
    
%     subplot(2,1,1)
%     imagesc(options.refbrain(:,:,mcl(1,3))); colormap('gray'); hold on;
%     plot(mcl(1,1),mcl(1,2),'ro')
%     subplot(2,1,2)
%     imagesc(options.refbrain(:,:,rabd(1,3)));  hold on;
%     plot(rabd(1,1),rabd(1,2),'ro');
%     plot(cabd(1,1),cabd(1,2),'ro');    
end

end

