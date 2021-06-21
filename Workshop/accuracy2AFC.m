function [handle] = accuracy2AFC(correctChoice,...
                    completedCatch, waitingTime, varargin)
% Plot accuracu  WT for 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      accuracy2AFC(correctChoice, completedCatch, ,...
%                    waitingTime, varargin)
%       Takes the the chosen side, whether the trial was a completed catch, 
%       waiting time to show accuracy vs waiting time

%       OPTIONAL INPUTS
%       Parent = Handle to figure to plot in (handle)
%       Title  = Title string, pass an empty string to leave blank 
%                (string/empty, default = 'Confidence')
%       NBins  = number of bins to plot


%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defParent    = [];
    defTitle       = "Accuracy";
    defNBins     = 5;
    
    % add inputParser defaults and check var type    
    addParameter(p, 'Title', defTitle, @(x) isstring(x));    
    addParameter(p,'NBins', defNBins, @(x) isscalar(x))
    addParameter(p, 'Parent', defParent, @ishandle);
    % addParameter(p, 'DrawLegend', defDrawLegend, @islogical);

    
    parse(p,varargin{:});
    
    nBins      = p.Results.NBins;
    parent     = p.Results.Parent;    
    titleString = p.Results.Title;
  %  drawLegend = p.Results.DrawLegend;

%% Process Data

   % Prepare Gramm Data
    xData = waitingTime;
    yData = correctChoice .* 100;
    cData = ones(size(correctChoice));
         
%% Plotting with gramm
  
    cmap = colourPicker('ylGnBu',9);
    cmap = cmap(5,:);    
    g = gramm('x',xData,'y',yData,'color',cData,'subset',completedCatch);
    g.stat_summary('bin_in',nBins,...
       'geom',{'line','errorbar'},'type','sem');
            
    if ~isempty(titleString)
        g.set_title(titleString);
    end
    if ~isempty(parent)
        g.set_parent(parent);
    end
    
    g.set_color_options('map',cmap,'n_color',1,'n_lightness',1);
    
    % set labels
    g.set_names('x','Waiting Time (s)','y','Accuracy (%)');
    
    g.draw();  

    handle = g;
    
end % end function
    