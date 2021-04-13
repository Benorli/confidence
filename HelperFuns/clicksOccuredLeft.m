function [leftClicks] = clicksOccuredLeft(fastClicks, slowClicks, samplingDuration, trialType)
% return the click times of clicks which occured on the left side

validateattributes(fastClicks, {'cell'}, {'nonempty'});
validateattributes(slowClicks, {'cell'}, {'nonempty'});
validateattributes(samplingDuration, {'double'}, {'nonempty'});
validateattributes(trialType, {'double'}, {'nonempty'});


leftClicks = cell(size(fastClicks)); 

for i = 1:length(fastClicks)
    
    switch trialType(i)
        case 1
            tempClicks = fastClicks{i};
            tempClicks(tempClicks>samplingDuration(i)) = [];
            leftClicks{i} = tempClicks;
        case 2
            tempClicks = slowClicks{i};
            tempClicks(tempClicks>samplingDuration(i)) = [];
            leftClicks{i} = tempClicks;
    end
    
end


leftClicks = leftClicks(:);

end