function [g2] = psth(varargin)
% PSTH Return data for a persitimuls time histogram, with a plot option.
%   [psth_data] = psth(spikeTimes, eventTimes) takes a vector of spike times
%       (s) and event times (s), and returns a vector of spike frequencies
%       in Hz.
%
%   Name Value Arguments
%   Previous     = The amount of time (ms) before the event to include.
%   Post         = The amount of time (ms) after the event to include.
%   BinSize      = Time (ms) per bin
%   Counts       = Logical or numeric scalar, 0 or 1. 0 gives results in
%                  Hz, 1 gives results in counts
%   FigureHandle = Either 0, 1 or 2. 0 returns no figure, 1 returns bar,
%                  histogram style, 2 returns a line plot.
%   Visible      = Either 'on' or 'off'. Determines if the figure is
%                  visible (on) or hidden (off)
%
%   TODO: Need to be confident of y axis before moving to categorical plot!
%
%% parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
prev  = 2500; % in ms
post  = 2500; % in ms
sbin  = 100;  % in ms
defHz = true;

% validation funs
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar'});
valBinaryScalar = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'scalar'});

addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNumColNonEmpty);
addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
addParameter(p, 'Post', post, valNumScalarNonEmpty);
addParameter(p, 'BinSize', sbin, valNumScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinaryScalar);

parse(p, varargin{:});

spikeTimes = p.Results.spikeTimes; 
eventTimes = p.Results.eventTimes;
prev = p.Results.Previous;
post = p.Results.Post;
sbin = p.Results.BinSize;
Hz = p.Results.Hz;

clear p

%% set path
load(['C:\Users\Ben\Documents\_work_bnathanson\Summary_Analysis\',...
    'Scripts\confidence\pathStruct'], 'pathStruct');
addpath(pathStruct.gramm)

%% return spike times relative to each event

% This excludes trials without spikes by default, make as an option?
spikeTimesFromEvent = compareSpikes2Events(spikeTimes, eventTimes,...
    'Previous', prev,...
    'Post', post);
[binnedSpikes, binCentres] = binSpikesPerEvent(spikeTimes, eventTimes,...
    'Previous', prev,...
    'Post', post,...
    'BinSize', sbin,...
    'Hz', Hz);

g2(1,1) = gramm('x', spikeTimesFromEvent);
g2(1,2) = gramm('x', binCentres', 'y', binnedSpikes');

g2(1,1).stat_bin('geom','stairs','fill','transparent');
g2(1,1).set_title('''transparent''');

g2(1,2).stat_summary();
g2(1,2).set_title('stat_summary()');

g2.set_title('psth');
g2.draw();

end


