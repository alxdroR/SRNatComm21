function titleStr = generateTitle(caobj)
% titleStr = generateTitle(caobj)
% Method that creates the following string usually
% used as a title:
% titleStr = ['fishID-' num2str(caobj.fishID) '-expCond-' caobj.expCond];
titleStr = ['fishID-' num2str(caobj.fishID) '-expCond-' caobj.expCond];
end