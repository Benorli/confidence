function [spikeTrials] = isSpikeTrial(spikeTimes, spike2TrialStart)
% ISSPIKETRIAL determine if a spike occured in each trial. The spikeTimes 
% and spike2TrialStart must be synchronised (in the same time).
%
%   [spikeTrials] = isSpikeTrial(spikeTimes, spike2TrialStart) takes a
%   column vector of spike times (spikeTimes), and a column vector of trial 
%   start times (spike2TrialStart). The function returns a binary vector, 
%   with each element representing a trial, 0 for no spikes in the trial 1 
%   for spikes in the trial.

% validation funs
validateattributes(spikeTimes, {'numeric'}, {'nonempty', 'column'});
validateattributes(spike2TrialStart, {'numeric'}, {'nonempty', 'column'});


spikeTrials = spike2TrialStart > spikeTimes(1) &...
                spike2TrialStart < spikeTimes(end);
            
end 
