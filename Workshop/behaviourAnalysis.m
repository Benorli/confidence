function fig = behaviourAnalysis(T, varargin)
% Plot a series of graphs charcterising behavioural performance in 2AFC task
%
%      SYNTAX
%      behaviourPerformance(T) : Where T is a 2AFC session table

%       OPTIONAL IN
%       Title: custom title for plot (string) !TO DO!



%% Parse variable input arguments
    
    p = inputParser; % Create object of class 'inputParser'
    
    % Create defaults 
    defTitle = "";

    % add inputParser defaults and check var type
    
    addParameter(p, 'Title', defTitle, @(x) isstring(x));
      
    parse(p,varargin{:});
    
    figTitle  = p.Results.Title;
    

    %% Create figure and uipanels for plotting
    % Figure will be 4 x 3 panels with the following layout:
    % Sampling Distribution, Psychometric; Performance; Drop Out Dist;
    % WT x Trial type, scatter plots veviaometric (left, right both)
    % veviaometric mean, veviaometric single, Accuracy x WT, WT split Psychometric
  
    fig = figure('Position',[200 100 1200 800],'Color',[1 1 1]);
    panels = createSubPanels(4,3,'Handle',fig,'Title',false);
    
    %% Plotting is done here
    
    % Panel 1 = Sampling Times Histogram
    plotHandles(1,1) = samplingHisto2AFC(T.samplingDuration,...
        'Parent',panels(1),'Title',"");
    
    % Panel 2 = Psychometric
    sdo = ~T.completedSampling;
    rdo = T.correctSideChosenClicks & ~T.completedCatchTrial & ~T.rewarded;
    plotHandles(2,1) = psychometric2AFC(T.nRightClicks,T.nLeftClicks,...
        T.sideChosen,'SDO',sdo,'RDO',rdo,...
        'Parent',panels(2),'Title',"");
        
    % Panel 3 = Perormance
    plotHandles(3,1) = performance2AFC(T.highEvidenceSideClicks,...
        T.sideChosen,T.completedSampling,T.completed,...
        T.completedCatchTrial,T.rewardDelayBpod,T.waitingTime,...
        'Parent',panels(3),'DrawLegend',false,'Title',"");
    
    % Panel 4 = Drop Outs x WT
    plotHandles(4,1) = dropOuts2AFC(T.highEvidenceSideClicks,T.sideChosen,...
        T.completed,T.completedCatchTrial,T.rewardDelayBpod,T.waitingTime,...
        'Parent',panels(4),'DrawLegend',false,'Title',"");
    
    % Panel 5 = Drop Outs x WT
    plotHandles(1,2) = waitingTime2AFC(T.correctSideChosenClicks, ...
        T.catchTrial, T.completed, T.waitingTime,...
        'Parent',panels(5),'DrawLegend',false,'Title',"");  
    
    % Panel 6 = Veviometric Scatter Plot - Left
    plotHandles(2,2) = Vevaiometric2AFC(T.nRightClicks,T.nLeftClicks,...
        T.waitingTime,T.correctSideChosenClicks, ...
        T.catchTrial, T.rewarded,'PlotSide','Left',...
        'DrawPoints',true','DrawMean',false,... % 'YLims',[0 8.5]
        'Parent',panels(6),'DrawLegend',false,'Title',"");  

    % Panel 7 = Veviometric Scatter Plot - Right
    plotHandles(3,2) = Vevaiometric2AFC(T.nRightClicks,T.nLeftClicks,...
        T.waitingTime,T.correctSideChosenClicks, ...
        T.catchTrial, T.rewarded,'PlotSide','Right',...
        'DrawPoints',true','DrawMean',false,... %'YLims',[0 8.5],...
        'Parent',panels(7),'DrawLegend',false,'Title',"");      
    
    % Panel 8 = Veviometric Scatter Plot - Single Sided
    plotHandles(4,2) = Vevaiometric2AFC(T.nRightClicks,T.nLeftClicks,...
        T.waitingTime,T.correctSideChosenClicks, ...
        T.catchTrial, T.rewarded,'OneSided',true,...
        'DrawPoints',true','DrawMean',false,... %'YLims',[0 8.5],...
        'Parent',panels(8),'DrawLegend',false,'Title',"");  
    
     % Panel 9 = Veviometric Mean Plot - Both Sides
    plotHandles(1,3) = Vevaiometric2AFC(T.nRightClicks,T.nLeftClicks,...
        T.waitingTime,T.correctSideChosenClicks, ...
        T.catchTrial, T.rewarded,'OneSided',false,...
        'DrawPoints',false,'DrawMean',true,... %'YLims',[2 8],...
        'Parent',panels(9),'DrawLegend',false,'Title',"");  
    
     % Panel 10 = Veviometric Mean Plot - Single Sided
    plotHandles(2,3) = Vevaiometric2AFC(T.nRightClicks,T.nLeftClicks,...
        T.waitingTime,T.correctSideChosenClicks, ...
        T.catchTrial, T.rewarded,'OneSided',true,...
        'DrawPoints',false,'DrawMean',true,... %'YLims',[2 8],...
        'Parent',panels(10),'DrawLegend',false,'Title',"");  
    
    % Panel 11 = Accuracy vs. Waiting Time (Catch Trials)
    plotHandles(3,3) = accuracy2AFC(T.correctSideChosenClicks,...
                    T.completedCatchTrial, T.waitingTime,...
                    'Parent',panels(11),'Title',"");  
    