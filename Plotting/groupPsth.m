function [g] = groupPsth(varargin)
% GROUPPSTH Return data for a persitimuls time histogram, with a plot option.
%   [psth_data] = groupPsth(spikeTimes, eventTimes, group) takes a vector  
%       of spike times(s), event times (s), and group (an array with the 
%       same length as event times, with each element defining the group 
%       the event belongs to (for example, correct, error, or low/mid/high 
%       evidence)), and returns a vector of spike frequencies in Hz.
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
deftitle = 'Visualising Spike Densities';

% validation funs
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar'});
valBinaryScalar = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'scalar'});
% group must be a valid input for findgroups
valGroup = @(x) validateattributes(x, {'numeric', 'categorical',...
    'calendarDuration', 'datetime', 'duration', 'logical', 'string'}, {});
valText = @(x) validateattributes(x, {'char', 'string'}, {'nonempty'});
    
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNumColNonEmpty);
addRequired(p, 'group', valGroup);
addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
addParameter(p, 'Post', post, valNumScalarNonEmpty);
addParameter(p, 'BinSize', sbin, valNumScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinaryScalar);
addParameter(p, 'Title', deftitle, valText);

parse(p, varargin{:});

spikeTimes = p.Results.spikeTimes; 
eventTimes = p.Results.eventTimes;
group      = p.Results.group;
prev       = p.Results.Previous;
post       = p.Results.Post;
sbin       = p.Results.BinSize;
Hz         = p.Results.Hz;
figTitle   = p.Results.Title;

clear p

assert(length(eventTimes) == length(group), ['group must be the same length', ...
    'as eventTimes']);

%% set path
load(['C:\Users\Ben\Documents\_work_bnathanson\Summary_Analysis\',...
    'Scripts\confidence\pathStruct'], 'pathStruct');
addpath(pathStruct.gramm)

%% return spike times relative to each event

group = categorical(group);

spikeTimesFromEvent = compareSpikes2Events(spikeTimes, eventTimes,...
    'Previous', prev,...
    'Post', post);
[binnedSpikes, binCenters] = binSpikesPerEvent(spikeTimes, eventTimes,...
    'Previous', prev,...
    'Post', post,...
    'BinSize', sbin,...
    'Hz', Hz);

g(1,1) = gramm('x', binCenters', 'y', binnedSpikes', 'color', group);

g(1,1).stat_summary();
g(1,1).set_title('stat_summary()');

g(1,2) = gramm('x', spikeTimesFromEvent', 'color', group);
g(1,2).geom_raster();
g(1,2).set_title('geom_raster()');

g.set_title(figTitle);
g.draw();

end


