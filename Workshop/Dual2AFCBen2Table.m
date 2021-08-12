function T = Dual2AFCBen2Table(SessionData)
% Converts the session data struct from a 2AFC (confidence task) session
% into a data table to be used for analysis and plotting. 

% Input: SessionData struct from Dual2AFCBen recording session

%% Check Input

assert(isstruct(SessionData),'Session Data is not a valid Dual2AFCBen recording struct');
assert(isfield(SessionData,'Custom'),'Session Data is not a valid Dual2AFCBen recording struct');

%% Grab some initial data 

nTrials = SessionData.Custom.TrialNumber(end);

GUI = [SessionData.TrialSettings.GUI];

Custom = SessionData.Custom;

%% Get values that have direct correspondence

trialStartTimeBpod  = SessionData.TrialStartTimestamp(1:nTrials)';

samplingDuration            = Custom.ST(1:nTrials)';
catchTrial                  = Custom.CatchTrial(1:nTrials)';
rewardDelayBpod             = Custom.FeedbackDelay(1:nTrials)';
preStimulusDelayDuration    = Custom.StimDelay(1:nTrials)';
waitingTime                 = Custom.FeedbackTime(1:nTrials)';
rewarded                    = Custom.Rewarded(1:nTrials);

rewardGrace         = [GUI.FeedbackDelayGrace]; rewardGrace = rewardGrace(1:nTrials)';
rewardAmountLeft    = [GUI.RewardAmountL]; rewardAmountLeft = rewardAmountLeft(1:nTrials)';
rewardAmountRight   = [GUI.RewardAmountR]; rewardAmountRight = rewardAmountRight(1:nTrials)';
stimulusDuration    = [GUI.AuditoryStimulusTime]; stimulusDuration = stimulusDuration(1:nTrials)';
sumRates            = [GUI.SumRates]; sumRates = sumRates(1:nTrials)';

maximumRewardDelayLeft = [GUI.FeedbackDelayMax]; maximumRewardDelayLeft = maximumRewardDelayLeft(1:nTrials)';
minimumRewardDelayLeft = [GUI.FeedbackDelayMin]; minimumRewardDelayLeft = minimumRewardDelayLeft(1:nTrials)';
exponentRewardDelayLeft = [GUI.FeedbackDelayTau]; exponentRewardDelayLeft = exponentRewardDelayLeft(1:nTrials)';

maximumRewardDelayRight = [GUI.FeedbackDelayMax]; maximumRewardDelayRight = maximumRewardDelayRight(1:nTrials)';
minimumRewardDelayRight = [GUI.FeedbackDelayMin]; minimumRewardDelayRight = minimumRewardDelayRight(1:nTrials)';
exponentRewardDelayRight = [GUI.FeedbackDelayTau]; exponentRewardDelayRight = exponentRewardDelayRight(1:nTrials)';

% This value is always 1, should this be Custom.AuditoryOmega, which changes every trial
alpha               = [GUI.AuditoryAlpha]; alpha = alpha(1:nTrials)';
% Not sure this is correct
punishGrace = [GUI.FeedbackDelayGrace]; punishGrace = punishGrace(1:nTrials)';


%% Calculate correct side per BPod and per actual Clicks

rightClickTrain = Custom.RightClickTrain;
leftClickTrain  = Custom.LeftClickTrain;

for trialI = 1:nTrials
    rightClicksIdx{trialI} = rightClickTrain{trialI} <= Custom.ST(trialI);
    rightClickCount(trialI) = sum(rightClicksIdx{trialI});
    rightClickTrainActual{trialI} = ...
        rightClickTrain{trialI}(rightClicksIdx{trialI});
    
    leftClicksIdx{trialI} = leftClickTrain{trialI} <= Custom.ST(trialI);
    leftClickCount(trialI) = sum(leftClicksIdx{trialI});
    leftClickTrainActual{trialI} = ...
        leftClickTrain{trialI}(leftClicksIdx{trialI});
    
    correctSideBpod(trialI) = categorical(...
        length(leftClickTrain{trialI}) > length(rightClickTrain{trialI}),...
        [1,0],{'left','right'});
    
    correctSideClicks(trialI) = categorical(...
        length(leftClickTrainActual{trialI}) > length(rightClickTrainActual{trialI}),...
        [1,0],{'left','right'});
    
    sideChosen(trialI) = categorical(...
        Custom.ChoiceLeft(trialI),[1,0,nan],{'left','right','no choice'});
    
    completedSampling(trialI) = ~Custom.FixBroke(trialI) && ~Custom.EarlyWithdrawal(trialI);
    % Are completedSampling and completed ever different?
    completed(trialI)         = ~Custom.FixBroke(trialI) && ~Custom.EarlyWithdrawal(trialI);
    
    switch sideChosen(trialI)
        case 'left'
            if correctSideBpod(trialI) == 'right'
                errorBpod(trialI) = true;
            else
                errorBpod(trialI) = false;
            end
            if correctSideClicks(trialI) == 'right'
                errorClicks(trialI) = true;
            else
                errorClicks(trialI) = false;
            end
        case 'right'
            if correctSideBpod(trialI) == 'left'
                errorBpod(trialI) = true;
            else
                errorBpod(trialI) = false;
            end
            if correctSideClicks == 'left'
                errorClicks(trialI) = true;
            else
                errorClicks(trialI) = false;
            end
        case 'no choice'
            errorBpod(trialI) = false;
            errorClicks(trialI) = false;
    end
    
    
    % Add extra time to waiting time - state transitions are missing
    % Get state matrix
    
    trialStates = SessionData.RawEvents.Trial{trialI}.States;
    portEntryTime = trialStates.wait_Sin(2);
    switch sideChosen(trialI)
        case 'left'
            if rewarded(trialI)
                waitingTime(trialI) = (trialStates.rewarded_Lin(end,2) - portEntryTime) + 0.0001;
            else
                waitingTime(trialI) = (trialStates.rewarded_Lin_grace(end,1) - portEntryTime) + 0.0001;
            end
        case 'right'
            if rewarded(trialI)
                waitingTime(trialI) = (trialStates.rewarded_Rin(end,2) - portEntryTime) + 0.0001;
            else
                waitingTime(trialI) = (trialStates.rewarded_Rin_grace(end,1) - portEntryTime) + 0.0001;
            end
    end
  
 end
    
    
%% Calculate a bunch of logical conditions

sideChosen = sideChosen(:);
completed  = completed(:);
rewarded   = rewarded(:);

correctSideChosenClicks = correctSideClicks' == sideChosen;
% correctSideChosenClicks(sideChosen == 'no choice') = nan;

correctSideChosenBpod   = correctSideBpod'   == sideChosen;
% correctSideChosenBpod(sideChosen == 'no choice') = nan;

completedCatchTrial = Custom.CatchTrial(1:nTrials)' & completed;

correctCatchEvidenceClicks  = correctSideChosenClicks & catchTrial;
errorCatchEvidenceClicks    = errorClicks' & catchTrial;
correctLeftChoiceClicks     = correctSideChosenClicks & sideChosen == 'left';
correctRightChoiceClicks    = correctSideChosenClicks & sideChosen == 'right';
errorLeftChoiceClicks       = errorClicks' & sideChosen == 'left';
errorRightChoiceClicks      = errorClicks' & sideChosen == 'right';

highEvidenceSideBpod   = correctSideBpod(:);
highEvidenceSideClicks = correctSideClicks(:);
punishState = errorBpod(:); % Not sure this is correct

nLeftClicks  = leftClickCount(:);
nRightClicks = rightClickCount(:);

completedSampling = completedSampling(:);

leftSampledClicks  = leftClickTrainActual(:);
rightSampledClicks = rightClickTrainActual(:);
%% Create Table

% This is currently just every table column from the existing table used
% for Slim2
T = table(highEvidenceSideBpod,samplingDuration,catchTrial,rewardDelayBpod,...
    rewardGrace,rewardAmountRight,rewardAmountLeft,stimulusDuration,alpha,...
    sumRates,minimumRewardDelayLeft,maximumRewardDelayLeft,exponentRewardDelayLeft,...
    minimumRewardDelayRight,maximumRewardDelayRight,exponentRewardDelayRight,...
    punishGrace,punishState,completedSampling,correctSideChosenBpod,...
    nLeftClicks,nRightClicks,sideChosen,trialStartTimeBpod,...
    preStimulusDelayDuration,leftSampledClicks,rightSampledClicks,...
    highEvidenceSideClicks,correctSideChosenClicks,completed,...
    completedCatchTrial,correctCatchEvidenceClicks,waitingTime,...
    errorCatchEvidenceClicks,rewarded,correctLeftChoiceClicks,...
    correctRightChoiceClicks,errorLeftChoiceClicks,errorRightChoiceClicks);

