function trialInfo = trialExplorer(trialNum, T)
%% Pulls out some relevant info for any trial number you throw in
% Designed to help confirm the logic behind trial events
% INPUT 
% trialNum = trial number you want to look at (scalar)
% sessionData = struct of bpod Click2AFC results


%% Check inputs

assert(trialNum <= height(T),'Trial Number too high');

%% 
% Was the trial completed (completed = Punish|WaitforReward occurs)
trialInfo.Completed = T.completedTrial(trialNum);

% Which side was the trial evidence (supposed to be) on?
% What was the chosen direction (chosen direction = actual choice?)
trialInfo.highEvidenceSideBpod = T.highEvidenceSideBpod(trialNum);

% Which side actually had the most clicks 
trialInfo.highEvidenceSideClicks = T.highEvidenceSideClicks(trialNum);

% What was the chosen direction (chosen direction = actual choice?)
trialInfo.sideChosen = T.sideChosen(trialNum);

% Which side did the animal choose given the evidence heard?
switch T.correctSideChosenClicks(trialNum)
    case 1
        trialInfo.correctSideChosenClicks = categorical({'Correct'});
    case 0
        trialInfo.correctSideChosenClicks = categorical({'Incorrect'});
end

% Does the Bpod think the animal made the right choice?
switch T.correctSideChosenBpod(trialNum)
    case 1
        trialInfo.correctSideChosenBpod = categorical({'Correct'});
    case 0
        trialInfo.correctSideChosenBpod = categorical({'Incorrect'});
end
   
% Was the trial sampled (sampled = completed sampling?)
trialInfo.completedSampling = T.completedSampling(trialNum);

% How long did the animal sample the evidence?
trialInfo.samplingDuration = T.samplingDuration(trialNum);

% Was the trial a catch trial
trialInfo.catchTrial = T.catchTrial(trialNum);

% Was it a completed catch trial (completed trial and a catch trial)
trialInfo.completedCatchTrial = T.completedCatchTrial(trialNum);

% Was the trial rewarded? Trial is rewarded if waitforReward and Reward
% states both occur
trialInfo.rewardedTrial = T.rewardedTrial(trialNum);

% Was the trial punished (punished = time out?)
trialInfo.completedErrorBpod = T.completedErrorBpod(trialNum);

% What type of completed catch trial was it?
% Type 1 = CompletedCatchTrial & Correct Choice Given Clicks
trialInfo.correctCatchEvidenceClicks = T.correctCatchEvidenceClicks(trialNum);
% Type 2 = Wait for Reward Start & ~Reward & ~CompletedCatch
% Maybe this is when the choice given clicks doesn't match the programmed side?
% trialInfo.CorrectCatchType2 = T.CorrectCatchTrial_type2(trialNum);

% How long was the animal supposed to wait?
trialInfo.BpodWaitingTime = T.rewardDelayBpod(trialNum);

% How long did the animal wait for?
trialInfo.actualWaitingTime = T.waitingTime(trialNum);

% Was the catch trial correct? correctCatchTrial =
% correctCatch1|correctCatch2 if ConfidenceReport == 1 in GUI...
% trialInfo.CorrectCatchTrial = T.CorrectCatchTrial(trialNum);

% % Was the catch trial incorrect? incorrectCatchTrial =
% % completedCatch & ~choicegivenclick
% trialInfo.IncorrectCatchTrial = T.IncorrectCatchTrial(trialNum);

% How hard was the choice? RatioDiscri = log10(NRightClick./NLeftClick)
trialInfo.Evidence = (T.nRightClicks(trialNum) - T.nLeftClicks(trialNum))...
                            ./ (T.nRightClicks(trialNum) + T.nLeftClicks(trialNum));

% Correct sides = choice give click is correct and side is left/right
trialInfo.correctLeftChoiceClicks  = T.correctLeftChoiceClicks(trialNum);
trialInfo.correctRightChoiceClicks = T.correctRightChoiceClicks(trialNum);

% Incorrect sides = choice give click is incorrect and side is left/right
trialInfo.errorLeftChoiceClicks  = T.errorLeftChoiceClicks(trialNum);
trialInfo.errorRightChoiceClicks = T.errorRightChoiceClicks(trialNum);

trialInfo.NClicksLeft  = T.nLeftClicks(trialNum);
trialInfo.NClicksRight = T.nRightClicks(trialNum);
trialInfo.ClickDifference = trialInfo.NClicksRight - trialInfo.NClicksLeft;









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


