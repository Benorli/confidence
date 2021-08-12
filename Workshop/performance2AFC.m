function [handle] = performance2AFC(highEvidenceSide, chosenSide,...
                    completedSampling, completedTrial,completedCatch,...
                    rewardDelay, waitingTime, varargin)
% Plot task performance over time for 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      performance2AFC(highEvidenceSide, chosenSide, ,...
%                    completedSampling, rewardDelay, waitingTime, varargin)
%       Takes the correct side (given clicks), the chosen side, whether the
%       animal completed the sampling, the reward delay time and the
%       waiting time to show animal performance over time

%       OPTIONAL INPUTS
%       Width = Width of moving average (integer)
%       Parent = Handle to figure to plot in (handle)
%       Title  = Title string, pass an empty string to leave blank 
%                (string/empty, default = 'Confidence')
%       DrawLegend = whether to draw Legend (logical)



%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defWidth = 50;
    defParent   = [];
    defTitle     = "Performance";
    defDrawLegend    = true;

    % add inputParser defaults and check var type
    addParameter(p, 'Title', defTitle, @(x) isstring(x));    
    addParameter(p,'Width', defWidth, @(x) isscalar(x));
    addParameter(p, 'Parent', defParent, @ishandle);
    addParameter(p, 'DrawLegend', defDrawLegend, @islogical);
    
    
    parse(p,varargin{:});
    
    movWidth   = p.Results.Width;
    titleString = p.Results.Title;
    drawLegend = p.Results.DrawLegend;
    parent     = p.Results.Parent;
    
    

%% Process Data

    % calculate sampling drop outs
    samplingDO = movmean(~completedSampling,movWidth);
    
    % calculate reward drop outs
    rewardDO = double(rewardDelay > waitingTime);
    rewardDO(~completedTrial | completedCatch) = nan;
    rewardDO = movmean(rewardDO,movWidth,'omitnan');

    % calculate left correct
    leftCorrect = double(highEvidenceSide == 'left' & chosenSide == 'left');
    leftCorrect(~completedTrial | highEvidenceSide == 'right') = nan;
    leftCorrect = movmean(leftCorrect,movWidth,'omitnan');
    
    % calculate right correct
    rightCorrect = double(highEvidenceSide == 'right' & chosenSide == 'right');
    rightCorrect(~completedTrial | highEvidenceSide == 'left') = nan;
    rightCorrect = movmean(rightCorrect,movWidth,'omitnan');
        
    % Combine
    
    xData = repmat(1:length(leftCorrect),1,4);
    yData = [leftCorrect; rightCorrect; samplingDO; rewardDO] .* 100;
    cData = cellstr([repmat("Left",size(leftCorrect)); ...
             repmat("Right",size(rightCorrect)); 
             repmat("SDO",size(samplingDO)); ...
             repmat("RDO",size(rewardDO))]);
         
%% Plotting with gramm
  
    choiceMap = colourPicker('ylGnBu',9);
    dropMap   = colourPicker('Inferno',9);
    cmap = [choiceMap([4 7],:); dropMap([6 2],:)];
    
    g = gramm('x',xData,'y',yData,'color',cData);
    g.geom_line();
            
    if ~isempty(titleString)
        g.set_title(titleString);
    end
    
    if ~isempty(parent)
        g.set_parent(parent);
    end
    
    g.set_color_options('map',cmap,'n_color',4,'n_lightness',1);
    g.set_order_options('color',{'Left','Right','SDO','RDO'});
    
    % set labels
    g.set_names('x','Trial #','y','Accuracy %');

    if ~drawLegend
        % g.set_layout_options('legend','false');
        % g.no_legend('color');
    end
    
    g.draw();  

    handle = g;
    
end % end function
    