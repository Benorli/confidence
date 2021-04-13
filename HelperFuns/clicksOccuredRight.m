function [rightClicks] = clicksOccuredRight(fastClicks, slowClicks, samplingDuration, trialType)
% return the click times of clicks which occured on the right side

validateattributes(fastClicks, {'cell'}, {'nonempty'});
validateattributes(slowClicks, {'cell'}, {'nonempty'});
validateattributes(samplingDuration, {'double'}, {'nonempty'});
validateattributes(trialType, {'double'}, {'nonempty'});


rightClicks = cell(size(fastClicks)); 

for i = 1:length(fastClicks)
    
    switch trialType(i)
        case 2
            tempClicks = fastClicks{i};
            tempClicks(tempClicks>samplingDuration(i)) = [];
            rightClicks{i} = tempClicks;
        case 1
            tempClicks = slowClicks{i};
            tempClicks(tempClicks>samplingDuration(i)) = [];
            rightClicks{i} = tempClicks;
    end
    
end

rightClicks = rightClicks(:);

end