function [varargout] = psychometric2AFC(stimulusA, stimulusB, choice, varargin)
% Plot a psychometric curve for a 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      Psychometric2AFC(StimulusA, StimulusB, Choice) takes a vector of 
%           click counts for each side (StimulusA/StimulusB) and choice, a 
%           vector of decisions. It then plots a psychometric. 
%
%       OPTIONAL IN
%       nBins: number of bins, scalar
%       DefaultTitle: on or off
%       OptionA/OptionB: Title for each A/B Stimulus resptectivly
%       SaturationMax: Value of horizontal line to represent saturation
%       SaturationMin: Value of horizontal line to represent saturation
%       TxtHozShift: Scalar, how much to shift text
%       PlotNameVal: Cell array of Name Values to feed to plot function
%       ErrorBarNameVal: Cell array of Name Values to feed to ErrorBar 
%           function.
%       FitNameVal:Cell array of Name Values to feed to fit function



%% Parse variable input arguments
    
    VarArgs = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    DefaultnBins = 7;
    DefaultTitle = 'on';
    ExpectedDefaultTitleOptions = {'on', 'off'};
    DefaultOptionA = 'Left';
    DefaultOptionB = 'Right';
    DefaultSaturationMax = 0.9;
    DefaultSaturationMin = 0.1;
    DefaultTxtHozShift = 0;
    DefaultNameVal = {}; % Pass onto plot as {:}
    
    % add inputParser defaults and check var type
    addParameter(VarArgs,'nBins', DefaultnBins, @(x) isscalar(x))
    addParameter(VarArgs, 'DefaultTitle', DefaultTitle,... 
        @(x) any(validatestring(x,ExpectedDefaultTitleOptions)))
    addParameter(VarArgs, 'OptionA', DefaultOptionA, @(x) isstring(x))
    addParameter(VarArgs, 'OptionB', DefaultOptionB, @(x) isstring(x))
    addParameter(VarArgs, 'SaturationMax', DefaultSaturationMax, @(x) isscalar(x))
    addParameter(VarArgs, 'SaturationMin', DefaultSaturationMin, @(x) isscalar(x))
    addParameter(VarArgs, 'TxtHozShift', DefaultTxtHozShift, @(x) isscalar(x))
    addParameter(VarArgs, 'PlotNameVal', DefaultNameVal, @(x) iscell(x))
    addParameter(VarArgs, 'ErrorBarNameVal', DefaultNameVal, @(x) iscell(x))
    addParameter(VarArgs, 'FitNameVal', DefaultNameVal, @(x) iscell(x))
    
    parse(VarArgs,varargin{:});

%% Prepare Data

    % Remove any trials with zero evidence both sides
    zeroEvidence = stimulusA == 0 & stimulusB == 0;
    stimulusA = stimulusA(~zeroEvidence);
    stimulusB = stimulusB(~zeroEvidence);
    choice = choice(~zeroEvidence);
  
    % Stimulus normalization, difference over sum
    stimulus = (stimulusA-stimulusB)./(stimulusA+stimulusB);
    
    % Compute Bin edges and centres
    [binEdges, DV_BinCenters] = binVals(VarArgs.Results.nBins, -1, 1);
    
    % Binning
    binnedData = discretize(stimulus, binEdges);
    
    % Index of a trials a choice was made
    choiceMadeIdx = ~isnan(choice);
    
    [ProbabilityLeft, sem, nPoints] = grpstats(choice(choiceMadeIdx),...
        binnedData(choiceMadeIdx), {'mean', 'sem', 'numel'});
    
    % Exclude Bins without data
    DV_BinCenters = DV_BinCenters(unique(binnedData(choiceMadeIdx)));
    
%% Plot Data 

    hold on

    % Plot data and errorbars
    h.ErrorBarHandle = errorbar(DV_BinCenters , ProbabilityLeft, sem,...
        'Color', [0.8 0.8 0.8],... 
        'LineStyle', 'none',...
        VarArgs.Results.ErrorBarNameVal{:});
    h.DataLineHandle = line(DV_BinCenters , ProbabilityLeft,...
        'LineWidth', 2,...
        'Color', [0.6 0.6 1],...
        VarArgs.Results.PlotNameVal{:});
    
    % Lines for visual orientation
    h.OrientLine.Middle = plot([-1,1],...
        [0.5,0.5],...
        'Color', [0.8 0.8 0.8]);
    h.OrientLine.Max = plot([-1,1],...
        [DefaultSaturationMax ,DefaultSaturationMax],... 
        'Color', [0.9 0.9 0.9]);
    h.OrientLine.Min = plot([-1,1],...
        [DefaultSaturationMin, DefaultSaturationMin],... 
        'Color', [0.9 0.9 0.9]);
    
    % Set axes limits
    xlim([-1, 1])
    ylim([0, 1])
    
    % Set default labels
    if strcmp(VarArgs.Results.DefaultTitle, 'on')
        title('Psychometric Plot for a Two Alternative Forced Choice Task')
             xlabel(sprintf('Difference Over Sum of %s Clicks vs %s',...
                 VarArgs.Results.OptionB, VarArgs.Results.OptionA));
             ylabel(sprintf('P(%s Choice)', VarArgs.Results.OptionA));
    end 
    
%% Fitting

    % Assumes 1st input will be constant/s, THEN data, can switch with
    % function handle
    [constant, resnorm, residual] = lsqcurvefit(@sig,... Function you will fit
        [0, 0],... Arbitrary starting constant values
        DV_BinCenters, ProbabilityLeft.'); % data x,y
    
    % Plot fit
    h.Fit = line(-1:0.001:1, sig(constant, -1:0.001:1),...
        'LineWidth', 1.5',...
        VarArgs.Results.FitNameVal{:});

%% Text

   nNumber = length(stimulusA);
   h.CornerText.nTotal = text(-0.95 + VarArgs.Results.TxtHozShift, 0.95,...
       strcat('n = ', num2str(nNumber)));
   h.CornerText.Slope = text(-0.95 + VarArgs.Results.TxtHozShift, 0.91,...
       strcat('Slope = ', num2str(round(constant(1), 3))));
   h.CornerText.Midpoint = text(-0.95 + VarArgs.Results.TxtHozShift, 0.87,...
       strcat('x Midpoint =  ', num2str(round(constant(2), 3))));
   h.CornerText.Goodness = text(-0.95 + VarArgs.Results.TxtHozShift, 0.83,...
       strcat('Goodness of fit =  ', num2str(round(resnorm, 3))));

   h.PlotText.nNumbers = text(DV_BinCenters, ProbabilityLeft,...
       num2str(nPoints));
   
   hold off
   
   h.Axes = gca;
    
%% Output   

    varargout{1} = h; % Handle
    varargout{2} = constant;
    varargout{3} = resnorm; % Quality of fit: Squared norm of the residual
    varargout{4} = residual; % Quality of fit 

end 


function y = sig(constant, x)
% return sigmoid/logistic function of x
% constant(1) = steepness of curve
% constant(2) = x value of sigmoid midpoint

    y = 1 ./ (1 + exp(-constant(1).*(x - constant(2))));

end

function [varargout] = binVals(nBins, Min, Max)
% Calculate the Edge and centers of Bins given the number of bins and the
% minumum/ maximum of the bin range

    binEdges = linspace(Min, Max, nBins + 1);
    binWidth = 1/nBins;
    binCenters = binEdges(2:end) - binWidth;
    
    varargout{1} = binEdges;
    varargout{2} = binCenters;
end

    