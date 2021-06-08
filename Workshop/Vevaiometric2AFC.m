function [varargout] = Vevaiometric2AFC(StimulusA, StimulusB, WT, Correct, Catch, Rewarded, varargin)
% Plot a psychometric curve for a 2 alternative forced choice (2AFC) task
%
%      SYNTAX
%      [AxesHandle] = Psychometric2AFC()
%       
%      DESCRIPTION
%      
%
%      NOTES: 
%      
%
%      % TO DO: 

%% Parse variable input arguments
    
    VarArgs = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    DefaultTitle = 'on';
    ExpectedDefaultTitleOptions = {'on', 'off'};
    DefaultnBins = 7;
    DefaultOptionA = 'Left';
    DefaultOptionB = 'Right';
    DefaultNameVal = {}; % Pass onto plot as {:}
    
    % add inputParser defaults and check var type
    addParameter(VarArgs,'nBins', DefaultnBins)
    addParameter(VarArgs, 'DefaultTitle', DefaultTitle,... 
        @(x) any(validatestring(x,ExpectedDefaultTitleOptions)))
    addParameter(VarArgs, 'OptionA', DefaultOptionA, @(x) isstring(x))
    addParameter(VarArgs, 'OptionB', DefaultOptionB, @(x) isstring(x))
    addParameter(VarArgs, 'ScatterNameVal', DefaultNameVal, @(x) iscell(x))
    addParameter(VarArgs, 'ErrorBarNameVal', DefaultNameVal, @(x) iscell(x))
    
    parse(VarArgs,varargin{:});

%% Prepare Data

    % Remove any trials with zero evidence both sides
    ZeroEvidence = StimulusA == 0 & StimulusB == 0;
    StimulusA = StimulusA(~ZeroEvidence);
    StimulusB = StimulusB(~ZeroEvidence);
    WT = WT(~ZeroEvidence);
    Correct = Correct(~ZeroEvidence);
    Catch = Catch(~ZeroEvidence);
    Rewarded = Rewarded(~ZeroEvidence);

    % Stimulus normalization, difference over sum
    Stimulus = (StimulusA-StimulusB)./(StimulusA+StimulusB);
    
    % Compute Bin edges and centres
    [BinEdges, DV_BinCenters] = BinVals(VarArgs.Results.nBins, -1, 1);
    
    % Binning
    BinnedData = discretize(Stimulus, BinEdges);
    
%% Define Trial conditions

    % Waiting time given trial condition
    WT_CorrectCatch = WT(~isnan(WT) & Catch == 1 & Correct == 1);
    WT_CorrectDropOut = WT(~isnan(WT) & Catch == 0 & Correct == 1 & ~Rewarded);
    WT_ErrorCatch = WT(~isnan(WT) & Catch == 1 & Correct == 0);
    WT_Error = WT(~isnan(WT) & Correct == 0);
    
    % Waiting time given trial condition
    Stimulus_CorrectCatch = Stimulus(~isnan(WT) & Catch == 1 & Correct == 1);
    Stimulus_CorrectDropOut = Stimulus(~isnan(WT) & Catch == 0 & Correct == 1 & ~Rewarded);
    Stimulus_ErrorCatch = Stimulus(~isnan(WT) & Catch == 1 & Correct == 0);
    Stimulus_Error = Stimulus(~isnan(WT) & Correct == 0);
    
    % Bin given trial condition
    Bin_CorrectCatch = BinnedData(~isnan(WT) & Catch == 1 & Correct == 1);
    Bin_CorrectDropOut = BinnedData(~isnan(WT) & Catch == 0 & Correct == 1 & ~Rewarded);
    Bin_ErrorCatch = BinnedData(~isnan(WT) & Catch == 1 & Correct == 0);
    Bin_Error = BinnedData(~isnan(WT) & Correct == 0);
    
%% Calculate statistics

    % Group statistics for each condition
    [WT_CorrectCatch_Avg, WT_CorrectCatch_STD, WT_CorrectCatch_nPoints] = grpstats(WT_CorrectCatch,...
        Bin_CorrectCatch, {'mean', 'std', 'numel'});
    [WT_CorrectDropOut_Avg, WT_CorrectDropOut_STD, WT_CorrectDropOut_nPoints] = grpstats(WT_CorrectDropOut,...
        Bin_CorrectDropOut, {'mean', 'std', 'numel'});
    [WT_ErrorCatch_Avg, WT_ErrorCatch_STD, WT_ErrorCatch_nPoints] = grpstats(WT_ErrorCatch,...
        Bin_ErrorCatch, {'mean', 'std', 'numel'});
    [WT_Error_Avg, WT_Error_STD, WT_Error_nPoints] = grpstats(WT_Error,...
        Bin_Error, {'mean', 'std', 'numel'});
    
%% Init plotting
    
    hold on

%% Plot errorbars

    % Correct catch
    h.WT_CorrectCatch_ErrorBarHandle = errorbar(DV_BinCenters(unique(Bin_CorrectCatch)),...
        WT_CorrectCatch_Avg,...
        WT_CorrectCatch_STD,...
        'Color', [0.8 1 0.8],... 
        'LineStyle', 'none',...
        VarArgs.Results.ErrorBarNameVal{:});
    % Correct drop out
    h.WT_CorrectDropOut_ErrorBarHandle = errorbar(DV_BinCenters(unique(Bin_CorrectDropOut)),...
        WT_CorrectDropOut_Avg,...
        WT_CorrectDropOut_STD,...
        'Color', [0.8 1 0.8],... 
        'LineStyle', 'none',...
        VarArgs.Results.ErrorBarNameVal{:});
    % Error catch
    h.WT_ErrorCatch_ErrorBarHandle = errorbar(DV_BinCenters(unique(Bin_ErrorCatch)),...
        WT_ErrorCatch_Avg,...
        WT_ErrorCatch_STD,...
        'Color', [1 0.8 0.8],... 
        'LineStyle', 'none',...
        'Visible', 'off',...
        VarArgs.Results.ErrorBarNameVal{:});
    % Error drop out
    h.WT_Error_ErrorBarHandle = errorbar(DV_BinCenters(unique(Bin_Error)),...
        WT_Error_Avg,...
        WT_Error_STD,...
        'Color', [1 0.8 0.8],... 
        'LineStyle', 'none',...
        VarArgs.Results.ErrorBarNameVal{:});
    
%% Plot data line

    % Correct catch
    h.WT_CorrectCatch_PlotHandle = plot(DV_BinCenters(unique(Bin_CorrectCatch)),...
        WT_CorrectCatch_Avg,...
        'Color', [0.2 1 0.2],... 
        'LineWidth', 1.5,...
        VarArgs.Results.ErrorBarNameVal{:});
    % Correct drop out
    h.WT_CorrectDropOut_PlotHandle = plot(DV_BinCenters(unique(Bin_CorrectDropOut)),...
        WT_CorrectDropOut_Avg,...
        'Color', [0.5 1 0.5],... 
        VarArgs.Results.ErrorBarNameVal{:});
    % Error catch
    h.WT_ErrorCatch_PlotHandle = plot(DV_BinCenters(unique(Bin_ErrorCatch)),...
        WT_ErrorCatch_Avg,...
        'Color', [1 0.5 0.5],...
        'Visible', 'off',...
        VarArgs.Results.ErrorBarNameVal{:});
    % Error drop out
    h.WT_Error_PlotHandle = plot(DV_BinCenters(unique(Bin_Error)),...
        WT_Error_Avg,...
        'Color', [1 0.2 0.2],... 
        'LineWidth', 1.5,...
        VarArgs.Results.ErrorBarNameVal{:});
    
%% Plot data points

    % Correct catch
    h.WT_CorrectCatch_ScatterHandle = plot(Stimulus_CorrectCatch,...
        WT_CorrectCatch,...
        'LineStyle', 'none',...
        'Marker', 'o',...
        'MarkerFaceColor', [0 1 0],...
        VarArgs.Results.ErrorBarNameVal{:});
    % Correct drop out
    h.WT_CorrectDropOut_ScatterHandle = plot(Stimulus_CorrectDropOut,...
        WT_CorrectDropOut,...
        'LineStyle', 'none',...
        'Marker', 'o',...
        'MarkerFaceColor', 'none',...
        'MarkerEdgeColor', [0.5 1 0.5],...
        VarArgs.Results.ErrorBarNameVal{:});
    % Error catch
    h.WT_ErrorCatch_ScatterHandle = plot(Stimulus_ErrorCatch,...
        WT_ErrorCatch,...
        'LineStyle', 'none',...
        'Marker', 'o',...
        'MarkerFaceColor', 'r',...
        'Visible', 'off',...
        VarArgs.Results.ErrorBarNameVal{:});
    % Error drop out
    h.WT_Error_ScatterHandle = plot(Stimulus_Error,...
        WT_Error,...
        'LineStyle', 'none',...
        'Marker', 'o',...
        'MarkerFaceColor', 'r',...
        'MarkerEdgeColor', 'r',...
        VarArgs.Results.ErrorBarNameVal{:});
    
%% Axes properties
    
    % Set axes limits
    xlim([-1, 1])
    ylim([0, (max(WT) + 1.1)])
    
    % Set default labels
    if strcmp(VarArgs.Results.DefaultTitle, 'on')
        title('Vevaiometric Plot for a Two Alternative Forced Choice Task')
             xlabel(sprintf('Difference Over Sum of %s vs %s',...
                 VarArgs.Results.OptionB, VarArgs.Results.OptionA));
             ylabel('Waiting Time (s)');
    end 
    
%% Fitting
%     
%     [CorrectCacthFit, CorrectCatch_gof] = fit(Stimulus_CorrectCatch.', WT_CorrectCatch.', 'poly2');
% 
%     [ErrorFit, Error_gof] = fit(Stimulus_Error.', WT_Error.', 'poly2');
% 
%      
%      % Plot fit
%      h.Fit1 = plot(CorrectCacthFit);
%      h.Fit2 = plot(ErrorFit);
%      
%      h.Fit1.Color = 'g';
%      h.Fit1.Color = 'r';

%% Text

    h.Axes = gca;
    
    % Corner text
    CornerString = {sprintf('n Correct catch = %s', num2str(numel(WT_CorrectCatch)));
        sprintf("n Correct but did't wait = %s", num2str(numel(WT_CorrectDropOut)));
        sprintf('n Error catch = %s', num2str(numel(WT_ErrorCatch)));
        sprintf('n Error = %s', num2str(numel(WT_Error)))};
    h.CornerText = text(h.Axes, -0.9, h.Axes.YLim(2), CornerString,...
        'VerticalAlignment', 'top');
    
    % n values for each bin
    h.PlotText.CorrectCatch = text(DV_BinCenters(unique(Bin_CorrectCatch)),...
        WT_CorrectCatch_Avg,...
        num2str(WT_CorrectCatch_nPoints));
    h.PlotText.CorrectDropOut = text(DV_BinCenters(unique(Bin_CorrectDropOut)),...
        WT_CorrectDropOut_Avg,...
        num2str(WT_CorrectDropOut_nPoints));
    h.PlotText.ErrorCatch = text(DV_BinCenters(unique(Bin_ErrorCatch)),...
        WT_ErrorCatch_Avg,...
        num2str(WT_ErrorCatch_nPoints),...
        'Visible', 'off');
    h.PlotText.Error = text(DV_BinCenters(unique(Bin_Error)),...
        WT_Error_Avg,...
        num2str(WT_Error_nPoints));
   
   hold off
   
    
%% Output   

    varargout{1} = h; % Handle
    %varargout{2} = constant;
    %varargout{3} = gof; % Quality of fit: Squared norm of the residual
    %varargout{4} = residual; % Quality of fit 

end 