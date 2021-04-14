function [T] = extractRawData(SessionData, T)
% EXCTRACTRAWDATA extract times from the rawdata in a SessionData struct 
% output from Bpod and add to the trial table

validateattributes(SessionData, {'struct'}, {})
validateattributes(T, {'table'}, {})

T.trialEndTime = NaN(SessionData.nTrials, 1);

punishEndStateStarts = getTrialEventStart(SessionData, 'PunishEndState')...
    - T.punishGrace;
rewardStart = getTrialEventStart(SessionData, 'Reward');
rewGraceEndTimesL = getTrialEventTimes(SessionData, 'WaitForRewardGraceL');
rewGraceEndTimesR = getTrialEventTimes(SessionData, 'WaitForRewardGraceR');

rewGraceEndTimesL = cellfun(@(x) x(end, 1), rewGraceEndTimesL);
rewGraceEndTimesR = cellfun(@(x) x(end, 1), rewGraceEndTimesR);

rewGraceIdxL = (T.correctCatchBpod | T.waitingTimeDropOut) & ...
    T.highEvidenceSideBpod == 'left';
rewGraceIdxR = (T.correctCatchBpod | T.waitingTimeDropOut) & ...
    T.highEvidenceSideBpod == 'right';

T.trialEndTime(T.rewarded) = rewardStart(T.rewarded);
T.trialEndTime(T.punishState) = punishEndStateStarts(T.punishState);
T.trialEndTime(rewGraceIdxL) = rewGraceEndTimesL(rewGraceIdxL);
T.trialEndTime(rewGraceIdxR) = rewGraceEndTimesR(rewGraceIdxR);

T.sampleStartTime  = getTrialEventStart(SessionData, 'DeliverStimulus');
T.waitingStartTime = getTrialEventEnd(SessionData, 'WaitForResponse');
T.lastState = categorical(getLastStates(SessionData, 1:SessionData.nTrials));

end