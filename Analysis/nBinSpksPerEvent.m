function [binnedSpikes, binCenters, binEdges] = nBinSpksPerEvent(varargin)
% NBINSPKSPEREVENT Takes a time window, surrounding each event and
% returns spike counts per bin. Binsize varies per trial. A fixed number of
% bins with variable size depending on diff(prev, post). Each cell contains 
% binned spike frequencies (Hz) or counts within the window relative to the
% respective event. WrapRowInCell works well with gramm stat_summary.
%
%   [spikeTimesFromEvent] = nBinSpksPerEvent(spikeTimes, nBins, prev, post)
%       takes a vector of spike times (s) and prev/post times (s). It then
%       takes a window of time before and after the event. Binsize varies 
%       per trial. A fixed number of bins with variable
%       size depending on diff(prev, post). Each spike which
%       falls within that window is binned relative to that event and put
%       in a cell as binnedSpikes as a frequency (Hz) or counts if 
%       specified. The output is a column cell array with a cell per trial.
%       Optionally returns the centre of each bin per bin (bin), the width 
%       of the bin in ms (binWidth) which can be used to convert to Hz 
%       later, and the bin edges used to define binning (binEdges).
%
%   NOTE: If trial has no spikes eventIdx == 0
%
%   Name Value Arguments
%   Hz               = A binary logical or numeric, if 1/true counts are 
%                      converted to Hz. Default is true.
%   WrapOutputInCell = Wrap each output into a cell, particularly useful
%                      for running with splitapply, to bin in groups.

%% Parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
defHz       = true;
defcellWrap = false;
defrowCellWrap = false;

% validation functions
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valIntScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar', 'integer'});
valBinary = @(x) validateattributes(x, {'numeric', 'logical'},...   
    {'nonempty', 'scalar', 'binary'});

addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'nBins', valIntScalarNonEmpty);
addRequired(p, 'prev', valNumColNonEmpty);
addRequired(p, 'post', valNumColNonEmpty);
addParameter(p, 'Hz', defHz, valBinary);
addParameter(p, 'WrapOutputInCell', defcellWrap, valBinary);
addParameter(p, 'WrapRowInCell', defrowCellWrap, valBinary);

parse(p, varargin{:});

% unpack parser and convert units
spikeTimes  = p.Results.spikeTimes * 1000; % convert to ms
prev        = p.Results.prev * 1000; % convert to ms
post        = p.Results.post * 1000; % convert to ms
cellWrap    = p.Results.WrapOutputInCell;
rowCellWrap = p.Results.WrapRowInCell;
nBins       = p.Results.nBins;
Hz          = p.Results.Hz;

clear p defHz defcellWrap defrowCellWrap valNumColNonEmpty...
    valIntScalarNonEmpty valBinary

%% Iterate through events, binning spike times in window

assert(length(prev) == length(post));
nTrials = length(prev);

% prealocate
binnedSpikes = zeros(nTrials, nBins);
binWidths = zeros(nTrials, 1);
binCenters = zeros(nTrials, nBins);

% remove spikes outside event range - faster if high n spikes
spikeTimes(spikeTimes < min(prev) | ... 
           spikeTimes > max(post)) = [];

for i = 1 : nTrials
    % isolate spikes in trial
    spksInEventRange = spikeTimes > prev(i) & spikeTimes < post(i);
    % define bin size per trial then bin spikes
    binWidths(i) = (post(i) - prev(i)) / nBins;
    binEdges = prev(i) : binWidths(i) : post(i);
    binnedSpikes(i, :) = histcounts(spikeTimes(spksInEventRange), binEdges);
    % avg bin edges to find centers
    rowBinCent = movmean(binEdges, 2);
    binCenters(i, :) = rowBinCent(2:end);
end

if Hz
    binnedSpikes = binnedSpikes * 1000 ./ binWidths;
end

if rowCellWrap
    binnedSpikes = num2cell(binnedSpikes, 2);
end

if cellWrap
    binnedSpikes = {binnedSpikes};
    binCenters   = {binCenters};
    binEdges     = {binEdges};
end

end