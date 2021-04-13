function trialInfo = trialExplorer(trialNum, sessionData)
%% Pulls out some relevant info for any trial number you throw in
% Designed to help confirm the logic behind trial events
% INPUT 
% trialNum = trial number you want to look at (scalar)
% sessionData = struct of bpod Click2AFC results


%% Check inputs

assert(trialNum <= sessionData.nTrials,'Trial Number too high');

%% 

% Was the trial completed (completed = finished?)
trialInfo.Completed = sessionData.CompletedTrial(trialNum);

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
        
trialInfo.ChosenDirection = sessionData.ChosenDirection(trialNum);
