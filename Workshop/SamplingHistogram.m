function [AxesHandle] = SamplingHistogram(SamplingTimes, varargin)
% Sampling time plot
% Include n on each bar

   %% Parse inputs
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    DefaultThreshold = 0.15;
    DefaultBinSize = 0.01;
    
    % add inputParser methods
    addParameter(p,...
        'Threshold', DefaultThreshold,... 
        @(x) isnumeric(x))
    addParameter(p,...
        'BinSize', DefaultBinSize,... 
        @(x) isnumeric(x))
    
    parse(p,varargin{:});
    
    Threshold = p.Results.Threshold;
    BinSize = p.Results.BinSize;
    
    %% Plotting
    
    hold on
    histogram(SamplingTimes,...
        'BinWidth', BinSize,...
        'FaceColor', 'blue',...
        'EdgeColor', 'none');
    line([Threshold,Threshold], ylim, 'Color', [0.7 0.7 0.7], 'LineWidth', 2);
    ylim([0 inf])
    
    AxesHandle = gca;
    
    title('Sampling Time Ditribution')