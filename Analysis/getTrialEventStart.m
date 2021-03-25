function [trialEventTimes] = getTrialEventStart(SessionData, event)
% GETTRIALEVENTSTART
%   Get the first event time, for the specified event, in every trial.
%   
% SYNTAX
%   trialEventTimes = getTrialEventStart(SessionData, event) takes a 
%       SessionData struct, and event, a char containing the name of a 
%       specific Bpod event. It returnd a vector of times. Each time 
%       represents the time from the Bpod trial start until the first time
%       the chosen event occurs. 

validateattributes(SessionData, {'struct'}, {})
validateattributes(event, {'char'}, {})

[trialEventTimes] = cellfun(@(x) getSingleTrialEventStart(x, event),...
    SessionData.RawEvents.Trial);
trialEventTimes = trialEventTimes(:); % force column

end


function [trial_event_time] = getSingleTrialEventStart(RawTrialData, event)
% A single iteration of GETTRIALEVENTSTART

    trial_event_time = RawTrialData.States.(event);
    trial_event_time = trial_event_time(1);

end

