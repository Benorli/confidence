function [binnedSpikes, bin, eventIdx, binWidth, binEdges] = binSpikesPerEvent(varargin)
% BINSPIKEPEREVENT Takes a time window, surrounding each event and
% returns binned spike frequencies (Hz) or counts within the window
% relative to the respective event. Works well with gramm stat_summary.
%
%   [spikeTimesFromEvent] = binSpikesPerEvent(spikeTimes, eventTimes)
%       takes a vector of spike times (ms) and event times (ms). It then
%       takes a window of time before and after the event. Each spike which
%       falls within that window is binned relative to that event and
%       Output as binnedSpikes as a frequency (Hz) or counts if specified.
%       Optionally returns the centre of each bin per bin (bin), the event
%       index of each bin (eventIdx), the width of the bin (binWidth) which
%       can be used to convert to Hz later, and the bin edges used to
%       define binning (binEdges).
%
%   Note: If trial has no spikes eventIdx == 0
%
%   Name Value Arguments
%   Previous         = The amount of time (ms) before the event to include.
%   Post             = The amount of time (ms) after the event to include.
%   BinSize          = The bin size in ms.
%   Hz               = A binary logical or numeric, if 1/true counts are 
%                      converted to Hz. Default is true.
%   WrapOutputInCell = Wrap each output into a cell, particularly useful
%                      for running with splitapply, to bin in groups.

%% Parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
defprev     = 2500; % in ms
defpost     = 2500; % in ms
defbinsize  = 100;  % in ms
defHz       = true;
defcellWrap = false;

% validation functions
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valPosScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar', 'positive'});
valIntScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar', 'integer'});
valBinary = @(x) validateattributes(x, {'numeric', 'logical'},...
    {'nonempty', 'scalar', 'binary'});

addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNumColNonEmpty);
addParameter(p, 'BinSize', defbinsize, valIntScalarNonEmpty);
addParameter(p, 'Previous', defprev, valPosScalarNonEmpty);
addParameter(p, 'Post', defpost, valPosScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinary);
addParameter(p, 'WrapOutputInCell', defcellWrap, valBinary);

parse(p, varargin{:});

% unpack parser and convert units
spikeTimes = p.Results.spikeTimes * 1000; % convert to ms
eventTimes = p.Results.eventTimes * 1000; % convert to ms
cellWrap   = p.Results.WrapOutputInCell;
binWidth   = p.Results.BinSize;
prev       = p.Results.Previous;
post       = p.Results.Post;
Hz         = p.Results.Hz;

clear p

%% Iterate through events, binning spike times in window

binEdges = (-prev : binWidth : post)';
binCenters = movmean(binEdges, 2, 'Endpoints', 'discard');
nbin = length(binCenters);

occurringEvents = find(~isnan(eventTimes))';
assert(~isempty(occurringEvents), ['No events occured, eventTimes ',...
    'contained only NaNs'])
nEventsOccured = length(occurringEvents);

eventIdx = zeros(nEventsOccured * nbin, 1);
binnedSpikes = zeros(nEventsOccured * nbin, 1);

for i = 1:nEventsOccured
    
    tempSpikes = spikeTimes;
    tempSpikes = tempSpikes - eventTimes(occurringEvents(i));
    spikeTimesFromEvent = tempSpikes(tempSpikes >= -prev &...
        tempSpikes <= post);
    if ~isempty(spikeTimesFromEvent) && i==1
        binnedSpikes(1:nbin) = histcounts(...
            spikeTimesFromEvent, binEdges);
        eventIdx(1:nbin) = repmat(...
            occurringEvents(i), nbin, 1);
    elseif ~isempty(spikeTimesFromEvent)
        binnedSpikes((i - 1) * nbin + 1: i * nbin) = histcounts(...
            spikeTimesFromEvent, binEdges);
        eventIdx((i - 1) * nbin + 1: i * nbin) = repmat(...
            occurringEvents(i), nbin, 1);
    end
    
end

assert(sum(binnedSpikes) ~= 0, ['No spikes found in any trials. '....
    'Please check 1) spike times vector is not empty, 2) You remembered'...
    ' to add the trial start time stamp to the event_times 3) The'...
    ' synchronisation was effective 4) The time window is large enough']);

if Hz
    binnedSpikes = binnedSpikes * 1000 / binWidth;
end

bin = repmat(binCenters, nEventsOccured, 1);

if cellWrap == true
    binnedSpikes = {binnedSpikes};
    bin          = {bin};
    eventIdx     = {eventIdx};
    binWidth     = {binWidth};
    binEdges     = {binEdges};
end
    

end
