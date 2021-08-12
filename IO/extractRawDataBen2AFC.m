function [T] = extractRawDataBen2AFC(SessionData, T)
% EXCTRACTRAWDATA extract times from the rawdata in a SessionData struct 
% output from Bpod and add to the trial table

validateattributes(SessionData, {'struct'}, {})
validateattributes(T, {'table'}, {})

% T.trialEndTime = NaN(SessionData.nTrials, 1);
nTrials = SessionData.Custom.TrialNumber(end);
T.trialEndTime = NaN(nTrials,1);

sampleStartTime  = getTrialEventStart(SessionData, 'stimulus_delivery');
T.sampleStartTime = sampleStartTime(1:nTrials);
waitingStartTime = getTrialEventEnd(SessionData, 'wait_Sin');
T.waitingStartTime = waitingStartTime(1:nTrials);
T.lastState = categorical(getLastStates(SessionData, 1:SessionData.Custom.TrialNumber(end)));

for j = 1:height(T)
    trialTimes = getTrialEventEnd(SessionData, char(T.lastState(j)));
    T.trialEndTime(j) = trialTimes(j);
end

end