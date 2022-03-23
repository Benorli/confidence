function panels = createSubPanels(varargin)
%% Create a group of uiPanels in a figure
% Serves the same function as subplot but can be used with Gramm toolbox
% Takes number of columns, number of rows.
% Optionally takes indicies to span - like subplot, if not provided will
% return each individual panel requested, i.e. createSubPanels(2,2) will
% create and return handles to 4 panels in a 2x2 figure. 
% createSubPanels(2,2,3) will create and return a single panel in the lower 
% left corner of the figuer.
%   Name Value Arguments
%   handle      = Handle to an existing figure to plot into,   
%                 if not given will spawn a new figure
%   borders     = Width of outside borders.  Default is 2.5%
%   spacing     = Width of internal spacing. Default is 1%
%   title       = Logical, create a panel for a title. Will be last panel 
%                 Default is false        

%% parse variable input arguments

p = inputParser; % Create object of class 'inputParser'

% define defaults
defIndex        = [];
defHandle       = [];
defBorders      = 2.5;
defSpacing      = 1;
defTitle        = true;
defTitleSize    = 5;  

% validation funs
valPercentage = @(x) validateattributes(x, {'numeric'},...
    {'nonempty','scalar','<=',100,'>=',0});
valLogical = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'scalar'});
valIntegerScalar = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar','integer'});
valIntegerVector = @(x) validateattributes(x, {'numeric'},...
    {'nonempty','integer'});

addRequired(p, 'columns', valIntegerScalar);
addRequired(p, 'rows', valIntegerScalar);
addOptional(p, 'index', defIndex, valIntegerVector);
addParameter(p, 'Handle', defHandle, @ishandle);
addParameter(p, 'Borders', defBorders, valPercentage);
addParameter(p, 'Spacing', defSpacing, valPercentage);
addParameter(p, 'Title', defTitle, valLogical);
addParameter(p, 'TitleSize', defTitleSize, valPercentage);

parse(p, varargin{:});

columns = p.Results.columns; 
rows    = p.Results.rows;
index   = p.Results.index;
figHandle  = p.Results.Handle;
borders = p.Results.Borders;
spacing = p.Results.Spacing;
title   = p.Results.Title;
titleSize = p.Results.TitleSize;

clear p

% Validate Indices provided
if isempty(index)
    createAll = true;
else
    createAll = false;
    assert(all(index <= rows*columns),...
        'Indices provided are outside range of panels...');
end

% Create Figure if needed
if isempty(figHandle)
    figHandle = figure;
    figHandle.Color = [1 1 1];
end

% Convert Percentages to fractions
borders     = borders ./100;
spacing     = spacing ./100;
titleSize   = titleSize ./100; 

if ~title 
    titleSize = 0;
end

%% Loop to Create Panels

verticalSize   = (1 - titleSize - 2*borders - spacing*(rows-1))/rows;
horizontalSize = (1 - 2*borders - spacing*(columns-1))/columns;
rowVector = rows:-1:1;
indexCount = 1;

for rowI = 1:rows % Work backwards as position values start at bottom

    if rowI == 1
        verticalPosition = borders;
    else
        verticalPosition = borders + (rowI-1)*(verticalSize + spacing);
    end

    for colI = 1:columns
        currentIndex = (rowVector(rowI)-1) .* columns + colI;
        
        if colI == 1
            horizontalPosition = borders;
        else
            horizontalPosition = borders + ...
                (colI-1)*(horizontalSize + spacing);
        end

        panelPosition = ...
            [horizontalPosition verticalPosition horizontalSize verticalSize];

        if createAll
            panels(currentIndex)= uipanel('Position',panelPosition,...
            'Parent',figHandle,'BackgroundColor',[1 1 1],'BorderType','none'); 
        else
             panelPositions(currentIndex,:) = panelPosition;
        end
    end
end

if ~createAll % We just need to create a single panel
    
    % find extents of indexed panels
    panelPosition(1) = min(panelPositions(index,1));
    panelPosition(2) = min(panelPositions(index,2));
    maxX = max(panelPositions(index,1) + panelPositions(index,3));
    maxY = max(panelPositions(index,2) + panelPositions(index,4));
    
    panelPosition(3) = maxX - panelPosition(1);
    panelPosition(4) = maxY - panelPosition(2);    
    
    panels= uipanel('Position',panelPosition,...
            'Parent',figHandle,'BackgroundColor',[1 1 1],'BorderType','none'); 
    
end

if title % Create a panel for the title  
    panels(end+1) = uipanel('Position',[0 1-titleSize 1 titleSize],...
            'Parent',figHandle,'BackgroundColor',[1 1 1],...
            'BorderType','none');        
end