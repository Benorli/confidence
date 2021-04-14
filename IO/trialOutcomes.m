function [T] = trialOutcomes(T)
% Takes bpod data table that has been generated using trials2table
% (from 2AFC task) and adds some extra variables and useful data



%% Create a categorical description of trial types
% Glossary: Match means Bpod and click evidence agrees, Mismatch means they
%           disagree 
%           Correct and Error always refers to the Bpods decision
%           based on the programmed trial type (left or right)

% First get some potentially useful combinations
evidenceMatch    = T.highEvidenceSideBpod == T.highEvidenceSideClicks & ...
                   T.completedTrial;
evidenceMismatch = T.highEvidenceSideBpod ~= T.highEvidenceSideClicks &...
                   T.completedTrial;
choiceMatchBpod  = T.sideChosen == T.highEvidenceSideBpod;
choiceMatchClick = T.sideChosen == T.highEvidenceSideClicks;

% Uncompleted: Trial did not end with Reward/Punish
%   Usually means animal didn't sample correctly
trialOutcome(~T.completedTrial) = categorical({'Uncompleted'});

% Match, Correct, Rewarded: Correct decision ending with Reward
%   Correct for both Bpod and actual clicks
correctBpodClick  = evidenceMatch & choiceMatchBpod;
trialOutcome(correctBpodClick & ~T.catchTrial & T.completedTrial) ...
             = categorical({'Match, Correct, Rewarded'});

% Match, Error, Unrewarded: Incorrect decision ending with punishment,
% Incorrect for both Bpod and actual clicks
errorBpod = T.sideChosen ~= T.highEvidenceSideBpod;
trialOutcome(errorBpod & evidenceMatch & ~T.catchTrial & T.completedTrial) ...
             = categorical({'Match, Error, Unrewarded'});
  
% Match, Correct, Unrewarded - WT Animal made correct decision(Bpod & Clicks)
%   but didn't reach waiting time
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






