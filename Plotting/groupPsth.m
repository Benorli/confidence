function [g] = groupPsth(varargin)
% GROUPPSTH Return data for a persitimuls time histogram, with a plot option.
%   [g] = groupPsth(spikeTimes, eventTimes, group) takes a vector  
%       of spike times(s), event times (s), and group (an array with the 
%       same length as event times, with each element defining the group 
%       the event belongs to (for example, correct, error, or low/mid/high 
%       evidence)), and returns a vector of spike frequencies in Hz.
%       
%   Name Value Arguments
%   Previous     = The amount of time (ms) before the event to include.
%   Post         = The amount of time (ms) after the event to include.
%   BinSize      = Time (ms) per bin
%   Hz           = Logical or numeric scalar, 0 or 1. 0 gives results in
%                  Hz, 1 gives results in counts
%   Title        = Set title for figure
%% parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
prev  = 2500; % in ms
post  = 2500; % in ms
sbin  = 100;  % in ms
defHz = true;
deftitle = 'Visualising Spike Densities';
defSubTitle = {'PSTH','Raster'};
defXLabelPsth = 'Time (ms)';
defYLabelPsth = 'Frequency (HZ)';
defXLabelRaster = 'Time (ms)';
defYLabelRaster = 'Trial';

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
valTitleArray = @(x) validateattributes(x, {'cell', 'string'},...
    {'nonempty', 'length', 2});
    
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNumColNonEmpty);
addRequired(p, 'group', valGroup);
addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
addParameter(p, 'Post', post, valNumScalarNonEmpty);
addParameter(p, 'BinSize', sbin, valNumScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinaryScalar);
addParameter(p, 'Title', deftitle, valText);
addParameter(p, 'SubTitles',defSubTitle',valTitleArray);
addParameter(p, 'XLabelPsth', defXLabelPsth, valText);
addParameter(p, 'YLabelPsth', defYLabelPsth, valText);
addParameter(p, 'XLabelRaster', defXLabelRaster, valText);
addParameter(p, 'YLabelRaster', defYLabelRaster, valText); 

parse(p, varargin{:});

spikeTimes   = p.Results.spikeTimes; 
eventTimes   = p.Results.eventTimes;
group        = p.Results.group;
prev         = p.Results.Previous;
post         = p.Results.Post;
sbin         = p.Results.BinSize;
Hz           = p.Results.Hz;
figTitle     = p.Results.Title;
subTitles    = p.Results.SubTitles;
XLabelPsth   = p.Results.XLabelPsth;
YLabelPsth   = p.Results.YLabelPsth;
XLabelRaster = p.Results.XLabelRaster;
YLabelRaster = p.Results.YLabelRaster;

clear p

assert(length(eventTimes) == length(group), ['group must be the same length', ...
    'as eventTimes']);

%% set path
load('pathStruct', 'pathStruct');
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
g(1,1).stat_summary('setylim', true);
g(1,1).set_title(subTitles(1));
g(1,1).axe_property('YLim', [0 inf]);
g(1,1).set_names('x', XLabelPsth, 'y', YLabelPsth);

g(2,1) = gramm('x', spikeTimesFromEvent', 'color', group);
g(2,1).geom_raster();
g(2,1).set_title(subTitles(2));
g(2,1).set_names('x', XLabelRaster, 'y', YLabelRaster);

g.set_title(figTitle);
g.draw();

end


