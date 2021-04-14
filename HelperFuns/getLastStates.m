function [lastStates] = getLastStates(SessionData, trials)
% GET_LAST_STATES
% Return the last Bpod state of a selection of trials
% 
%   SYNTAX
%   [last_states] = get_last_states(SessionData, trials)
%   
%   DESCRIPTION
%   [last_states] = get_last_states(SessionData, trials) takes a
%   SessionData struct, as output from Bpod and a double trials, 
%   containing a vector of trial numbers to include. Returns last_states, 
%   a cell array giving the name of the last occuring state per trial. 

validateattributes(SessionData, {'struct'}, {})
validateattributes(trials, {'numeric'}, {})

lastStates = arrayfun(@(x) getLastState(SessionData, x), trials);
lastStates = lastStates(:);

end


function [lastState] = getLastState(SessionData, trial)
% GET_LAST_STATE
% Return the last Bpod state of a specific trial
% 
%   SYNTAX
%   [last_states] = get_last_state(SessionData, trial)
%   
%   DESCRIPTION
%   [last_state] = get_last_state(SessionData, trial) takes a
%   SessionData struct, as output from Bpod and an integer trial, 
%   containing a trial numbers to include. Returns last_states, 
%   a cell array giving the name of the last occuring state in trial. 

validateattributes(SessionData, {'struct'}, {})
validateattributes(trial, {'numeric'}, {'size', [1,1]})

[~, maxIdx] = max(structfun(@(x) max(x, [], 'all'),...
    SessionData.RawEvents.Trial{trial}.States));
allFieldnames = fieldnames(SessionData.RawEvents.Trial{trial}.States);
lastState = allFieldnames(maxIdx);

end