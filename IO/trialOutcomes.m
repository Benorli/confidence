function [T] = trialOutcomes(T)

% temporary function to convert bpod data table (from 2AFC task) to add
% extra variables and useful data



%% Create a categorical description of trial types

% Glossary: Match means Bpod and click evidence agrees, Mismatch means they
%           disagree 
%           Correct and Error always refers to the Bpods decision
%           based on the programmed trial type (left or right)
%

% Description of trial types and logic

% Uncompleted: Trial did not end with Reward/Punish,
%          nearly always means animal didn't sample correctly
% Definition: End State = ~WaitForReward | ~Punish    
%             Can use ~T.completedTrial

% Match, Correct, Rewarded: Correct decision ending with Reward,
%          truly correct for both Bpod and actual clicks heard
% Definition: (highEvidenceSideBpod & highEvidenceSideClicks ==
%             sideChosen) & ~CatchTrial & T.completedTrial

% Match, Error, Unrewarded: Incorrect decision ending with punishment,
%          truly incorrect for both Bpod and actual clicks
% Definition: (highEvidenceSideBpod & highEvidenceSideClicks ==
%             ~sideChosen) & ~CatchTrial & T.completedTrial

% Match, Correct, Unrewarded - WT
% Animal made correct decision(Bpod), but didn't reach waiting time.
% Definition: ~catchTrial & correctSideChosenBpod & correctSideChosenClicks
% & ~rewardedTrial & T.completedTrial
%            This needs to be verified, but seems to work

% Mismatch, BPod Correct, Unrewarded - WT
%Animal made correct decision(Bpod), but didn't reach waiting time.
% Definition: ~catchTrial & correctSideChosenBpod & ~rewardedTrial & T.completedTrial
%            This needs to be verified, but seems to work

% Mismatch, Incorrect Clicks, Rewarded: Mismatch between evidence and bpod, 
%          We either keep these and treat them as low-evidence correct or
%          discard
% Definition: ~T.catchTrial & ~T.correctSideChosenClicks & T.rewardedTrial & T.completedTrial

% Match, Catch, Correct:  Catch trial where animal made the correct decision and
%           evidence and bpod agree
% Definition: T.catchTrial & T.correctSideChosenBpod & T.correctSideChosenClicks

% Mismatch, Catch, Correct Clicks
%      B = Catch trial where animal made the correct decision by the
%           evidence but the bpod is incorrect
% Definition: T.catchTrial & ~T.correctSideChosenBpod & T.correctSideChosenClicks
%          
% Match, Catch, Error: Catch trial where animal made the wrong 
%          decision and the evidence and Bpod agrees
% Definition: T.catchTrial & ~T.correctSideChosenBpod & ~T.correctSideChosenClicks    

% Mismatch, Catch, Correct Bpod, : Catch trial where animal made 
%          the wrong decision on the clicks but the Bpod disagrees
% Definition: T.catchTrial & T.correctSideChosenBpod & ~T.correctSideChosenClicks    

% Mismatch, (PsuedoCatch), Correct Clicks, : Animal made correct 
%           decision by Clicks, but Bpod disagrees
% Definition: ~catchTrial & correctSideChosenClicks & ~rewardedTrial
%           This needs to be verified, but seems to work

%% Implementation of logic

% First get some potentiallt useful combinations
evidenceMatch    = T.highEvidenceSideBpod == T.highEvidenceSideClicks & ...
                   T.completedTrial;
evidenceMismatch = T.highEvidenceSideBpod ~= T.highEvidenceSideClicks &...
                   T.completedTrial;
choiceMatchBpod  = T.sideChosen == T.highEvidenceSideBpod;
choiceMatchClick = T.sideChosen == T.highEvidenceSideClicks;

% Type 1 = Uncompleted: Trial did not end with Reward/Punish,
trialOutcome(~T.completedTrial) = categorical({'Uncompleted'});

% Type 2 = Correct: Correct decision ending with Reward,
correctBpodClick  = evidenceMatch & choiceMatchBpod;
trialOutcome(correctBpodClick & ~T.catchTrial & T.completedTrial) ...
             = categorical({'Match, Correct, Rewarded'});

% Type 3 = Incorrect: Incorrect decision ending with punishment,
errorBpod = T.sideChosen ~= T.highEvidenceSideBpod;
trialOutcome(errorBpod & evidenceMatch & ~T.catchTrial & T.completedTrial) ...
             = categorical({'Match, Error, Unrewarded'});
  
% Match, Correct, Unrewarded - WT Animal made correct decision(Bpod & Clicks)
%           but didn't reach waiting time.
trialOutcome(~T.catchTrial & T.correctSideChosenBpod &  T.correctSideChosenClicks ...
             & ~T.rewardedTrial & T.completedTrial) = ...
             categorical({'Match, Correct, Unrewarded - WT'});
         
 % Match, Catch, Correct: Catch trial where animal made the correct decision 
%                        and evidence and bpod agree
trialOutcome(T.catchTrial & T.correctSideChosenBpod & ...
             T.correctSideChosenClicks & T.completedTrial) ...
             = categorical({'Match, Catch, Correct '});   
         
% Match, Catch, Error: Catch trial where animal made the wrong decision and the
%          evidence and Bpod agrees
trialOutcome(T.catchTrial & ~T.correctSideChosenBpod ...
             & ~T.correctSideChosenClicks & T.completedTrial) ...
            = categorical({'Match, Catch, Error'});             
         
% Mismatch, Incorrect Clicks, Rewarded: Disconnect between clicks and bpod    
trialOutcome(~T.catchTrial & ~T.correctSideChosenClicks & T.rewardedTrial ...
             & T.completedTrial) = categorical({'Mismatch, Incorrect Clicks, Rewarded'}); 
     
         
 % Mismatch, Bpod Correct, Unrewarded - WT Animal made correct decision(Bpod)
%           but didn't reach waiting time.
trialOutcome(~T.catchTrial & T.correctSideChosenBpod &  ~T.correctSideChosenClicks ...
             & ~T.rewardedTrial & T.completedTrial) = ...
             categorical({'Mismatch, Bpod Correct, Unrewarded - WT'});  
         
% Mismatch, Catch, Correct Clicks = Catch trial where animal made the 
%           correct decision by the clicks but the bpod is incorrect
trialOutcome(T.catchTrial & ~T.correctSideChosenBpod ...
             & T.correctSideChosenClicks & T.completedTrial ) ...
             = categorical({'Mismatch, Catch, Correct Clicks'});        
               
        
% Mismatch, Catch, Correct Bpod:  Catch trial where animal made the wrong 
%          decision on the clicks but the Bpod disagrees          
trialOutcome(T.catchTrial & T.correctSideChosenBpod ...
             & T.completedTrial & ~T.correctSideChosenClicks) ...
             = categorical({'Mismatch, Catch, Correct Bpod'}); 

% Mismatch, (PsuedoCatch), Correct Clicks: Animal made correct decision by 
%           Clicks, but Bpod disagrees
trialOutcome(~T.catchTrial & T.correctSideChosenClicks & ~T.correctSideChosenBpod...
             & T.completedTrial & ~T.rewardedTrial) ...
             = categorical({'Mismatch, (PsuedoCatch), Correct Clicks'}); 

trialOutcome = trialOutcome';

%%  Create a mismatch column

mismatch = evidenceMismatch;


%% Add to table
T = [T table(trialOutcome, mismatch)];






