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
%       GaussSize: SD of gaussian kernel to smooth data
%       Smooth: Logical, whether to further smooth data (moving average) for PSTH stats
%       Plot: Logical, whether to make plots of data
%       Split : Method to split the WT: 'Percentile','Seconds'; default =
%       'Percentile'
%       Percentiles : Divisions in WT to use for splits, only used if split
%       method is 'Percentile'


%% Input parsing
p = inputParser; % Create object of class 'inputParser'
% define defaults
defBinSize     = 2; % in ms
defGauss       = 8; % in ms
defSmooth      = false; % Smooth data
defPlot        = false; % Plot data
defPercentile  = [0 33 66 100]; 
defParent      = [];
defSpikeTrials = [];
defOutliers    = true;
defSplit       = 'Percentile';

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
valBinaryCol = @(x) validateattributes(x, {'logical', 'numeric'},...
    {'nonempty', 'binary', 'column'});
valSplit = @(x) validateattributes(x, {'char', 'string', 'cell'},...
     {'nonempty'});
 
addRequired(p, 'spikeTimes', valNumColNonEmpty);
addRequired(p, 'T', valTable);
addParameter(p, 'BinSize', defBinSize, valNumScalarNonEmpty);
addParameter(p, 'GaussSize', defGauss, valNumScalarNonEmpty);
addParameter(p, 'Smooth', defSmooth, valBinaryScalar);
addParameter(p, 'Plot', defPlot, valBinaryScalar);
addParameter(p, 'Parent', defParent, @ishandle);
addParameter(p, 'SpikeTrials', defSpikeTrials, valBinaryCol);
addParameter(p, 'Outliers', defOutliers,@islogical);
addParameter(p, 'Split', defSplit, valSplit);
addParameter(p, 'Percentile', defPercentile, valPercentile);

parse(p, varargin{:});

spikeTimes  = p.Results.spikeTimes; 
T           = p.Results.T;
binSize     = p.Results.BinSize;
gaussSize   = p.Results.GaussSize;
drawPlot    = p.Results.Plot;
smoothData  = p.Results.Smooth;
parent      = p.Results.Parent;
spikeTrials = p.Results.SpikeTrials;
outliers    = p.Results.Outliers;
percentiles = p.Results.Percentile;
splitType = validatestring(p.Results.Split,{'Percentile','Seconds'});


clear p

assert(any(strcmp(T.Properties.VariableNames,'ephysTrialStartTime')),...
    'Bpod Session Table doesn''t contain ephys trial start times...');

%% Gather trial data

if isempty(spikeTrials)
    % find spike trials
    spikeTrials = isSpikeTrial(spikeTimes, T.ephysTrialStartTime);
else 
    assert(length(spikeTrials) == T.Properties.CustomProperties.nTrials,... 
        'SpikeTrials should have the same length as the trial number in T')
end

% Rewarded Trials
rewardTrials = find(T.rewarded & spikeTrials); 
rewardTimes  = [T.trialEndTime(rewardTrials), ...
                T.waitingStartTime(rewardTrials)] ...
             +  T.ephysTrialStartTime(rewardTrials);   
         
% Unrewarded Trials
leaveTrials  = find(T.selfExit & spikeTrials);
leaveTimes  = [T.trialEndTime(leaveTrials), ...
                T.waitingStartTime(leaveTrials)] ...
             +  T.ephysTrialStartTime(leaveTrials);   


% Remove outliers here if option is selected         
% if ~outliers
%     outlierGroups = discretize(
%     [~, trials2Remove] = rmoutliers(T.waitingTime(rewardTrials));
%     rewardTrials(trials2Remove) = [];     
% end         
         
switch splitType
    case 'Percentile'
        rewardSplits = prctile(T.waitingTime(rewardTrials),percentiles);
        leaveSplits = prctile(T.waitingTime(leaveTrials),percentiles);
    case 'Seconds'
        rewardSplits = floor(min(T.waitingTime(rewardTrials))):1:...
                       ceil(max(T.waitingTime(rewardTrials))); 
        leaveSplits = floor(min(T.waitingTime(leaveTrials))):1:...
                       ceil(max(T.waitingTime(leaveTrials)));          
end

rewardGroups = discretize(T.waitingTime(rewardTrials),rewardSplits);
leaveGroups  = discretize(T.waitingTime(leaveTrials),leaveSplits);

        
%% Statistical Analysis

% Leave trials - Raw
leaveStats = calculateResponse(T, spikeTimes, leaveTrials, binSize, gaussSize, false);
% Leave trials - Percentiles
for j = 1:length(unique(leaveGroups))    
    % Check there are more than 8 trials in group
    if sum(leaveGroups ==j) < 8
        continue
    else    
        leavePrcStats(j) = calculateResponse(T, spikeTimes, ...
            leaveTrials(leaveGroups == j), binSize, gaussSize, false);
    end
end

% Rewarded Trials - Raw
rewardStats = calculateResponse(T, spikeTimes, rewardTrials, binSize, gaussSize, true);
% Rewarded trials - Percentiles
for j = 1:length(unique(rewardGroups))
    rewardPrcStats(j) = calculateResponse(T, spikeTimes, ...
        rewardTrials(rewardGroups == j), binSize, gaussSize, true);
end

%% Per trial analysis

leaveTrialResponse  = trialResponse(T, spikeTimes, leaveTrials, leaveStats.PeakTime);
rewardTrialResponse = trialResponse(T, spikeTimes, rewardTrials, rewardStats.PeakTime);
for j = 1:length(unique(leaveGroups))
    if sum(leaveGroups ==j) < 8
        continue
    else    
        leavePrcTrialResponse(j) = trialResponse(T, spikeTimes, ...
            leaveTrials(leaveGroups == j), leavePrcStats(j).PeakTime);
    end
end
for j = 1:length(unique(rewardGroups))
    if sum(leaveGroups ==j) < 8
        continue
    else 
        rewardPrcTrialResponse(j) = trialResponse(T, spikeTimes, ...
            rewardTrials(rewardGroups == j), rewardPrcStats(j).PeakTime);
    end
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
    
     switch splitType
            case 'Percentile'
                for prcI = 1:length(percentiles) - 1
                    if percentiles(prcI) == 0
                        legends{prcI+1} = ['WT <= ' num2str(percentiles(prcI+1)) '%'];
                    else
                        legends{prcI+1} = ['WT ' num2str(percentiles(prcI)) ...
                                            ' - ' num2str(percentiles(prcI+1)) '%'];
                    end  
                end
            case 'Seconds'
                for legI = 1:length(rewardSplits) - 1
                    legends{legI+1} = [num2str(rewardSplits(legI)) ' - ' ...
                        num2str(rewardSplits(legI+1)) ' s'];
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
    hold(leaveAx,'on');
    leavePlots = plotResponseStats(leaveAx, leaveStats, ...
        'Legend', legends{1});
    for legI = 1:length(legends) - 1
        leavePlots(legI+1) = plotResponseStats(leaveAx, leavePrcStats(legI),...
            'color',cmap([1:2] + ((legI-1)*2),:),'Legend',legends{legI+1});     
    end   
    hold(leaveAx,'off');
  
    rewardAx = subplot(2,xPlots,2);
    title('Rewarded Trials');
    hold(rewardAx,'on');
    rewardPlots = plotResponseStats(rewardAx, rewardStats, ...
        'Legend', legends{1});
    for legI = 1:length(percentiles) - 1
        rewardPlots(legI+1) = plotResponseStats(rewardAx, rewardPrcStats(legI),... 
        'color',cmap([1:2] + ((legI-1)*2),:),'Legend',legends{legI+1});
    end   
    hold(rewardAx,'off');
  
    if smoothData
        leaveAxSm = subplot(2,xPlots,3);
        title('Unrewarded Trials - Smoothed');
        hold(leaveAx,'on');
        leaveSmPlots = plotResponseStats(leaveAxSm, leaveStats,'smooth',...
            'Legend', legends{1});      
        for prcI = 1:length(percentiles) - 1
            leaveSmPlots(prcI+1) = plotResponseStats(leaveAxSm, leavePrcStats(prcI),'smooth',...
            'color',cmap([1:2] + ((prcI-1)*2),:), 'Legend', legends{prcI+1});
        end   
        hold(leaveAx, 'off');

        rewardAxSm = subplot(2,xPlots,4);
        title('Rewarded Trials - Smoothed');
        hold(rewardAx,'on');
        rewardPlots = plotResponseStats(rewardAxSm, rewardStats,'smooth',...
            'Legend', legends{1}); 
        for prcI = 1:length(percentiles) - 1
            rewardPlots(prcI+1) = plotResponseStats(rewardAxSm, rewardPrcStats(prcI),'smooth',...
            'color',cmap([1:2] + ((prcI-1)*2),:), 'Legend', legends{prcI+1});
        end   
        hold(rewardAx,'off');   
    end
end % end if drawPlot

end % End main responseStats function 

function results = calculateResponse(T, spikeTimes, trials, binSize, gaussSize, zeroEnd)

if nargin < 6
    zeroEnd = false;
end

% Gather needed info
waitingTimeStart = T.waitingStartTime(trials) + T.ephysTrialStartTime(trials);
waitingTimeEnd   = T.trialEndTime(trials) + T.ephysTrialStartTime(trials);
waitingTime      = T.waitingTime(trials);


%% Find point where ramping stops
% Want to estimate the point where the firing rate starts decreasing
% Will use a small bin size and then smooth the data with gaussian kernel
% Will then  find the point where the data changes the most:
% this will be roughly the middle of the line where it drop to zero
% Then find the first peak before this and the first (negative peak after
% this) to get get start and end of the end of the ramp.

% Get Binned Spikes
[binnedSpikes, binCenters] = binSpikesPerEventMex(spikeTimes, waitingTimeEnd,...
    'Previous', max(waitingTime).*1000,'Post', 1000,...
    'TrialLimits',waitingTimeStart,'BinSize', binSize);
% Convert to matrix
binnedSpikes = reshape(cell2mat(binnedSpikes),length(binCenters),length(binnedSpikes))';
 
% Gaussian convolution
nanPositions = isnan(binnedSpikes);
gaussSpikes = binnedSpikes;
gaussSpikes(nanPositions) = 0;

mu  = 0; 
gaussKernel = normpdf(-5*gaussSize:1:5*gaussSize, mu, gaussSize);

for j = 1:size(binnedSpikes,1)
    gaussSpikes(j,:)   = conv(binnedSpikes(j,:),gaussKernel,'same'); % convolve with gaussian window
end
    
gaussSpikes(nanPositions) = nan;
    
% Remove timepoints that have less than 8 trials included
trialsIncluded = sum(~isnan(gaussSpikes));
points2Keep = find(trialsIncluded >= 8);
if any(find(diff(sign(diff(points2Keep)))))
    warning('There are discontinuities in the trials 2 keep...')
    % TODO: Add more sophisticated discontinuity checking here
end
gaussSpikes = gaussSpikes(:,points2Keep);
gaussCenters = binCenters(:,points2Keep);

% Find average firing rate
meanFR = nanmean(gaussSpikes);
% Find 95% CI (Copied from gramm stat_summary function)
alfa = 0.05;
ciFR=tinv(1-alfa/2,sum(~isnan(gaussSpikes))-1).*nanstd(gaussSpikes)...
    ./sqrt(sum(~isnan(gaussSpikes)));

% Find FR peak 
if zeroEnd % Just use 0 bin as the 'peak' firing, i.e. for rewarded trials
    peakIdx = dsearchn(gaussCenters(:),0);
else    
    [~, peakIdx] = max(meanFR);
end

peakFR   = meanFR(peakIdx);
peakTime = gaussCenters(peakIdx);
% find FR minimum (or the latest 0 point prior to the peak)
[~,preMinFRIdx] = min(meanFR(1:peakIdx));
prePeakMinIdx = max([1 find(meanFR(1:peakIdx) == 0) preMinFRIdx]);
preMinFR = meanFR(prePeakMinIdx);
% Define an alternate minimum as 0 Hz at the longest trial 
% maybe should be median trial for this time group?
prePeakZeroIdx = 1;
prePeakZeroFR  = 0;


% find FR minimum post peak
[postMinFR,postPeakMinIdx] = min(meanFR(peakIdx:end));
postPeakMinIdx = postPeakMinIdx + peakIdx - 1;

%% Find change point and peak before and trough after

if zeroEnd % Find the peak closest to the 0 point
    prePeakFR  = peakFR;
    prePeakIdx = peakIdx;
    prePeakTime = gaussCenters(prePeakIdx);

   [postTroughFR, postTroughIdx] = min(meanFR(peakIdx:end));
   postTroughIdx = postTroughIdx + (peakIdx - 1);
   postTroughTime = gaussCenters(postTroughIdx);
else   
    changePoint = findchangepts(meanFR,'Statistic','linear');

    prePeakDistance = peakFR; % We will try gey the distance between our detected
    % peak and the true maximum below a threshold, as a way avoid false peaks 
    peakRange = 1;

    while prePeakDistance > 0.1 * peakFR

        [prePeakFR,prePeakIdx] = findpeaks(fliplr(meanFR(1:changePoint)),...
                              'NPeaks',peakRange);
        prePeakFR  = prePeakFR(peakRange);
        prePeakIdx = prePeakIdx(peakRange); 

        timepoints = fliplr(gaussCenters(1:changePoint));                      
        prePeakTime = timepoints(prePeakIdx);
        prePeakIdx  = changePoint - (prePeakIdx - 1);

        peakRange = peakRange + 1;
        prePeakDistance = abs(prePeakFR - peakFR);
    end
    [postTroughFR,postTroughTime] = findpeaks(-meanFR(changePoint:end),...
                                gaussCenters(changePoint:end),'NPeaks',1);
    postTroughFR = -postTroughFR;
    postTroughIdx = dsearchn(gaussCenters(:),postTroughTime);
end

%% Optional Plotting
%     f = figure;
%     ax = axes(f);
%     grid(ax,'on');
%     hold(ax,'on');
%     plot(ax, gaussCenters, meanFR,'k','lineWidth',1);
%     scatter(ax, gaussCenters(changePoint),meanFR(changePoint),25,'ko','filled');
%     scatter(ax, gaussCenters(prePeakIdx),meanFR(prePeakIdx),25,'g^','filled');
%     scatter(ax, gaussCenters(postTroughIdx),meanFR(postTroughIdx),25,'rv','filled');
% 
%     % scatter(ax, gaussCenters(peakIdx),meanFR(peakIdx),25,'g^');
% 
%     % Also plot a smoother binned spikes
%     % Get Binned Spikes
%     [binnedSpikes, binCenters] = binSpikesPerEventMex(spikeTimes, waitingTimeEnd,...
%         'Previous', max(waitingTime).*1000,'Post', 1000,...
%         'TrialLimits',waitingTimeStart,'BinSize', 50);
% 
%     % Convert to matrix
%     binnedSpikes = reshape(cell2mat(binnedSpikes),length(binCenters),length(binnedSpikes))';
% 
%     plot(ax, binCenters, nanmean(binnedSpikes),'k--','lineWidth',1);
% 
%     hold(ax,'off');

%% Slope Calculations
% Simple Slope Calculation
% preSlope  = (prePeakFR - preMinFR)./...
%     ((prePeakTime - gaussCenters(prePeakMinIdx))./1000);
% postSlope = (postTroughFR - prePeakFR) ./ ...
%     ((gaussCenters(postTroughIdx) - prePeakTime)./1000);

%% Slightly More Complex Slope Calculation

preLinFit  = polyfit([gaussCenters(prePeakZeroIdx) gaussCenters(prePeakMinIdx:prePeakIdx)]./1000,...
                    [0 meanFR(prePeakMinIdx:prePeakIdx)],1);
preSlope   = preLinFit(1); 

postLinFit = polyfit(gaussCenters(prePeakIdx:postTroughIdx)./1000,...
                     meanFR(prePeakIdx:postTroughIdx),1);
postSlope  = postLinFit(1);


%% More Complex Slope Calculation
% linear fit across different time scales and see where fit changes
                   
% fitEnds = prePeakMinIdx+1:postTroughIdx-1;
% for timeI = 1:length(fitEnds)
%     [preLinFit(timeI,:),S] = polyfit(gaussCenters(prePeakMinIdx:fitEnds(timeI))./1000,...
%                                   meanFR(prePeakMinIdx:fitEnds(timeI)),1);
%     preNorm(timeI) = S.normr;
%     [postLinFit(timeI,:),S] = polyfit(gaussCenters(fitEnds(timeI):postPeakMinIdx)./1000,...
%                                   meanFR(fitEnds(timeI):postPeakMinIdx),1);
%     postNorm(timeI) = S.normr;
%              
%     totalNorm = preNorm+postNorm;
% end
% 
% [~,bestFitIdx] = min(totalNorm);
% fitPreSlope  = preLinFit(bestFitIdx,:);
% fitPostSlope = postLinFit(bestFitIdx,:);
% fitPeakTime  = gaussCenters(fitEnds(bestFitIdx));
% fitPeakFR    = meanFR(fitEnds(bestFitIdx));

%% Polynomial fitting using the best sliding linear fit 
% 
% x = binCenters(prePeakMinIdx:peakIdx)./1000;
% x = x(:);
% smoothY = smooth(meanFR(prePeakMinIdx:peakIdx),5);
% smoothY = smoothY(:);
% 
% f = figure; ax = axes(f); hold(ax,'on');    
% plot(x, smoothY,...
%         'LineWidth',2,'color','k');    
% for polyOrder = 1:12
%     [cE{polyOrder}, S(polyOrder)] = polyfit(x,smoothY,polyOrder);
%     y{polyOrder} = polyval(cE{polyOrder}, x, S(polyOrder));
%     plot(x, y{polyOrder});   
% end
% 
% hold(ax,'off');


%% Assign data

results.meanFR          = meanFR;
results.X               = gaussCenters;
results.ciFR            = ciFR;
results.Peak            = prePeakFR;
results.PeakTime        = prePeakTime;
results.PreMin          = meanFR(prePeakMinIdx);
results.PreMinTime      = gaussCenters(prePeakMinIdx);
results.PreSlope        = preSlope;
results.PreSlopeFit     = preLinFit;

results.PostMin         = meanFR(postTroughIdx);
results.PostMinTime     = gaussCenters(postTroughIdx);
results.PostSlope       = postSlope;
results.PostSlopeFit    = postLinFit;


% results.FitPeak         = fitPeakFR;
% results.FitPeakTime     = fitPeakTime;
% results.FitPreSlope     = fitPreSlope;
% results.FitPostSlope    = fitPostSlope;

% % Calculate for smoothed data?
% if smoothData
%     binSize = 25;
%     % Get Binned Spikes
%     [binnedSpikes, binCenters] = binSpikesPerEventMex(spikeTimes, waitingTimeEnd,...
%     'Previous', max(waitingTime).*1000,'Post', 1000,...
%     'TrialLimits',waitingTimeStart,'BinSize', binSize);
% 
%     % Convert to matrix
%     binnedSpikes = reshape(cell2mat(binnedSpikes),length(binCenters),length(binnedSpikes))';
% 
%     % Remove timepoints that have less than 10 trials included
%     trialsIncluded = sum(~isnan(binnedSpikes));
%     points2Remove = find(trialsIncluded<4);
%     if any(find(diff(sign(diff(points2Remove)))))
%         warning('There are discontinuities in the trials 2 remove...')
%         % TODO: Add more sophisticated discontinuity checking here
%     end
%     binnedSpikes(:,points2Remove) = [];
%     binCenters(:,points2Remove) = [];
%     
%     % smooth individual trials
%     span = 500/binSize; % 500 ms moving average
%     for j = 1:size(binnedSpikes,1)
%         binnedSpikes(j,:) = movmean(binnedSpikes(j,:), span, 'omitnan');
%     end
%     smoothFR = nanmean(binnedSpikes);
%     
%     % Find 95% CI (Copied from gramm stat_summary function)
%     alfa = 0.05;
%     ciFRSm=tinv(1-alfa/2,sum(~isnan(binnedSpikes))-1).*nanstd(binnedSpikes)...
%         ./sqrt(sum(~isnan(binnedSpikes)));
%     % Replace any values below 0
%     smoothFR(smoothFR < 0) = 0;
% 
%     % Find FR peak
%     [~, peakIdxSm] = max(smoothFR);
%     
%     % Alternative method
% %     peakTimeSm = binCenters(peakIdxSm);
% %     altPeakIdxSm  = findchangepts(smoothFR);
% %     altPeakTimeSm    = binCenters(altPeakIdxSm);
% %     % find which one is closer to zero
% %     [~, minIdx] = min([abs(peakTimeSm) abs(altPeakTimeSm)]);
% %     if minIdx == 2
% %         peakIdxSm = altPeakIdxSm;
% %     end
%     peakFRSm   = smoothFR(peakIdxSm);
%     peakTimeSm = binCenters(peakIdxSm);
% 
%     % find FR minimum (or the latest 0 point prior to the peak)
%     [minFRSm,minFRSmIdx] = min(smoothFR(1:peakIdx));
%     zeroPointSmIdx = max([1 ; find(smoothFR(1:peakIdx) == 0)'; minFRSmIdx]);
%     slopeSm = peakFRSm./((peakTimeSm - binCenters(zeroPointSmIdx))./1000);
%     
%     results.smoothFR       = smoothFR;
%     results.smoothX        = binCenters;
%     results.smoothFRci     = ciFRSm;
%     results.smoothPeak     = peakFRSm;
%     results.smoothPeakTime = peakTimeSm;
%     results.smoothMin      = smoothFR(zeroPointSmIdx);
%     results.smoothMinTime  = binCenters(zeroPointSmIdx);
%     results.smoothSlope    = slopeSm;
% 
% end % End if smoothData

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

% % Draw Simple Slopes
handles.PreSlope = line([data.PreMinTime data.PeakTime],...
    [data.PreMin data.Peak],...
    'lineWidth',1,'color',cmap(2,:),'lineStyle','--',...
    'HandleVisibility','off');
handles.PostSlope = line([data.PeakTime data.PostMinTime ],...
    [data.Peak data.PostMin],...
    'lineWidth',1,'color',cmap(2,:),'lineStyle','--',...
    'HandleVisibility','off');

% % Draw Fit Slopes
% preFit = ( (data.PreMinTime:diff(data.X(1:2)):data.FitPeakTime) ./1000 ...
%          .* data.FitPreSlope(1) ) + data.FitPreSlope(2);
% % preFit = preFit - (preFit(1) - data.PreMin);    
% handles.FitPreSlope = plot(data.PreMinTime:diff(data.X(1:2)):data.FitPeakTime,...
%                       preFit,'lineWidth',1,'color',cmap(2,:),'lineStyle',':',...
%                       'HandleVisibility','off');
%                   
% postFit = ( (data.FitPeakTime:diff(data.X(1:2)):data.PostMinTime) ./1000 ...
%          .* data.FitPostSlope(1) ) + data.FitPostSlope(2);
% postFit = postFit - (postFit(1) - data.FitPeak); 
% handles.FitPostSlope = plot(data.FitPeakTime:diff(data.X(1:2)):data.PostMinTime,...
%     postFit,...
%     'lineWidth',1,'color',cmap(2,:),'lineStyle',':',...
%     'HandleVisibility','off');
      
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