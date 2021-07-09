function [handle] = waitingTime2AFC(correctChoice, catchTrial, ...
                    completedTrial,...
                    waitingTime, varargin)
% Plot trialType x Waiting Time for 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      waitingTime2AFC(highEvidenceSide, chosenSide, ,...
%                    completedSampling, rewardDelay, waitingTime, varargin)
%       Takes the correct side (given clicks), the chosen side, whether the
%       animal completed the sampling, the reward delay time and the
%       waiting time to show animal performance over time

%       OPTIONAL INPUTS
%       NBins  = number of bins to plot data in
%       Parent = Handle to figure to plot in (handle)
%       Title  = Title string, pass an empty string to leave blank 
%                (string/empty, default = 'Confidence')
%       DrawLegend = whether to draw Legend (logical)


%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defParent    = [];
    defTitle = "Waiting Time Distribution";
    % defNBins     = 5;
    defDrawLegend    = true;

    % add inputParser defaults and check var type    
    addParameter(p, 'Title', defTitle, @(x) isstring(x));    
    % addParameter(p,'NBins', defNBins, @(x) isscalar(x))
    addParameter(p, 'Parent', defParent, @ishandle);
    addParameter(p, 'DrawLegend', defDrawLegend, @islogical);

    parse(p,varargin{:});
    
    % nBins      = p.Results.NBins;
    titleString = p.Results.Title;
    drawLegend = p.Results.DrawLegend;
    parent     = p.Results.Parent;
    

%% Process Data

    % Correct Catch
    correctCatch = find(correctChoice & catchTrial & completedTrial);
    % correctCatch(~correctChoice | ~catchTrial | ~completedTrial) = nan;
    
    % Correct Non-Catch
    correctNonCatch = find(correctChoice & ~catchTrial & completedTrial);
    % correctNonCatch(~correctChoice | catchTrial | ~completedTrial) = nan;
    
    % Errors
    errors = find(~correctChoice & completedTrial);
    % errors(correctChoice | ~completedTrial) = nan;

    %Combine
    xData = [waitingTime(correctCatch); waitingTime(correctNonCatch); ...
             waitingTime(errors)];
    cData = cellstr([repmat("Correct Catch",size(correctCatch)); ...
             repmat("Correct Non-Catch",size(correctNonCatch)); ...
             repmat("Error",size(errors))]);
                  
%% Plotting with gramm
  
    cmap = colourPicker('paired');
    cmap = cmap([3 4 6],:);    
    g = gramm('x',xData,'color',cData);
    g.stat_bin('geom','stairs','normalization','pdf');
    % g.stat_density();

    if ~isempty(titleString)
        g.set_title(titleString);
    end
    if ~isempty(parent)
        g.set_parent(parent);
    end
    
    g.set_color_options('map',cmap,'n_color',3,'n_lightness',1);
    % g.set_order_options('color',{"Correct Catch","Correct Non-Catch","Error"});
    
    % set labels
    g.set_names('x','Waiting Time (s)','y','Probability');

    if ~drawLegend
        % g.set_layout_options('legend','false');
        % g.no_legend('color');
    end
    
    g.draw();  

    handle = g;
    
end % end function
    