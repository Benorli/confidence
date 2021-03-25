function [trialEventTimes] = getTrialEventTimes(SessionData, event)
% GETTRIALEVENTTIMES
%   Get every event time, for the specified event, in every trial.
%   
% SYNTAX
%   trialEventTimes = getTrialEventTimes(SessionData, event) takes a 
%       SessionData struct, and event, a char containing the name of a 
%       specific Bpod event. It returns an array of times. Each row 
%       represents a trial. Each time represents the time from the Bpod 
%       trial start until the last time the chosen event occurs.     

validateattributes(SessionData, {'struct'}, {})
validateattributes(event, {'char'}, {})


[trialEventTimes] = cellfun(@(x) getSingleTrialEventTimes(x, event),...
    SessionData.RawEvents.Trial, 'UniformOutput', false);
trialEventTimes = trialEventTimes(:); % force column

end


function [trial_event_time] = getSingleTrialEventTimes(RawTrialData, event)
% A single iteration of GETTRIALEVENTTIMES

    trial_event_time = RawTrialData.States.(event);
    trial_event_time = trial_event_time;

end

