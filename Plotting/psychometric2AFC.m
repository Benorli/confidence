function [handle] = psychometric2AFC(stimulusA, stimulusB, choice, varargin)
% Plot a psychometric curve for a 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      Psychometric2AFC(StimulusA, StimulusB, Choice) takes a vector of 
%           click counts for each side (StimulusA/StimulusB) and choice, a 
%           vector of decisions. It then plots a psychometric. 
%
%       OPTIONAL IN
%       Parent  = Handle to figure to plot in (handle)
%       nBins   = number of bins, scalar
%       SDO     = Vector of Sampling Drop Outs, will plot proportion of
%                 dropouts at each difficulty bin
%       RDO     = Vector of Reward Drop Outs, same as SDO
%       Title  = Title string, pass an empty string to leave blank 
%                (string/empty, default = 'Confidence')
%       DrawFit    = Draw a binomial distribution fit to the data (logical)
%       DrawTrials = Label the number of trials at each data point (logical)
%       BaseFontSize = base font size, scalar number
 



%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defNBins = 7;
    defParent   = [];
    defTitle     = "Psychometric";
    defDrawFit       = true;
    defDrawTrials    = true;
    defSDO           = [];
    defRDO           = [];
    defBaseSize     = 16;
  
    % Validation functions
    %valNumNonEmpty = @(x) validateattributes(x, {'numeric'},{'nonempty'});
    valDropOuts    = @(x) validateattributes(x, {'numeric','logical'},...
                                             {'nonempty'});
    valNumScalar   = @(x) validateattributes(x, {'numeric'}, ...
                       {'scalar'});

    % add inputParser defaults and check var type
    addParameter(p, 'Title', defTitle, @(x) isstring(x));    
    addParameter(p, 'nBins', defNBins, @(x) isscalar(x));
    addParameter(p, 'Parent', defParent, @(x) ishandle(x));
    addParameter(p, 'DrawFit', defDrawFit, @(x) islogical(x));
    addParameter(p, 'DrawTrials', defDrawTrials, @(x) islogical(x));
    addParameter(p, 'SDO', defSDO, valDropOuts);
    addParameter(p, 'RDO', defRDO, valDropOuts);
    addParameter(p, 'BaseFontSize', defBaseSize, valNumScalar);
    
    parse(p,varargin{:});
    
    nBins           = p.Results.nBins;
    titleString     = p.Results.Title;
    drawFit         = p.Results.DrawFit;
    % drawMean        = p.Results.DrawMean;
    drawTrials      = p.Results.DrawTrials;
    parent          = p.Results.Parent;
    sdo             = p.Results.SDO;
    rdo             = p.Results.RDO; 
    baseFontSize    = p.Results.BaseFontSize;
 
    %% Prepare Data
    
    % Stimulus normalization, difference over sum
    stimulus = (stimulusA-stimulusB)./(stimulusA+stimulusB);   
 
    % Convert categorical choice to numbers;
    if iscategorical(choice)
        oldChoice = choice;
        newChoice = zeros(size(choice));
        newChoice(choice == 'noChoice') = nan;
        newChoice(choice == 'left') = 0;
        newChoice(choice == 'right') = 1;
        choice = newChoice;
    end        
            
    % Remove any trials with zero evidence both sides
    zeroEvidence = stimulusA == 0 & stimulusB == 0;
    stimulusA = stimulusA(~zeroEvidence);
    stimulusB = stimulusB(~zeroEvidence);
    choice = choice(~zeroEvidence);    
    stimulus = stimulus(~zeroEvidence);  
            
%% Plotting with gramm
  
    cmap = colourPicker('ylGnBu',9);
    g = gramm('x',stimulus,'y',choice);
    g.stat_summary('bin_in',nBins,...
       'geom',{'line','errorbar'});
    g.set_color_options('map',cmap(5,:),'n_color',1,'n_lightness',1);
            
    if ~isempty(titleString)
        g.set_title(titleString);
    end
    if ~isempty(parent)
        g.set_parent(parent);
    end
        
    % Mark 10 & 90% and 0 point
    g.geom_hline('yintercept',0.1,'style','k:');
    g.geom_hline('yintercept',0.9,'style','k:');
    % g.geom_vline('xintercept',0,'style','k:')
    
    % set labels
    g.set_names('x','Evidence (difference/sum)','y','Proportion Right Choice');
    g.set_text_options('base_size', baseFontSize);
    g.axe_property('TickDir', 'out');
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
    
    if drawFit
        g.update('color',ones(size(stimulus)));
        g.set_color_options('map',cmap(8,:),'n_color',1,'n_lightness',1);
        g.stat_glm('distribution','binomial','geom','line');
        g.draw();  
    end
    
    % if SDO was provided
    if ~isempty(sdo)
        dropMap   = colourPicker('Inferno',9);
        g.update('y',sdo(~zeroEvidence),'color',ones(size(stimulus)));
        g.set_color_options('map',dropMap(6,:),'n_color',1,'n_lightness',1);
        g.stat_summary('bin_in',nBins,'geom','line');
        g.draw();  
    end
    
        % if RDO was provided
    if ~isempty(rdo)
        dropMap   = colourPicker('Inferno',9);
        g.update('y',rdo(~zeroEvidence),'color',ones(size(stimulus)));
        g.set_color_options('map',dropMap(2,:),'n_color',1,'n_lightness',1);
        g.stat_summary('bin_in',nBins,'geom','line');
        g.draw();  
    end

    handle = g;
end 
    