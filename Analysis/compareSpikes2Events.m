function [spikeTimesFromEvent, eventIdx] = compareSpikes2Events(varargin)
% COMPARESPIKES2EVENTS Takes a time window, surrounding each event and
% returns each spike time within the window relative to the respective
% event. Works well with histcounts and gramm.
%
%   [spikeTimesFromEvent] = compareSpikes2Events(spikeTimes, eventTimes) 
%       takes a vector of spike times (ms) and event times (ms). It then
%       takes a window of time before and after the event. Each spike which
%       falls within that window is given a time relative to that event.
%       Optionally returns the event index of each spike.
%        
%   Name Value Arguments
%   Previous     = The amount of time (ms) before the event to include.
%   Post         = The amount of time (ms) after the event to include. 

%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % define defaults
    prev = 2500; % in ms
    post = 2500; % in ms
    
    % validation functions
    valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
        {'nonempty', 'column'});
    valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
        {'nonempty', 'scalar'});
    
    addRequired(p, 'spikeTimes', valNumColNonEmpty);
    addRequired(p, 'eventTimes', valNumColNonEmpty);
    addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
    addParameter(p, 'Post', post, valNumScalarNonEmpty);
    
    parse(p, varargin{:});
    
    % unpack parser and convert units   
    spikeTimes = p.Results.spikeTimes * 1000; % convert to ms
    eventTimes = p.Results.eventTimes * 1000; % convert to ms
    prev = p.Results.Previous;
    post = p.Results.Post;
    
    clear p
    
%% Iterate through events, returning spike times in window

occurringEvents = find(~isnan(eventTimes))';
assert(~isempty(occurringEvents), ['No events occured, eventTimes ',...
    'contained only NaNs'])
nEventsOccured = length(occurringEvents);
    
spikeTimesFromEvent = cell(nEventsOccured, 1);
eventIdx = cell(nEventsOccured, 1);

for i = 1:nEventsOccured
    
    tempSpikes = spikeTimes;
    tempSpikes = tempSpikes - eventTimes(occurringEvents(i));
    spikeTimesFromEvent{i} = tempSpikes(tempSpikes >= -prev &...
        tempSpikes <= post);
    eventIdx{i} = repmat(occurringEvents(i),...
        length(spikeTimesFromEvent{i}), 1);

end

assert(~isempty(spikeTimesFromEvent), ['No spikes found in any trials. '....
    'Please check 1) spike times vector is not empty, 2) You remembered'...
    ' to add the trial start time stamp to the event_times 3) The'...
    ' synchronisation was effective 4) The time window is large enough'])

spikeTimesFromEvent = cell2mat(spikeTimesFromEvent);
eventIdx = cell2mat(eventIdx);

end
