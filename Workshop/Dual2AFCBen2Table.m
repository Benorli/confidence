function T = Dual2AFCBen2Table(SessionData)
% Converts the session data struct from a 2AFC (confidence task) session
% into a data table to be used for analysis and plotting. 

% Input: SessionData struct from Dual2AFCBen recording session

%% Check Input

assert(isstruct(SessionData),'Session Data is not a valid Dual2AFCBen recording struct');
assert(isfield(SessionData,'Custom'),'Session Data is not a valid Dual2AFCBen recording struct');

%% Grab some initial data 

nTrials = min(SessionData.Custom.TrialNumber(end),length(SessionData.TrialStartTimestamp));

GUI = [SessionData.TrialSettings.GUI];

Custom = SessionData.Custom;

%% Get values that have direct correspondence

trialStartTimeBpod = SessionData.TrialStartTimestamp(1:nTrials);
trialStartTimeBpod = trialStartTimeBpod(:);

samplingDuration            = Custom.ST(1:nTrials);
samplingDuration            = samplingDuration(:);
catchTrial                  = Custom.CatchTrial(1:nTrials);
catchTrial                  = catchTrial(:);
rewardDelayBpod             = Custom.FeedbackDelay(1:nTrials);
rewardDelayBpod             = rewardDelayBpod(:);
preStimulusDelayDuration    = Custom.StimDelay(1:nTrials);
preStimulusDelayDuration    = preStimulusDelayDuration(:);
waitingTime                 = Custom.FeedbackTime(1:nTrials);
waitingTime                 = waitingTime(:);
rewarded                    = Custom.Rewarded(1:nTrials);
rewarded                    = rewarded(:);


rewardGrace        = [GUI(1:nTrials).FeedbackDelayGrace]; 
rewardGrace        = rewardGrace(:);
rewardAmountLeft   = [GUI(1:nTrials).RewardAmountL]; 
rewardAmountLeft   = rewardAmountLeft(:);
rewardAmountRight  = [GUI(1:nTrials).RewardAmountR]; 
rewardAmountRight  = rewardAmountRight(:);
stimulusDuration   = [GUI(1:nTrials).AuditoryStimulusTime]; 
stimulusDuration   = stimulusDuration(:);
sumRates           = [GUI(1:nTrials).SumRates]; 
sumRates           = sumRates(:);

maximumRewardDelayLeft  = [GUI(1:nTrials).FeedbackDelayMax]; 
maximumRewardDelayLeft  = maximumRewardDelayLeft(:);
minimumRewardDelayLeft  = [GUI(1:nTrials).FeedbackDelayMin]; 
minimumRewardDelayLeft  = minimumRewardDelayLeft(:);
exponentRewardDelayLeft = [GUI(1:nTrials).FeedbackDelayTau]; 
exponentRewardDelayLeft = exponentRewardDelayLeft(:);

maximumRewardDelayRight  = [GUI(1:nTrials).FeedbackDelayMax]; 
maximumRewardDelayRight  = maximumRewardDelayRight(:);
minimumRewardDelayRight  = [GUI(1:nTrials).FeedbackDelayMin]; 
minimumRewardDelayRight  = minimumRewardDelayRight(:);
exponentRewardDelayRight = [GUI(1:nTrials).FeedbackDelayTau]; 
exponentRewardDelayRight = exponentRewardDelayRight(:);

% This value is always 1, should this be Custom.AuditoryOmega, which changes every trial
alpha               = [GUI(1:nTrials).AuditoryAlpha]; 
alpha = alpha(:);

% Not sure this is correct
punishGrace = [GUI(1:nTrials).FeedbackDelayGrace];
punishGrace = punishGrace(:);


%% Calculate correct side per BPod and per actual Clicks

rightClickTrain = Custom.RightClickTrain(1:nTrials);
rightClickTrain = rightClickTrain(:);
leftClickTrain  = Custom.LeftClickTrain(1:nTrials);
leftClickTrain  = leftClickTrain(:);


for trialI = 1:nTrials
    rightClicksIdx{trialI,1} = rightClickTrain{trialI} <= Custom.ST(trialI);
    rightClickCount(trialI,1) = sum(rightClicksIdx{trialI});
    rightClickTrainActual{trialI,1} = ...
        rightClickTrain{trialI}(rightClicksIdx{trialI});
    
    leftClicksIdx{trialI,1} = leftClickTrain{trialI} <= Custom.ST(trialI);
    leftClickCount(trialI,1) = sum(leftClicksIdx{trialI});
    leftClickTrainActual{trialI,1} = ...
        leftClickTrain{trialI}(leftClicksIdx{trialI});
    
    correctSideBpod(trialI,1) = categorical(...
        length(leftClickTrain{trialI}) > length(rightClickTrain{trialI}),...
        [1,0],{'left','right'});     
    
    correctSideClicks(trialI,1) = categorical(...
        length(leftClickTrainActual{trialI}) > length(rightClickTrainActual{trialI}),...
        [1,0],{'left','right'});
    
    sideChosen(trialI,1) = categorical(...
        Custom.ChoiceLeft(trialI),[1,0,nan],{'left','right','no choice'});
    
    completedSampling(trialI,1) = ~Custom.FixBroke(trialI) && ~Custom.EarlyWithdrawal(trialI);
    % Are completedSampling and completed ever different? Yes, when the
    % animal doesn't make a choice
    completed(trialI,1)         = ~Custom.FixBroke(trialI) && ~Custom.EarlyWithdrawal(trialI) ...
                              && ~isnan(Custom.ChoiceLeft(trialI));
    
    
    
    switch sideChosen(trialI)
        case 'left'
            if correctSideBpod(trialI,1) == 'right'
                errorBpod(trialI,1) = true;
            else
                errorBpod(trialI,1) = false;
            end
            if correctSideClicks(trialI,1) == 'right'
                errorClicks(trialI,1) = true;
            else
                errorClicks(trialI,1) = false;
            end
        case 'right'
            if correctSideBpod(trialI,1) == 'left'
                errorBpod(trialI,1) = true;
            else
                errorBpod(trialI,1) = false;
            end
            if correctSideClicks == 'left'
                errorClicks(trialI,1) = true;
            else
                errorClicks(trialI,1) = false;
            end
        case 'no choice'
            errorBpod(trialI,1) = false;
            errorClicks(trialI,1) = false;
    end
    
    
    % Add extra time to waiting time - state transitions are missing
    % Get state matrix
    
    trialStates = SessionData.RawEvents.Trial{trialI}.States;
    portEntryTime = trialStates.wait_Sin(2);
    switch sideChosen(trialI)
        case 'left'
            if rewarded(trialI)
                waitingTime(trialI,1) = (trialStates.rewarded_Lin(end,2) - portEntryTime) + 0.0001;
            else
                waitingTime(trialI,1) = (trialStates.rewarded_Lin_grace(end,1) - portEntryTime) + 0.0001;
            end
        case 'right'
            if rewarded(trialI)
                waitingTime(trialI,1) = (trialStates.rewarded_Rin(end,2) - portEntryTime) + 0.0001;
            else
                waitingTime(trialI,1) = (trialStates.rewarded_Rin_grace(end,1) - portEntryTime) + 0.0001;
            end
    end
  
 end
    
    
%% Calculate a bunch of logical conditions

sideChosen = sideChosen(:);
completed  = completed(:);
rewarded   = rewarded(:);

correctSideChosenClicks = correctSideClicks == sideChosen;
% correctSideChosenClicks(sideChosen == 'no choice') = nan;

correctSideChosenBpod   = correctSideBpod   == sideChosen;
% correctSideChosenBpod(sideChosen == 'no choice') = nan;

completedCatchTrial = catchTrial & completed;

correctCatchEvidenceClicks  = correctSideChosenClicks & catchTrial;
errorCatchEvidenceClicks    = errorClicks & catchTrial;
correctLeftChoiceClicks     = correctSideChosenClicks & sideChosen == 'left';
correctRightChoiceClicks    = correctSideChosenClicks & sideChosen == 'right';
errorLeftChoiceClicks       = errorClicks & sideChosen == 'left';
errorRightChoiceClicks      = errorClicks & sideChosen == 'right';

highEvidenceSideBpod   = correctSideBpod(:);
highEvidenceSideClicks = correctSideClicks(:);
punishState = errorBpod(:); % Not sure this is correct

nLeftClicks  = leftClickCount(:);
nRightClicks = rightClickCount(:);

completedSampling = completedSampling(:);

leftSampledClicks  = leftClickTrainActual(:);
rightSampledClicks = rightClickTrainActual(:);

%% Force some variables into columns
correctSideBpod             = correctSideBpod(:);
correctSideClicks           = correctSideClicks(:);
errorClicks                 = errorClicks(:);
leftClickCount              = leftClickCount(:);
leftClicksIdx               = leftClicksIdx(:);
leftClickTrainActual        = leftClickTrainActual(:); 
preStimulusDelayDuration    = preStimulusDelayDuration(:);
rewardDelayBpod             = rewardDelayBpod(:);
rightClickCount             = rightClickCount(:);
rightClicksIdx              = rightClicksIdx(:);
rightClickTrainActual       = rightClickTrainActual(:);
waitingTime                 = waitingTime(:);

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

