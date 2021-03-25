function [trialEventTimes] = getTrialEventEnd(SessionData, event)
% GETTRIALEVENTEND
%   Get the last event time, for the specified event, in every trial.
%   
% SYNTAX
%   trialEventTimes = getTrialEventEnd(SessionData, event) takes a 
%       SessionData struct, and event, a char containing the name of a 
%       specific Bpod event. It returnd a vector of times. Each time 
%       represents the time from the Bpod trial start until the last time
%       the chosen event occurs. 

validateattributes(SessionData, {'struct'}, {})
validateattributes(event, {'char'}, {})

[trialEventTimes] = cellfun(@(x) getSingleTrialEventEnd(x, event),...
    SessionData.RawEvents.Trial);
trialEventTimes = trialEventTimes(:); % force column

end


function [trial_event_time] = getSingleTrialEventEnd(RawTrialData, event)
% A single iteration of GETTRIALEVENTEND

    trial_event_time = RawTrialData.States.(event);
    trial_event_time = trial_event_time(end);

end

