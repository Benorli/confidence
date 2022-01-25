function trialEventTimes = getMainTrialEventTimes(T, trialIdx)
% GETMAINTRIALEVENTTIMES return the Sample start, sample end, waiting time 
% start, waiting time end of trials from a table.
%
% trialEventTimes = getMainTrialEventTimes(T, trialIdx) where T is a
%   behaviour table as defined by trials2table and trialIdx are trial 
%   indexes

validateattributes(T, {'table'}, {'nonempty'});
validateattributes(trialIdx, {'numeric', 'logical'}, {'nonempty', 'column'});

sampleStrt = T.ephysTrialStartTime(trialIdx) + T.sampleStartTime(trialIdx);
sampleEnds = T.ephysTrialStartTime(trialIdx) + T.sampleStartTime(trialIdx)...
     + T.samplingDuration(trialIdx);
wtingTStrt = T.ephysTrialStartTime(trialIdx) + T.waitingStartTime(trialIdx);
wtingTEnds = T.ephysTrialStartTime(trialIdx) + T.trialEndTime(trialIdx);


trialEventTimes = [sampleStrt; sampleEnds; wtingTStrt; wtingTEnds];
end