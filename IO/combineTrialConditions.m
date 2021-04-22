function [T] = combineTrialConditions(T)
% Takes bpod data table that has been generated using trials2table
% (from 2AFC task) and adds some extra variables and useful data

validateattributes(T, {'table'}, {})

%% Create a categorical description of trial types
% Glossary: Match means Bpod and click evidence agrees, Mismatch means they
%           disagree 
%           Correct and Error always refers to the Bpods decision
%           based on the programmed trial type (left or right)

% First get some potentially useful combinations
evidenceMatch    = T.highEvidenceSideBpod == T.highEvidenceSideClicks & ...
                   T.completed;
evidenceMismatch = T.highEvidenceSideBpod ~= T.highEvidenceSideClicks &...
                   T.completed;
choiceCorrectBpod  = T.sideChosen == T.highEvidenceSideBpod;

% Uncompleted: Trial did not end with Reward/Punish
%   Usually means animal didn't sample correctly
trialOutcome(~T.completed) = categorical({'Uncompleted'});

% Match, Correct, Rewarded: Correct decision ending with Reward
%   Correct for both Bpod and actual clicks
correctBpodClick  = evidenceMatch & choiceCorrectBpod;
trialOutcome(correctBpodClick & ~T.catchTrial & T.completed) ...
             = categorical({'Match, Correct, Rewarded'});

% Match, Error, Unrewarded: Incorrect decision ending with punishment,
% Incorrect for both Bpod and actual clicks
errorBpod = T.sideChosen ~= T.highEvidenceSideBpod;
trialOutcome(errorBpod & evidenceMatch & ~T.catchTrial & T.completed) ...
             = categorical({'Match, Error, Unrewarded'});
  
% Match, Correct, Unrewarded - WT Animal made correct decision(Bpod & Clicks)
%   but didn't reach waiting time
trialOutcome(~T.catchTrial & T.correctSideChosenBpod &  T.correctSideChosenClicks ...
             & ~T.rewarded & T.completed) = ...
             categorical({'Match, Correct, Unrewarded - WT'});
         
 % Match, Catch, Correct: Catch trial where animal made the correct decision 
%                        and evidence and bpod agree
trialOutcome(T.catchTrial & T.correctSideChosenBpod & ...
             T.correctSideChosenClicks & T.completed) ...
             = categorical({'Match, Catch, Correct'});   
         
% Match, Catch, Error: Catch trial where animal made the wrong decision and 
%          the evidence and Bpod agrees
trialOutcome(T.catchTrial & ~T.correctSideChosenBpod ...
             & ~T.correctSideChosenClicks & T.completed) ...
            = categorical({'Match, Catch, Error'});             
         
% Mismatch, Incorrect Clicks, Rewarded: Disconnect between clicks and bpod    
trialOutcome(~T.catchTrial & ~T.correctSideChosenClicks & T.rewarded ...
             & T.completed) = categorical({'Mismatch, Incorrect Clicks, Rewarded'}); 
     
         
 % Mismatch, Bpod Correct, Unrewarded - WT Animal made correct decision(Bpod)
%           but didn't reach waiting time.
trialOutcome(~T.catchTrial & T.correctSideChosenBpod &  ~T.correctSideChosenClicks ...
             & ~T.rewarded & T.completed) = ...
             categorical({'Mismatch, Correct Bpod, Unrewarded - WT'});  
         
% Mismatch, Catch, Correct Clicks = Catch trial where animal made the 
%           correct decision by the clicks but the bpod is incorrect
trialOutcome(T.catchTrial & ~T.correctSideChosenBpod ...
             & T.correctSideChosenClicks & T.completed ) ...
             = categorical({'Mismatch, Catch, Correct Clicks'});        
               
        
% Mismatch, Catch, Correct Bpod:  Catch trial where animal made the wrong 
%          decision on the clicks but the Bpod disagrees          
trialOutcome(T.catchTrial & T.correctSideChosenBpod ...
             & T.completed & ~T.correctSideChosenClicks) ...
             = categorical({'Mismatch, Catch, Correct Bpod'}); 

% Mismatch, (PseudoCatch), Correct Clicks: Animal made correct decision by 
%           Clicks, but Bpod disagrees
trialOutcome(~T.catchTrial & T.correctSideChosenClicks & ~T.correctSideChosenBpod...
             & T.completed & ~T.rewarded) ...
             = categorical({'Mismatch, (PseudoCatch), Correct Clicks'}); 

T.trialOutcome = trialOutcome';

%%  Create a mismatch column

T.mismatch = evidenceMismatch;



%% Trial conditions

T.correctRewardedMatch = T.trialOutcome == 'Match, Correct, Rewarded';
T.errorUnRewardedMatch = T.trialOutcome == 'Match, Error, Unrewarded';
T.correctUnrewardedWTMatch = T.trialOutcome ==...
    'Match, Correct, Unrewarded - WT';
T.catchCorrectMatch = T.trialOutcome == 'Match, Catch, Correct';
T.catchErrorMatch = T.trialOutcome == 'Match, Catch, Error';
% T.mismatchIncorrectClicksRewarded = T.trialOutcome ==...
%     'Mismatch, Incorrect Clicks, Rewarded';
% T.mismatchCorrectBpodUnrewardedWT = T.trialOutcome ==...
%     'Mismatch, Correct Bpod, Unrewarded - WT';
% T.mismatchCatchCorrectClicks = T.trialOutcome ==...
%     {'Mismatch, Catch, Correct Clicks'};
% T.mismatchCatchCorrectBpod = T.trialOutcome ==...
%     'Mismatch, Catch, Correct Bpod';
% T.mismatchPseudoCatchCorrectClicks = T.trialOutcome ==...
%     'Mismatch, (PseudoCatch), Correct Clicks';

T.waitingTimeDropOut = T.correctUnrewardedWTMatch |...
    T.trialOutcome == 'Mismatch, Correct Bpod, Unrewarded - WT';
T.correctCatchBpod = T.correctSideChosenBpod & T.catchTrial;
T.selfExit = T.completed & ~T.rewarded;

T.decisionVariable = (T.nRightClicks - T.nLeftClicks)...
    ./ (T.nRightClicks + T.nLeftClicks);

end



























