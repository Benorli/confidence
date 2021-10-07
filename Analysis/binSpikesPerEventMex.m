function [binnedSpikes, binCenters, binEdges] = binSpikesPerEventMex(varargin)
% BINSPIKEPEREVENT Takes a time window, surrounding each event and
% returns a cell array, with a cell per trial. Each cell contains binned 
% spike frequencies (Hz) or counts within the window relative to the
% respective event. Works well with gramm stat_summary.
%
%   [spikeTimesFromEvent] = binSpikesPerEvent(spikeTimes, eventTimes)
%       takes a vector of spike times (ms) and event times (ms). It then
%       takes a window of time before and after the event. Each spike which
%       falls within that window is binned relative to that event and put
%       in a cell as binnedSpikes as a frequency (Hz) or counts if 
%       specified. The output is a column cell array with a cell per trial.
%       Optionally returns the centre of each bin per bin (bin), the width 
%       of the bin (binWidth) which can be used to convert to Hz later, 
%       and the bin edges used to define binning (binEdges).
%
%   NOTE: If trial has no spikes eventIdx == 0
%
%   Name Value Arguments
%   Previous         = The amount of time (ms) before the event to include.
%   Post             = The amount of time (ms) after the event to include.
%   BinSize          = The width of each bin in ms (default 100 ms).
%   Hz               = A binary logical or numeric, if 1/true counts are 
%                      converted to Hz. Default is true.
%   WrapOutputInCell = Wrap each output into a cell, particularly useful
%                      for running with splitapply, to bin in groups.
%   TrialLimits      = Vector the same length as eventTimes with the
%                      start/end of the trial 

%% Parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
defprev        = 2500; % in ms
defpost        = 2500; % in ms
defbinsize     = 100;  % in ms
defHz          = true;
defcellWrap    = false;
defTrialLimits = varargin{2} - defprev./1000;

% validation functions
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valPosScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar', '>=', 0});
valIntScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar', 'integer'});
valBinary = @(x) validateattributes(x, {'numeric', 'logical'},...
    {'nonempty', 'scalar', 'binary'});
valTrialLimits = @(x) validateattributes(x, {'numeric'},...
    {'nonempty','size',[length(varargin{2}) 1]});

addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNumColNonEmpty);
addParameter(p, 'BinSize', defbinsize, valIntScalarNonEmpty);
addParameter(p, 'Previous', defprev, valPosScalarNonEmpty);
addParameter(p, 'Post', defpost, valPosScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinary);
addParameter(p, 'WrapOutputInCell', defcellWrap, valBinary);
addParameter(p, 'TrialLimits', defTrialLimits, valTrialLimits)

parse(p, varargin{:});

% unpack parser and convert units
spikeTimes  = p.Results.spikeTimes * 1000; % convert to ms
eventTimes  = p.Results.eventTimes * 1000; % convert to ms
trialLimits = p.Results.TrialLimits * 1000; % convert to ms
cellWrap    = p.Results.WrapOutputInCell;
binWidth    = p.Results.BinSize;
prev        = p.Results.Previous;
post        = p.Results.Post;
Hz          = p.Results.Hz;

clear p

%% Iterate through events, binning spike times in window

binEdges = (-prev : binWidth : post)';
% binCenters = movmean(binEdges, 2, 'Endpoints', 'discard');

% Sort eventTimes for speed
[sortedEventTimes, eventIdx] = sort(eventTimes,'ascend');
sortedTrialLimits = trialLimits(eventIdx);

occurringEvents = find(~isnan(eventTimes))';
assert(~isempty(occurringEvents), ['No events occured, eventTimes ',...
    'contained only NaNs'])

% remove spikes outside our event range - can speed things up if there are
% lots of spikes
spikeTimes(spikeTimes < min(eventTimes)-prev | ... 
           spikeTimes > max(eventTimes)+post) = [];

binnedSpikes = cell(length(eventTimes), 1);
binnedSpikes(:) = {zeros(length(binEdges)-1, 1)};

for i = occurringEvents    
    
    [counts, binCenters] = histdiff(spikeTimes, eventTimes(i),binEdges);
    
    % Check if the trial start provided is within the window
    if trialLimits(i) > eventTimes(i)
        prevLimit = prev;
        postLimit = min(post, trialLimits(i) - eventTimes(i));
    else
        prevLimit = min(prev, eventTimes(i) - trialLimits(i));
        postLimit = post;
    end
    
    prevBin  = dsearchn(binCenters',-prevLimit);   
    postBin  = dsearchn(binCenters',postLimit);   
    counts(1:prevBin-1) = nan;
    counts(postBin+1:end) = nan;
    binnedSpikes(i) = {counts'};      
    
end


assert(sum(cell2mat(binnedSpikes)) ~= 0, ['No spikes found in any trials. '....
    'Please check 1) spike times vector is not empty, 2) You remembered'...
    ' to add the trial start time to the eventTimes 3) The'...
    ' synchronisation was effective 4) The time window is large enough']);

if Hz
    binnedSpikes = cellfun(@(x) x * 1000 / binWidth, binnedSpikes,...
        'UniformOutput', false);
end

if cellWrap == true
    binnedSpikes = {binnedSpikes};
    binEdges     = {binEdges};
end
    

end
