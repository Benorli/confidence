function [spikeTrials] = findSpikeTrials(spikeTimes, spike2TrialStart)
% FINDSPIKETRIAL Find the index of all trials in which a spike occured. The
% spikeTimes and spike2TrialStart must be synchronised (in the same time).
%
%   [spikeTrials] = findSpikeTrial(spikeTimes, spike2TrialStart) takes a
%   column vector of spike times (spikeTimes), and a column vector of trial 
%   start times (spike2TrialStart). The function returns a vector of trial
%   indexes, each index for a trial in which spike occured.

% validation funs
validateattributes(spikeTimes, {'numeric'}, {'nonempty', 'column'});
validateattributes(spike2TrialStart, {'numeric'}, {'nonempty', 'column'});

isSpikeTrial = spike2TrialStart > spikeTimes(1) &...
                spike2TrialStart < spikeTimes(end);
spikeTrials = find(isSpikeTrial);

end
