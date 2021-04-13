function trialInfo = trialExplorer(trialNum, sessionData)
%% Pulls out some relevant info for any trial number you throw in
% Designed to help confirm the logic behind trial events
% INPUT 
% trialNum = trial number you want to look at (scalar)
% sessionData = struct of bpod Click2AFC results


%% Check inputs

assert(trialNum <= sessionData.nTrials,'Trial Number too high');

%% 

% Which side was the trial evidence (supposed to be) on?
trialInfo.EvidenceSideBpod = sessionData.TrialTypes;

% How long did the animal sample the evidence?
trialInfo.SamplingDuration = sessionData.SamplingDuration;

% Was the trial a catch trial
trialInfo.CatchTrial = sessionData.CatchTrial(trialNum);

% Was the trial punished (punished = time out?)
trialInfo.Punished = sessionData.PunishedTrial(trialNum);

% Was the trial sampled (sampled = completed sampling?)
trialInfo.Sampled = sessionData.SampledTrial(trialNum);

% Was the choice on the correct side (correct side = made the correct choice?)
trialInfo.CorrectSide = sessionData.CorrectSide(trialNum);

% What was the chosen direction (chosen direction = actual choice?)
switch sessionData.ChosenDirection(trialNum)
    case 1
        trialInfo.ChosenDirection = categorical({'Correct'});
    case 2
        trialInfo.ChosenDirection = categorical({'Incorrect'});
    case 3
        trialInfo.ChosenDirection = categorical({'No Choice'});
end

% Which side actually had the most clicks 
switch sessionData.MostClickSide(trialNum) % if they are even this is random
    case 1
        trialInfo.MostclickSide = categorical({'Left'});
    case 2
        trialInfo.MostclickSide = categorical({'Right'});
end

% Which side did the animal choose given the evidence heard?
trialInfo.ChoiceGivenClick = sessionData.ChoiceGivenClick(trialNum);

% Was the trial completed (completed = Punish|WaitforReward occurs)
trialInfo.Completed = sessionData.CompletedTrial(trialNum);

% Was it a completed catch trial (completed trial and a catch trial)
trialInfo.CompletedCatchTrial = sessionData.CompletedCatchTrial;

% What type of completed catch trial was it?
% Type 1 = CompletedCatchTrial & Correct Choice Given Clicks
trialInfo.CorrectCatchType1 = sessionData.CorrectCatchTrial_type1(trialNum);
% Type 2 = Wait for Reward Start & ~Reward & ~CompletedCatch
% Maybe this is when the choice given clicks doesn't match the programmed side?
trialInfo.CorrectCatchType2 = sessionData.CorrectCatchTrial_type2(trialNum);

% How long did the animal wait for?
trialInfo.AnimalWaited = sessionData.WaitingTime(trialNum);

% Was the catch trial correct? correctCatchTrial =
% correctCatch1|correctCatch2 if ConfidenceReport == 1 in GUI...
trialInfo.CorrectCatchTrial = sessionData.CorrectCatchTrial(trialNum);

% Was the catch trial incorrect? incorrectCatchTrial =
% completedCatch & ~choicegivenclick
trialInfo.IncorrectCatchTrial = sessionData.IncorrectCatchTrial(trialNum);

% How hard was the choice? RatioDiscri = log10(NRightClick./NLeftClick)
trialInfo.StimulusDifficulty = sessionData.RatioDiscri(trialNum);

% Was the trial rewarded? Trial is rewarded if waitforReward and Reward
% states both occur
trialInfo.RewardedTrial = sessionData.RewardedTrial(trialNum);

% Correct sides = choice give click is correct and side is left/right
trialInfo.CorrectLeft = sessionData.CorrectLeft(trialNum);
trialInfo.CorrectRight = sessionData.CorrectRight(trialNum);

% Incorrect sides = choice give click is incorrect and side is left/right
trialInfo.ErrorLeft = sessionData.ErrorLeft(trialNum);
trialInfo.ErrorRight = sessionData.ErrorRight(trialNum);









% % Get correct WaitingTime Trials
% BpodSystem.Data.CorrectWaitingTimeTrials(currentTrial)=BpodSystem.Data.CorrectCatchTrial(currentTrial)==1 & ...
%     BpodSystem.Data.WaitingTime(currentTrial)>BpodSystem.Data.WTlimitLow & ...
%     BpodSystem.Data.WaitingTime(currentTrial)<BpodSystem.Data.WTlimitHigh;

% Get incorrect WaitingTime Trials
% BpodSystem.Data.InCorrectWaitingTimeTrials(currentTrial)= ...
%     (BpodSystem.Data.IncorrectCatchTrial(currentTrial)==1 |  ...
%     ((BpodSystem.Data.PunishedTrial(currentTrial)==1 &  ...
%     BpodSystem.Data.CompletedTrial(currentTrial)==1) &  ...
%     BpodSystem.Data.ChoiceGivenClick(currentTrial)==0)) & ...
%     BpodSystem.Data.WaitingTime(currentTrial)>BpodSystem.Data.WTlimitLow & ...
%     BpodSystem.Data.WaitingTime(currentTrial)<BpodSystem.Data.WTlimitHigh;


