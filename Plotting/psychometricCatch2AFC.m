function [handle] = psychometric2AFC(stimulusA, stimulusB, correct,... 
                    waitingTimes, catchTrials, varargin)
% Plot a psychometric curve for a 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      PsychometricCatch2AFC(StimulusA, StimulusB, Choice,WaitingTimes,Catch) 
%      takes a vector of click counts for each side (StimulusA/StimulusB) 
%      a vector of if the decision was correct, a vector of waiting times and a 
%      vector of catch trials. It then plots a psychometric of the catch
%      trials split by waiting time high vs low (by median waiting time).
%      using the absolute difference over sum (can plot both sides).
%
%       OPTIONAL IN
%       Parent  = Handle to figure to plot in (handle)
%       nBins   = number of bins, scalar
%       WTSplit = number of bins to split waiting times into (integer,
%       default  = 2);
%       Title  = Title string, pass an empty string to leave blank 
%                (string/empty, default = 'Confidence')
%       DrawTrials = Label the number of trials at each data point (logical)
%       OneSided   = plot absolute values for Evidence - ignores left/right distinction
%                    (logical, default = true)        
 



%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defNBins = 7;
    defParent   = [];
    defTitle     = "Psychometric - Catch Trials";
    defDrawTrials    = true;
    defWTSplit       = 2;
    defOneSided     = true;

    % add inputParser defaults and check var type
    addParameter(p, 'Title', defTitle, @(x) isstring(x));    
    addParameter(p, 'nBins', defNBins, @(x) isscalar(x));
    addParameter(p, 'Parent', defParent, @(x) ishandle(x));
    addParameter(p, 'DrawTrials', defDrawTrials, @(x) islogical(x));
    addParameter(p, 'WTSplit', defWTSplit, @(x) isinteger(x)); 
    addParameter(p, 'OneSided', defOneSided, @(x) islogical(x))

    parse(p,varargin{:});
    
    nBins           = p.Results.nBins;
    titleString     = p.Results.Title;
    drawTrials      = p.Results.DrawTrials;
    parent          = p.Results.Parent;
    wtSplit         = p.Results.WTSplit;         
    oneSided        = p.Results.OneSided;    
            
    %% Prepare Data

    % X Data
    % Stimulus normalization, difference over sum
    stimulus = (stimulusA-stimulusB)./(stimulusA+stimulusB);       
    if oneSided
        stimulus = abs(stimulus);
    end
    xData = stimulus;
        
    % Y Data   
    yData = correct;
    
    % Subset
    subset = catchTrials;
    
    % Color - Waiting time high vs low
    edges = [0 prctile(waitingTimes(subset),(1:wtSplit-1).*(1/wtSplit.*100)) ...
            max(waitingTimes(subset))];
    wtSplits = discretize(waitingTimes,edges);
    cData = wtSplits;    
    
    % Duplicate data to plot all and splits seperatley
    xData   = [xData; xData];
    yData   = [yData; yData] .* 100;
    subset  = [subset; subset];
    cData   = [cData; ones(size(cData)).*wtSplit+1];
            
%% Plotting with gramm
    redGreenMap = colourPicker('RdYlGn',wtSplit );
    cmap = [redGreenMap; 0 0 0];
    g = gramm('x',xData,'y',yData,'color',cData','subset',subset);
    g.stat_summary('bin_in',nBins,'geom',{'line','errorbar'},'type','sem');
    g.set_color_options('map',cmap,'n_color',wtSplit+1,'n_lightness',1);
    
    if ~isempty(titleString)
        g.set_title(titleString);
    end
    if ~isempty(parent)
        g.set_parent(parent);
    end
    
    % set labels
    g.set_names('x','Evidence (difference/sum)','y','Correct (%)');     
    g.draw();   
    
    if drawTrials        
        binnedTrials = discretize(stimulus,p.Results.nBins);
        hold(gca,'on');
        for j = 1:p.Results.nBins
            count = sum(binnedTrials == j);
            text(g.facet_axes_handles,...
                 g.results.stat_summary.x(j)-0.15,g.results.stat_summary.y(j)+0.05,...
                 num2str(count));
        end
    end 

    handle = g;
end 
    