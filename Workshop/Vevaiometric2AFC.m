function [handle] = Vevaiometric2AFC(StimulusA, StimulusB, waitingTime, Correct, Catch, Rewarded, varargin)
% Plot a psychometric curve for a 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      [handle] = Vevaiometric2AFC()
%       
%       OPTIONAL INPUTS
%       Parent = Handle to figure to plot in (handle)
%       Title  = Title string, pass an empty string to leave blank 
%                (string/empty, default = 'Confidence')
%       DrawLegend = whether to draw Legend (logical)
%       NBins  = # of bins to use (integer,default = 7, halved for 1 side)
%       DrawPoints = draw individual data points (logical, default = true)
%       DrawMean   = draw mean +- SEM (logical, default = true)
%       OneSided   = plot absolute values for Evidence - ignores left/right distinction
%                    (logical, default = false)                    
%       PlotSide   = Draw data from specific side only, ('both','left' or
%                    'right', default = 'both'
%       YLims      = Set yLimits for plot (yLim vector, default = [] i.e. auto) 


%      % TO DO: 

%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defParent       = [];
    defNBins        = 7;
    defDrawPoints   = true;
    defDrawMean     = true;
    defOneSided     = false;
    defPlotSide     = 'both';
    defDrawLegend   = true;
    defTitle        = "Confidence";
    defYLims        = [];

    % Validation functions
    valPlotSide = @(x) validateattributes(x, {'cell', 'string','char'}, {'nonempty'});
    valYLims    = @(x) validateattributes(x, {'numeric'}, ...
                       {'nonempty','increasing','numel',2});

    
    % add inputParser defaults and check var type
    addParameter(p, 'Parent', defParent, @ishandle);    
    addParameter(p, 'Title', defTitle, @(x) isstring(x));    
    addParameter(p, 'nBins', defNBins)
    addParameter(p, 'DrawPoints', defDrawPoints, @(x) islogical(x))
    addParameter(p, 'DrawMean', defDrawMean, @(x) islogical(x))
    addParameter(p, 'OneSided', defOneSided, @(x) islogical(x))
    addParameter(p, 'PlotSide', defPlotSide, valPlotSide)
    addParameter(p, 'DrawLegend', defDrawLegend, @islogical);
    addParameter(p, 'YLims', defYLims, @isnumeric);
        
    parse(p,varargin{:});
    
    parent      = p.Results.Parent;    
    nBins       = p.Results.nBins;
    drawPoints  = p.Results.DrawPoints;
    drawMean    = p.Results.DrawMean;
    drawLegend  = p.Results.DrawLegend;
    oneSided    = p.Results.OneSided;    
    plotSide    = p.Results.PlotSide;
    yLims       = p.Results.YLims;
    titleString = p.Results.Title;    
    
    plotSide = validatestring(plotSide,{'Left','Right','Both'});
    if oneSided && ~strcmp(plotSide,'Both')
        warning('Plotting a single decision side and absolute values, this makes little sense...');
    end
            
    if (oneSided || ~strcmp(plotSide,'Both')) && (nBins == defNBins)
        nBins = ceil(nBins/2);
    end        
  
%% Prepare Data

    % Remove any trials with zero evidence both sides
    ZeroEvidence = StimulusA == 0 & StimulusB == 0;
    StimulusA = StimulusA(~ZeroEvidence);
    StimulusB = StimulusB(~ZeroEvidence);
    waitingTime = waitingTime(~ZeroEvidence);
    Correct = Correct(~ZeroEvidence);
    Catch = Catch(~ZeroEvidence);
    Rewarded = Rewarded(~ZeroEvidence);

    % Stimulus normalization, difference over sum
    Stimulus = (StimulusA-StimulusB)./(StimulusA+StimulusB);
    
    % Trial Labels - Correct vs. Error
    correctLabel = "";
    correctLabel(find(Correct))  = "Correct";
    correctLabel(find(~Correct)) = "Error";
    correctLabel = cellstr(correctLabel(:));
    
    % Trial Labels - Correct & Catch
    trialTypes = string;
    trialTypes(Catch & Correct) = "Correct Catch";
    trialTypes(~Catch & Correct & ~Rewarded) = "Correct RDO";
    trialTypes(Catch & ~Correct) = "Error Catch";
    trialTypes(~Catch & ~Correct) = "Error";
    trialTypes(Rewarded) = "Rewarded";
    trialTypes = cellstr(trialTypes(:));
    
    % Prepare Gramm Data
    xData = Stimulus;
    yData = waitingTime; 
    
    if oneSided
        xData = abs(xData);
    end
%% Gramm Plotting
 
    % Setup universal properties    
    pairedCmap = colourPicker('paired');
    switch plotSide
        case 'Left'
            subset = xData <= 0;
        case 'Right'
            subset = xData >= 0;
        otherwise
            subset = ones(size(xData));
    end
            
    % First plot means and error for all correct vs. errors
    cData = cellstr(correctLabel);
    cmap = pairedCmap([4 6],:);

    g = gramm('x',xData,'y',yData,'color',cData,...
        'subset',subset  & (trialTypes ~= "Rewarded" & trialTypes ~= "Correct RDO"));
    if ~isempty(parent)
        g.set_parent(parent);
    end
    if ~drawLegend
        % g.set_layout_options('legend','false');
        g.no_legend('color');
    end
    if ~isempty(titleString)
        g.set_title(titleString);
    end  
    if ~isempty(yLims)
        g.axe_property('YLim',yLims);
    end
    
    g.set_color_options('map',cmap,'n_color',2,'n_lightness',1);
    g.set_names('x','Stimulus (Diff/Sum)','y','Waiting Time (s)');
    if drawMean
        g.stat_summary('bin_in',nBins,'geom',{'line','errorbar'},'type','sem');
        g.draw();
    end
    
    if drawPoints
        if ~isempty(parent)
          g.set_parent(parent);
        end
        cData = cellstr(trialTypes);
        cmap = pairedCmap([3 4 5 6],:);
        
        g.update('color',cData,'subset',subset & (cData ~= "Rewarded"));
        g.geom_point('alpha',0.5);
        g.set_color_options('map',cmap,'n_color',4,'n_lightness',1);
        % g.set_order_options('color',{"Correct","Error"},'lightness',{"Catch",""});
        g.set_names('x','Stimulus (Diff/Sum)','y','Waiting Time (s)');
        g.draw();
    end
    
    
    
%% Output   

    handle = g; % Handle


end 