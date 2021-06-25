function [spikeTimesFromEvent] = compareSpikes2EventsMex(varargin)
% COMPARESPIKES2EVENTS Takes a time window, surrounding each event and
% returns each spike time within the window relative to the respective
% event. Works well with histcounts and gramm stat_bin.
%
%   [spikeTimesFromEvent] = compareSpikes2EventsMex(spikeTimes, eventTimes)
%       takes a vector of spike times (ms) and event times (ms). It then
%       takes a window of time before and after the event. If given trial
%       start times it will also limit spikes found to within that range
%       Spike times are given time relative to the event.
%
%   Name Value Arguments
%   Previous         = The amount of time (ms) before the event to include.
%   Post             = The amount of time (ms) after the event to include.
%   WrapOutputInCell = Wrap each output into a cell, particularly useful
%                      for running with splitapply, to bin in groups.
%   TrialLimit       = An index of trial Limit times, same length as event times (s)
%
%% Parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
prev = 2500; % in ms
post = 2500; % in ms
defcellWrap = false;
defTrialLimits = [];

% validation functions
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar'});
valBinary = @(x) validateattributes(x, {'numeric', 'logical'},...
    {'nonempty', 'scalar', 'binary'});
valTrialLimits = @(x) validateattributes(x, {'numeric'},...
    {'nonempty','size',[length(varargin{2}) 1]});

addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNumColNonEmpty);
addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
addParameter(p, 'Post', post, valNumScalarNonEmpty);
addParameter(p, 'WrapOutputInCell', defcellWrap, valBinary);
addParameter(p, 'TrialLimits', defTrialLimits, valTrialLimits)

parse(p, varargin{:});

% unpack parser and convert units
spikeTimes  = p.Results.spikeTimes * 1000; % convert to ms
eventTimes  = p.Results.eventTimes * 1000; % convert to ms
trialLimits = p.Results.TrialLimits * 1000; % convert to ms
cellWrap    = p.Results.WrapOutputInCell;
prev        = p.Results.Previous;
post        = p.Results.Post;

% if trial limits not provided use psth cutoff
if isempty(trialLimits)
    trialLimits = eventTimes - prev./1000;
end

clear p

%% Iterate through events, returning spike times in window

% Sort eventTimes for speed
[sortedEventTimes, eventIdx] = sort(eventTimes,'ascend');
sortedTrialLimits = trialLimits(eventIdx);

occurringEvents = find(~isnan(sortedEventTimes))';
assert(~isempty(occurringEvents), ['No events occured, eventTimes ',...
    'contained only NaNs'])
nEvents = length(eventTimes);
nEventsOccured = length(occurringEvents);

spikeTimesFromEvent = cell(nEvents, 1);

% remove spikes outside our event range - can speed things up if there are
% lots of spikes
spikeTimes(spikeTimes < min(eventTimes)-prev | ... 
       spikeTimes > max(eventTimes)+post) = [];
                
for i = 1:nEventsOccured        
    % Check if the trial start provided is within the window
    if trialLimits(i) > eventTimes(i)
        prevLimit = prev;
        postLimit = min(post, sortedTrialLimits(i) - sortedEventTimes(i));
    else
        prevLimit = min(prev, sortedEventTimes(i) - sortedTrialLimits(i));
        postLimit = post;
    end
                                              
    tempSpikes = spikeTimes - sortedEventTimes(i);
    spikeTimesFromEvent{eventIdx(i)} = tempSpikes(tempSpikes >= -prevLimit &...
        tempSpikes <= postLimit);    
    spikeTimes(tempSpikes < -prev) = []; % remove unneccessary spikes
end

assert(~isempty(spikeTimesFromEvent), ['No spikes found in any trials. '....
    'Please check 1) spike times vector is not empty, 2) You remembered'...
    ' to add the trial start time stamp to the event_times 3) The'...
    ' synchronisation was effective 4) The time window is large enough'])

if cellWrap == true
    spikeTimesFromEvent = {spikeTimesFromEvent};
end
    

end
