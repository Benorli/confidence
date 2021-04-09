function [g] = groupPsthTrialLimits(varargin)
% GROUPPSTH Return figure of a persitimuls time histogram
%   [g] = groupPsthTrialLimits(spikeTimes, eventTimes, group) takes a vector  
%   of spike times(s), a two column matrix of event times (s) - first
%   column is the 0 point, second column is trial start/end point,
%   and group (an array with the same length as event times, 
%   with each element defining the group the event belongs to 
%   (for example, correct, error, or low/mid/high evidence)), 
%   and returns a two element figure with rasters and mean spike times
%       
%   Name Value Arguments
%   Previous     = The amount of time (ms) before the event to include.
%   Post         = The amount of time (ms) after the event to include.
%   BinSize      = Time (ms) per bin
%   Hz           = Logical or numeric scalar, 0 or 1. 0 gives results in
%                  Hz, 1 gives results in counts
%
%   TODO: Maybe options to only plot 1 of the subplots or different
%         types?
%         Adapt this so it will handle both single and double time vector?
%
%% parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
prev  = 2500; % in ms
post  = 2500; % in ms
sbin  = 100;  % in ms
defHz = true;
deftitle = 'Visualising Spike Densities';
defSubTitle = {'PSTH','Raster'};

% validation funs
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valNum2ColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty','ncols', 2});
valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar'});
valBinaryScalar = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'scalar'});
% group must be a valid input for findgroups
valGroup = @(x) validateattributes(x, {'numeric', 'categorical',...
    'calendarDuration', 'datetime', 'duration', 'logical', 'string'}, {});
valText = @(x) validateattributes(x, {'char', 'string'}, {'nonempty'});
valTitleArray = @(x) validateattributes(x, {'cell', 'string'}, {'nonempty'}, ...
    {'length',2});
    
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNum2ColNonEmpty);
addRequired(p, 'group', valGroup);
addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
addParameter(p, 'Post', post, valNumScalarNonEmpty);
addParameter(p, 'BinSize', sbin, valNumScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinaryScalar);
addParameter(p, 'Title', deftitle, valText);
addParameter(p, 'SubTitles',defSubTitle',valTitleArray)

parse(p, varargin{:});

spikeTimes  = p.Results.spikeTimes; 
eventTimes  = p.Results.eventTimes(:,1);
trialLimits = p.Results.eventTimes(:,2);
group       = p.Results.group;
prev        = p.Results.Previous;
post        = p.Results.Post;
sbin        = p.Results.BinSize;
Hz          = p.Results.Hz;
figTitle    = p.Results.Title;
subTitles   = p.Results.SubTitles;

clear p

assert(length(eventTimes) == length(group), ['group must be the same length', ...
    'as eventTimes']);

%% set path
load('pathStruct', 'pathStruct');
addpath(pathStruct.gramm)

%% return spike times relative to each event

group = categorical(group);

spikeTimesFromEvent = compareSpikes2EventsMex(spikeTimes, eventTimes,...
    'Previous', prev,...
    'Post', post,...
    'TrialLimits',trialLimits);
[binnedSpikes, binCenters] = binSpikesPerEventMex(spikeTimes, eventTimes,...
    'Previous', prev,...
    'Post', post,...
    'TrialLimits',trialLimits,...
    'BinSize', sbin,...
    'Hz', Hz);

if Hz
    rasterYAxisLabel = 'Firing Rate (Hz)';
else
    rasterYAxisLabel = 'Firing Rate (Count)';
end

g(1,1) = gramm('x', binCenters', 'y', binnedSpikes', 'color', group);

g(1,1).stat_summary('setylim',true);
g(1,1).set_title(subTitles(1));
g(1,1).set_names('x','Time (ms)','y', rasterYAxisLabel,'color','Groups');

g(1,2) = gramm('x', spikeTimesFromEvent', 'color', group);
g(1,2).geom_raster();
g(1,2).set_title(subTitles(2));
g(1,2).set_names('x','Time (ms)','y', 'Trials','color','Groups');


g.set_title(figTitle);
g.draw();

end


