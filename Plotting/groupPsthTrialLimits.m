function [g] = groupPsthTrialLimits(varargin)
% GROUPPSTH Return figure of a persitimuls time histogram
%   [g] = groupPsthTrialLimits(spikeTimes, eventTimes, *group) takes a vector  
%   of spike times(s), a two column matrix of event times (s) - first
%   column is the 0 point, second column is trial start/end point,
%   and optinally group (an array with the same length as event times, 
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
%   Title        = String to use as figure title
%   GroupNames   = Names to use for groups
%   GroupTitle   = Label for group legend
%   Parent       = handle to a figure or uipanel to plot into
%   PlotType     = 1, 2 or 3 - will plot (1) rasters, (2) PSTH, 
%                 (3=Default) both
%   ShowError    = Show shaded error bars on PSTH's (logical, default = true)
%   ZeroLine     = Show a vertical line at time 0 (logical, default = false)
%
%   TODO: Adapt this so it will handle both single and double time vectors?
%
%% parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
prev            = []; % in ms
post            = 1000; % in ms
sbin            = 100;  % in ms
defHz           = true;
deftitle        = 'Visualising Spike Densities';
defSubTitle     = {'PSTH','Raster'};
defParent       = [];
defPlotType     = 3;
defGroup        = [];
defGroupNames   = [];
defGroupTitle   = "Groups";
defOrdering     = [];
defShowError    = true;
defZeroLine     = false;

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
    'calendarDuration', 'datetime', 'duration', 'logical', 'string','cell','char'}, {});
valText = @(x) validateattributes(x, {'char', 'string'}, {'nonempty'});
valTitleArray = @(x) validateattributes(x, {'cell', 'string'}, {'nonempty'}, ...
    {'length',2});
valPlotType = @(x) validateattributes(x, {'numeric'},...
    {'nonempty','scalar','>',0,'<',4});
valGroupNames = @(x) validateattributes(x, {'char', 'string','cell'}, {'nonempty'});
valOrdering = @(x) validateattributes(x, {'char', 'string','cell','numeric'}, {'nonempty'});
    
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNum2ColNonEmpty);
addOptional(p, 'group', defGroup, valGroup);
addParameter(p, 'Previous', prev, valNumScalarNonEmpty);
addParameter(p, 'Post', post, valNumScalarNonEmpty);
addParameter(p, 'BinSize', sbin, valNumScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinaryScalar);
addParameter(p, 'Title', deftitle, valText);
addParameter(p, 'SubTitles',defSubTitle,valTitleArray)
addParameter(p, 'Parent', defParent, @ishandle);
addParameter(p, 'PlotType',defPlotType,valPlotType)
addParameter(p, 'GroupNames', defGroupNames, valGroupNames);
addParameter(p, 'GroupTitle', defGroupTitle, valText);
addParameter(p, 'Ordering', defOrdering, valOrdering);
addParameter(p, 'ShowError',defShowError,@(x) islogical(x));
addParameter(p, 'ZeroLine',defZeroLine,@(x) islogical(x));

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
plotType    = p.Results.PlotType;
parent      = p.Results.Parent;
groupNames  = p.Results.GroupNames;
ordering    = p.Results.Ordering;
showError   = p.Results.ShowError;
groupTitle  = p.Results.GroupTitle;
zeroLine  = p.Results.ZeroLine;

clear p

if isempty(group) || length(unique(group)) == 1
    group = ones(size(eventTimes));
    setColour = true;
else
    setColour = false;
end

assert(length(eventTimes) == length(group), ['group must be the same length', ...
    'as eventTimes']);

if isempty(groupNames)
    setGroupNames = false;
else
    assert(length(groupNames) == length(nanUnique(group)), ['groupNames must be the same length', ...
    ' as number of unique Groups']);
    setGroupNames = true;
end

if isempty(ordering)
    setOrdering = false;
else
    assert(length(ordering) == length(nanUnique(group)), ['Ordering values must be the same length', ...
    ' as number of unique Groups']);
    setOrdering = true;
end


%% set path
load('pathStruct', 'pathStruct');
addpath(pathStruct.gramm)

%% return spike times relative to each event

if setGroupNames
    group = categorical(groupNames(group));
else
    group = categorical(group);
end

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

if plotType > 2
    yIdx = 2;
else
    yIdx = 1;
end

if plotType >= 2
    g(1,1) = gramm('x', binCenters', 'y', binnedSpikes', 'color', group);
    if setColour
        g(1,1).set_color_options('map',[0 0 0],'n_color',1,'n_lightness',1);
    end
    if setOrdering
        g(1,1).set_order_options('color',ordering);
    end
    if showError
        g(1,1).stat_summary('setylim',true);
    else
        g(1,1).stat_summary('setylim',true,'geom','line');
    end
    g(1,1).axe_property('YLim',[0 Inf]); % Don't allow negative values
    g(1,1).set_title(subTitles(1),...
        'FontSize', 20);
    g(1,1).set_text_options('base_size', 15,...
        'label_scaling', 2,...
        'legend_scaling', 0.8,...
        'legend_title_scaling', 1.2);
    g(1,1).set_names('x','Time (ms)',...
        'y', rasterYAxisLabel,...
        'color',groupTitle);
    if zeroLine
        g(1,1).geom_vline('xintercept',0,...
            'style','k:');
    end
end

if plotType == 1 || plotType == 3
    g(yIdx, 1) = gramm('x', spikeTimesFromEvent', 'color', group);
    if setColour
        g(1,1).set_color_options('map',[0 0 0],'n_color',1,'n_lightness',1);
    end
    if setOrdering
        g(yIdx, 1).set_order_options('color',ordering);
    end
    g(yIdx, 1).geom_raster('geom','point');
    g(yIdx, 1).set_point_options('base_size', 2);
    g(yIdx, 1).set_title(subTitles(2),...
        'FontSize', 20);
    g(yIdx,1).set_text_options('base_size', 15,...
        'label_scaling', 2,...
        'legend_scaling', 0.8,...
        'legend_title_scaling', 1.2);
    g(yIdx, 1).set_names('x','Time (ms)',...
        'y', 'Trials',...
        'color',groupTitle);
    if zeroLine
        g(yIdx,1).geom_vline('xintercept',0,...
            'style','k:');
    end
end

g.set_title(figTitle,...
    'FontSize', 26);
if ~isempty(parent)
    g.set_parent(parent);
end
g.draw();

if zeroLine
    % Need to set new Y limits
    [maxY, maxYIdx] = max([g(1,1).results.stat_summary.y]);
    yCIs = [g(1,1).results.stat_summary.yci];
    yCI = yCIs(maxYIdx);
    g(1,1).update();
    g(1,1).axe_property('YLim',...
        [0 (maxY + yCI + 2)]);
    g(1,1).set_layout_options('legend',false);
    g(1,1).draw();
end
    
end

function y = nanUnique(x,keepNaNs) % unique that ignores nans

if nargin < 2
    keepNaNs = true;
end

  y = unique(x);
  if any(isnan(y))
    y(isnan(y)) = []; % remove all nans
    if keepNaNs
        y(end+1) = NaN; % add the unique one.
    end
  end
end
