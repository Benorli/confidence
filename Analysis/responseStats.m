function [responseData, statsFig] = responseStats(varargin)
%% Calculates Statistics on cells behavioural response 
% to the confidence task (2AFC). 
% INPUT: 
% spikeTimes = a column vector of spike times,
% T          = a Table of Bpod data, must include the variable 
%              ephysTrialStartTime. 
% Generate with 'preProcessSessionData' or 'parseIntanSessionData'
% Optional Parameters:
%       BinSize: Width of bins to use for PSTH based statistics    
%       Smooth: Logical, whether to smooth data for PSTH stats
%       Plot: Logical, whether to make plots of data
%       Percentiles : Divisions in WT to use for stats 

%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defBinSize    = 100;  % in ms
defSmooth     = false; % Smooth data
defPlot       = false; % Plot data
defPercentile = [0 50 100]; 
defParent     = [];

% validation funs
valNumColNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'column'});
valNumScalarNonEmpty = @(x) validateattributes(x, {'numeric'},...
    {'nonempty', 'scalar'});
valTable = @(x) validateattributes(x, {'table'},...
    {'nonempty'}); % Could build a custom validator for Bpod Table
valBinaryScalar = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'scalar'});
valPercentile = @(x) validateattributes(x, {'numeric'},...
    {'row','nonempty','>=', 0, '<=', 100,'increasing'});
    
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'T', valTable);
addParameter(p, 'BinSize', defBinSize, valNumScalarNonEmpty);
addParameter(p, 'Smooth', defSmooth, valBinaryScalar);
addParameter(p, 'Plot', defPlot, valBinaryScalar);
addParameter(p, 'Parent', defParent, @ishandle);
addParameter(p, 'Percentile', defPercentile, valPercentile);

parse(p, varargin{:});

spikeTimes  = p.Results.spikeTimes; 
T           = p.Results.T;
binSize     = p.Results.BinSize;
drawPlot    = p.Results.Plot;
smoothData  = p.Results.Smooth;
percentiles = p.Results.Percentile;
parent      = p.Results.Parent;

clear p

assert(any(strcmp(T.Properties.VariableNames,'ephysTrialStartTime')),...
    'Bpod Session Table doesn''t contain ephys trial start times...');

%% Gather trial data

% Rewarded Trials
rewardTrials = find(T.rewarded);
rewardTimes  = [T.trialEndTime(rewardTrials), ...
                T.waitingStartTime(rewardTrials)] ...
             +  T.ephysTrialStartTime(rewardTrials);   
rewardSplits = prctile(T.waitingTime(rewardTrials),percentiles);
rewardGroups = discretize(T.waitingTime(rewardTrials),rewardSplits);

% Unrewarded Trials
leaveTrials  = find(T.selfExit);
leaveTimes  = [T.trialEndTime(leaveTrials), ...
                T.waitingStartTime(leaveTrials)] ...
             +  T.ephysTrialStartTime(leaveTrials);   
leaveSplits = prctile(T.waitingTime(leaveTrials),percentiles);
leaveGroups = discretize(T.waitingTime(leaveTrials),leaveSplits);
        
%% Statistical Analysis

% Leave trials - Raw
leaveStats = calculateResponse(T, spikeTimes, leaveTrials, binSize, smoothData);
% Leave trials - Percentiles
for j = 1:length(unique(leaveGroups))
    leavePrcStats(j) = calculateResponse(T, spikeTimes, ...
        leaveTrials(leaveGroups == j), binSize, smoothData);
end
% Rewarded Trials - Raw
rewardStats = calculateResponse(T, spikeTimes, rewardTrials, binSize, smoothData);
% Rewarded trials - Percentiles
for j = 1:length(unique(rewardGroups))
    rewardPrcStats(j) = calculateResponse(T, spikeTimes, ...
        rewardTrials(rewardGroups == j), binSize, smoothData);
end




%% Per trial analysis

leaveTrialResponse  = trialResponse(T, spikeTimes, leaveTrials, leaveStats.PeakTime);
rewardTrialResponse = trialResponse(T, spikeTimes, rewardTrials, rewardStats.PeakTime);
for j = 1:length(unique(leaveGroups))
    leavePrcTrialResponse(j) = trialResponse(T, spikeTimes, ...
        leaveTrials(leaveGroups == j), leavePrcStats(j).PeakTime);
end
for j = 1:length(unique(rewardGroups))
    rewardPrcTrialResponse(j) = trialResponse(T, spikeTimes, ...
        rewardTrials(rewardGroups == j), rewardPrcStats(j).PeakTime);
end


%% Assign data
responseData.leave             = leaveStats;
responseData.leavePrc          = leavePrcStats;
responseData.leaveTrial        = leaveTrialResponse;
responseData.leaveTrialPrc     = leavePrcTrialResponse;

responseData.reward            = rewardStats;
responseData.rewardPrc         = rewardPrcStats;
responseData.rewardTrial       = rewardTrialResponse;
responseData.rewardTrialPrc    = rewardPrcTrialResponse;

responseData.percentiles       = percentiles;

%% Optional Plotting
if drawPlot
    
    % generate legend text
    legends{1} = 'All trials';
    
    for prcI = 1:length(percentiles) - 1
        if percentiles(prcI) == 0
            legends{prcI+1} = ['WT <= ' num2str(percentiles(prcI+1)) '%'];
        else
            legends{prcI+1} = ['WT ' num2str(percentiles(prcI)) ...
                                ' - ' num2str(percentiles(prcI+1)) '%'];
        end  
    end
    
    cmap = colourPicker('Paired');
    
    statsFig = figure;
    statsFig.Color = [1 1 1];

    if smoothData
        xPlots = 2;
    else
        xPlots = 1;
    end    
    leaveAx = subplot(2,xPlots,1);
    title('Unrewarded Trials');
    hold('on',leaveAx);
    leavePlots = plotResponseStats(leaveAx, leaveStats, ...
        'Legend', legends{1});
    for prcI = 1:length(percentiles) - 1
        leavePlots(prcI+1) = plotResponseStats(leaveAx, leavePrcStats(prcI),...
            'color',cmap([1:2] + ((prcI-1)*2),:),'Legend',legends{prcI+1});     
    end   
    hold('off',leaveAx);
  
    rewardAx = subplot(2,xPlots,2);
    title('Rewarded Trials');
    hold('on',rewardAx);
    rewardPlots = plotResponseStats(rewardAx, rewardStats, ...
        'Legend', legends{1});
    for prcI = 1:length(percentiles) - 1
        rewardPlots(prcI+1) = plotResponseStats(rewardAx, rewardPrcStats(prcI),... 
        'color',cmap([1:2] + ((prcI-1)*2),:),'Legend',legends{prcI+1});
    end   
    hold('off',rewardAx);
  
    if smoothData
        leaveAxSm = subplot(2,xPlots,3);
        title('Unrewarded Trials - Smoothed');
        hold('on',leaveAx);
        leaveSmPlots = plotResponseStats(leaveAxSm, leaveStats,'smooth',...
            'Legend', legends{1});      
        for prcI = 1:length(percentiles) - 1
            leaveSmPlots(prcI+1) = plotResponseStats(leaveAxSm, leavePrcStats(prcI),'smooth',...
            'color',cmap([1:2] + ((prcI-1)*2),:), 'Legend', legends{prcI+1});
        end   
        hold('off',leaveAx);

        rewardAxSm = subplot(2,xPlots,4);
        title('Rewarded Trials - Smoothed');
        hold('on',rewardAx);
        rewardPlots = plotResponseStats(rewardAxSm, rewardStats,'smooth',...
            'Legend', legends{1}); 
        for prcI = 1:length(percentiles) - 1
            rewardPlots(prcI+1) = plotResponseStats(rewardAxSm, rewardPrcStats(prcI),'smooth',...
            'color',cmap([1:2] + ((prcI-1)*2),:), 'Legend', legends{prcI+1});
        end   
        hold('off',rewardAx);   
    end
end % end if drawPlot

end % End main responseStats function 

function results = calculateResponse(T, spikeTimes, trials, binSize, smoothData)

% Gather needed info
waitingTimeStart = T.waitingStartTime(trials) + T.ephysTrialStartTime(trials);
waitingTimeEnd   = T.trialEndTime(trials) + T.ephysTrialStartTime(trials);
waitingTime      = T.waitingTime(trials);

% Get Binned Spikes
[binnedSpikes, binCenters] = binSpikesPerEventMex(spikeTimes, waitingTimeEnd,...
    'Previous', max(waitingTime).*1000,'Post', 1000,...
    'TrialLimits',waitingTimeStart,'BinSize', binSize);

% Convert to matrix
binnedSpikes = reshape(cell2mat(binnedSpikes),length(binCenters),length(binnedSpikes))';

% Remove timepoints that have less than 10 trials included
trialsIncluded = sum(~isnan(binnedSpikes));
points2Remove = find(trialsIncluded<10);
if any(find(diff(sign(diff(points2Remove)))))
    warning('There are discontinuities in the trials 2 remove...')
    % TODO: Add more sophisticated discontinuity checking here
end
binnedSpikes(:,points2Remove) = [];
binCenters(:,points2Remove) = [];

% Find average firing rate
meanFR = nanmean(binnedSpikes);
% Find 95% CI (Copied from gramm stat_summary function)
alfa = 0.05;
ciFR=tinv(1-alfa/2,sum(~isnan(binnedSpikes))-1).*nanstd(binnedSpikes)...
    ./sqrt(sum(~isnan(binnedSpikes)));

% Find FR peak
[~, peakIdx] = max(meanFR);
peakFR   = meanFR(peakIdx);
peakTime = binCenters(peakIdx);
% find FR minimum (or the latest 0 point prior to the peak)
[~,preMinFRIdx] = min(meanFR(1:peakIdx));
prePeakMinIdx = max([1 find(meanFR(1:peakIdx) == 0) preMinFRIdx]);
preMinFR = meanFR(prePeakMinIdx);
% find FR minimum post peak
[postMinFR,postPeakMinIdx] = min(meanFR(peakIdx:end));
postPeakMinIdx = postPeakMinIdx + peakIdx - 1;
% Simple Slopes
preSlope  = (peakFR - preMinFR)./...
    ((peakTime - binCenters(prePeakMinIdx))./1000);
postSlope = (postMinFR - peakFR) ./ ...
    ((binCenters(postPeakMinIdx) - peakTime)./1000);

% Complicated slope - linear fit across different time scales and see where
%                     fit changes
fitEnds = prePeakMinIdx+1:postPeakMinIdx-1;
for timeI = 1:length(fitEnds)
    [preLinFit(timeI,:),S] = polyfit(binCenters(prePeakMinIdx:fitEnds(timeI))./1000,...
                                  meanFR(prePeakMinIdx:fitEnds(timeI)),1);
    preNorm(timeI) = S.normr;
    [postLinFit(timeI,:),S] = polyfit(binCenters(fitEnds(timeI):postPeakMinIdx)./1000,...
                                  meanFR(fitEnds(timeI):postPeakMinIdx),1);
    postNorm(timeI) = S.normr;
             
    totalNorm = preNorm+postNorm;
end

[~,bestFitIdx] = min(totalNorm);
fitPreSlope  = preLinFit(bestFitIdx,1);
fitPostSlope = postLinFit(bestFitIdx,1);
fitPeakTime  = binCenters(fitEnds(bestFitIdx));
fitPeakFR    = meanFR(fitEnds(bestFitIdx));

results.meanFR          = meanFR;
results.X               = binCenters;
results.ciFR            = ciFR;
results.Peak            = peakFR;
results.PeakTime        = peakTime;
results.PreMin          = meanFR(prePeakMinIdx);
results.PreMinTime      = binCenters(prePeakMinIdx);
results.PreSlope        = preSlope;
results.PostMin         = meanFR(postPeakMinIdx);
results.PostMinTime     = binCenters(postPeakMinIdx);
results.PostSlope       = postSlope;
results.FitPeak         = fitPeakFR;
results.FitPeakTime     = fitPeakTime;
results.FitPreSlope     = fitPreSlope;
results.FitPostSlope    = fitPostSlope;

% Calculate for smoothed data?
if smoothData
    binSize = 25;
    % Get Binned Spikes
    [binnedSpikes, binCenters] = binSpikesPerEventMex(spikeTimes, waitingTimeEnd,...
    'Previous', max(waitingTime).*1000,'Post', 1000,...
    'TrialLimits',waitingTimeStart,'BinSize', binSize);

    % Convert to matrix
    binnedSpikes = reshape(cell2mat(binnedSpikes),length(binCenters),length(binnedSpikes))';

    % Remove timepoints that have less than 10 trials included
    trialsIncluded = sum(~isnan(binnedSpikes));
    points2Remove = find(trialsIncluded<10);
    if any(find(diff(sign(diff(points2Remove)))))
        warning('There are discontinuities in the trials 2 remove...')
        % TODO: Add more sophisticated discontinuity checking here
    end
    binnedSpikes(:,points2Remove) = [];
    binCenters(:,points2Remove) = [];
    
    % smooth individual trials
    span = 500/binSize; % 500 ms moving average
    for j = 1:size(binnedSpikes,1)
        binnedSpikes(j,:) = movmean(binnedSpikes(j,:), span, 'omitnan');
    end
    smoothFR = nanmean(binnedSpikes);
    
    % Find 95% CI (Copied from gramm stat_summary function)
    alfa = 0.05;
    ciFRSm=tinv(1-alfa/2,sum(~isnan(binnedSpikes))-1).*nanstd(binnedSpikes)...
        ./sqrt(sum(~isnan(binnedSpikes)));
    % Replace any values below 0
    smoothFR(smoothFR < 0) = 0;

    % Find FR peak
    [~, peakIdxSm] = max(smoothFR);
    
    % Alternative method
%     peakTimeSm = binCenters(peakIdxSm);
%     altPeakIdxSm  = findchangepts(smoothFR);
%     altPeakTimeSm    = binCenters(altPeakIdxSm);
%     % find which one is closer to zero
%     [~, minIdx] = min([abs(peakTimeSm) abs(altPeakTimeSm)]);
%     if minIdx == 2
%         peakIdxSm = altPeakIdxSm;
%     end
    peakFRSm   = smoothFR(peakIdxSm);
    peakTimeSm = binCenters(peakIdxSm);

    % find FR minimum (or the latest 0 point prior to the peak)
    [minFRSm,minFRSmIdx] = min(smoothFR(1:peakIdx));
    zeroPointSmIdx = max([1 ; find(smoothFR(1:peakIdx) == 0); minFRSmIdx]);
    slopeSm = peakFRSm./((peakTimeSm - binCenters(zeroPointSmIdx))./1000);
    
    results.smoothFR       = smoothFR;
    results.smoothX        = binCenters;
    results.smoothFRci     = ciFRSm;
    results.smoothPeak     = peakFRSm;
    results.smoothPeakTime = peakTimeSm;
    results.smoothMin      = smoothFR(zeroPointSmIdx);
    results.smoothMinTime  = binCenters(zeroPointSmIdx);
    results.smoothSlope    = slopeSm;

end % End if smoothData

end % End calculate Response Function

function results = trialResponse(T, spikeTimes, trials, peakTime)

% Gather needed info
waitingTimeStart = T.waitingStartTime(trials) + T.ephysTrialStartTime(trials);
waitingTimeEnd   = T.trialEndTime(trials) + T.ephysTrialStartTime(trials);
waitingTime      = T.waitingTime(trials);

% Get Event Spikes 
spikeTimesFromEvent = compareSpikes2EventsMex(spikeTimes, waitingTimeEnd,...
    'Previous', max(waitingTime).*1000,'Post', 1000,...
    'TrialLimits',waitingTimeStart);

for trialI = 1:length(spikeTimesFromEvent)
    
    % get spike times in seconds
    st = spikeTimesFromEvent{trialI}./ 1000;
    % remove spikes after the peak time
    st(st>(peakTime+100)./1000) = [];
    % get iterspike interval
    ISI = diff(st);
    if length(ISI) <= 1 % if there is less than 2 spikes skip this trial
       trialSlope(trialI)       = nan;
       trialIntercept(trialI)   = nan;
    else       
        % get instantaneous firing rate = first spike is assigned 1
        iF  = 1./[1; ISI];
        % Smooth firing rate
        iFSmooth = smooth(iF,0.33,'lowess');
        % linear fit 
        cSm = polyfit(st,iFSmooth,1);
        
% % %         % quick test plot
%         testFig = figure;
%         testAx  = axes(testFig);
%         hold(testAx,'on')        
%          scatter(st, iFSmooth,'markeredgecolor','k') 
%          plot(st,st.*c(1) + c(2))
%          plot(st,st.*cSm(1) + cSm(2),'k')
%          uiwait(testFig)
        % Save slope and intercept
        trialSlope(trialI)      = cSm(1);
        trialIntercept(trialI)  = cSm(2);
   end
   
end

results.Slope       = trialSlope;
results.Intercept   = trialIntercept;

end % end trialResponse function
    
function handles = plotResponseStats(axis, data, varargin)
hold(axis,'on')

%% process inputs

% get legend text
tmp = strncmpi(varargin,'Legend',3); 
if any(tmp)
    legendText = varargin{find(tmp)+1};
else
    legendText = '';
end

% Set colourmap
tmp = strncmpi(varargin,'colour',3); 
if any(tmp)
    cmap = varargin{find(tmp)+1};
else
    cmap = [0.5 0.5 0.5; 0 0 0 ];
end

% Plot smooth data if requested
if any(strcmpi(varargin,'smooth'))   
    data.meanFR     = data.smoothFR;
    data.X          = data.smoothX;
    data.PeakTime   = data.smoothPeakTime;
    data.Peak       = data.smoothPeak;
    data.MinTime    = data.smoothMinTime;
    data.Min        = data.smoothMin;
    data.Slope      = data.smoothSlope;
end

% plot raw
handles.FRPlot = plot(axis, data.X, data.meanFR,...
    'color',cmap(1,:));

% Mark peak
handles.Peak = scatter(data.PeakTime, data.Peak,...
   'marker','^','markerEdgeColor','none','markerFaceColor',cmap(2,:),...
   'HandleVisibility','off');
% Mark Pre Min
handles.PreMin = scatter(data.PreMinTime, data.PreMin,...
   'marker','v','markerEdgeColor','none','markerFaceColor',cmap(2,:),...
   'HandleVisibility','off');
% Mark post Min
handles.PreMin = scatter(data.PostMinTime, data.PostMin,...
   'marker','v','markerEdgeColor','none','markerFaceColor',cmap(2,:),...
   'HandleVisibility','off');

% Draw Simple Slopes
handles.PreSlope = line([data.PreMinTime data.PeakTime],...
    [data.PreMin data.Peak],...
    'lineWidth',1,'color',cmap(2,:),'lineStyle','--',...
    'HandleVisibility','off');
handles.PostSlope = line([data.PeakTime data.PostMinTime ],...
    [data.Peak data.PostMin],...
    'lineWidth',1,'color',cmap(2,:),'lineStyle','--',...
    'HandleVisibility','off');

% Draw Fit Slopes
preFit = (data.PreMinTime:diff(data.X(1:2)):data.FitPeakTime) ./1000 ...
         .* data.FitPreSlope;
preFit = preFit - (preFit(1) - data.PreMin);    
handles.FitPreSlope = plot(data.PreMinTime:diff(data.X(1:2)):data.FitPeakTime,...
                      preFit,'lineWidth',1,'color',cmap(2,:),'lineStyle',':',...
                      'HandleVisibility','off');
                  
postFit = (data.FitPeakTime:diff(data.X(1:2)):data.PostMinTime) ./1000 ...
         .* data.FitPostSlope;
postFit = postFit - (postFit(1) - data.FitPeak); 
handles.FitPostSlope = plot(data.FitPeakTime:diff(data.X(1:2)):data.PostMinTime,...
    postFit,...
    'lineWidth',1,'color',cmap(2,:),'lineStyle',':',...
    'HandleVisibility','off');
      
% % Inset perTrial slope distribution
% trialSlopeAx = axes('Position',[.3 .7 .2 .2]);


legendText = [legendText ': slope = ' num2str(round(data.PreSlope,2))];

axLegend = axis.Legend;
if isempty(axLegend)
    legend(legendText,'Location','northwest')
else
    axLegend.String{end} = legendText;
end

hold(axis,'off')
end  % end plotResponseStats function