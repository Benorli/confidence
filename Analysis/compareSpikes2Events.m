function [spikeTimesFromEvent] = compareSpikes2Events(varargin)
% COMPARESPIKES2EVENTS Takes a time window, surrounding each event and
% returns each spike time within the window relative to the respective
% event. Works well with histcounts and gramm stat_bin.
%
%   [spikeTimesFromEvent] = compareSpikes2Events(spikeTimes, eventTimes)
%       takes a vector of spike times (ms) and event times (ms). It then
%       takes a window of time before and after the event. Each spike which
%       falls within that window is given a time relative to that event.
%       Optionally returns the event index of each spike.
%
%   Name Value Arguments
%   Previous         = The amount of time (ms) before the event to include.
%   Post             = The amount of time (ms) after the event to include.
%   WrapOutputInCell = Wrap each output into a cell, particularly useful
%                      for running with splitapply, to bin in groups.

%% Parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
prev = 2500; % in ms
post = 2500; % in ms
defcellWrap = false;

% validation functions
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar'});
valBinary = @(x) validateattributes(x, {'numeric', 'logical'},...
    {'nonempty', 'scalar', 'binary'});

addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNumColNonEmpty);
addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
addParameter(p, 'Post', post, valNumScalarNonEmpty);
addParameter(p, 'WrapOutputInCell', defcellWrap, valBinary);

parse(p, varargin{:});

% unpack parser and convert units
spikeTimes = p.Results.spikeTimes * 1000; % convert to ms
eventTimes = p.Results.eventTimes * 1000; % convert to ms
cellWrap   = p.Results.WrapOutputInCell;
prev       = p.Results.Previous;
post       = p.Results.Post;

clear p

%% Iterate through events, returning spike times in window

occurringEvents = find(~isnan(eventTimes))';
assert(~isempty(occurringEvents), ['No events occured, eventTimes ',...
    'contained only NaNs'])
nEvents = length(eventTimes);
nEventsOccured = length(occurringEvents);

spikeTimesFromEvent = cell(nEvents, 1);

for i = 1:nEventsOccured
    
    tempSpikes = spikeTimes;
    tempSpikes = tempSpikes - eventTimes(occurringEvents(i));
    spikeTimesFromEvent{i} = tempSpikes(tempSpikes >= -prev &...
        tempSpikes <= post);
    
end

assert(~isempty(spikeTimesFromEvent), ['No spikes found in any trials. '....
    'Please check 1) spike times vector is not empty, 2) You remembered'...
    ' to add the trial start time stamp to the event_times 3) The'...
    ' synchronisation was effective 4) The time window is large enough'])

if cellWrap == true
    spikeTimesFromEvent = {spikeTimesFromEvent};
end
    

end
