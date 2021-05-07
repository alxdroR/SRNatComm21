function [regParameters,F2] = linearRegFilter(F,timeF,saccadeTimes,saccadeDirection,maxTimeBack,varargin)
options = struct('onlyRunBeforeSaccade',false);
options = parseNameValueoptions(options,varargin{:});

if options.onlyRunBeforeSaccade
    [STR,timeSegments,direction,absTime] = STresponses(F,saccadeTimes,saccadeDirection,timeF,'startpoint', ...
        0,'endpoint','all');
    
    regParameters=struct('leftward',cell(length(STR),1),'rightward',cell(length(STR),1),'both',cell(length(STR),1));
    for cellIndex = 1 : length(STR)
        regParameters(cellIndex).leftward = NaN(length(timeSegments{cellIndex})-1,2);
        regParameters(cellIndex).rightward = NaN(length(timeSegments{cellIndex})-1,2);
        for jj=2:length(timeSegments{cellIndex})
            timeReversal = absTime{cellIndex}{jj-1} - saccadeTimes(jj,1);
            regMatrix = [timeReversal ones(size(timeReversal))];
            
            indices2use=length(timeReversal)-(min(length(timeReversal)-1,maxTimeBack-1)):length(timeReversal);
            regMatrix = regMatrix(indices2use,:);
            if direction{cellIndex}(jj)
                regParameters(cellIndex).leftward(jj-1,:) = pinv(regMatrix)*STR{cellIndex}{jj-1}(indices2use);
            else
                regParameters(cellIndex).rightward(jj-1,:) = pinv(regMatrix)*STR{cellIndex}{jj-1}(indices2use);
            end
            regParameters(cellIndex).both(jj-1,:) = pinv(regMatrix)*STR{cellIndex}{jj-1}(indices2use);
        end
    end
else
    [T,N]=size(F);
    regParameters = zeros(2,T,N);
    F2 = zeros(T,N);
    for cellIndex = 1 : N
        dt = timeF(2,cellIndex)-timeF(1,cellIndex);
        timeReversal =(-(maxTimeBack-1):1:0)'*dt;
        
        for jj=1:T
            if jj<maxTimeBack
                fsegment = [zeros(maxTimeBack-jj,1);F(1:jj,cellIndex)];
            else
                fsegment = F(jj-(maxTimeBack-1):jj,cellIndex);
            end
            if jj==40 && cellIndex ==10
           %     keyboard
            end
            regMatrix = [timeReversal ones(size(timeReversal))];
            regParameters(:,jj,cellIndex)=pinv(regMatrix)*fsegment;
            % linear prediction of value in the next 500ms
            F2(jj,cellIndex) = 0.5*regParameters(1,jj,cellIndex) + regParameters(2,jj,cellIndex);
        end
    end
end