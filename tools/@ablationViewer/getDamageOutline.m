function abobj=getDamageOutline(abobj)
%damageOutFname = damageOutlineFilename(abobj.fishID);
damageOutFname = getFilenames(abobj.fishID,'expcond','damage','fileType','damageOutline');
if exist(damageOutFname,'file')==2
    load(damageOutFname);
    % set properties
    abobj.radius = damageRadius;
    abobj.offset = damageOffset;
    abobj.damageMask = damageMask;
end
end