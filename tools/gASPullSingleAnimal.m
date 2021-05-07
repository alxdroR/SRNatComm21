function [ISIBeforeSinglAnimal,ISIAfterSinglAnimal] = gASPullSingleAnimal(behaviorStat,animalName)

BIndexL=cellfun(@(x) strcmp(x,animalName),behaviorStat.leftEye.before.animalName);
BIndexR=cellfun(@(x) strcmp(x,animalName),behaviorStat.rightEye.before.animalName);
ISIBeforeSinglAnimal = [behaviorStat.leftEye.before.ISI(BIndexL);behaviorStat.rightEye.before.ISI(BIndexR)];

AIndexL=cellfun(@(x) strcmp(x,animalName),behaviorStat.leftEye.after.animalName);
AIndexR=cellfun(@(x) strcmp(x,animalName),behaviorStat.rightEye.after.animalName);
ISIAfterSinglAnimal = [behaviorStat.leftEye.after.ISI(AIndexL);behaviorStat.rightEye.after.ISI(AIndexR)];

end

