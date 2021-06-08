function [figHandle, responseData] = responsePlot(varargin)
%% Generates a plots that characterises an individual cells 
%  response to the confidence task (2AFC). 
% INPUT: 
% spikeTimes = a column vector of spike times,
% T          = a Table of Bpod data, must include the variable 
%              ephysTrialStartTime. 
% Generate with 'preProcessSessionData' or 'parseIntanSessionData'
% Optional Parameters:
%       BinSize: Width of bins to use for PSTH  
%       Percentile  : Divisions in WT to use for plotting groups 
%       Previous    : The amount of time (ms) before the event to include.
%       Post        : The amount of time (ms) after the event to include
%       RmOutliers  : Logical, remove extreme high waiting times. 
%                     Default = false;

% Will generate the following subplots:
% 1) PSTH of Voluntary Withdrawal Trials (Errors + Catch)
% 2) PSTH of Rewarded Trials

%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defBinSize   = 100;  % in ms
defPercentile = [0 50 100];
defParent     = [];
defPrev  = []; % defaults to longest waiting time
defPost  = 1000; % in ms
defRmOutliers = false;

% validation funs
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar'});
valTable = @(x) validateattributes(x, {'table'},...
    {'nonempty'}); % Could build a custom validator for Bpod Table
valPercentile = @(x) validateattributes(x, {'numeric'},...
    {'row','nonempty','>=', 0, '<=', 100,'increasing'});
valBinaryScalar = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'scalar'});
    
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'T', valTable);
addParameter(p, 'BinSize', defBinSize, valNumScalarNonEmpty);
addParameter(p, 'Percentile', defPercentile, valPercentile);
addParameter(p, 'Parent', defParent, @ishandle);
addParameter(p, 'Previous', defPrev, valNumScalarNonEmpty);
addParameter(p, 'Post', defPost, valNumScalarNonEmpty);
addParameter(p, 'RmOutliers', defRmOutliers, valBinaryScalar);

parse(p, varargin{:});

spikeTimes  = p.Results.spikeTimes; 
T           = p.Results.T;
sbin        = p.Results.BinSize;
percentiles = p.Results.Percentile;
figParent   = p.Results.Parent;
prev        = p.Results.Previous;
post        = p.Results.Post;
rmOutliers  = p.Results.RmOutliers;

clear p

assert(any(strcmp(T.Properties.VariableNames,'ephysTrialStartTime')),...
    'Bpod Session Table doesn''t contain ephys trial start times...');

%% Gather trial data

if rmOutliers % Calculate per trial stats
    responseData = responseStats(spikeTimes,T,...
    'BinSize',sbin,'Percentile',percentiles,'Plot',false,'Smooth',true);   
end

% Make labels for groups;
for prcI = 1:length(percentiles) - 1
    if percentiles(prcI) == 0
        categories{prcI} = ['WT <= ' num2str(percentiles(prcI+1)) '%'];
    else
        categories{prcI} = ['WT ' num2str(percentiles(prcI)) ...
                            ' - ' num2str(percentiles(prcI+1)) '%'];
    end  
end

% Find Rewarded Trials
rewardTrials = find(T.rewarded);
if rmOutliers
    % method 1 - use rmoutliers will remove values +- 3*MAD
    % typically just high values
    % [~,outlierIdx] = rmoutliers(T.waitingTime(rewardTrials));   
%      rewardTrials = rewardTrials(~outlierIdx); 
    % method 2 - remove the top and bottom extreme 2.5% (5% total)
%     outlierPrctiles = prctile(T.waitingTime(rewardTrials),[2.5 97.5]);
%     outlierIdx =  find(T.waitingTime(rewardTrials) < outlierPrctiles(1) | ...
%                        T.waitingTime(rewardTrials) > outlierPrctiles(2));
%     rewardTrials(outlierIdx) = []; 
    % Method 3 - use response stats calcualtion to remove -ve slope trials
    selectedRewardTrials = responseData.rewardTrial.Slope > 5;
    rewardTrials = rewardTrials(selectedRewardTrials);
end

rewardTimes  = [T.trialEndTime(rewardTrials), ...
                T.waitingStartTime(rewardTrials)] ...
             +  T.ephysTrialStartTime(rewardTrials); 
      
rewardSplits = prctile(T.waitingTime(rewardTrials),percentiles);
rewardGroups = discretize(T.waitingTime(rewardTrials),rewardSplits,...
               'categorical',categories);
% find plot limits
if isempty(prev)
    rewardPrev = max(T.waitingTime(rewardTrials)).*1000;
else
    rewardPrev = prev;
end

% Find Unrewarded Trials
leaveTrials  = find(T.selfExit);
if rmOutliers
    % method 1 - use rmoutliers will remove values +- 3*MAD
    % typically just high values
    % [~,outlierIdx] = rmoutliers(T.waitingTime(leaveTrials));    
    % leaveTrials = leaveTrials(~outlierIdx); 
    % method 2 - remove the top and bottom extreme 2.5% (5% total)
%     outlierPrctiles = prctile(T.waitingTime(leaveTrials),[2.5 97.5]);
%     outlierIdx =  find(T.waitingTime(leaveTrials) < outlierPrctiles(1) | ...
%                        T.waitingTime(leaveTrials) > outlierPrctiles(2));
%     leaveTrials(outlierIdx) = [];  
    % Method 3 - remove -ve slope trials
    selectedLeaveTrials  = responseData.leaveTrial.Slope > 5;
    leaveTrials  = leaveTrials(selectedLeaveTrials);
end
leaveTimes  = [T.trialEndTime(leaveTrials), ...
                T.waitingStartTime(leaveTrials)] ...
             +  T.ephysTrialStartTime(leaveTrials);   
leaveSplits = prctile(T.waitingTime(leaveTrials),percentiles);
leaveGroups = discretize(T.waitingTime(leaveTrials),leaveSplits,...
              'categorical',categories);        
% find plot limits
if isempty(prev)
    leavePrev = max(T.waitingTime(leaveTrials)).*1000;
else
    leavePrev = prev;
end

%% Plot Data
% Setup figure
responseFig = figure;
% responseFig.Position = [100 200 1200 800];
responseFig.Color = [1 1 1];

% create panels to hold  plots
figPanels = createSubPanels(1,2,'Handle',responseFig,'title',true);

plotHandles(1) = groupPsthTrialLimits(spikeTimes,rewardTimes,rewardGroups,...
    'Previous',rewardPrev,'Post',post,'BinSize',sbin,...
    'PlotType',2,'Parent',figPanels(1),'Title','Rewarded Trials');

plotHandles(2) = groupPsthTrialLimits(spikeTimes,leaveTimes,leaveGroups,...
    'Previous',leavePrev,'Post',post,'BinSize',sbin,...
    'PlotType',2,'Parent',figPanels(2),'Title','Error + Catch Trials');


