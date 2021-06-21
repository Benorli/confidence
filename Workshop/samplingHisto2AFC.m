function [Handle] = samplingHisto2AFC(SamplingTimes, varargin)
% Sampling time plot
% Include n on each bar

   %% Parse inputs
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    DefaultThreshold = 0.15;
    DefaultBinSize = 0.01;
    defParent   = [];
    defDrawThreshold = true;
    defTitle     = "Sampling Time Distribution";
    
    % add inputParser methods
    addParameter(p,...
        'Threshold', DefaultThreshold,... 
        @(x) isnumeric(x))
    addParameter(p,...
        'BinSize', DefaultBinSize,... 
        @(x) isnumeric(x))
    addParameter(p, 'Parent', defParent, @ishandle);
    addParameter(p, 'DrawThreshold', defDrawThreshold, @islogical);
    addParameter(p, 'Title', defTitle, @isstring);


    parse(p,varargin{:});
    
    Threshold = p.Results.Threshold;
    BinSize = p.Results.BinSize;
    parent      = p.Results.Parent;
    drawThreshold = p.Results.DrawThreshold;
    titleString     = p.Results.Title;

    %% Plotting
    cmap = colourPicker('ylGnBu',9);
    
    nBins = round(max(SamplingTimes),1)./BinSize;
    
    g = gramm('x',SamplingTimes);
    g.stat_bin('nbins',nBins,'normalization','probability','fill','all');
    
    if drawThreshold
        g.geom_vline('xintercept',Threshold,'style','k:');
    end
    g.set_names('x','Sampling (s)','y','Probability');
    g.set_color_options('map',cmap(5,:),'n_color',1,'n_lightness',1);
  
    if ~isempty(titleString)
        g.set_title(titleString);
    end
    if ~isempty(parent)
        g.set_parent(parent);
    end
    g.draw();
    
    Handle = g;