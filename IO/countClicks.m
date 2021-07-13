function [nClicks] = countClicks(clickTrain, samplingDuration)
% return the number of clicks for a samplingDuration

for j = 1:length(clickTrain)
    nClicks(j) = sum(clickTrain{j} <= samplingDuration(j));
end

end