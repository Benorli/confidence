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
%   PointSize    = Scalar value, scales raster point size.
%   ZScore       = If using Z score, otherwise firing rate is used (logical,
%                  default = false)
%   PointRaster  = Scalar logical. Default true: raster elements are
%                  points. If false: raster elements are lines.
%   SortRasterLimRange = Sort trials in raster based on limit range.
%                        Logical binary. default true.
%                  
%
%   TODO: Adapt this so it will handle both single and double time vectors?
%
%% parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
defPrev               = []; % in ms
defPost               = 1000; % in ms
defSbin               = 100;  % in ms
defHz                 = true;
deftitle              = 'Visualising Spike Densities';
defSubTitle           = {'PSTH','Raster'};
defParent             = [];
defPlotType           = 3;
defGroup              = [];
defGroupNames         = [];
defGroupTitle         = "Groups";
defOrdering           = [];
defShowError          = true;
defZeroLine           = false;
defPointSize          = 2;
defZScore             = false;
defPointRaster        = true;
defSortRasterLimRange = true;

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
valTitleArray = @(x) validateattributes(x, {'cell', 'string'}, {'nonempty'});
valPlotType = @(x) validateattributes(x, {'numeric'},...
    {'nonempty','scalar','>',0,'<',4});
valGroupNames = @(x) validateattributes(x, {'char', 'string','cell'}, {'nonempty'});
valOrdering = @(x) validateattributes(x, {'char', 'string','cell','numeric'}, {'nonempty'});
    
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'eventTimes', valNum2ColNonEmpty);
addOptional(p, 'Group', defGroup, valGroup);
addParameter(p, 'Previous', defPrev, valNumScalarNonEmpty);
addParameter(p, 'Post', defPost, valNumScalarNonEmpty);
addParameter(p, 'BinSize', defSbin, valNumScalarNonEmpty);
addParameter(p, 'Hz', defHz, valBinaryScalar);
addParameter(p, 'Title', deftitle, valText);
addParameter(p, 'SubTitles', defSubTitle, valTitleArray)
addParameter(p, 'Parent', defParent, @ishandle);
addParameter(p, 'PlotType',defPlotType, valPlotType)
addParameter(p, 'GroupNames', defGroupNames, valGroupNames);
addParameter(p, 'GroupTitle', defGroupTitle, valText);
addParameter(p, 'Ordering', defOrdering, valOrdering);
addParameter(p, 'ShowError', defShowError, @(x) islogical(x));
addParameter(p, 'ZeroLine', defZeroLine,@(x) islogical(x));
addParameter(p, 'PointSize', defPointSize, valNumScalarNonEmpty);
addParameter(p, 'ZScore', defZScore, valBinaryScalar);
addParameter(p, 'PointRaster', defPointRaster, valBinaryScalar);
addParameter(p, 'SortRasterLimRange', defSortRasterLimRange,...
    valBinaryScalar);
parse(p, varargin{:});

spikeTimes         = p.Results.spikeTimes; 
eventTimes         = p.Results.eventTimes(:,1);
trialLimits        = p.Results.eventTimes(:,2);
group              = p.Results.Group;
prev               = p.Results.Previous;
post               = p.Results.Post;
sbin               = p.Results.BinSize;
Hz                 = p.Results.Hz;
figTitle           = p.Results.Title;
subTitles          = p.Results.SubTitles;
plotType           = p.Results.PlotType;
parent             = p.Results.Parent;
groupNames         = p.Results.GroupNames;
ordering           = p.Results.Ordering;
showError          = p.Results.ShowError;
groupTitle         = p.Results.GroupTitle;
zeroLine           = p.Results.ZeroLine;
pointSize          = p.Results.PointSize;
isZScore           = p.Results.ZScore;
isPointRaster      = p.Results.PointRaster;
sortRasterLimRange = p.Results.SortRasterLimRange;

clear p valNumColNonEmpty valNum2ColNonEmpty valNumScalarNonEmpty...
    valBinaryScalar valGroup valText valTitleArray valPlotType...
    valGroupNames valOrdering defPrev defPost defSbin defHz deftitle...
    defSubTitle defParent defPlotType defGroup defGroupNames...
    defGroupTitle defOrdering defShowError defZeroLine defPointSize...
    defZScore defPointRaster defSortRasterLimRange

if isempty(group) || length(nanUnique(group,false)) == 1
    group = ones(size(eventTimes));
    setColour = true;
else
    setColour = false;
end

assert(length(eventTimes) == length(group), ['group must be the same ', ...
    'length as eventTimes']);

if isempty(groupNames) || length(nanUnique(group)) == 1
    setGroupNames = false;
else
     assert(length(groupNames) == length(nanUnique(group,false)), ['groupNames ', ...
     'must be the same length as number of unique Groups']);
    setGroupNames = true;
end

if isempty(ordering)  || length(nanUnique(group)) == 1
    setOrdering = false;
else
    assert(length(ordering) == length(nanUnique(group,false)), ['Ordering ', ...
    'values must be the same length as number of unique Groups']);
    setOrdering = true;
end

if isPointRaster
    geomRaster = 'point';
else
    geomRaster = 'line';
end


%% set path
load('pathStruct', 'pathStruct');
addpath(pathStruct.gramm)

%% return spike times relative to each event

if setGroupNames
    try
        group = categorical(groupNames(group));
    catch
        group = categorical(group);
    end
else
    group = categorical(group);
end

 if sortRasterLimRange
      limitRange =  abs(eventTimes - trialLimits);
      [~, eventIdx] = sort(limitRange); 
      trialLimits = trialLimits(eventIdx);
      eventTimes = eventTimes(eventIdx);
      group = group(eventIdx);
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
    psthYAxisLabel = 'Firing Rate (Hz)';
else
    psthYAxisLabel = 'Firing Rate (Count)';
end

if plotType > 2
    yIdx = 2;
else
    yIdx = 1;
end

botYLim = 0; % Don't allow negative values for non ZScore data

if isZScore
    nCellRows = length(binnedSpikes);
    lenPrCell = length(binnedSpikes{1});
    
    binnedSpikes = cell2mat(binnedSpikes); % unpack
    
    % z score: uses mean and std from every bin in every trial
    binnedSpikes = (binnedSpikes - nanmean(binnedSpikes, 'all'))...
        / nanstd(binnedSpikes, 0, 'all');
    
    binnedSpikes = mat2cell(binnedSpikes, lenPrCell*ones(nCellRows, 1), 1);
    
    psthYAxisLabel = 'Firing rate (Z-Score)';
    botYLim = -inf; % allow negative values    
end

if plotType >= 2
    g(1,1) = gramm('x', binCenters',...
                   'y', binnedSpikes,...
                   'color', group);
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
    g(1,1).axe_property('YLim',[botYLim Inf]); % Don't allow negative values
    g(1,1).set_title(subTitles(1),...
        'FontSize', 16);
    g(1,1).set_text_options('base_size', 15,...
        'label_scaling', 1.33,...
        'legend_scaling', 0.8,...
        'legend_title_scaling', 1.2);
    g(1,1).set_names('x','Time (ms)',...
        'y', psthYAxisLabel,...
        'color',groupTitle);
    g(1,1).set_names('x','Time (ms)','y', psthYAxisLabel,'color',groupTitle);
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
    g(yIdx, 1).geom_raster('geom', geomRaster);
    g(yIdx, 1).set_point_options('base_size', pointSize);
    g(yIdx, 1).set_title(subTitles(2),...
        'FontSize', 16);
    g(yIdx,1).set_text_options('base_size', 15,...
        'label_scaling', 1.33,...
        'legend_scaling', 0.8,...
        'legend_title_scaling', 1.2);
    g(yIdx, 1).set_names('x','Time (ms)',...
        'y', 'Trials',...
        'color',groupTitle);
    if zeroLine
        g(yIdx,1).geom_vline('xintercept',0,...
            'style','k:');
    end
    if zeroLine
        g(1,1).geom_vline('xintercept',0,'style','k:');
    end
    g(yIdx, 1).set_names('x','Time (ms)','y', 'Trials','color',groupTitle);
end

% Set title
g.set_title(figTitle,...
    'FontSize', 20);


% plot into parent panel/axes as needed
if ~isempty(parent)
    for j = 1:length(g)
        g(j).set_parent(parent);
    end
end

% actually draw
g.draw();

% if zeroLine
%     % Need to set new Y limits
%     [maxY, maxYIdx] = max([g(1,1).results.stat_summary.y]);
%     yCIs = [g(1,1).results.stat_summary.yci];
%     yCI = yCIs(maxYIdx);
%     g(1,1).update();
%     g(1,1).axe_property('YLim',...
%         [0 (maxY + yCI + 2)]);
%     g(1,1).set_layout_options('legend',false);
%     g(1,1).draw();
% end
    
% Fix axis bugs
if plotType > 1
    % Get data values
    try
        allStats = [g(1,1).results.stat_summary.y];
        yMax = max(max(allStats)).* 1.33;
        g(1,1).facet_axes_handles.YLim(2) = yMax;
        if isZScore % create lims when y can be negative
            allStats = [g(1,1).results.stat_summary.y];
            yMin = min(min(allStats)).* 1.33;
            g(1,1).facet_axes_handles.YLim(1) = yMin;
        end
    end
end

end % end groupPSTHTrialLimits function

function y = nanUnique(x,keepNaNs) % unique that ignores nans

if nargin < 2
    keepNaNs = true;
end

  y = unique(x);
  
  if iscategorical(x)
      
      
  else  
      if any(isnan(y))
        y(isnan(y)) = []; % remove all nans
        if keepNaNs
            y(end+1) = NaN; % add the unique one.
        end
      end
  end
end
