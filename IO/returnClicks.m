function [clickTrain] = returnClicks(clickTrain, samplingDuration)
% return the number of clicks for a samplingDuration

for j = 1:length(clickTrain)
clickTrain{j} = clickTrain{j}(clickTrain{j} <= samplingDuration(j));

end