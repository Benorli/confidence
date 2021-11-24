function [handle] = dropOuts2AFC(highEvidenceSide, chosenSide,...
                    completedTrial,completedCatch,...
                    rewardDelay, waitingTime, varargin)
% Plot reward drops vs WT for 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      performance2AFC(highEvidenceSide, chosenSide, ,...
%                    completedSampling, rewardDelay, waitingTime, varargin)
%       Takes the correct side (given clicks), the chosen side, whether the
%       animal completed the sampling, the reward delay time and the
%       waiting time to show animal performance over time

%       OPTIONAL INPUTS
%       Parent = Handle to figure to plot in (handle)
%       Title  = Title string, pass an empty string to leave blank 
%                (string/empty, default = 'Confidence')
%       DrawLegend = whether to draw Legend (logical)


%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defParent    = [];
    defTitle       = "Reward Dropouts";
    defDrawLegend  = true;
    defNBins     = 5;
    
    % add inputParser defaults and check var type    
    addParameter(p, 'Title', defTitle, @(x) isstring(x));    
    addParameter(p,'NBins', defNBins, @(x) isscalar(x))
    addParameter(p, 'Parent', defParent, @ishandle);
    addParameter(p, 'DrawLegend', defDrawLegend, @islogical);

    
    parse(p,varargin{:});
    
    nBins      = p.Results.NBins;
    drawLegend = p.Results.DrawLegend;
    parent     = p.Results.Parent;    
    titleString = p.Results.Title;

%% Process Data

    % Left Reward drop outs
    leftDO = double( highEvidenceSide == 'left' & chosenSide == 'left' ...);
                    &  (rewardDelay >= waitingTime) );
    leftDO(~completedTrial | highEvidenceSide == 'right' | completedCatch) = nan;

    % Right Reward drop outs
    rightDO = double( highEvidenceSide == 'right' & chosenSide == 'right' ...);
                    &  (rewardDelay >= waitingTime) );
    rightDO(~completedTrial | highEvidenceSide == 'left' | completedCatch) = nan;
   
    % Combine
    xData = repmat(waitingTime,1,2);
    yData = [leftDO; rightDO] .* 100;
    cData = cellstr([repmat("Left",size(leftDO)); ...
             repmat("Right",size(rightDO))]);
         
%% Plotting with gramm
  
    cmap = colourPicker('ylGnBu',9);
    cmap = cmap([4 7],:);    
    g = gramm('x',xData,'y',yData,'color',cData);
    g.stat_summary('bin_in',nBins,...
       'geom',{'bar','errorbar'});
            
    % g.stat_bin('normalization','probability');

    if ~isempty(titleString)
        g.set_title(titleString);
    end
    if ~isempty(parent)
        g.set_parent(parent);
    end
    
    g.set_color_options('map',cmap,'n_color',2,'n_lightness',1);
    g.set_order_options('color',{'Left','Right'});
    
    % set labels
    g.set_names('x','Waiting Time (s)','y','Percentatge %');

    if ~drawLegend
        % g.set_layout_options('legend','false');
        % g.no_legend('color');
    end
    
    g.draw();  

    handle = g;
    
end % end function
    