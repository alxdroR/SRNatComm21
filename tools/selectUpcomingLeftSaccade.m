function upcomingISIs = selectUpcomingLeftSaccade(saccadeDirectionVector,ISIInFigure)
% upcomingISIs = selectUpcomingSaccade(saccadeDirectionVector,ISIInFigure)

if ~isempty(saccadeDirectionVector)
    upcomingISIs = ISIInFigure(saccadeDirectionVector(2:end),1);
else
    upcomingISIs = [];
end

end

